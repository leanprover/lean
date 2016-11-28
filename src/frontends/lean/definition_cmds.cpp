/*
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include <string>
#include <vector>
#include "library/sorry.h"
#include "library/module_mgr.h"
#include "util/timeit.h"
#include "kernel/type_checker.h"
#include "kernel/declaration.h"
#include "kernel/instantiate.h"
#include "kernel/replace_fn.h"
#include "library/trace.h"
#include "library/constants.h"
#include "library/explicit.h"
#include "library/typed_expr.h"
#include "library/private.h"
#include "library/protected.h"
#include "library/scoped_ext.h"
#include "library/unfold_macros.h"
#include "library/noncomputable.h"
#include "library/module.h"
#include "library/documentation.h"
#include "library/scope_pos_info_provider.h"
#include "library/replace_visitor.h"
#include "library/equations_compiler/equations.h"
#include "library/compiler/vm_compiler.h"
#include "library/compiler/rec_fn_macro.h"
#include "library/tactic/eqn_lemmas.h"
#include "frontends/lean/parser.h"
#include "frontends/lean/tokens.h"
#include "frontends/lean/elaborator.h"
#include "frontends/lean/util.h"
#include "frontends/lean/decl_util.h"
#include "frontends/lean/decl_attributes.h"
#include "frontends/lean/definition_cmds.h"
#include "frontends/lean/update_environment_exception.h"

// We don't display profiling information for declarations that take less than 0.01 secs
#ifndef LEAN_PROFILE_THRESHOLD
#define LEAN_PROFILE_THRESHOLD 0.01
#endif

namespace lean {
environment ensure_decl_namespaces(environment const & env, name const & full_n) {
    if (full_n.is_atomic())
        return env;
    return add_namespace(env, full_n.get_prefix());
}

expr parse_equation_lhs(parser & p, expr const & fn, buffer<expr> & locals) {
    auto lhs_pos = p.pos();
    buffer<expr> lhs_args;
    lhs_args.push_back(p.parse_pattern_or_expr(get_max_prec()));
    while (!p.curr_is_token(get_assign_tk())) {
        lhs_args.push_back(p.parse_pattern_or_expr(get_max_prec()));
    }
    expr lhs = p.mk_app(p.save_pos(mk_explicit(fn), lhs_pos), lhs_args, lhs_pos);
    bool skip_main_fn = true;
    return p.patexpr_to_pattern(lhs, skip_main_fn, locals);
}

expr parse_equation(parser & p, expr const & fn) {
    p.check_token_next(get_bar_tk(), "invalid equation, '|' expected");
    buffer<expr> locals;
    expr lhs = parse_equation_lhs(p, fn, locals);
    auto assign_pos = p.pos();
    p.check_token_next(get_assign_tk(), "invalid equation, ':=' expected");
    expr rhs = p.parse_scoped_expr(locals);
    return Fun(locals, p.save_pos(mk_equation(lhs, rhs), assign_pos), p);
}

optional<expr_pair> parse_using_well_founded(parser & p) {
    if (p.curr_is_token(get_using_well_founded_tk())) {
        p.next();
        expr R   = p.parse_expr(get_max_prec());
        expr Rwf = p.parse_expr(get_max_prec());
        return optional<expr_pair>(R, Rwf);
    } else {
        return optional<expr_pair>();
    }
}

expr mk_equations(parser & p, buffer<expr> const & fns, buffer<name> const & fn_full_names, buffer<expr> const & eqs,
                  optional<expr_pair> const & R_Rwf, pos_info const & pos) {
    buffer<expr> new_eqs;
    for (expr const & eq : eqs) {
        new_eqs.push_back(Fun(fns, eq, p));
    }
    equations_header h = mk_equations_header(to_list(fn_full_names));
    if (R_Rwf) {
        return p.save_pos(mk_equations(h, new_eqs.size(), new_eqs.data(), R_Rwf->first, R_Rwf->second), pos);
    } else {
        return p.save_pos(mk_equations(h, new_eqs.size(), new_eqs.data()), pos);
    }
}

expr mk_equations(parser & p, expr const & fn, name const & full_name, buffer<expr> const & eqs,
                  optional<expr_pair> const & R_Rwf, pos_info const & pos) {
    buffer<expr> fns; fns.push_back(fn);
    buffer<name> full_names; full_names.push_back(full_name);
    return mk_equations(p, fns, full_names, eqs, R_Rwf, pos);
}

expr parse_mutual_definition(parser & p, buffer<name> & lp_names, buffer<expr> & fns, buffer<expr> & params) {
    parser::local_scope scope1(p);
    auto header_pos = p.pos();
    buffer<expr> pre_fns;
    parse_mutual_header(p, lp_names, pre_fns, params);
    buffer<expr> eqns;
    buffer<name> full_names;
    for (expr const & pre_fn : pre_fns) {
        // TODO(leo, dhs): make use of attributes
        expr fn_type = parse_inner_header(p, local_pp_name(pre_fn)).first;
        declaration_name_scope scope2(local_pp_name(pre_fn));
        declaration_name_scope scope3("_main");
        full_names.push_back(scope2.get_name());
        if (p.curr_is_token(get_period_tk())) {
            auto period_pos = p.pos();
            p.next();
            eqns.push_back(p.save_pos(mk_no_equation(), period_pos));
        } else {
            while (p.curr_is_token(get_bar_tk())) {
                eqns.push_back(parse_equation(p, pre_fn));
            }
            if (!p.curr_is_command() && !p.curr_is_eof()) {
                throw parser_error("invalid equations, must be followed by a command or EOF", p.pos());
            }
        }
        expr fn      = mk_local(mlocal_name(pre_fn), local_pp_name(pre_fn), fn_type, mk_rec_info(true));
        fns.push_back(fn);
    }
    if (p.curr_is_token(get_with_tk()))
        throw parser_error("unexpected 'with' clause", p.pos());
    optional<expr_pair> R_Rwf = parse_using_well_founded(p);
    for (expr & eq : eqns) {
        eq = replace_locals_preserving_pos_info(eq, pre_fns, fns);
    }
    expr r = mk_equations(p, fns, full_names, eqns, R_Rwf, header_pos);
    collect_implicit_locals(p, lp_names, params, r);
    return r;
}

environment mutual_definition_cmd_core(parser & p, def_cmd_kind kind, decl_modifiers const & modifiers, decl_attributes /* attrs */) {
    buffer<name> lp_names;
    buffer<expr> fns, params;
    declaration_info_scope scope(p, kind, modifiers);
    expr val = parse_mutual_definition(p, lp_names, fns, params);
    elaborator elab(p.env(), p.get_options(), metavar_context(), local_context());
    buffer<expr> new_params;
    elaborate_params(elab, params, new_params);
    val = replace_locals_preserving_pos_info(val, params, new_params);

    // TODO(Leo)
    for (auto p : new_params) { tout() << ">> " << p << " : " << mlocal_type(p) << "\n"; }
    tout() << val << "\n";

    return p.env();
}

