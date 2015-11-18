/*
Copyright (c) 2014 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include "util/sexpr/option_declarations.h"
#include "frontends/lean/elaborator_context.h"
#include "frontends/lean/opt_cmd.h"

#ifndef LEAN_DEFAULT_ELABORATOR_LOCAL_INSTANCES
#define LEAN_DEFAULT_ELABORATOR_LOCAL_INSTANCES true
#endif

#ifndef LEAN_DEFAULT_ELABORATOR_IGNORE_INSTANCES
#define LEAN_DEFAULT_ELABORATOR_IGNORE_INSTANCES false
#endif

#ifndef LEAN_DEFAULT_ELABORATOR_FLYCHECK_GOALS
#define LEAN_DEFAULT_ELABORATOR_FLYCHECK_GOALS false
#endif

#ifndef LEAN_DEFAULT_ELABORATOR_FAIL_MISSING_FIELD
#define LEAN_DEFAULT_ELABORATOR_FAIL_MISSING_FIELD false
#endif

#ifndef LEAN_DEFAULT_ELABORATOR_LIFT_COERCIONS
#define LEAN_DEFAULT_ELABORATOR_LIFT_COERCIONS true
#endif

#ifndef LEAN_DEFAULT_ELABORATOR_COERCIONS
#define LEAN_DEFAULT_ELABORATOR_COERCIONS true
#endif


namespace lean {
// ==========================================
// elaborator configuration options
static name * g_elaborator_local_instances    = nullptr;
static name * g_elaborator_ignore_instances   = nullptr;
static name * g_elaborator_flycheck_goals     = nullptr;
static name * g_elaborator_fail_missing_field = nullptr;
static name * g_elaborator_lift_coercions     = nullptr;
static name * g_elaborator_coercions          = nullptr;

name const & get_elaborator_ignore_instances_name() {
    return *g_elaborator_ignore_instances;
}

bool get_elaborator_local_instances(options const & opts) {
    return opts.get_bool(*g_elaborator_local_instances, LEAN_DEFAULT_ELABORATOR_LOCAL_INSTANCES);
}

bool get_elaborator_ignore_instances(options const & opts) {
    return opts.get_bool(*g_elaborator_ignore_instances, LEAN_DEFAULT_ELABORATOR_IGNORE_INSTANCES);
}

bool get_elaborator_flycheck_goals(options const & opts) {
    return opts.get_bool(*g_elaborator_flycheck_goals, LEAN_DEFAULT_ELABORATOR_FLYCHECK_GOALS);
}

bool get_elaborator_fail_missing_field(options const & opts) {
    return opts.get_bool(*g_elaborator_fail_missing_field, LEAN_DEFAULT_ELABORATOR_FAIL_MISSING_FIELD);
}

bool get_elaborator_lift_coercions(options const & opts) {
    return opts.get_bool(*g_elaborator_lift_coercions, LEAN_DEFAULT_ELABORATOR_LIFT_COERCIONS);
}

bool get_elaborator_coercions(options const & opts) {
    return opts.get_bool(*g_elaborator_coercions, LEAN_DEFAULT_ELABORATOR_COERCIONS);
}

// ==========================================

elaborator_context::elaborator_context(environment const & env, io_state const & ios, local_decls<level> const & lls,
                                       pos_info_provider const * pp, info_manager * info, bool check_unassigned):
    m_env(env), m_ios(ios), m_lls(lls), m_pos_provider(pp), m_info_manager(info), m_check_unassigned(check_unassigned) {
    set_options(ios.get_options());
}

elaborator_context::elaborator_context(elaborator_context const & ctx, options const & o):
    m_env(ctx.m_env), m_ios(ctx.m_ios), m_lls(ctx.m_lls), m_pos_provider(ctx.m_pos_provider),
    m_info_manager(ctx.m_info_manager), m_check_unassigned(ctx.m_check_unassigned) {
    set_options(o);
}

void elaborator_context::set_options(options const & opts) {
    m_options             = opts;
    m_use_local_instances = get_elaborator_local_instances(opts);
    m_ignore_instances    = get_elaborator_ignore_instances(opts);
    m_flycheck_goals      = get_elaborator_flycheck_goals(opts);
    m_fail_missing_field  = get_elaborator_fail_missing_field(opts);
    m_lift_coercions      = get_elaborator_lift_coercions(opts);
    m_coercions           = get_elaborator_coercions(opts);

    if (has_show_goal(opts, m_show_goal_line, m_show_goal_col)) {
        m_show_goal_at = true;
    } else {
        m_show_goal_at = false;
    }

    if (has_show_hole(opts, m_show_hole_line, m_show_hole_col)) {
        m_show_hole_at = true;
    } else {
        m_show_hole_at = false;
    }
}

bool elaborator_context::has_show_goal_at(unsigned & line, unsigned & col) const {
    if (m_show_goal_at) {
        line = m_show_goal_line;
        col  = m_show_goal_col;
        return true;
    } else {
        return false;
    }
}

void elaborator_context::reset_show_goal_at() {
    m_show_goal_at = false;
}

bool elaborator_context::has_show_hole_at(unsigned & line, unsigned & col) const {
    if (m_show_hole_at) {
        line = m_show_hole_line;
        col  = m_show_hole_col;
        return true;
    } else {
        return false;
    }
}

void elaborator_context::reset_show_hole_at() {
    m_show_hole_at = false;
}

void initialize_elaborator_context() {
    g_elaborator_local_instances    = new name{"elaborator", "local_instances"};
    g_elaborator_ignore_instances   = new name{"elaborator", "ignore_instances"};
    g_elaborator_flycheck_goals     = new name{"elaborator", "flycheck_goals"};
    g_elaborator_fail_missing_field = new name{"elaborator", "fail_if_missing_field"};
    g_elaborator_lift_coercions     = new name{"elaborator", "lift_coercions"};
    g_elaborator_coercions          = new name{"elaborator", "coercions"};
    register_bool_option(*g_elaborator_local_instances, LEAN_DEFAULT_ELABORATOR_LOCAL_INSTANCES,
                         "(elaborator) use local declarates as class instances");
    register_bool_option(*g_elaborator_ignore_instances, LEAN_DEFAULT_ELABORATOR_IGNORE_INSTANCES,
                         "(elaborator) if true, then elaborator does not perform class-instance resolution");
    register_bool_option(*g_elaborator_flycheck_goals, LEAN_DEFAULT_ELABORATOR_FLYCHECK_GOALS,
                         "(elaborator) if true, then elaborator display current goals for flycheck before each "
                         "tactic is executed in a `begin ... end` block");
    register_bool_option(*g_elaborator_fail_missing_field, LEAN_DEFAULT_ELABORATOR_FAIL_MISSING_FIELD,
                         "(elaborator) if true, then elaborator generates an error for missing fields instead "
                         "of adding placeholders");
    register_bool_option(*g_elaborator_lift_coercions, LEAN_DEFAULT_ELABORATOR_LIFT_COERCIONS,
                         "(elaborator) if true, the elaborator will automatically lift coercions from A to B "
                         "into coercions from (C -> A) to (C -> B)");
    register_bool_option(*g_elaborator_coercions, LEAN_DEFAULT_ELABORATOR_COERCIONS,
                         "(elaborator) if true, the elaborator will automatically introduce coercions");
}
void finalize_elaborator_context() {
    delete g_elaborator_local_instances;
    delete g_elaborator_ignore_instances;
    delete g_elaborator_flycheck_goals;
    delete g_elaborator_fail_missing_field;
    delete g_elaborator_lift_coercions;
    delete g_elaborator_coercions;
}
}
