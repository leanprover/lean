/*
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include "util/scoped_map.h"
#include "util/name_map.h"
#include "kernel/instantiate.h"
#include "kernel/abstract.h"
#include "library/trace.h"
#include "library/match.h"
#include "library/constants.h"
#include "library/app_builder.h"
#include "library/kernel_bindings.h"
#include "library/tmp_type_context.h"
#include "library/relation_manager.h"

namespace lean {
struct app_builder::imp {
    tmp_type_context * m_ctx;
    bool               m_ctx_owner;

    struct entry {
        unsigned             m_num_umeta;
        unsigned             m_num_emeta;
        expr                 m_app;
        list<optional<expr>> m_inst_args; // "mask" of implicit instance arguments
        list<expr>           m_expl_args; // metavars for explicit arguments

        /*
          IMPORTANT: for m_inst_args we store the arguments in reverse order.
          For example, the first element in the list indicates whether the last argument
          is an instance implicit argument or not. If it is not none, then the element
          is the associated metavariable

          m_expl_args are also stored in reverse order
        */
    };

    struct key {
        name       m_name;
        unsigned   m_num_expl;
        unsigned   m_hash;
        // If nil, then the mask is composed of the last m_num_expl arguments.
        // If nonnil, then the mask is NOT of the form [false*, true*]
        list<bool> m_mask;

        key(name const & c, unsigned n):
            m_name(c), m_num_expl(n),
            m_hash(::lean::hash(c.hash(), n)) {
        }

        key(name const & c, list<bool> const & m):
            m_name(c), m_num_expl(length(m)) {
            m_hash = ::lean::hash(c.hash(), m_num_expl);
            m_mask = m;
            for (bool b : m) {
                if (b)
                    m_hash = ::lean::hash(m_hash, 17u);
                else
                    m_hash = ::lean::hash(m_hash, 31u);
            }
        }

        bool check_invariant() const {
            lean_assert(empty(m_mask) || length(m_mask) == m_num_expl);
            return true;
        }

        unsigned hash() const {
            return m_hash;
        }

        friend bool operator==(key const & k1, key const & k2) {
            return k1.m_name == k2.m_name && k1.m_num_expl == k2.m_num_expl && k1.m_mask == k2.m_mask;
        }
    };

    struct key_hash_fn {
        unsigned operator()(key const & k) const { return k.hash(); }
    };

    typedef std::unordered_map<key, entry, key_hash_fn> map;

    map               m_map;
    relation_info_getter m_rel_getter;
    refl_info_getter     m_refl_getter;
    symm_info_getter     m_symm_getter;
    trans_info_getter    m_trans_getter;

    imp(tmp_type_context & ctx, bool owner):
        m_ctx(&ctx),
        m_ctx_owner(owner),
        m_rel_getter(mk_relation_info_getter(m_ctx->env())),
        m_refl_getter(mk_refl_info_getter(m_ctx->env())),
        m_symm_getter(mk_symm_info_getter(m_ctx->env())),
        m_trans_getter(mk_trans_info_getter(m_ctx->env())) {
    }

    imp(environment const & env, options const & o, reducible_behavior b):
        imp(*new tmp_type_context(env, o, b), true) {
    }

    imp(tmp_type_context & ctx):
        imp(ctx, false) {
    }

    ~imp() {
        lean_assert(m_ctx);
        if (m_ctx_owner)
            delete m_ctx;
    }

    levels mk_metavars(declaration const & d, buffer<expr> & mvars, buffer<optional<expr>> & inst_args) {
        m_ctx->clear();
        unsigned num_univ = d.get_num_univ_params();
        buffer<level> lvls_buffer;
        for (unsigned i = 0; i < num_univ; i++) {
            lvls_buffer.push_back(m_ctx->mk_uvar());
        }
        levels lvls = to_list(lvls_buffer);
        expr type   = m_ctx->relaxed_whnf(instantiate_type_univ_params(d, lvls));
        while (is_pi(type)) {
            expr mvar = m_ctx->mk_mvar(binding_domain(type));
            if (binding_info(type).is_inst_implicit())
                inst_args.push_back(some_expr(mvar));
            else
                inst_args.push_back(none_expr());
            mvars.push_back(mvar);
            type = m_ctx->relaxed_whnf(instantiate(binding_body(type), mvar));
        }
        return lvls;
    }

    optional<entry> get_entry(name const & c, unsigned nargs) {
        key k(c, nargs);
        lean_assert(k.check_invariant());
        auto it = m_map.find(k);
        if (it == m_map.end()) {
            if (auto d = m_ctx->env().find(c)) {
                buffer<expr> mvars;
                buffer<optional<expr>> inst_args;
                levels lvls = mk_metavars(*d, mvars, inst_args);
                if (nargs > mvars.size())
                    return optional<entry>(); // insufficient number of arguments
                entry e;
                e.m_num_umeta = d->get_num_univ_params();
                e.m_num_emeta = mvars.size();
                e.m_app       = ::lean::mk_app(mk_constant(c, lvls), mvars);
                e.m_inst_args = reverse_to_list(inst_args.begin(), inst_args.end());
                e.m_expl_args = reverse_to_list(mvars.begin() + mvars.size() - nargs, mvars.end());
                m_map.insert(mk_pair(k, e));
                return optional<entry>(e);
            } else {
                return optional<entry>(); // unknown decl
            }
        } else {
            return optional<entry>(it->second);
        }
    }

    void trace_fun(name const & n) {
        tout() << "failed to create an '" << n << "'-application";
    }

    void trace_failure(name const & n, unsigned nargs, char const * msg) {
        lean_trace("app_builder",
                   trace_fun(n); tout() << " with " << nargs << ", " << msg << "\n";);
    }

    void trace_failure(name const & n, char const * msg) {
        lean_trace("app_builder",
                   trace_fun(n); tout() << ", " << msg << "\n";);
    }

    levels mk_metavars(declaration const & d, unsigned arity, buffer<expr> & mvars, buffer<optional<expr>> & inst_args) {
        m_ctx->clear();
        unsigned num_univ = d.get_num_univ_params();
        buffer<level> lvls_buffer;
        for (unsigned i = 0; i < num_univ; i++) {
            lvls_buffer.push_back(m_ctx->mk_uvar());
        }
        levels lvls = to_list(lvls_buffer);
        expr type   = instantiate_type_univ_params(d, lvls);
        for (unsigned i = 0; i < arity; i++) {
            type   = m_ctx->relaxed_whnf(type);
            if (!is_pi(type)) {
                trace_failure(d.get_name(), arity, "too many arguments");
                throw app_builder_exception();
            }
            expr mvar = m_ctx->mk_mvar(binding_domain(type));
            if (binding_info(type).is_inst_implicit())
                inst_args.push_back(some_expr(mvar));
            else
                inst_args.push_back(none_expr());
            mvars.push_back(mvar);
            type = instantiate(binding_body(type), mvar);
        }
        return lvls;
    }

    optional<entry> get_entry(name const & c, unsigned mask_sz, bool const * mask) {
        key k(c, to_list(mask, mask+mask_sz));
        lean_assert(k.check_invariant());
        auto it = m_map.find(k);
        if (it == m_map.end()) {
            if (auto d = m_ctx->env().find(c)) {
                buffer<expr> mvars;
                buffer<optional<expr>> inst_args;
                levels lvls = mk_metavars(*d, mask_sz, mvars, inst_args);
                entry e;
                e.m_num_umeta = d->get_num_univ_params();
                e.m_num_emeta = mvars.size();
                e.m_app       = ::lean::mk_app(mk_constant(c, lvls), mvars);
                e.m_inst_args = reverse_to_list(inst_args.begin(), inst_args.end());
                list<expr> expl_args;
                for (unsigned i = 0; i < mask_sz; i++) {
                    if (mask[i])
                        expl_args = cons(mvars[i], expl_args);
                }
                e.m_expl_args = expl_args;
                m_map.insert(mk_pair(k, e));
                return optional<entry>(e);
            } else {
                return optional<entry>(); // unknown decl
            }
        } else {
            return optional<entry>(it->second);
        }
    }

    bool check_all_assigned(entry const & e) {
        lean_assert(e.m_num_emeta == length(e.m_inst_args));
        // recall that the flags at e.m_inst_args are stored in reverse order.
        // For example, the first flag in the list indicates whether the last argument
        // is an instance implicit argument or not.
        unsigned i = e.m_num_emeta;
        for (optional<expr> const & inst_arg : e.m_inst_args) {
            lean_assert(i > 0);
            --i;
            if (inst_arg) {
                expr type = m_ctx->instantiate_uvars_mvars(mlocal_type(*inst_arg));
                if (auto v = m_ctx->mk_class_instance(type)) {
                    if (!m_ctx->relaxed_force_assign(*inst_arg, *v))
                        return false;
                } else {
                    return false;
                }
            }
            if (!m_ctx->is_mvar_assigned(i))
                return false;
        }
        for (unsigned i = 0; i < e.m_num_umeta; i++) {
            if (!m_ctx->is_uvar_assigned(i))
                return false;
        }
        return true;
    }

    void init_ctx_for(entry const & e) {
        m_ctx->clear();
        m_ctx->set_next_uvar_idx(e.m_num_umeta);
        m_ctx->set_next_mvar_idx(e.m_num_emeta);
    }

    void trace_unify_failure(name const & n, unsigned i, expr const & m, expr const & v) {
        lean_trace("app_builder",
                   trace_fun(n);
                   tout () << ", failed to solve unification constraint for argument #" << (i+1)
                   << " (" << m_ctx->infer(m) << " =?= " << m_ctx->infer(v) << ")\n";);
    }

    expr mk_app(name const & c, unsigned nargs, expr const * args) {
        optional<entry> e = get_entry(c, nargs);
        if (!e) {
            trace_failure(c, "failed to retrieve declaration");
            throw app_builder_exception();
        }
        init_ctx_for(*e);
        unsigned i = nargs;
        for (auto m : e->m_expl_args) {
            if (i == 0) {
                trace_failure(c, "too many explicit arguments");
                throw app_builder_exception();
            }
            --i;
            if (!m_ctx->relaxed_assign(m, args[i])) {
                trace_unify_failure(c, i, m, args[i]);
                throw app_builder_exception();
            }
        }
        if (!check_all_assigned(*e)) {
            trace_failure(c, "there are missing implicit arguments");
            throw app_builder_exception();
        }
        return m_ctx->instantiate_uvars_mvars(e->m_app);
    }

    expr mk_app(name const & c, std::initializer_list<expr> const & it) {
        return mk_app(c, it.size(), it.begin());
    }

    static unsigned get_nargs(unsigned mask_sz, bool const * mask) {
        unsigned nargs = 0;
        for (unsigned i = 0; i < mask_sz; i++) {
            if (mask[i])
                nargs++;
        }
        return nargs;
    }

    expr mk_app(name const & c, unsigned mask_sz, bool const * mask, expr const * args) {
        unsigned nargs = get_nargs(mask_sz, mask);
        optional<entry> e = get_entry(c, mask_sz, mask);
        if (!e) {
            trace_failure(c, "failed to retrieve declaration");
            throw app_builder_exception();
        }
        init_ctx_for(*e);
        unsigned i    = mask_sz;
        unsigned j    = nargs;
        list<expr> it = e->m_expl_args;
        while (i > 0) {
            --i;
            if (mask[i]) {
                --j;
                expr const & m = head(it);
                if (!m_ctx->relaxed_assign(m, args[j])) {
                    trace_unify_failure(c, j, m, args[j]);
                    throw app_builder_exception();
                }
                it = tail(it);
            }
        }
        if (!check_all_assigned(*e)) {
            trace_failure(c, "there are missing implicit arguments");
            throw app_builder_exception();
        }
        return m_ctx->instantiate_uvars_mvars(e->m_app);
    }

    expr mk_app(name const & c, unsigned total_nargs, unsigned expl_nargs, expr const * expl_args) {
        lean_assert(total_nargs >= expl_nargs);
        buffer<bool> mask;
        mask.resize(total_nargs - expl_nargs, false);
        mask.resize(total_nargs, true);
        return mk_app(c, mask.size(), mask.data(), expl_args);
    }

    expr mk_app(name const & c, unsigned total_nargs, std::initializer_list<expr> const & it) {
        return mk_app(c, total_nargs, it.size(), it.begin());
    }

    level get_level(expr const & A) {
        expr Type = m_ctx->relaxed_whnf(m_ctx->infer(A));
        if (!is_sort(Type)) {
            lean_trace("app_builder", tout() << "failed to infer universe level for type " << A << "\n";);
            throw app_builder_exception();
        }
        return sort_level(Type);
    }

    expr mk_eq(expr const & a, expr const & b) {
        expr A    = m_ctx->infer(a);
        level lvl = get_level(A);
        return ::lean::mk_app(mk_constant(get_eq_name(), {lvl}), A, a, b);
    }

    expr mk_iff(expr const & a, expr const & b) {
        return ::lean::mk_app(mk_constant(get_iff_name()), a, b);
    }

    expr mk_eq_refl(expr const & a) {
        expr A     = m_ctx->infer(a);
        level lvl  = get_level(A);
        return ::lean::mk_app(mk_constant(get_eq_refl_name(), {lvl}), A, a);
    }

    expr mk_iff_refl(expr const & a) {
        return ::lean::mk_app(mk_constant(get_iff_refl_name()), a);
    }

    expr mk_eq_symm(expr const & H) {
        expr p    = m_ctx->relaxed_whnf(m_ctx->infer(H));
        expr lhs, rhs;
        if (!is_eq(p, lhs, rhs)) {
            lean_trace("app_builder", tout() << "failed to build eq.symm, equality expected:\n" << H << "\n";);
            throw app_builder_exception();
        }
        expr A    = m_ctx->infer(lhs);
        level lvl = get_level(A);
        return ::lean::mk_app(mk_constant(get_eq_symm_name(), {lvl}), A, lhs, rhs, H);
    }

    expr mk_iff_symm(expr const & H) {
        expr p    = m_ctx->infer(H);
        expr lhs, rhs;
        if (is_iff(p, lhs, rhs)) {
            return ::lean::mk_app(mk_constant(get_iff_symm_name()), lhs, rhs, H);
        } else {
            return mk_app(get_iff_symm_name(), {H});
        }
    }

    expr mk_eq_trans(expr const & H1, expr const & H2) {
        expr p1    = m_ctx->relaxed_whnf(m_ctx->infer(H1));
        expr p2    = m_ctx->relaxed_whnf(m_ctx->infer(H2));
        expr lhs1, rhs1, lhs2, rhs2;
        if (!is_eq(p1, lhs1, rhs1) || !is_eq(p2, lhs2, rhs2)) {
            lean_trace("app_builder", tout() << "failed to build eq.trans, equality expected:\n"
                       << H1 << "\n" << H2 << "\n";);
            throw app_builder_exception();
        }
        expr A     = m_ctx->infer(lhs1);
        level lvl  = get_level(A);
        return ::lean::mk_app({mk_constant(get_eq_trans_name(), {lvl}), A, lhs1, rhs1, rhs2, H1, H2});
    }

    expr mk_iff_trans(expr const & H1, expr const & H2) {
        expr p1    = m_ctx->infer(H1);
        expr p2    = m_ctx->infer(H2);
        expr lhs1, rhs1, lhs2, rhs2;
        if (is_iff(p1, lhs1, rhs1) && is_iff(p2, lhs2, rhs2)) {
            return ::lean::mk_app({mk_constant(get_iff_trans_name()), lhs1, rhs1, rhs2, H1, H2});
        } else {
            return mk_app(get_iff_trans_name(), {H1, H2});
        }
    }

    expr mk_rel(name const & n, expr const & lhs, expr const & rhs) {
        if (n == get_eq_name()) {
            return mk_eq(lhs, rhs);
        } else if (n == get_iff_name()) {
            return mk_iff(lhs, rhs);
        } else if (auto info = m_rel_getter(n)) {
            buffer<bool> mask;
            for (unsigned i = 0; i < info->get_arity(); i++) {
                mask.push_back(i == info->get_lhs_pos() || i == info->get_rhs_pos());
            }
            expr args[2] = {lhs, rhs};
            return mk_app(n, info->get_arity(), mask.data(), args);
        } else {
            // for unregistered relations assume lhs and rhs are the last two arguments.
            expr args[2] = {lhs, rhs};
            return mk_app(n, 2, args);
        }
    }

    expr mk_refl(name const & relname, expr const & a) {
        if (relname == get_eq_name()) {
            return mk_eq_refl(a);
        } else if (relname == get_iff_name()) {
            return mk_iff_refl(a);
        } else if (auto info = m_refl_getter(relname)) {
            return mk_app(info->m_name, 1, &a);
        } else {
            lean_trace("app_builder", tout() << "failed to build reflexivity proof, '" << relname
                       << "' is not registered as a reflexive relation\n";);
            throw app_builder_exception();
        }
    }

    expr mk_symm(name const & relname, expr const & H) {
        if (relname == get_eq_name()) {
            return mk_eq_symm(H);
        } else if (relname == get_iff_name()) {
            return mk_iff_symm(H);
        } else if (auto info = m_symm_getter(relname)) {
            return mk_app(info->m_name, 1, &H);
        } else {
            lean_trace("app_builder", tout() << "failed to build symmetry proof, '" << relname
                       << "' is not registered as a symmetric relation\n";);
            throw app_builder_exception();
        }
    }

    expr mk_trans(name const & relname, expr const & H1, expr const & H2) {
        if (relname == get_eq_name()) {
            return mk_eq_trans(H1, H2);
        } else if (relname == get_iff_name()) {
            return mk_iff_trans(H1, H2);
        } else if (auto info = m_trans_getter(relname, relname)) {
            expr args[2] = {H1, H2};
            return mk_app(info->m_name, 2, args);
        } else {
            lean_trace("app_builder", tout() << "failed to build symmetry proof, '" << relname
                       << "' is not registered as a transitive relation\n";);
            throw app_builder_exception();
        }
    }

    expr lift_from_eq(name const & R, expr const & H) {
        if (R == get_eq_name())
            return H;
        expr H_type = m_ctx->relaxed_whnf(m_ctx->infer(H));
        // H_type : @eq A a b
        expr const & a = app_arg(app_fn(H_type));
        expr const & A = app_arg(app_fn(app_fn(H_type)));
        expr x         = m_ctx->mk_tmp_local(A);
        // motive := fun x : A, a ~ x
        expr motive    = Fun(x, mk_rel(R, a, x));
        // minor : a ~ a
        expr minor     = mk_refl(R, a);
        return mk_eq_rec(motive, minor, H);
    }

    expr mk_eq_rec(expr const & motive, expr const & H1, expr const & H2) {
        if (is_constant(get_app_fn(H2), get_eq_refl_name()))
            return H1;
        expr p       = m_ctx->relaxed_whnf(m_ctx->infer(H2));
        expr lhs, rhs;
        if (!is_eq(p, lhs, rhs)) {
            lean_trace("app_builder", tout() << "failed to build eq.rec, equality proof expected:\n" << H2 << "\n";);
            throw app_builder_exception();
        }
        expr A      = m_ctx->infer(lhs);
        level A_lvl = get_level(A);
        expr mtype  = m_ctx->relaxed_whnf(m_ctx->infer(motive));
        if (!is_pi(mtype) || !is_sort(binding_body(mtype))) {
            lean_trace("app_builder", tout() << "failed to build eq.rec, invalid motive:\n" << motive << "\n";);
            throw app_builder_exception();
        }
        level l_1    = sort_level(binding_body(mtype));
        name const & eqrec = is_standard(m_ctx->env()) ? get_eq_rec_name() : get_eq_nrec_name();
        return ::lean::mk_app({mk_constant(eqrec, {l_1, A_lvl}), A, lhs, motive, H1, rhs, H2});
    }

    expr mk_eq_drec(expr const & motive, expr const & H1, expr const & H2) {
        if (is_constant(get_app_fn(H2), get_eq_refl_name()))
            return H1;
        expr p       = m_ctx->relaxed_whnf(m_ctx->infer(H2));
        expr lhs, rhs;
        if (!is_eq(p, lhs, rhs)) {
            lean_trace("app_builder", tout() << "failed to build eq.drec, equality proof expected:\n" << H2 << "\n";);
            throw app_builder_exception();
        }
        expr A      = m_ctx->infer(lhs);
        level A_lvl = get_level(A);
        expr mtype  = m_ctx->relaxed_whnf(m_ctx->infer(motive));
        if (!is_pi(mtype) || !is_pi(binding_body(mtype)) || !is_sort(binding_body(binding_body(mtype)))) {
            lean_trace("app_builder", tout() << "failed to build eq.drec, invalid motive:\n" << motive << "\n";);
            throw app_builder_exception();
        }
        level l_1    = sort_level(binding_body(binding_body(mtype)));
        name const & eqrec = is_standard(m_ctx->env()) ? get_eq_drec_name() : get_eq_rec_name();
        return ::lean::mk_app({mk_constant(eqrec, {l_1, A_lvl}), A, lhs, motive, H1, rhs, H2});
    }

    expr mk_congr_arg(expr const & f, expr const & H) {
        // TODO(Leo): efficient version
        return mk_app(get_congr_arg_name(), {f, H});
    }

    expr mk_congr_fun(expr const & H, expr const & a) {
        // TODO(Leo): efficient version
        return mk_app(get_congr_fun_name(), {H, a});
    }

    expr mk_congr(expr const & H1, expr const & H2) {
        // TODO(Leo): efficient version
        return mk_app(get_congr_name(), {H1, H2});
    }

    expr mk_iff_false_intro(expr const & H) {
        // TODO(Leo): implement custom version if bottleneck.
        return mk_app(get_iff_false_intro_name(), {H});
    }

    expr mk_iff_true_intro(expr const & H) {
        // TODO(Leo): implement custom version if bottleneck.
        return mk_app(get_iff_true_intro_name(), {H});
    }

    expr mk_not_of_iff_false(expr const & H) {
        if (is_constant(get_app_fn(H), get_iff_false_intro_name())) {
            // not_of_iff_false (iff_false_intro H) == H
            return app_arg(H);
        }
        // TODO(Leo): implement custom version if bottleneck.
        return mk_app(get_not_of_iff_false_name(), 2, {H});
    }

    expr mk_of_iff_true(expr const & H) {
        if (is_constant(get_app_fn(H), get_iff_true_intro_name())) {
            // of_iff_true (iff_true_intro H) == H
            return app_arg(H);
        }
        // TODO(Leo): implement custom version if bottleneck.
        return mk_app(get_of_iff_true_name(), {H});
    }

    expr mk_false_of_true_iff_false(expr const & H) {
        // TODO(Leo): implement custom version if bottleneck.
        return mk_app(get_false_of_true_iff_false_name(), {H});
    }

    expr mk_not(expr const & H) {
        // TODO(dhs): implement custom version if bottleneck.
        return mk_app(get_not_name(), {H});
    }

    void trace_inst_failure(expr const & A, char const * n) {
        lean_trace("app_builder",
                   tout() << "failed to build instance of '" << n << "' for " << A << "\n";);
    }

    expr mk_add(expr const & A, expr const & e1, expr const & e2) {
        level lvl = get_level(A);
        auto A_has_add = m_ctx->mk_class_instance(::lean::mk_app(mk_constant(get_has_add_name(), {lvl}), A));
        if (!A_has_add) {
            trace_inst_failure(A, "has_add");
            throw app_builder_exception();
        }
        return ::lean::mk_app(mk_constant(get_add_name(), {lvl}), {A, *A_has_add, e1, e2});
    }

    expr mk_mul(expr const & A, expr const & e1, expr const & e2) {
        level lvl = get_level(A);
        auto A_has_mul = m_ctx->mk_class_instance(::lean::mk_app(mk_constant(get_has_mul_name(), {lvl}), A));
        if (!A_has_mul) {
            trace_inst_failure(A, "has_mul");
            throw app_builder_exception();
        }
        return ::lean::mk_app(mk_constant(get_mul_name(), {lvl}), {A, *A_has_mul, e1, e2});
    }

    expr mk_partial_add(expr const & A) {
        level lvl = get_level(A);
        auto A_has_add = m_ctx->mk_class_instance(::lean::mk_app(mk_constant(get_has_add_name(), {lvl}), A));
        if (!A_has_add) {
            trace_inst_failure(A, "has_add");
            throw app_builder_exception();
        }
        return ::lean::mk_app(mk_constant(get_add_name(), {lvl}), A, *A_has_add);
    }

    expr mk_partial_mul(expr const & A) {
        level lvl = get_level(A);
        auto A_has_mul = m_ctx->mk_class_instance(::lean::mk_app(mk_constant(get_has_mul_name(), {lvl}), A));
        if (!A_has_mul) {
            trace_inst_failure(A, "has_mul");
            throw app_builder_exception();
        }
        return ::lean::mk_app(mk_constant(get_mul_name(), {lvl}), A, *A_has_mul);
    }

    expr mk_zero(expr const & A) {
        level lvl = get_level(A);
        auto A_has_zero = m_ctx->mk_class_instance(::lean::mk_app(mk_constant(get_has_zero_name(), {lvl}), A));
        if (!A_has_zero) {
            trace_inst_failure(A, "has_zero");
            throw app_builder_exception();
        }
        return ::lean::mk_app(mk_constant(get_zero_name(), {lvl}), A, *A_has_zero);
    }

    expr mk_one(expr const & A) {
        level lvl = get_level(A);
        auto A_has_one = m_ctx->mk_class_instance(::lean::mk_app(mk_constant(get_has_one_name(), {lvl}), A));
        if (!A_has_one) {
            trace_inst_failure(A, "has_one");
            throw app_builder_exception();
        }
        return ::lean::mk_app(mk_constant(get_one_name(), {lvl}), A, *A_has_one);
    }

    expr mk_partial_left_distrib(expr const & A) {
        level lvl = get_level(A);
        auto A_distrib = m_ctx->mk_class_instance(::lean::mk_app(mk_constant(get_distrib_name(), {lvl}), A));
        if (!A_distrib) {
            trace_inst_failure(A, "distrib");
            throw app_builder_exception();
        }
        return ::lean::mk_app(mk_constant(get_left_distrib_name(), {lvl}), A, *A_distrib);
    }

    expr mk_partial_right_distrib(expr const & A) {
        level lvl = get_level(A);
        auto A_distrib = m_ctx->mk_class_instance(::lean::mk_app(mk_constant(get_distrib_name(), {lvl}), A));
        if (!A_distrib) {
            trace_inst_failure(A, "distrib");
            throw app_builder_exception();
        }
        return ::lean::mk_app(mk_constant(get_right_distrib_name(), {lvl}), A, *A_distrib);
    }

    expr mk_bit0(expr const & A, expr const & n) {
        level lvl = get_level(A);
        auto A_has_add = m_ctx->mk_class_instance(::lean::mk_app(mk_constant(get_has_add_name(), {lvl}), A));
        if (!A_has_add) {
            trace_inst_failure(A, "has_add");
            throw app_builder_exception();
        }
        return ::lean::mk_app(mk_constant(get_bit0_name(), {lvl}), {A, *A_has_add, n});
    }

    expr mk_bit1(expr const & A, expr const & n) {
        level lvl = get_level(A);
        auto A_has_one = m_ctx->mk_class_instance(::lean::mk_app(mk_constant(get_has_one_name(), {lvl}), A));
        if (!A_has_one) {
            trace_inst_failure(A, "has_one");
            throw app_builder_exception();
        }
        auto A_has_add = m_ctx->mk_class_instance(::lean::mk_app(mk_constant(get_has_add_name(), {lvl}), A));
        if (!A_has_add) {
            trace_inst_failure(A, "has_add");
            throw app_builder_exception();
        }
        return ::lean::mk_app(mk_constant(get_bit1_name(), {lvl}), {A, *A_has_one, *A_has_add, n});
    }

    expr mk_neg(expr const & A, expr const & e) {
        level lvl = get_level(A);
        auto A_has_neg = m_ctx->mk_class_instance(::lean::mk_app(mk_constant(get_has_neg_name(), {lvl}), A));
        if (!A_has_neg) {
            trace_inst_failure(A, "has_neg");
            throw app_builder_exception();
        }
        return ::lean::mk_app(mk_constant(get_neg_name(), {lvl}), {A, *A_has_neg, e});
    }

    expr mk_inv(expr const & A, expr const & e) {
        level lvl = get_level(A);
        auto A_has_inv = m_ctx->mk_class_instance(::lean::mk_app(mk_constant(get_has_inv_name(), {lvl}), A));
        if (!A_has_inv) {
            trace_inst_failure(A, "has_inv");
            throw app_builder_exception();
        }
        return ::lean::mk_app(mk_constant(get_inv_name(), {lvl}), {A, *A_has_inv, e});
    }

    expr mk_le(expr const & A, expr const & lhs, expr const & rhs) {
        level lvl = get_level(A);
        auto A_has_le = m_ctx->mk_class_instance(::lean::mk_app(mk_constant(get_has_le_name(), {lvl}), A));
        if (!A_has_le) {
            trace_inst_failure(A, "has_le");
            throw app_builder_exception();
        }
        return ::lean::mk_app(mk_constant(get_le_name(), {lvl}), {A, *A_has_le, lhs, rhs});
    }

    expr mk_lt(expr const & A, expr const & lhs, expr const & rhs) {
        level lvl = get_level(A);
        auto A_has_lt = m_ctx->mk_class_instance(::lean::mk_app(mk_constant(get_has_lt_name(), {lvl}), A));
        if (!A_has_lt) {
            trace_inst_failure(A, "has_lt");
            throw app_builder_exception();
        }
        return ::lean::mk_app(mk_constant(get_lt_name(), {lvl}), {A, *A_has_lt, lhs, rhs});
    }

    expr mk_one_add_one(expr const & A) {
        level lvl = get_level(A);
        auto A_add_comm_semigroup = m_ctx->mk_class_instance(::lean::mk_app(mk_constant(get_add_comm_semigroup_name(), {lvl}), A));
        if (!A_add_comm_semigroup) {
            trace_inst_failure(A, "add_comm_semigroup");
            throw app_builder_exception();
        }
        auto A_has_one = m_ctx->mk_class_instance(::lean::mk_app(mk_constant(get_has_one_name(), {lvl}), A));
        if (!A_has_one) {
            trace_inst_failure(A, "has_one");
            throw app_builder_exception();
        }
        return ::lean::mk_app(mk_constant(get_numeral_one_add_one_name(), {lvl}), {A, *A_add_comm_semigroup, *A_has_one});
    }

    expr mk_ordered_semiring(expr const & A) {
        level lvl = get_level(A);
        return ::lean::mk_app(mk_constant(get_ordered_semiring_name(), {lvl}), A);
    }

    expr mk_ordered_ring(expr const & A) {
        level lvl = get_level(A);
        return ::lean::mk_app(mk_constant(get_ordered_ring_name(), {lvl}), A);
    }

    expr mk_linear_ordered_comm_ring(expr const & A) {
        level lvl = get_level(A);
        return ::lean::mk_app(mk_constant(get_linear_ordered_comm_ring_name(), {lvl}), A);
    }

    expr mk_linear_ordered_field(expr const & A) {
        level lvl = get_level(A);
        return ::lean::mk_app(mk_constant(get_linear_ordered_field_name(), {lvl}), A);
    }

    expr mk_false_rec(expr const & c, expr const & H) {
        level c_lvl = get_level(c);
        if (is_standard(m_ctx->env())) {
            return ::lean::mk_app(mk_constant(get_false_rec_name(), {c_lvl}), c, H);
        } else {
            expr H_type = m_ctx->infer(H);
            return ::lean::mk_app(mk_constant(get_empty_rec_name(), {c_lvl}), mk_lambda("e", H_type, c), H);
        }
    }
};