static expr_pair parse_definition(parser & p, buffer<name> & lp_names, buffer<expr> & params,
                                  bool is_example, bool is_instance) {
    parser::local_scope scope1(p);
    auto header_pos = p.pos();
    expr fn = parse_single_header(p, lp_names, params, is_example, is_instance);
    declaration_name_scope scope2(local_pp_name(fn));
    expr val;
    if (p.curr_is_token(get_assign_tk())) {
        p.next();
        val = p.parse_expr();
    } else if (p.curr_is_token(get_bar_tk()) || p.curr_is_token(get_period_tk())) {
        declaration_name_scope scope2("_main");
        fn = mk_local(mlocal_name(fn), local_pp_name(fn), mlocal_type(fn), mk_rec_info(true));
        p.add_local(fn);
        buffer<expr> eqns;
        if (p.curr_is_token(get_period_tk())) {
            auto period_pos = p.pos();
            p.next();
            eqns.push_back(p.save_pos(mk_no_equation(), period_pos));
        } else {
            while (p.curr_is_token(get_bar_tk())) {
                eqns.push_back(parse_equation(p, fn));
            }
            if (!p.curr_is_command() && !p.curr_is_eof()) {
                throw parser_error("invalid equations, must be followed by a command or EOF", p.pos());
            }
        }
        optional<expr_pair> R_Rwf = parse_using_well_founded(p);
        val = mk_equations(p, fn, scope2.get_name(), eqns, R_Rwf, header_pos);
    } else {
        throw parser_error("invalid definition, '|' or ':=' expected", p.pos());
    }
    collect_implicit_locals(p, lp_names, params, {mlocal_type(fn), val});
    return mk_pair(fn, val);
}

static void replace_params(buffer<expr> const & params, buffer<expr> const & new_params, expr & fn, expr & val) {
    expr fn_type = replace_locals_preserving_pos_info(mlocal_type(fn), params, new_params);
    expr new_fn  = update_mlocal(fn, fn_type);
    val          = replace_locals_preserving_pos_info(val, params, new_params);
    val          = replace_local_preserving_pos_info(val, fn, new_fn);
    fn           = new_fn;
}

