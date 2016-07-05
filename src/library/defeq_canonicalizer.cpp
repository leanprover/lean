/*
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include "util/list_fn.h"
#include "kernel/instantiate.h"
#include "library/locals.h"
#include "library/type_context.h"
#include "library/cache_helper.h"

namespace lean {
struct defeq_canonicalize_cache {
    environment           m_env;
    /* Canonical mapping I -> J (i.e., J is the canonical expression for I).
       Invariant: locals_subset(J, I) */
    expr_struct_map<expr>        m_C;
    /* Mapping from head symbol N to list of expressions es s.t.
       for each e in es, head_symbol(e) = N. */
    name_map<list<expr>>  m_M;
    defeq_canonicalize_cache(environment const & env):m_env(env) {}
    environment const & env() const { return m_env; }
};

/* The defeq_canonicalize_cache does not depend on the transparency mode */
typedef transparencyless_cache_compatibility_helper<defeq_canonicalize_cache>
defeq_canonicalize_cache_helper;

MK_THREAD_LOCAL_GET_DEF(defeq_canonicalize_cache_helper, get_dcch);

defeq_canonicalize_cache & get_defeq_canonicalize_cache_for(type_context const & ctx) {
    return get_dcch().get_cache_for(ctx);
}

struct defeq_canonicalize_fn {
    type_context &                   m_ctx;
    defeq_canonicalize_cache &           m_cache;
    type_context::transparency_scope m_scope;
    bool &                           m_updated;

    defeq_canonicalize_fn(type_context & ctx, bool & updated):
        m_ctx(ctx),
        m_cache(get_defeq_canonicalize_cache_for(ctx)),
        m_scope(m_ctx, transparency_mode::All),
        m_updated(updated) {}

    optional<name> get_head_symbol(expr type) {
        type    = m_ctx.whnf(type);
        expr const & fn = get_app_fn(type);
        if (is_constant(fn)) {
            return optional<name>(const_name(fn));
        } else if (is_pi(type)) {
            type_context::tmp_locals locals(m_ctx);
            expr l = locals.push_local_from_binding(type);
            return get_head_symbol(instantiate(binding_body(type), l));
        } else {
            return optional<name>();
        }
    }

    optional<expr> find_defeq(name const & h, expr const & e) {
        list<expr> const * lst = m_cache.m_M.find(h);
        if (!lst) return none_expr();
        for (expr const & e1 : *lst) {
            if (locals_subset(e1, e) && m_ctx.is_def_eq(e1, e))
                return some_expr(e1);
        }
        return none_expr();
    }

    void replace_C(expr const & e1, expr const & e2) {
        m_cache.m_C.erase(e1);
        m_cache.m_C.insert(mk_pair(e1, e2));
        m_updated = true;
    }

    void insert_C(expr const & e1, expr const & e2) {
        m_cache.m_C.insert(mk_pair(e1, e2));
    }

    void insert_M(name const & h, expr const & e) {
        list<expr> const * lst = m_cache.m_M.find(h);
        if (lst) {
            m_cache.m_M.insert(h, cons(e, *lst));
        } else {
            m_cache.m_M.insert(h, to_list(e));
        }
    }

    void replace_M(name const & h, expr const & e, expr const & new_e) {
        list<expr> const * lst = m_cache.m_M.find(h);
        lean_assert(lst);
        m_cache.m_M.insert(h, cons(new_e, remove(*lst, e)));
    }

    expr canonicalize(expr const & e) {
        auto it = m_cache.m_C.find(e);
        if (it != m_cache.m_C.end()) {
            expr e1 = it->second;
            if (e1 == e)
                return e;
            expr e2 = canonicalize(e1);
            if (e2 != e1) {
                replace_C(e, e2);
            }
            return e2;
        }
        expr e_type  = m_ctx.infer(e);
        optional<name> h = get_head_symbol(e_type);
        if (!h) {
            /* canonization is not support for type of e */
            insert_C(e, e);
            return e;
        } else if (optional<expr> new_e = find_defeq(*h, e)) {
            if (get_weight(e) < get_weight(*new_e) && locals_subset(e, *new_e)) {
                replace_C(*new_e, e);
                replace_M(*h, *new_e, e);
                insert_C(e, e);
                return e;
            } else {
                insert_C(e, *new_e);
                return *new_e;
            }
        } else {
            insert_C(e, e);
            insert_M(*h, e);
            return e;
        }
    }

    expr operator()(expr const & e) { return canonicalize(e); }
};

expr defeq_canonicalize(type_context & ctx, expr const & e, bool & updated) {
    if (has_expr_metavar(e))
        return e; // do nothing if e contains metavariables
    return defeq_canonicalize_fn(ctx, updated)(e);
}
}