app_builder::app_builder(environment const & env, options const & o, reducible_behavior b):
    m_ptr(new imp(env, o, b)) {
}

app_builder::app_builder(environment const & env, reducible_behavior b):
    app_builder(env, options(), b) {
}

app_builder::app_builder(tmp_type_context & ctx):
    m_ptr(new imp(ctx)) {
}

app_builder::~app_builder() {}

expr app_builder::mk_app(name const & c, unsigned nargs, expr const * args) {
    return m_ptr->mk_app(c, nargs, args);
}

expr app_builder::mk_app(name const & c, unsigned mask_sz, bool const * mask, expr const * args) {
    return m_ptr->mk_app(c, mask_sz, mask, args);
}

expr app_builder::mk_app(name const & c, unsigned total_nargs, unsigned expl_nargs, expr const * expl_args) {
    return m_ptr->mk_app(c, total_nargs, expl_nargs, expl_args);
}

expr app_builder::mk_rel(name const & n, expr const & lhs, expr const & rhs) {
    return m_ptr->mk_rel(n, lhs, rhs);
}

expr app_builder::mk_eq(expr const & lhs, expr const & rhs) {
    return m_ptr->mk_eq(lhs, rhs);
}

expr app_builder::mk_iff(expr const & lhs, expr const & rhs) {
    return m_ptr->mk_iff(lhs, rhs);
}