static expr_pair elaborate_theorem(elaborator & elab, expr const & fn, expr val) {
    expr fn_type = elab.elaborate_type(mlocal_type(fn));
    elab.ensure_no_unassigned_metavars(fn_type);
    expr new_fn  = update_mlocal(fn, fn_type);
    val = replace_local_preserving_pos_info(val, fn, new_fn);
    return elab.elaborate_with_type(val, mk_as_is(fn_type));
}

static expr_pair elaborate_definition_core(elaborator & elab, def_cmd_kind kind, expr const & fn, expr const & val) {
    if (kind == Theorem) {
        return elaborate_theorem(elab, fn, val);
    } else {
        return elab.elaborate_with_type(val, mlocal_type(fn));
    }
}

static expr_pair elaborate_definition(parser & p, elaborator & elab, def_cmd_kind kind, expr const & fn, expr const & val, pos_info const & pos) {
    if (p.profiling()) {
        xtimeit timer(LEAN_PROFILE_THRESHOLD, [&](double duration) {
                auto msg = p.mk_message(pos, INFORMATION);
                msg.get_text_stream().get_stream()
                    << "elaboration time for " << fn << " "
                    << std::fixed << std::setprecision(5) << duration << " secs\n";
                msg.report();
            });
        return elaborate_definition_core(elab, kind, fn, val);
    } else {
        return elaborate_definition_core(elab, kind, fn, val);
    }
}

static void finalize_theorem_type(elaborator & elab, buffer<expr> const & params, expr & type,
                                  buffer<name> & lp_names,
                                  elaborator::theorem_finalization_info & info) {
    type = elab.mk_pi(params, type);
    buffer<name> implicit_lp_names;
    std::tie(type, info) = elab.finalize_theorem_type(type, implicit_lp_names);
    type = unfold_untrusted_macros(elab.env(), type);
    lp_names.append(implicit_lp_names);
}

static void finalize_theorem_proof(elaborator & elab, buffer<expr> const & params, expr & val,
                                   elaborator::theorem_finalization_info const & info) {
    val  = elab.mk_lambda(params, val);
    val = elab.finalize_theorem_proof(val, info);
    val = unfold_untrusted_macros(elab.env(), val);
}

static void finalize_definition(elaborator & elab, buffer<expr> const & params, expr & type,
                                expr & val, buffer<name> & lp_names) {
    type = elab.mk_pi(params, type);
    val  = elab.mk_lambda(params, val);
    buffer<expr> type_val;
    buffer<name> implicit_lp_names;
    type_val.push_back(type);
    type_val.push_back(val);
    elab.finalize(type_val, implicit_lp_names, true, false);
    type = unfold_untrusted_macros(elab.env(), type_val[0]);
    val  = unfold_untrusted_macros(elab.env(), type_val[1]);
    lp_names.append(implicit_lp_names);
}

static pair<environment, name> mk_real_name(environment const & env, name const & c_name, bool is_private, pos_info const & pos) {
    environment new_env = env;
    name c_real_name;
    if (is_private) {
        unsigned h  = hash(pos.first, pos.second);
        auto env_n  = add_private_name(new_env, c_name, optional<unsigned>(h));
        new_env     = env_n.first;
        c_real_name = env_n.second;
    } else {
        name const & ns = get_namespace(env);
        c_real_name     = ns + c_name;
    }
    return mk_pair(new_env, c_real_name);
}

static certified_declaration check(parser & p, environment const & env, name const & c_name, declaration const & d, pos_info const & pos) {
    if (p.profiling()) {
        xtimeit timer(LEAN_PROFILE_THRESHOLD, [&](double duration) {
                auto msg = p.mk_message(pos, INFORMATION);
                msg.get_text_stream().get_stream()
                    << "type checking time for " << c_name << " "
                    << std::fixed << std::setprecision(5) << duration << " secs\n";
                msg.report();
            });
        return ::lean::check(env, d);
    } else {
        return ::lean::check(env, d);
    }
}

static void check_noncomputable(bool ignore_noncomputable, environment const & env, name const & c_name, name const & c_real_name, bool is_noncomputable) {
    if (ignore_noncomputable)
        return;
    if (!is_noncomputable && is_marked_noncomputable(env, c_real_name)) {
        auto reason = get_noncomputable_reason(env, c_real_name);
        lean_assert(reason);
        throw exception(sstream() << "definition '" << c_name << "' is noncomputable, it depends on '" << *reason << "'");
    }
    if (is_noncomputable && !is_marked_noncomputable(env, c_real_name)) {
        throw exception(sstream() << "definition '" << c_name << "' was incorrectly marked as noncomputable");
    }
}

