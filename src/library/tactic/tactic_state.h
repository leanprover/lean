/*
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#pragma once
#include <algorithm>
#include "util/sstream.h"
#include "kernel/environment.h"
#include "library/metavar_context.h"
#include "library/type_context.h"
#include "library/defeq_canonizer.h"
#include "library/vm/vm.h"
#include "library/vm/interaction_state.h"

namespace lean {
typedef defeq_canonizer::state defeq_can_state;

struct tactic_user_state {
    unsigned_map<vm_obj> m_mem;
    list<unsigned>       m_free_refs;
    unsigned             m_next_idx{0};
public:
    unsigned alloc(vm_obj const & v);
    void dealloc(unsigned ref);
    vm_obj read(unsigned ref) const;
    void write(unsigned ref, vm_obj const & o);
};

class tactic_state_cell {
    MK_LEAN_RC();
    environment       m_env;
    options           m_options;
    name              m_decl_name;
    metavar_context   m_mctx;
    list<expr>        m_goals;
    expr              m_main;
    defeq_can_state   m_defeq_can_state;
    tactic_user_state m_tactic_user_state;
    friend class tactic_state;
    void dealloc();
public:
    tactic_state_cell(environment const & env, options const & o, name const & decl_name,
                      metavar_context const & ctx, list<expr> const & gs,
                      expr const & main, defeq_can_state const & s, tactic_user_state const & us):
        m_rc(0), m_env(env), m_options(o), m_decl_name(decl_name),
        m_mctx(ctx), m_goals(gs), m_main(main), m_defeq_can_state(s),
        m_tactic_user_state(us) {}
};

class tactic_state {
private:
    tactic_state_cell * m_ptr;
    tactic_state_cell * steal_ptr() { tactic_state_cell * r = m_ptr; m_ptr = nullptr; return r; }
    friend class optional<tactic_state>;
    tactic_state():m_ptr(nullptr) {}
    explicit tactic_state(tactic_state_cell * ptr):m_ptr(ptr) { if (m_ptr) m_ptr->inc_ref(); }
    format pp_goal(formatter_factory const & fmtf, expr const & g) const;
public:
    tactic_state(environment const & env, options const & o, name const & decl_name,
                 metavar_context const & ctx, list<expr> const & gs,
                 expr const & main, defeq_can_state const & s, tactic_user_state const & us);
    tactic_state(tactic_state const & s):m_ptr(s.m_ptr) { if (m_ptr) m_ptr->inc_ref(); }
    tactic_state(tactic_state && s):m_ptr(s.m_ptr) { s.m_ptr = nullptr; }
    ~tactic_state() { if (m_ptr) m_ptr->dec_ref(); }

    optional<expr> get_main_goal() const;
    optional<metavar_decl> get_main_goal_decl() const;
    tactic_state_cell * raw() const { return m_ptr; }
    options const & get_options() const { lean_assert(m_ptr); return m_ptr->m_options; }
    environment const & env() const { lean_assert(m_ptr); return m_ptr->m_env; }
    metavar_context const & mctx() const { lean_assert(m_ptr); return m_ptr->m_mctx; }
    list<expr> const & goals() const { lean_assert(m_ptr); return m_ptr->m_goals; }
    expr const & main() const { lean_assert(m_ptr); return m_ptr->m_main; }
    name const & decl_name() const { lean_assert(m_ptr); return m_ptr->m_decl_name; }
    defeq_can_state const & get_defeq_canonizer_state() const { return m_ptr->m_defeq_can_state; }
    defeq_can_state const & dcs() const { return get_defeq_canonizer_state(); }
    tactic_user_state const & get_user_state() const { return m_ptr->m_tactic_user_state; }
    tactic_user_state const & us() const { return get_user_state(); }

    tactic_state & operator=(tactic_state const & s) { LEAN_COPY_REF(s); }
    tactic_state & operator=(tactic_state && s) { LEAN_MOVE_REF(s); }

    friend void swap(tactic_state & a, tactic_state & b) { std::swap(a.m_ptr, b.m_ptr); }
    friend bool is_eqp(tactic_state const & a, tactic_state const & b) { return a.m_ptr == b.m_ptr; }

    format pp_core(formatter_factory const & fmtf) const;
    format pp_expr(formatter_factory const & fmtf, expr const & e) const;
    format pp_core() const;
    format pp() const;
    format pp_expr(expr const & e) const;
    format pp_goal(expr const & g) const;
};

inline bool operator==(tactic_state const & s1, tactic_state const & s2) { return is_eqp(s1, s2); }

SPECIALIZE_OPTIONAL_FOR_SMART_PTR(tactic_state)

inline optional<tactic_state> none_tactic_state() { return optional<tactic_state>(); }
inline optional<tactic_state> some_tactic_state(tactic_state const & e) { return optional<tactic_state>(e); }
inline optional<tactic_state> some_tactic_state(tactic_state && e) { return optional<tactic_state>(std::forward<tactic_state>(e)); }

tactic_state mk_tactic_state_for(environment const & env, options const & opts, name const & decl_name, metavar_context mctx,
                                 local_context const & lctx, expr const & type);
tactic_state mk_tactic_state_for(environment const & env, options const & opts, name const & decl_name,
                                 local_context const & lctx, expr const & type);
tactic_state mk_tactic_state_for_metavar(environment const & env, options const & opts, name const & decl_name,
                                         metavar_context const & mctx, expr const & mvar);

tactic_state set_options(tactic_state const & s, options const & o);
tactic_state set_env(tactic_state const & s, environment const & env);
tactic_state set_mctx(tactic_state const & s, metavar_context const & mctx);
tactic_state set_mctx_dcs(tactic_state const & s, metavar_context const & mctx, defeq_can_state const & dcs);
tactic_state set_env_mctx(tactic_state const & s, environment const & env, metavar_context const & mctx);
tactic_state set_goals(tactic_state const & s, list<expr> const & gs);
tactic_state set_mctx_goals(tactic_state const & s, metavar_context const & mctx, list<expr> const & gs);
tactic_state set_env_mctx_goals(tactic_state const & s, environment const & env, metavar_context const & mctx, list<expr> const & gs);
tactic_state set_mctx_goals_dcs(tactic_state const & s, metavar_context const & mctx, list<expr> const & gs, defeq_can_state const & dcs);
tactic_state set_defeq_can_state(tactic_state const & s, defeq_can_state const & dcs);
tactic_state set_user_state(tactic_state const & s, tactic_user_state const & us);
inline tactic_state set_dcs(tactic_state const & s, defeq_can_state const & dcs) { return set_defeq_can_state(s, dcs); }


/* Auxiliary function that returns an updated tactic_state such s' s.t. the metavariable context is mctx and
   the main goal is of the form

      lctx |- T

   for some type T.
   This function is particularly useful for implementing "converters" (aka "rewriters"). These
   kind of procedure doesn't care about goals, but env, options, mctx and lctx.

   \remark It returns s is is_eqp(s.mctx(), mctx) and is_decl_eqp(s.get_main_goal_decl()->get_context(), lctx) */