expr app_builder::mk_refl(name const & relname, expr const & a) {
    return m_ptr->mk_refl(relname, a);
}

expr app_builder::mk_eq_refl(expr const & a) {
    return m_ptr->mk_eq_refl(a);
}

expr app_builder::mk_iff_refl(expr const & a) {
    return m_ptr->mk_iff_refl(a);
}

expr app_builder::mk_symm(name const & relname, expr const & H) {
    return m_ptr->mk_symm(relname, H);
}

expr app_builder::mk_eq_symm(expr const & H) {
    return m_ptr->mk_eq_symm(H);
}

expr app_builder::mk_iff_symm(expr const & H) {
    return m_ptr->mk_iff_symm(H);
}

expr app_builder::mk_trans(name const & relname, expr const & H1, expr const & H2) {
    return m_ptr->mk_trans(relname, H1, H2);
}

expr app_builder::mk_eq_trans(expr const & H1, expr const & H2) {
    return m_ptr->mk_eq_trans(H1, H2);
}

expr app_builder::mk_iff_trans(expr const & H1, expr const & H2) {
    return m_ptr->mk_iff_trans(H1, H2);
}

expr app_builder::mk_eq_rec(expr const & C, expr const & H1, expr const & H2) {
    return m_ptr->mk_eq_rec(C, H1, H2);
}