static environment compile_decl(parser & p, environment const & env, def_cmd_kind kind, bool is_noncomputable,
                                name const & c_name, name const & c_real_name, pos_info const & pos) {
    if (is_noncomputable || kind == Theorem || kind == Example || is_vm_builtin_function(c_real_name))
        return env;
    try {
        declaration d = env.get(c_real_name);
        return vm_compile(env, d);
    } catch (exception & ex) {
        if (p.found_errors())
            return env;
        // FIXME(gabriel): use position from exception
        auto out = p.mk_message(pos, WARNING);
        out << "failed to generate bytecode for '" << c_name << "'\n";
        out.set_exception(ex);
        out.report();
        return env;
    }
}

static expr fix_rec_fn_name(expr const & e, name const & c_name, name const & c_real_name) {
    return replace(e, [&](expr const & m, unsigned) {
            if (is_rec_fn_macro(m) && get_rec_fn_name(m) == c_name) {
                return some_expr(mk_rec_fn_macro(c_real_name, get_rec_fn_type(m)));
            }
            return none_expr();
        });
}

static pair<environment, name>
declare_definition(parser & p, environment const & env, def_cmd_kind kind, buffer<name> const & lp_names,
                   name const & c_name, expr const & type, optional<expr> const & _val, task_result<expr> const & proof,
                   decl_modifiers const & modifiers, decl_attributes attrs, optional<std::string> const & doc_string,
                   pos_info const & pos) {
    auto env_n = mk_real_name(env, c_name, modifiers.m_is_private, pos);
    environment new_env = env_n.first;
    name c_real_name    = env_n.second;
    optional<expr> val  = _val;
    if (val && modifiers.m_is_meta)
        *val = fix_rec_fn_name(*val, c_name, c_real_name);
    bool use_conv_opt = true;
    bool is_trusted   = !modifiers.m_is_meta;
    auto def          =
        !val ? mk_theorem(c_real_name, to_list(lp_names), type, proof) : (kind == Theorem ?
        mk_theorem(c_real_name, to_list(lp_names), type, *val) :
        mk_definition(new_env, c_real_name, to_list(lp_names), type, *val, use_conv_opt, is_trusted));
    auto cdef         = check(p, new_env, c_name, def, pos);
    new_env           = module::add(new_env, cdef);

    check_noncomputable(p.ignore_noncomputable(), new_env, c_name, c_real_name, modifiers.m_is_noncomputable);

    if (modifiers.m_is_protected)
        new_env = add_protected(new_env, c_real_name);

    new_env = add_alias(new_env, modifiers.m_is_protected, c_name, c_real_name);

    if (!modifiers.m_is_private) {
        new_env = ensure_decl_namespaces(new_env, c_real_name);
    }

    new_env = attrs.apply(new_env, p.ios(), c_real_name);
    new_env = compile_decl(p, new_env, kind, modifiers.m_is_noncomputable, c_name, c_real_name, pos);
    if (doc_string) {
        new_env = add_doc_string(new_env, c_real_name, *doc_string, doc_kind::Declaration);
    }
    return mk_pair(new_env, c_real_name);
}

struct fix_rec_fn_macro_args_fn : public replace_visitor {
    buffer<expr> const &             m_params;
    buffer<pair<name, expr>> const & m_fns;

    fix_rec_fn_macro_args_fn(buffer<expr> const & params, buffer<pair<name, expr>> const & fns):
        m_params(params), m_fns(fns) {
    }

    expr fix_rec_fn_macro(name const & fn, expr const & type) {
        return mk_app(mk_rec_fn_macro(fn, type), m_params);
    }

    virtual expr visit_macro(expr const & e) override {
        if (is_rec_fn_macro(e)) {
            name n = get_rec_fn_name(e);
            for (unsigned i = 0; i < m_fns.size(); i++) {
                if (n == m_fns[i].first)
                    return fix_rec_fn_macro(m_fns[i].first, m_fns[i].second);
            }
        }
        return replace_visitor::visit_macro(e);
    }
};

static expr fix_rec_fn_macro_args(elaborator & elab, name const & fn, buffer<expr> const & params, expr const & type, expr const & val) {
    expr fn_new_type = elab.mk_pi(params, type);
    buffer<pair<name, expr>> fns;
    fns.emplace_back(fn, fn_new_type);
    return fix_rec_fn_macro_args_fn(params, fns)(val);
}

