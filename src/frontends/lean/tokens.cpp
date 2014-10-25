/*
Copyright (c) 2014 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include "util/name.h"

namespace lean {
static name * g_period       = nullptr;
static name * g_placeholder  = nullptr;
static name * g_colon        = nullptr;
static name * g_dcolon       = nullptr;
static name * g_lparen       = nullptr;
static name * g_rparen       = nullptr;
static name * g_llevel_curly = nullptr;
static name * g_lcurly       = nullptr;
static name * g_rcurly       = nullptr;
static name * g_ldcurly      = nullptr;
static name * g_rdcurly      = nullptr;
static name * g_lbracket     = nullptr;
static name * g_rbracket     = nullptr;
static name * g_bar          = nullptr;
static name * g_comma        = nullptr;
static name * g_add          = nullptr;
static name * g_max          = nullptr;
static name * g_imax         = nullptr;
static name * g_cup          = nullptr;
static name * g_import       = nullptr;
static name * g_show         = nullptr;
static name * g_have         = nullptr;
static name * g_assume       = nullptr;
static name * g_take         = nullptr;
static name * g_fun          = nullptr;
static name * g_ellipsis     = nullptr;
static name * g_raw          = nullptr;
static name * g_true         = nullptr;
static name * g_false        = nullptr;
static name * g_options      = nullptr;
static name * g_instances    = nullptr;
static name * g_classes      = nullptr;
static name * g_coercions    = nullptr;
static name * g_arrow        = nullptr;
static name * g_declarations = nullptr;
static name * g_decls        = nullptr;
static name * g_hiding       = nullptr;
static name * g_exposing     = nullptr;
static name * g_renaming     = nullptr;
static name * g_extends      = nullptr;
static name * g_as           = nullptr;
static name * g_on           = nullptr;
static name * g_off          = nullptr;
static name * g_none         = nullptr;
static name * g_in           = nullptr;
static name * g_assign       = nullptr;
static name * g_visible      = nullptr;
static name * g_from         = nullptr;
static name * g_using        = nullptr;
static name * g_then         = nullptr;
static name * g_by           = nullptr;
static name * g_proof        = nullptr;
static name * g_qed          = nullptr;
static name * g_begin        = nullptr;
static name * g_end          = nullptr;
static name * g_definition   = nullptr;
static name * g_theorem      = nullptr;
static name * g_axiom        = nullptr;
static name * g_axioms       = nullptr;
static name * g_variable     = nullptr;
static name * g_variables    = nullptr;
static name * g_opaque       = nullptr;
static name * g_instance     = nullptr;
static name * g_priority     = nullptr;
static name * g_coercion     = nullptr;
static name * g_reducible    = nullptr;
static name * g_with         = nullptr;
static name * g_class        = nullptr;
static name * g_prev         = nullptr;
static name * g_scoped       = nullptr;
static name * g_foldr        = nullptr;
static name * g_foldl        = nullptr;
static name * g_binder       = nullptr;
static name * g_binders      = nullptr;
static name * g_infix        = nullptr;
static name * g_infixl       = nullptr;
static name * g_infixr       = nullptr;
static name * g_postfix      = nullptr;
static name * g_prefix       = nullptr;
static name * g_notation     = nullptr;
static name * g_call         = nullptr;
static name * g_persistent   = nullptr;
static name * g_root         = nullptr;

void initialize_tokens() {
    g_period       = new name(".");
    g_placeholder  = new name("_");
    g_colon        = new name(":");
    g_dcolon       = new name("::");
    g_lparen       = new name("(");
    g_rparen       = new name(")");
    g_llevel_curly = new name(".{");
    g_lcurly       = new name("{");
    g_rcurly       = new name("}");
    g_ldcurly      = new name("⦃");
    g_rdcurly      = new name("⦄");
    g_lbracket     = new name("[");
    g_rbracket     = new name("]");
    g_bar          = new name("|");
    g_comma        = new name(",");
    g_add          = new name("+");
    g_max          = new name("max");
    g_imax         = new name("imax");
    g_cup          = new name("\u2294");
    g_import       = new name("import");
    g_show         = new name("show");
    g_have         = new name("have");
    g_assume       = new name("assume");
    g_take         = new name("take");
    g_fun          = new name("fun");
    g_ellipsis     = new name("...");
    g_raw          = new name("raw");
    g_true         = new name("true");
    g_false        = new name("false");
    g_options      = new name("options");
    g_instances    = new name("instances");
    g_classes      = new name("classes");
    g_coercions    = new name("coercions");
    g_arrow        = new name("->");
    g_declarations = new name("declarations");
    g_decls        = new name("decls");
    g_hiding       = new name("hiding");
    g_exposing     = new name("exposing");
    g_renaming     = new name("renaming");
    g_extends      = new name("extends");
    g_as           = new name("as");
    g_on           = new name("[on]");
    g_off          = new name("[off]");
    g_none         = new name("[none]");
    g_in           = new name("in");
    g_assign       = new name(":=");
    g_visible      = new name("[visible]");
    g_from         = new name("from");
    g_using        = new name("using");
    g_then         = new name("then");
    g_by           = new name("by");
    g_proof        = new name("proof");
    g_qed          = new name("qed");
    g_begin        = new name("begin");
    g_end          = new name("end");
    g_definition   = new name("definition");
    g_theorem      = new name("theorem");
    g_opaque       = new name("opaque");
    g_axiom        = new name("axiom");
    g_axioms       = new name("axioms");
    g_variable     = new name("variable");
    g_variables    = new name("variables");
    g_instance     = new name("[instance]");
    g_priority     = new name("[priority");
    g_coercion     = new name("[coercion]");
    g_reducible    = new name("[reducible]");
    g_with         = new name("with");
    g_class        = new name("[class]");
    g_prev         = new name("prev");
    g_scoped       = new name("scoped");
    g_foldr        = new name("foldr");
    g_foldl        = new name("foldl");
    g_binder       = new name("binder");
    g_binders      = new name("binders");
    g_infix        = new name("infix");
    g_infixl       = new name("infixl");
    g_infixr       = new name("infixr");
    g_postfix      = new name("postfix");
    g_prefix       = new name("prefix");
    g_notation     = new name("notation");
    g_call         = new name("call");
    g_persistent   = new name("[persistent]");
    g_root         = new name("_root_");
}

void finalize_tokens() {
    delete g_persistent;
    delete g_root;
    delete g_prev;
    delete g_scoped;
    delete g_foldr;
    delete g_foldl;
    delete g_binder;
    delete g_binders;
    delete g_infix;
    delete g_infixl;
    delete g_infixr;
    delete g_postfix;
    delete g_prefix;
    delete g_notation;
    delete g_call;
    delete g_with;
    delete g_class;
    delete g_definition;
    delete g_theorem;
    delete g_opaque;
    delete g_axiom;
    delete g_axioms;
    delete g_variables;
    delete g_variable;
    delete g_instance;
    delete g_priority;
    delete g_coercion;
    delete g_reducible;
    delete g_in;
    delete g_assign;
    delete g_visible;
    delete g_from;
    delete g_using;
    delete g_then;
    delete g_by;
    delete g_proof;
    delete g_qed;
    delete g_begin;
    delete g_end;
    delete g_raw;
    delete g_true;
    delete g_false;
    delete g_options;
    delete g_instances;
    delete g_classes;
    delete g_coercions;
    delete g_arrow;
    delete g_declarations;
    delete g_decls;
    delete g_hiding;
    delete g_exposing;
    delete g_renaming;
    delete g_extends;
    delete g_as;
    delete g_on;
    delete g_off;
    delete g_none;
    delete g_ellipsis;
    delete g_fun;
    delete g_take;
    delete g_assume;
    delete g_have;
    delete g_show;
    delete g_import;
    delete g_cup;
    delete g_imax;
    delete g_max;
    delete g_add;
    delete g_comma;
    delete g_bar;
    delete g_rbracket;
    delete g_lbracket;
    delete g_rdcurly;
    delete g_ldcurly;
    delete g_lcurly;
    delete g_rcurly;
    delete g_llevel_curly;
    delete g_rparen;
    delete g_lparen;
    delete g_colon;
    delete g_dcolon;
    delete g_placeholder;
    delete g_period;
}

name const & get_period_tk() { return *g_period; }
name const & get_placeholder_tk() { return *g_placeholder; }
name const & get_colon_tk() { return *g_colon; }
name const & get_dcolon_tk() { return *g_dcolon; }
name const & get_lparen_tk() { return *g_lparen; }
name const & get_rparen_tk() { return *g_rparen; }
name const & get_llevel_curly_tk() { return *g_llevel_curly; }
name const & get_lcurly_tk() { return *g_lcurly; }
name const & get_rcurly_tk() { return *g_rcurly; }
name const & get_ldcurly_tk() { return *g_ldcurly; }
name const & get_rdcurly_tk() { return *g_rdcurly; }
name const & get_lbracket_tk() { return *g_lbracket; }
name const & get_rbracket_tk() { return *g_rbracket; }
name const & get_bar_tk() { return *g_bar; }
name const & get_comma_tk() { return *g_comma; }
name const & get_add_tk() { return *g_add; }
name const & get_max_tk() { return *g_max; }
name const & get_imax_tk() { return *g_imax; }
name const & get_cup_tk() { return *g_cup; }
name const & get_import_tk() { return *g_import; }
name const & get_show_tk() { return *g_show; }
name const & get_have_tk() { return *g_have; }
name const & get_assume_tk() { return *g_assume; }
name const & get_take_tk() { return *g_take; }
name const & get_fun_tk() { return *g_fun; }
name const & get_ellipsis_tk() { return *g_ellipsis; }
name const & get_raw_tk() { return *g_raw; }
name const & get_true_tk() { return *g_true; }
name const & get_false_tk() { return *g_false; }
name const & get_options_tk() { return *g_options; }
name const & get_instances_tk() { return *g_instances; }
name const & get_classes_tk() { return *g_classes; }
name const & get_coercions_tk() { return *g_coercions; }
name const & get_arrow_tk() { return *g_arrow; }
name const & get_declarations_tk() { return *g_declarations; }
name const & get_decls_tk() { return *g_decls; }
name const & get_hiding_tk() { return *g_hiding; }
name const & get_exposing_tk() { return *g_exposing; }
name const & get_renaming_tk() { return *g_renaming; }
name const & get_extends_tk() { return *g_extends; }
name const & get_as_tk() { return *g_as; }
name const & get_on_tk() { return *g_on; }
name const & get_off_tk() { return *g_off; }
name const & get_none_tk() { return *g_none; }
name const & get_in_tk() { return *g_in; }
name const & get_assign_tk() { return *g_assign; }
name const & get_visible_tk() { return *g_visible; }
name const & get_from_tk() { return *g_from; }
name const & get_using_tk() { return *g_using; }
name const & get_then_tk() { return *g_then; }
name const & get_by_tk() { return *g_by; }
name const & get_proof_tk() { return *g_proof; }
name const & get_qed_tk() { return *g_qed; }
name const & get_begin_tk() { return *g_begin; }
name const & get_end_tk() { return *g_end; }
name const & get_definition_tk() { return *g_definition; }
name const & get_theorem_tk() { return *g_theorem; }
name const & get_axiom_tk() { return *g_axiom; }
name const & get_axioms_tk() { return *g_axioms; }
name const & get_variable_tk() { return *g_variable; }
name const & get_variables_tk() { return *g_variables; }
name const & get_opaque_tk() { return *g_opaque; }
name const & get_instance_tk() { return *g_instance; }
name const & get_priority_tk() { return *g_priority; }
name const & get_coercion_tk() { return *g_coercion; }
name const & get_reducible_tk() { return *g_reducible; }
name const & get_class_tk() { return *g_class; }
name const & get_with_tk() { return *g_with; }
name const & get_prev_tk() { return *g_prev; }
name const & get_scoped_tk() { return *g_scoped; }
name const & get_foldr_tk() { return *g_foldr; }
name const & get_foldl_tk() { return *g_foldl; }
name const & get_binder_tk() { return *g_binder; }
name const & get_binders_tk() { return *g_binders; }
name const & get_infix_tk() { return *g_infix; }
name const & get_infixl_tk() { return *g_infixl; }
name const & get_infixr_tk() { return *g_infixr; }
name const & get_postfix_tk() { return *g_postfix; }
name const & get_prefix_tk() { return *g_prefix; }
name const & get_notation_tk() { return *g_notation; }
name const & get_call_tk() { return *g_call; }
name const & get_persistent_tk() { return *g_persistent; }
name const & get_root_tk() { return *g_root; }
}