expr app_builder::mk_eq_drec(expr const & C, expr const & H1, expr const & H2) {
    return m_ptr->mk_eq_drec(C, H1, H2);
}

expr app_builder::mk_congr_arg(expr const & f, expr const & H) {
    return m_ptr->mk_congr_arg(f, H);
}

expr app_builder::mk_congr_fun(expr const & H, expr const & a) {
    return m_ptr->mk_congr_fun(H, a);
}

expr app_builder::mk_congr(expr const & H1, expr const & H2) {
    return m_ptr->mk_congr(H1, H2);
}

expr app_builder::lift_from_eq(name const & R, expr const & H) {
    return m_ptr->lift_from_eq(R, H);
}

expr app_builder::mk_iff_false_intro(expr const & H) {
    return m_ptr->mk_iff_false_intro(H);
}

expr app_builder::mk_iff_true_intro(expr const & H) {
    return m_ptr->mk_iff_true_intro(H);
}
expr app_builder::mk_not_of_iff_false(expr const & H) {
    return m_ptr->mk_not_of_iff_false(H);
}

expr app_builder::mk_of_iff_true(expr const & H) {
    return m_ptr->mk_of_iff_true(H);
}

expr app_builder::mk_false_of_true_iff_false(expr const & H) {
    return m_ptr->mk_false_of_true_iff_false(H);
}