static void throw_unexpected_error_at_copy_lemmas() {
    throw exception("unexpected error, failed to generate equational lemmas in the front-end");
}

/* Given e of the form Pi (a_1 : A_1) ... (a_n : A_n), lhs = rhs,
   return the pair (lhs, n) */
static pair<expr, unsigned> get_lemma_lhs(expr e) {
    unsigned nparams = 0;
    while (is_pi(e)) {
        nparams++;
        e = binding_body(e);
    }
    expr lhs, rhs;
    if (!is_eq(e, lhs, rhs))
        throw_unexpected_error_at_copy_lemmas();
    return mk_pair(lhs, nparams);
}

/*
   Given a lemma with parameters lp_names:
      [lp_1 ... lp_n]
   and the levels in the function application on the lemma left-hand-side lhs_fn_levels:
      [u_1 ... u_n] s.t. there is a permutation p s.t. p([u_1 ... u_n] = [(mk_univ_param lp_1) ... (mk_univ_param lp_n)],
   and levels fn_levels
      [v_1 ... v_n]
   Then, store
      p([v_1 ... v_n])
   in result.
*/
static void get_levels_for_instantiating_lemma(level_param_names const & lp_names,
                                               levels const & lhs_fn_levels,
                                               levels const & fn_levels,
                                               buffer<level> & result) {
    buffer<level> fn_levels_buffer;
    buffer<level> lhs_fn_levels_buffer;
    to_buffer(fn_levels, fn_levels_buffer);
    to_buffer(lhs_fn_levels, lhs_fn_levels_buffer);
    lean_assert(fn_levels_buffer.size() == lhs_fn_levels_buffer.size());
    for (name const & lp_name : lp_names) {
        unsigned j = 0;
        for (; j < lhs_fn_levels_buffer.size(); j++) {
            if (!is_param(lhs_fn_levels_buffer[j])) throw_unexpected_error_at_copy_lemmas();
            if (param_id(lhs_fn_levels_buffer[j]) == lp_name) {
                result.push_back(fn_levels_buffer[j]);
                break;
            }
        }
        lean_assert(j < lhs_fn_levels_buffer.size());
    }
}

/**
   Given a lemma with the given arity (i.e., number of nested Pi-terms),
   n = args.size() <= lhs_args.size(), and the first n
   arguments in lhs_args.size() are a permutation p of
     (var #0) ... (var #n-1)
   Then, store in result p(args)
*/
static void get_args_for_instantiating_lemma(unsigned arity,
                                             buffer<expr> const & lhs_args,
                                             buffer<expr> const & args,
                                             buffer<expr> & result) {
    for (unsigned i = 0; i < args.size(); i++) {
        if (!is_var(lhs_args[i]) || var_idx(lhs_args[i]) >= arity)
            throw_unexpected_error_at_copy_lemmas();
        result.push_back(args[arity - var_idx(lhs_args[i]) - 1]);
    }
}

