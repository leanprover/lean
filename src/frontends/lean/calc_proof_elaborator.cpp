/*
Copyright (c) 2014 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include "util/sexpr/option_declarations.h"
#include "kernel/free_vars.h"
#include "kernel/instantiate.h"
#include "library/unifier.h"
#include "library/reducible.h"
#include "library/metavar_closure.h"
#include "library/local_context.h"
#include "frontends/lean/util.h"
#include "frontends/lean/info_manager.h"
#include "frontends/lean/calc.h"
#include "frontends/lean/calc_proof_elaborator.h"
#include "frontends/lean/elaborator_exception.h"

#ifndef LEAN_DEFAULT_CALC_ASSISTANT
#define LEAN_DEFAULT_CALC_ASSISTANT true
#endif

namespace lean {
static name * g_elaborator_calc_assistant = nullptr;

void initialize_calc_proof_elaborator() {
    g_elaborator_calc_assistant = new name{"elaborator", "calc_assistant"};
    register_bool_option(*g_elaborator_calc_assistant,  LEAN_DEFAULT_CALC_ASSISTANT,
                         "(elaborator) when needed lean automatically adds symmetry, "
                         "inserts missing arguments, and applies substitutions");
}

void finalize_calc_proof_elaborator() {
    delete g_elaborator_calc_assistant;
}

bool get_elaborator_calc_assistant(options const & o) {
    return o.get_bool(*g_elaborator_calc_assistant, LEAN_DEFAULT_CALC_ASSISTANT);
}

static optional<pair<expr, expr>> mk_op(environment const & env, local_context & ctx, name_generator & ngen, type_checker_ptr & tc,
                                        name const & op, unsigned nunivs, unsigned nargs, std::initializer_list<expr> const & explicit_args,
                                        constraint_seq & cs, tag g) {
    levels lvls;
    for (unsigned i = 0; i < nunivs; i++)
        lvls = levels(mk_meta_univ(ngen.next()), lvls);
    expr c = mk_constant(op, lvls);
    expr op_type = instantiate_type_univ_params(env.get(op), lvls);
    buffer<expr> args;
    for (unsigned i = 0; i < nargs; i++) {
        if (!is_pi(op_type))
            return optional<pair<expr, expr>>();
        expr arg = ctx.mk_meta(ngen, some_expr(binding_domain(op_type)), g);
        args.push_back(arg);
        op_type  = instantiate(binding_body(op_type), arg);
    }
    expr r = mk_app(c, args, g);
    for (expr const & explicit_arg : explicit_args) {
        if (!is_pi(op_type))
            return optional<pair<expr, expr>>();
        r = mk_app(r, explicit_arg);
        expr type = tc->infer(explicit_arg, cs);
        justification j = mk_app_justification(r, explicit_arg, binding_domain(op_type), type);
        if (!tc->is_def_eq(binding_domain(op_type), type, j, cs))
            return optional<pair<expr, expr>>();
        op_type  = instantiate(binding_body(op_type), explicit_arg);
    }
    return some(mk_pair(r, op_type));
}

static optional<pair<expr, expr>> apply_symmetry(environment const & env, local_context & ctx, name_generator & ngen, type_checker_ptr & tc,
                                                 expr const & e, expr const & e_type, constraint_seq & cs, tag g) {
    buffer<expr> args;
    expr const & op = get_app_args(e_type, args);
    if (is_constant(op)) {
        if (auto t = get_calc_symm_info(env, const_name(op))) {
            name symm; unsigned nargs; unsigned nunivs;
            std::tie(symm, nargs, nunivs) = *t;
            return mk_op(env, ctx, ngen, tc, symm, nunivs, nargs-1, {e}, cs, g);
        }
    }
    return optional<pair<expr, expr>>();
}

static optional<pair<expr, expr>> apply_subst(environment const & env, local_context & ctx, name_generator & ngen,
                                              type_checker_ptr & tc, expr const & e, expr const & e_type,
                                              expr const & pred, constraint_seq & cs, tag g) {
    buffer<expr> pred_args;
    get_app_args(pred, pred_args);
    unsigned npargs = pred_args.size();
    if (npargs < 2)
        return optional<pair<expr, expr>>();
    buffer<expr> args;
    expr const & op = get_app_args(e_type, args);
    if (is_constant(op) && args.size() >= 2) {
        if (auto subst_it = get_calc_subst_info(env, const_name(op))) {
            name subst; unsigned subst_nargs; unsigned subst_univs;
            std::tie(subst, subst_nargs, subst_univs) = *subst_it;
            if (auto refl_it = get_calc_refl_info(env, const_name(op))) {
                name refl; unsigned refl_nargs; unsigned refl_univs;
                std::tie(refl, refl_nargs, refl_univs) = *refl_it;
                if (auto refl_pair = mk_op(env, ctx, ngen, tc, refl, refl_univs, refl_nargs-1,
                                           { pred_args[npargs-2] }, cs, g)) {
                    return mk_op(env, ctx, ngen, tc, subst, subst_univs, subst_nargs-2, {e, refl_pair->first}, cs, g);
                }
            }
        }
    }
    return optional<pair<expr, expr>>();
}

/** \brief Create a "choice" constraint that postpones the resolution of a calc proof step.

    By delaying it, we can perform quick fixes such as:
      - adding symmetry
      - adding !
      - adding subst
*/
constraint mk_calc_proof_cnstr(environment const & env, options const & opts,
                               local_context const & _ctx, expr const & m, expr const & _e,
                               constraint_seq const & cs, unifier_config const & cfg,
                               info_manager * im, update_type_info_fn const & fn) {
    justification j         = mk_failed_to_synthesize_jst(env, m);
    auto choice_fn = [=](expr const & meta, expr const & meta_type, substitution const & _s,
                         name_generator && ngen) {
        local_context ctx = _ctx;
        expr e            = _e;
        substitution s    = _s;
        type_checker_ptr tc(mk_type_checker(env, ngen.mk_child()));
        constraint_seq new_cs = cs;
        expr e_type = tc->infer(e, new_cs);
        e_type      = s.instantiate(e_type);
        e_type      = tc->whnf(e_type, new_cs);
        tag g       = e.get_tag();
        bool calc_assistant = get_elaborator_calc_assistant(opts);

        if (calc_assistant) {
            // add '!' is needed
            while (is_pi(e_type)) {
                binder_info bi = binding_info(e_type);
                if (!bi.is_implicit() && !bi.is_inst_implicit()) {
                    if (!has_free_var(binding_body(e_type), 0)) {
                        // if the rest of the type does not reference argument,
                        // then we also stop consuming arguments
                        break;
                    }
                }
                expr imp_arg = ctx.mk_meta(ngen, some_expr(binding_domain(e_type)), g);
                e            = mk_app(e, imp_arg, g);
                e_type       = tc->whnf(instantiate(binding_body(e_type), imp_arg), new_cs);
            }
            if (im)
                fn(e);
        }

        auto try_alternative = [&](expr const & e, expr const & e_type, constraint_seq fcs, bool conservative) {
            justification new_j = mk_type_mismatch_jst(e, e_type, meta_type);
            if (!tc->is_def_eq(e_type, meta_type, new_j, fcs))
                throw unifier_exception(new_j, s);
            buffer<constraint> cs_buffer;
            fcs.linearize(cs_buffer);
            metavar_closure cls(meta);
            cls.add(meta_type);
            cls.mk_constraints(s, j, cs_buffer);
            cs_buffer.push_back(mk_eq_cnstr(meta, e, j));

            unifier_config new_cfg(cfg);
            new_cfg.m_discard      = false;
            new_cfg.m_kind         = conservative ? unifier_kind::Conservative : unifier_kind::Liberal;
            unify_result_seq seq   = unify(env, cs_buffer.size(), cs_buffer.data(), ngen.mk_child(), substitution(), new_cfg);
            auto p = seq.pull();
            lean_assert(p);
            substitution new_s     = p->first.first;
            constraints  postponed = map(p->first.second,
                                         [&](constraint const & c) {
                                             // we erase internal justifications
                                             return update_justification(c, j);
                                         });
            if (conservative && has_expr_metavar_relaxed(new_s.instantiate_all(e)))
                throw_elaborator_exception("solution contains metavariables", e);
            if (im)
                im->instantiate(new_s);
            constraints r = cls.mk_constraints(new_s, j);
            return append(r, postponed);
        };

        if (!get_elaborator_calc_assistant(opts)) {
            bool conservative = false;
            return try_alternative(e, e_type, new_cs, conservative);
        } else {
            // TODO(Leo): after we have the simplifier and rewriter tactic, we should revise
            // this code. It is "abusing" the higher-order unifier.

            {
                // Try the following possible intrepretations using a "conservative" unification procedure.
                // That is, we only unfold definitions marked as reducible.
                // Assume pr is the proof provided.

                // 1. pr
                bool conservative = true;
                try { return try_alternative(e, e_type, new_cs, conservative); } catch (exception & ex) {}

                // 2. eq.symm pr
                constraint_seq symm_cs = new_cs;
                auto symm  = apply_symmetry(env, ctx, ngen, tc, e, e_type, symm_cs, g);
                if (symm) {
                    try { return try_alternative(symm->first, symm->second, symm_cs, conservative); } catch (exception &) {}
                }

                // 3. subst pr (eq.refl lhs)
                constraint_seq subst_cs = new_cs;
                if (auto subst = apply_subst(env, ctx, ngen, tc, e, e_type, meta_type, subst_cs, g)) {
                    try { return try_alternative(subst->first, subst->second, subst_cs, conservative); } catch (exception&) {}
                }

                // 4. subst (eq.symm pr) (eq.refl lhs)
                if (symm) {
                    constraint_seq subst_cs = symm_cs;
                    if (auto subst = apply_subst(env, ctx, ngen, tc, symm->first, symm->second,
                                                 meta_type, subst_cs, g)) {
                        try { return try_alternative(subst->first, subst->second, subst_cs, conservative); }
                        catch (exception&) {}
                    }
                }
            }

            {
                // Try the following possible insterpretations using the default unification procedure.

                // 1. pr
                bool conservative = false;
                std::unique_ptr<throwable> saved_ex;
                try {
                    return try_alternative(e, e_type, new_cs, conservative);
                } catch (exception & ex) {
                    saved_ex.reset(ex.clone());
                }

                // 2. eq.symm pr
                constraint_seq symm_cs = new_cs;
                auto symm  = apply_symmetry(env, ctx, ngen, tc, e, e_type, symm_cs, g);
                if (symm) {
                    try { return try_alternative(symm->first, symm->second, symm_cs, conservative); }
                    catch (exception &) {}
                }

                // We use the exception for the first alternative as the error message
                saved_ex->rethrow();
                lean_unreachable();
            }
        }
    };
    bool owner = false;
    return mk_choice_cnstr(m, choice_fn, to_delay_factor(cnstr_group::Epilogue), owner, j);
}
}