expr app_builder::mk_not(expr const & H) {
    return m_ptr->mk_not(H);
}

expr app_builder::mk_add(expr const & A, expr const & e1, expr const & e2) {
    return m_ptr->mk_add(A, e1, e2);
}

expr app_builder::mk_mul(expr const & A, expr const & e1, expr const & e2) {
    return m_ptr->mk_mul(A, e1, e2);
}

expr app_builder::mk_partial_add(expr const & A) {
    return m_ptr->mk_partial_add(A);
}

expr app_builder::mk_partial_mul(expr const & A) {
    return m_ptr->mk_partial_mul(A);
}

expr app_builder::mk_zero(expr const & A) {
    return m_ptr->mk_zero(A);
}

expr app_builder::mk_one(expr const & A) {
    return m_ptr->mk_one(A);
}

expr app_builder::mk_partial_left_distrib(expr const & A) {
    return m_ptr->mk_partial_left_distrib(A);
}

expr app_builder::mk_partial_right_distrib(expr const & A) {
    return m_ptr->mk_partial_right_distrib(A);
}

expr app_builder::mk_bit0(expr const & A, expr const & n) {
    return m_ptr->mk_bit0(A, n);
}

expr app_builder::mk_bit1(expr const & A, expr const & n) {
    return m_ptr->mk_bit1(A, n);
}