/**
   Given a declaration d defined as
     (fun (a_1 : A_1) ... (a_n : A_n), d._main a_1' ... a_n')
   where a_1' ... a_n' is a permutation of a_1 ... a_n.
   Then, copy the equation lemmas from d._main to d.
*/
static environment copy_equation_lemmas(environment const & env, name const & d_name) {
    declaration const & d = env.get(d_name);
    levels lps = param_names_to_levels(d.get_univ_params());
    expr val   = instantiate_value_univ_params(d, lps);
    type_context ctx(env, transparency_mode::All);
    type_context::tmp_locals locals(ctx);
    while (is_lambda(val)) {
        expr local = locals.push_local_from_binding(val);
        val = instantiate(binding_body(val), local);
    }
    buffer<expr> args;
    expr const & fn = get_app_args(val, args);
    if (!is_constant(fn) ||
        !std::all_of(args.begin(), args.end(), is_local) ||
        length(const_levels(fn)) != length(lps)) {
        throw_unexpected_error_at_copy_lemmas();
    }
    /* We want to create new equations where we replace val with new_val in the equations
       associated with fn. */
    expr new_val = mk_app(mk_constant(d_name, lps), locals.as_buffer());
    /* Copy equations */
    environment new_env = env;
    unsigned i = 1;
    while (true) {
        name eqn_suffix = name({"equations", "eqn"}).append_after(i);
        name eqn_name = const_name(fn) + eqn_suffix;
        optional<declaration> eqn_decl = env.find(eqn_name);
        if (!eqn_decl) break;
        unsigned num_eqn_levels = eqn_decl->get_num_univ_params();
        if (num_eqn_levels != length(lps))
            throw_unexpected_error_at_copy_lemmas();
        expr lhs; unsigned num_eqn_params;
        std::tie(lhs, num_eqn_params) = get_lemma_lhs(eqn_decl->get_type());
        buffer<expr> lhs_args;
        expr const & lhs_fn = get_app_args(lhs, lhs_args);
        if (!is_constant(lhs_fn) || const_name(lhs_fn) != const_name(fn) || lhs_args.size() < args.size())
            throw_unexpected_error_at_copy_lemmas();
        /* Get levels for instantiating the lemma */
        buffer<level> eqn_level_buffer;
        get_levels_for_instantiating_lemma(eqn_decl->get_univ_params(),
                                           const_levels(lhs_fn),
                                           const_levels(fn),
                                           eqn_level_buffer);
        levels eqn_levels = to_list(eqn_level_buffer);
        /* Get arguments for instantiating the lemma */
        buffer<expr> eqn_args;
        get_args_for_instantiating_lemma(num_eqn_params, lhs_args, args, eqn_args);
        /* Convert type */
        expr eqn_type = instantiate_type_univ_params(*eqn_decl, eqn_levels);
        for (unsigned j = 0; j < eqn_args.size(); j++) eqn_type = binding_body(eqn_type);
        eqn_type = instantiate_rev(eqn_type, eqn_args);
        expr new_eqn_type = replace(eqn_type, [&](expr const & e, unsigned) {
                if (e == val)
                    return some_expr(new_val);
                else
                    return none_expr();
            });
        new_eqn_type = locals.mk_pi(new_eqn_type);
        name new_eqn_name    = d_name + eqn_suffix;
        expr new_eqn_value;
        new_eqn_value = mk_app(mk_constant(eqn_name, eqn_levels), args);
        new_eqn_value = locals.mk_lambda(new_eqn_value);
        declaration new_decl = mk_theorem(new_eqn_name, d.get_univ_params(), new_eqn_type, new_eqn_value);
        new_env = module::add(new_env, check(new_env, new_decl, true));
        if (is_rfl_lemma(env, eqn_name))
            new_env = mark_rfl_lemma(new_env, new_eqn_name);
        new_env = add_eqn_lemma(new_env, new_eqn_name);
        i++;
    }
    return new_env;
}

static expr inline_new_defs(environment const & old_env, environment const & new_env, expr const & e) {
    return replace(e, [=] (expr const & e, unsigned) -> optional<expr> {
        if (is_sorry(e)) {
            return none_expr();
        } else if (is_constant(e) && !old_env.find(const_name(e))) {
            auto decl = new_env.get(const_name(e));
            lean_assert(decl.is_definition());
            return some_expr(inline_new_defs(old_env, new_env, decl.get_value()));
        } else {
            return none_expr();
        }
    });
}

class proof_elaboration_task : public task<expr> {
    environment m_decl_env;
    options m_opts;
    bool m_use_info_manager;

    std::vector<expr> m_params;
    expr m_fn, m_val;
    elaborator::theorem_finalization_info m_finfo;
    bool m_is_rfl_lemma;
    expr m_final_type;

    metavar_context m_mctx;
    local_context m_lctx;
    parser_pos_provider m_pos_provider;

public:
    proof_elaboration_task(environment const & decl_env,
                           options const & opts,
                           buffer<expr> const & params,
                           expr const & fn, expr const & val, elaborator::theorem_finalization_info const & finfo,
                           bool is_rfl_lemma, expr const & final_type,
                           metavar_context const & mctx, local_context const & lctx,
                           parser_pos_provider const & prov) :
        m_decl_env(decl_env), m_opts(opts), m_use_info_manager(get_global_info_manager() != nullptr),
        m_params(params.begin(), params.end()), m_fn(fn), m_val(val), m_finfo(finfo),
        m_is_rfl_lemma(is_rfl_lemma), m_final_type(final_type),
        m_mctx(mctx), m_lctx(lctx), m_pos_provider(prov) {}

    void description(std::ostream & out) const override {
        out << "proving " << local_pp_name(m_fn) << " (" << get_module_id() << ")";
    }

