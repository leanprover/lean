/*
Copyright (c) 2014 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include <string>
#include <algorithm>
#include "util/lbool.h"
#include "util/sstream.h"
#include "util/fresh_name.h"
#include "kernel/instantiate.h"
#include "library/scoped_ext.h"
#include "library/kernel_serializer.h"
#include "library/reducible.h"
#include "library/aliases.h"
#include "library/protected.h"
#include "library/type_context.h"
#include "library/class.h"
#include "library/attribute_manager.h"

namespace lean {
enum class class_entry_kind { Class, Instance };
struct class_entry {
    class_entry_kind m_kind;
    name             m_class;
    name             m_instance; // only relevant if m_kind == Instance
    unsigned         m_priority; // only relevant if m_kind == Instance
    class_entry():m_kind(class_entry_kind::Class), m_priority(0) {}
    explicit class_entry(name const & c):m_kind(class_entry_kind::Class), m_class(c), m_priority(0) {}
    class_entry(class_entry_kind k, name const & c, name const & i, unsigned p):
        m_kind(k), m_class(c), m_instance(i), m_priority(p) {}
};

struct class_state {
    typedef name_map<list<name>> class_instances;
    typedef name_map<unsigned>   instance_priorities;
    class_instances       m_instances;
    instance_priorities   m_priorities;

    unsigned get_priority(name const & i) const {
        if (auto it = m_priorities.find(i))
            return *it;
        else
            return LEAN_DEFAULT_PRIORITY;
    }

    bool is_instance(name const & i) const {
        return m_priorities.contains(i);
    }

    list<name> insert(name const & inst, unsigned priority, list<name> const & insts) const {
        if (!insts)
            return to_list(inst);
        else if (priority >= get_priority(head(insts)))
            return list<name>(inst, insts);
        else
            return list<name>(head(insts), insert(inst, priority, tail(insts)));
    }

    void add_class(name const & c) {
        auto it = m_instances.find(c);
        if (!it)
            m_instances.insert(c, list<name>());
    }

    void add_instance(name const & c, name const & i, unsigned p) {
        auto it = m_instances.find(c);
        if (!it) {
            m_instances.insert(c, to_list(i));
        } else {
            auto lst = filter(*it, [&](name const & i1) { return i1 != i; });
            m_instances.insert(c, insert(i, p, lst));
        }
        m_priorities.insert(i, p);
    }
};

static name * g_class_name = nullptr;
static std::string * g_key = nullptr;

struct class_config {
    typedef class_state state;
    typedef class_entry entry;

    static class_state state_union(class_state const & a, class_state const & b) {
        auto u = a;
        b.m_instances.for_each([&](name const & c, list<name> const & is) {
            u.add_class(c);
            for (auto & i : reverse(is))
                u.add_instance(c, i, b.get_priority(i));
        });
        return u;
    }

    static void add_entry(environment const &, io_state const &, state & s, entry const & e) {
        switch (e.m_kind) {
        case class_entry_kind::Class:
            s.add_class(e.m_class);
            break;
        case class_entry_kind::Instance:
            s.add_instance(e.m_class, e.m_instance, e.m_priority);
            break;
        }
    }
    static name const & get_class_name() {
        return *g_class_name;
    }
    static std::string const & get_serialization_key() {
        return *g_key;
    }
    static void  write_entry(serializer & s, entry const & e) {
        s << static_cast<char>(e.m_kind);
        switch (e.m_kind) {
        case class_entry_kind::Class:
            s << e.m_class;
            break;
        case class_entry_kind::Instance:
            s << e.m_class << e.m_instance << e.m_priority;
            break;
        }
    }
    static entry read_entry(deserializer & d) {
        entry e; char k;
        d >> k;
        e.m_kind = static_cast<class_entry_kind>(k);
        switch (e.m_kind) {
        case class_entry_kind::Class:
            d >> e.m_class;
            break;
        case class_entry_kind::Instance:
            d >> e.m_class >> e.m_instance >> e.m_priority;
            break;
        }
        return e;
    }
    static optional<unsigned> get_fingerprint(entry const & e) {
        switch (e.m_kind) {
        case class_entry_kind::Class:
            return some(e.m_class.hash());
        case class_entry_kind::Instance:
            return some(hash(hash(e.m_class.hash(), e.m_instance.hash()), e.m_priority));
        }
        lean_unreachable();
    }
};

template class scoped_ext<class_config>;
typedef scoped_ext<class_config> class_ext;

static void check_class(environment const & env, name const & c_name) {
    env.get(c_name);
}

static void check_is_class(environment const & env, name const & c_name) {
    class_state const & s = class_ext::get_state(env);
    if (!s.m_instances.contains(c_name))
        throw exception(sstream() << "'" << c_name << "' is not a class");
}

name get_class_name(environment const & env, expr const & e) {
    if (!is_constant(e))
        throw exception("class expected, expression is not a constant");
    name const & c_name = const_name(e);
    check_is_class(env, c_name);
    return c_name;
}

environment add_class_core(environment const &env, name const &n, bool persistent) {
    check_class(env, n);
    return class_ext::add_entry(env, get_dummy_ios(), class_entry(n), persistent);
}

void get_classes(environment const & env, buffer<name> & classes) {
    class_state const & s = class_ext::get_state(env);
    s.m_instances.for_each([&](name const & c, list<name> const &) {
            classes.push_back(c);
        });
}

bool is_class(environment const & env, name const & c) {
    class_state const & s = class_ext::get_state(env);
    return s.m_instances.contains(c);
}

static environment set_reducible_if_def(environment const & env, name const & n, bool persistent) {
    declaration const & d = env.get(n);
    if (d.is_definition() && !d.is_theorem())
        return set_reducible(env, n, reducible_status::Reducible, persistent);
    else
        return env;
}

environment add_instance_core(environment const & env, name const & n, unsigned priority, bool persistent) {
    declaration d = env.get(n);
    expr type = d.get_type();
    type_context ctx(env, transparency_mode::All);
    class_state S = class_ext::get_state(env);
    type_context::tmp_locals locals(ctx);
    while (true) {
        type = ctx.whnf_pred(type, [&](expr const & e) {
                expr const & fn = get_app_fn(e);
                return !is_constant(fn) || !S.m_instances.contains(const_name(fn)); });
        if (!is_pi(type))
            break;
        expr x = locals.push_local_from_binding(type);
        type = instantiate(binding_body(type), x);
    }
    name c = get_class_name(env, get_app_fn(type));
    check_is_class(env, c);
    environment new_env = class_ext::add_entry(env, get_dummy_ios(), class_entry(class_entry_kind::Instance, c, n, priority),
                                               persistent);
    return set_reducible_if_def(new_env, n, persistent);
}

bool is_instance(environment const & env, name const & i) {
    class_state const & s = class_ext::get_state(env);
    return s.is_instance(i);
}

unsigned get_instance_priority(environment const & env, name const & n) {
    class_state const & s                  = class_ext::get_state(env);
    class_state::instance_priorities insts = s.m_priorities;
    if (auto r = insts.find(n))
        return *r;
    return LEAN_DEFAULT_PRIORITY;
}

name_predicate mk_class_pred(environment const & env) {
    class_state const & s = class_ext::get_state(env);
    class_state::class_instances cs = s.m_instances;
    return [=](name const & n) { return cs.contains(n); }; // NOLINT
}

name_predicate mk_instance_pred(environment const & env) {
    class_state const & s = class_ext::get_state(env);
    class_state::instance_priorities insts = s.m_priorities;
    return [=](name const & n) { return insts.contains(n); }; // NOLINT
}

list<name> get_class_instances(environment const & env, name const & c) {
    class_state const & s = class_ext::get_state(env);
    return ptr_to_list(s.m_instances.find(c));
}

static name * g_class_attr_name    = nullptr;
static name * g_instance_attr_name = nullptr;

environment add_class(environment const &env, name const &n, bool persistent) {
    return static_cast<basic_attribute const &>(get_system_attribute(*g_class_attr_name)).set(env, get_global_ios(), n, LEAN_DEFAULT_PRIORITY, persistent);
}

environment add_instance(environment const & env, name const & n, unsigned priority, bool persistent) {
    return static_cast<basic_attribute const &>(get_system_attribute(*g_instance_attr_name)).set(env, get_global_ios(), n, priority, persistent);
}

void initialize_class() {
    g_class_attr_name = new name("class");
    g_instance_attr_name = new name("instance");
    g_class_name = new name("class");
    g_key = new std::string("class");
    class_ext::initialize();

    register_system_attribute(basic_attribute(*g_class_attr_name, "type class",
                                              [](environment const & env, io_state const &, name const & d, unsigned,
                                                 bool persistent) {
                                                  return add_class_core(env, d, persistent);
                                              }));

    register_system_attribute(basic_attribute(*g_instance_attr_name, "type class instance",
                                              [](environment const & env, io_state const &, name const & d,
                                                 unsigned prio, bool persistent) {
                                                  return add_instance_core(env, d, prio, persistent);
                                              }));
}

void finalize_class() {
    class_ext::finalize();
    delete g_key;
    delete g_class_name;
    delete g_class_attr_name;
    delete g_instance_attr_name;
}
}
