/*
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Gabriel Ebner
*/
#pragma once
#include <sstream>
#include <string>
#include <vector>
#include <unordered_set>
#include <library/message_buffer.h>
#include "util/thread.h"
#include "util/optional.h"
#include "util/rc.h"

namespace lean {

enum class task_result_state { QUEUED, EXECUTING, FINISHED, FAILED };

class generic_task;
class generic_task_result_cell {
    MK_LEAN_RC()
    void dealloc() { delete this; }

    friend class task_queue;
    friend class st_task_queue;
    friend class mt_task_queue;
    template <class T> friend class task_result_cell;
    friend class generic_task_result;

    generic_task * m_task = nullptr;
    atomic<task_result_state> m_state { task_result_state::QUEUED };
    std::string m_desc;
    std::exception_ptr m_ex;

    virtual ~generic_task_result_cell() { clear_task(); }
    void clear_task();

    generic_task_result_cell(generic_task * t);
    generic_task_result_cell(std::string const & desc) :
            m_rc(0), m_state(task_result_state::FINISHED), m_desc(desc) {}

    bool has_evaluated() const {
        auto state = m_state.load();
        return state != task_result_state::QUEUED && state != task_result_state::EXECUTING;
    }

    virtual void execute_and_store_result() = 0;
    bool execute();
};

class generic_task_result {
    friend class task_queue;
    friend class st_task_queue;
    friend class mt_task_queue;
    template <class T> friend class task_result;

    generic_task_result_cell * m_ptr = nullptr;

    generic_task_result_cell * operator->() const { return m_ptr; }
    generic_task_result_cell & operator*() const { return *m_ptr; }

public:
    generic_task_result(generic_task_result_cell * t) : m_ptr(t) { if (t) t->inc_ref(); }
    generic_task_result() {}
    generic_task_result(generic_task_result && t) : m_ptr(t.m_ptr) { t.m_ptr = nullptr; }
    generic_task_result(generic_task_result const & t) : m_ptr(t.m_ptr) { if (m_ptr) m_ptr->inc_ref(); }
    ~generic_task_result() { if (m_ptr) m_ptr->dec_ref(); m_ptr = nullptr; }

    generic_task_result & operator=(generic_task_result const & t) { LEAN_COPY_REF(t); }
    generic_task_result & operator=(generic_task_result && t) { LEAN_MOVE_REF(t); }

    bool operator==(generic_task_result const & t) const { return m_ptr == t.m_ptr; }
    operator bool() const { return m_ptr != nullptr; }

    struct hash {
        size_t operator()(generic_task_result const & t) const {
            return std::hash<generic_task_result_cell *>()(t.m_ptr);
        }
    };

    std::string description() const { return m_ptr->m_desc; }
    void cancel() const;

    void reset() { *this = nullptr; }
};

struct task_priority {
    unsigned m_prio = static_cast<unsigned>(-1);
    optional<chrono::steady_clock::time_point> m_not_before;

    bool operator<(task_priority const & p) const {
        if (m_prio < p.m_prio) return true;
        if (m_not_before && p.m_not_before && *m_not_before < *p.m_not_before) return true;
        if (!m_not_before && p.m_not_before) return true;
        return false;
    }

    void bump(task_priority const & p) {
        if (p.m_prio < m_prio) m_prio = p.m_prio;
        if (m_not_before && p.m_not_before && *p.m_not_before < *m_not_before)
            *m_not_before = *p.m_not_before;
    }
};

typedef std::string module_id;
enum class task_kind { parse, elab, print };

module_id get_current_module();
pos_info get_current_task_pos();
class scoped_task_context {
    module_id * m_old_id;
    pos_info * m_old_pos;
    module_id m_id;
    pos_info m_pos;

public:
    scoped_task_context(module_id const & mod, pos_info const & pos);
    ~scoped_task_context();
};

class generic_task {
    template <class T> friend class task;
    friend class task_queue;
    friend class st_task_queue;
    friend class mt_task_queue;

    task_priority m_prio;
    std::vector<generic_task_result> m_reverse_deps;
    condition_variable m_has_finished;

    // metadata
    message_bucket_id m_bucket;
    module_id m_mod;
    pos_info m_pos;

public:
    generic_task();
    virtual ~generic_task() {}