expr app_builder::mk_neg(expr const & A, expr const & e) {
    return m_ptr->mk_neg(A, e);
}

expr app_builder::mk_inv(expr const & A, expr const & e) {
    return m_ptr->mk_inv(A, e);
}

expr app_builder::mk_le(expr const & A, expr const & lhs, expr const & rhs) {
    return m_ptr->mk_le(A, lhs, rhs);
}

expr app_builder::mk_lt(expr const & A, expr const & lhs, expr const & rhs) {
    return m_ptr->mk_lt(A, lhs, rhs);
}

expr app_builder::mk_one_add_one(expr const & A) {
    return m_ptr->mk_one_add_one(A);
}

expr app_builder::mk_ordered_semiring(expr const & A) {
    return m_ptr->mk_ordered_semiring(A);
}

expr app_builder::mk_ordered_ring(expr const & A) {
    return m_ptr->mk_ordered_ring(A);
}

expr app_builder::mk_linear_ordered_comm_ring(expr const & A) {
    return m_ptr->mk_linear_ordered_comm_ring(A);
}

expr app_builder::mk_linear_ordered_field(expr const & A) {
    return m_ptr->mk_linear_ordered_field(A);
}

expr app_builder::mk_sorry(expr const & type) {
    return mk_app(get_sorry_name(), type);
}

expr app_builder::mk_false_rec(expr const & c, expr const & H) {
    return m_ptr->mk_false_rec(c, H);
}

void app_builder::set_local_instances(list<expr> const & insts) {
    m_ptr->m_ctx->set_local_instances(insts);
}
void initialize_app_builder() {
    register_trace_class("app_builder");
}
void finalize_app_builder() {}
}