    expr execute() override {
        scoped_expr_caching disable(false);  // FIXME: otherwise sigma.eq fails to elaborate
        auto tc = std::make_shared<type_context>(m_decl_env, m_opts, m_mctx, m_lctx);
        scope_trace_env scope2(m_decl_env, m_opts, *tc);
        scope_pos_info_provider scope3(m_pos_provider);
        scoped_info_manager scope4(
                m_use_info_manager ? get_scope_message_context().enable_info_manager(get_module_id())
                                   : nullptr);

        try {
            elaborator elab(m_decl_env, m_opts, m_mctx, m_lctx);
            expr val, type = mlocal_type(m_fn);
            std::tie(val, type) = elab.elaborate_with_type(m_val, mk_as_is(type));
            buffer<expr> params; for (auto & e : m_params) params.push_back(e);
            finalize_theorem_proof(elab, params, val, m_finfo);
            if (m_is_rfl_lemma && !is_rfl_lemma(m_final_type, val))
                throw exception("not a rfl-lemma, even though marked as rfl");
            return inline_new_defs(m_decl_env, elab.env(), val);
        } catch (exception & ex) {
            message_builder error_msg(&m_pos_provider, tc, m_decl_env, get_global_ios(),
                                      m_pos_provider.get_file_name(), m_pos_provider.get_some_pos(),
                                      ERROR);
            error_msg.set_exception(ex);
            error_msg.report();
            return mk_sorry();
        }
    }
};

class example_checking_task : public task<unit> {
    environment m_decl_env;
    options m_opts;
    bool m_use_info_manager;

    decl_modifiers m_modifiers;

    level_param_names m_univ_params;
    std::vector<expr> m_params;
    expr m_fn, m_val;

    metavar_context m_mctx;
    local_context m_lctx;
    parser_pos_provider m_pos_provider;

public:
    example_checking_task(environment const & decl_env, options const & opts,
                          decl_modifiers modifiers,
                          level_param_names const & univ_params,
                          buffer<expr> const & params,
                          expr const & fn, expr const & val,
                          metavar_context const & mctx, local_context const & lctx,
                          parser_pos_provider const & prov) :
        m_decl_env(decl_env), m_opts(opts), m_use_info_manager(get_global_info_manager() != nullptr),
        m_modifiers(modifiers),
        m_univ_params(univ_params), m_params(params.begin(), params.end()), m_fn(fn), m_val(val),
        m_mctx(mctx), m_lctx(lctx), m_pos_provider(prov) {
    }

    task_kind get_kind() const override { return task_kind::print; }

    void description(std::ostream & out) const override {
        out << "checking example on line " << m_pos_provider.get_some_pos().first << " (" << get_module_id() << ")";
    }

    unit execute() override {
        scoped_expr_caching disable(false);  // FIXME: otherwise sigma.eq fails to elaborate
        auto tc = std::make_shared<type_context>(m_decl_env, m_opts, m_mctx, m_lctx);
        scope_trace_env scope2(m_decl_env, m_opts, *tc);
        scope_pos_info_provider scope3(m_pos_provider);
        scoped_info_manager scope4(
                m_use_info_manager ? get_scope_message_context().enable_info_manager(get_module_id())
                                   : nullptr);

        try {
            elaborator elab(m_decl_env, m_opts, m_mctx, m_lctx);

            expr val, type;
            std::tie(val, type) = elab.elaborate_with_type(m_val, mlocal_type(m_fn));
            buffer<expr> params_buf; for (auto & p : m_params) params_buf.push_back(p);
            if (m_modifiers.m_is_meta) {
                val = fix_rec_fn_macro_args(elab, mlocal_name(m_fn), params_buf, type, val);
            }
            buffer<name> univ_params_buf; to_buffer(m_univ_params, univ_params_buf);
            finalize_definition(elab, params_buf, type, val, univ_params_buf);

            bool use_conv_opt = true;
            bool is_trusted  = !m_modifiers.m_is_meta;
            auto new_env = elab.env();
            auto def = mk_definition(new_env, mk_tagged_fresh_name("example"),
                                              to_list(univ_params_buf), type, val, use_conv_opt, is_trusted);
            auto cdef = check(new_env, def);
            new_env = module::add(new_env, cdef);

            check_noncomputable(false, new_env, "example", def.get_name(), m_modifiers.m_is_noncomputable);
        } catch (exception & ex) {
            message_builder error_msg(&m_pos_provider, tc, m_decl_env, get_global_ios(),
                                      m_pos_provider.get_file_name(), m_pos_provider.get_some_pos(),
                                      ERROR);
            error_msg.set_exception(ex);
            error_msg.report();
        }
        return {};
    }
};

static bool is_rfl_preexpr(expr const & e) {
    return is_constant(e, get_rfl_name());
}