tactic_state set_mctx_lctx(tactic_state const & s, metavar_context const & mctx, local_context const & lctx);
tactic_state set_mctx_lctx_dcs(tactic_state const & s, metavar_context const & mctx, local_context const & lctx, defeq_can_state const & dcs);
template<typename T> tactic_state update_option_if_undef(tactic_state const & s, name const & n, T v) {
    return set_options(s, s.get_options().update_if_undef(n, v));
}

typedef interaction_monad<tactic_state> tactic;

vm_obj to_obj(tactic_state const & s);

transparency_mode to_transparency_mode(vm_obj const & o);
vm_obj to_obj(transparency_mode m);

vm_obj mk_no_goals_exception(tactic_state const & s);

format pp_expr(tactic_state const & s, expr const & e);
format pp_indented_expr(tactic_state const & s, expr const & e);

type_context mk_type_context_for(tactic_state const & s, transparency_mode m = transparency_mode::Semireducible);
type_context mk_type_context_for(tactic_state const & s, local_context const & lctx, transparency_mode m = transparency_mode::Semireducible);
type_context mk_type_context_for(environment const & env, options const & o,
                                 metavar_context const & mctx, local_context const & lctx, transparency_mode m = transparency_mode::Semireducible);
type_context mk_type_context_for(vm_obj const & s);
type_context mk_type_context_for(vm_obj const & s, vm_obj const & m);

#define lean_tactic_trace(N, S, Code) lean_trace(N, {   \
    type_context _ctx = mk_type_context_for(S);         \
    scope_trace_env _scope((S).env(), _ctx);            \
    Code                                                \
})

#define LEAN_TACTIC_TRY try {
#define LEAN_TACTIC_CATCH(S) } catch (exception const & ex) { return tactic::mk_exception(ex, S); }

void initialize_tactic_state();
void finalize_tactic_state();
}