    virtual void description(std::ostream &) const = 0;
    std::string description() const;
    virtual std::vector<generic_task_result> get_dependencies() { return {}; }

    virtual bool is_tiny() const { return false; }
    virtual task_kind get_kind() const { return task_kind::elab; }
    virtual pos_info get_pos() const { return get_task_pos(); }

    message_bucket_id const & get_bucket() const { return m_bucket; }
    period get_version() const { return m_bucket.m_version; }
    module_id const & get_module_id() const { return m_mod; }
    pos_info const & get_task_pos() const { return m_pos; }
};

template <class T>
class task : public generic_task {
public:
    typedef T result;
    virtual ~task() {}
    virtual T execute() = 0;
};

template <class T>
class task_result_cell : public generic_task_result_cell {
    friend class task_queue;
    template <class S> friend class task_result;

    optional<T> m_result;

    task<T> * get_ptr() { return static_cast<task<T> *>(m_task); }

    virtual void execute_and_store_result() override {
        m_result = { get_ptr()->execute() };
    }

public:
    task_result_cell(task<T> * t) : generic_task_result_cell(t) {}
    task_result_cell(T const & t, std::string const & desc) :
            generic_task_result_cell(desc), m_result(t) {}
};

template <class T>
class task_result : public generic_task_result {
    friend class task_queue;

    optional<T> const & get_current_result() const { return static_cast<task_result_cell<T> *>(m_ptr)->m_result; }

public:
    task_result(task_result_cell<T> * t) : generic_task_result(t) {}
    task_result() : generic_task_result() {}
    task_result(task_result<T> const & t) : generic_task_result(t) {}
    task_result(task_result<T> && t) : generic_task_result(t) {}

    task_result<T> & operator=(task_result<T> const & t) { LEAN_COPY_REF(t); }
    task_result<T> & operator=(task_result<T> && t) { LEAN_MOVE_REF(t); }

    T const & get() const;

    optional<T> peek() const {
        if (m_ptr->m_state.load() == task_result_state::FINISHED) {
            return get_current_result();
        } else {
            return optional<T>();
        }
    }
};

template <class T>
task_result<T> mk_pure_task_result(T const & t, std::string const & desc) {
    return task_result<T>(new task_result_cell<T>(t, desc));
}

class task_cancellation_exception : public std::exception {
    generic_task_result m_cancelled_task;
    std::string m_msg;
public:
    task_cancellation_exception() : task_cancellation_exception(generic_task_result()) {}
    task_cancellation_exception(generic_task_result const & cancelled_task);
    char const * what() const noexcept override;

    generic_task_result get_cancelled_task() const { return m_cancelled_task; }
};

class task_queue {
    virtual void submit(generic_task_result const &) = 0;

protected:
    task_queue() {}

public:
    virtual ~task_queue() {}

    virtual optional<generic_task_result> get_current_task() = 0;
    virtual bool empty() = 0;

    template <typename T, typename... As>
    task_result<typename T::result> submit(As... args) {
        task_result<typename T::result> task(
                new task_result_cell<typename T::result>(
                        new T(std::forward<As>(args)...)));
        submit(task);
        return task;
    }

    template <typename T>
    T const & get_result(task_result<T> const & t) {
        while (true) {
            switch (t->m_state.load()) {
                case task_result_state::FINISHED:
                    return *t.get_current_result();
                case task_result_state::FAILED:
                    std::rethrow_exception(t->m_ex);
                default:
                    wait(t);
            }
        }
    }

    virtual void wait(generic_task_result const & t) = 0;

    virtual void cancel(generic_task_result const & t) = 0;
    virtual void cancel_if(std::function<bool(generic_task *)> const & pred) = 0; // NOLINT

    using progress_cb = std::function<void(generic_task *)>; // NOLINT
    // disabling lint because it this this is cast ^^^
    virtual void set_progress_callback(progress_cb const &) = 0;
};

class scope_global_task_queue {
    task_queue * m_old_tq;
public:
    scope_global_task_queue(task_queue * tq);
    ~scope_global_task_queue();
};
task_queue & get_global_task_queue();

template <class T>
T const & task_result<T>::get() const {
    return get_global_task_queue().get_result(*this);
}

inline void generic_task_result::cancel() const {
    get_global_task_queue().cancel(*this);
}

}