environment single_definition_cmd_core(parser & p, def_cmd_kind kind, decl_modifiers modifiers, decl_attributes attrs) {
    buffer<name> lp_names;
    buffer<expr> params;
    expr fn, val;
    auto header_pos = p.pos();
    optional<std::string> doc_string = p.get_doc_string();
    module::scope_pos_info scope_pos(header_pos);
    declaration_info_scope scope(p, kind, modifiers);
    bool is_example  = (kind == def_cmd_kind::Example);
    bool is_instance = modifiers.m_is_instance;
    bool aux_lemmas  = scope.gen_aux_lemmas();
    bool is_rfl      = false;
    if (is_instance)
        attrs.set_attribute(p.env(), "instance");
    std::tie(fn, val) = parse_definition(p, lp_names, params, is_example, is_instance);
    elaborator elab(p.env(), p.get_options(), metavar_context(), local_context());
    buffer<expr> new_params;
    elaborate_params(elab, params, new_params);
    elab.set_instance_fingerprint();
    replace_params(params, new_params, fn, val);

    auto process = [&](expr val) -> environment {
        expr type;
        optional<expr> opt_val;
        bool eqns = false;
        name c_name = mlocal_name(fn);
        pair<environment, name> env_n;
        if (kind == Theorem) {
            is_rfl = is_rfl_preexpr(val);
            type = elab.elaborate_type(mlocal_type(fn));
            elab.ensure_no_unassigned_metavars(type);
            expr new_fn = update_mlocal(fn, type);
            val = replace_local_preserving_pos_info(val, fn, new_fn);
            elaborator::theorem_finalization_info thm_finfo;
            finalize_theorem_type(elab, new_params, type, lp_names, thm_finfo);
            auto decl_env = elab.env();
            auto elab_task = get_global_task_queue().submit<proof_elaboration_task>(
                decl_env, p.get_options(), new_params, new_fn, val, thm_finfo, is_rfl, type,
                elab.mctx(), elab.lctx(), p.get_parser_pos_provider(header_pos));
            env_n = declare_definition(p, elab.env(), kind, lp_names, c_name, type, opt_val, elab_task, modifiers, attrs,
                                       doc_string, header_pos);
        } else if (kind == Example) {
            get_global_task_queue().submit<example_checking_task>(
                    p.env(), p.get_options(),
                    modifiers, to_list(lp_names),
                    new_params, fn, val,
                    elab.mctx(), elab.lctx(),
                    p.get_parser_pos_provider(header_pos));
            return p.env();
        } else {
            std::tie(val, type) = elaborate_definition(p, elab, kind, fn, val, header_pos);
            if (modifiers.m_is_meta) {
                val = fix_rec_fn_macro_args(elab, mlocal_name(fn), new_params, type, val);
            }
            eqns = is_equations_result(val);
            if (eqns) {
                lean_assert(is_equations_result(val));
                lean_assert(get_equations_result_size(val) == 1);
                val = get_equations_result(val, 0);
            }
            finalize_definition(elab, new_params, type, val, lp_names);
            opt_val = optional<expr>(val);
            env_n = declare_definition(p, elab.env(), kind, lp_names, c_name, type, opt_val, {}, modifiers, attrs, doc_string, header_pos);
        }
        environment new_env = env_n.first;
        name c_real_name    = env_n.second;
        if (is_rfl) new_env = mark_rfl_lemma(new_env, c_real_name);
        new_env = add_local_ref(p, new_env, c_name, c_real_name, lp_names, params);
        if (eqns && aux_lemmas) {
            new_env = copy_equation_lemmas(new_env, c_real_name);
        }
        return new_env;
    };

    try {
        return process(val);
    } catch (throwable & ex1) {
        /* Try again using 'sorry' */
        expr sorry = p.mk_sorry(header_pos);
        modifiers.m_is_noncomputable = true;
        environment new_env;
        try {
            new_env = process(sorry);
        } catch (throwable & ex2) {
            /* Throw original error */
            ex1.rethrow();
        }
        std::shared_ptr<throwable> ex_ptr(ex1.clone());
        throw update_environment_exception(new_env, ex_ptr);
    }
}

environment definition_cmd_core(parser & p, def_cmd_kind kind, decl_modifiers const & modifiers, decl_attributes attrs) {
    if (modifiers.m_is_mutual)
        return mutual_definition_cmd_core(p, kind, modifiers, attrs);
    else
        return single_definition_cmd_core(p, kind, modifiers, attrs);
}
}
