/*
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include "library/tactic/tactic_state.h"
#include "library/tactic/intro_tactic.h"
#include "library/tactic/revert_tactic.h"
#include "library/tactic/rename_tactic.h"
#include "library/tactic/clear_tactic.h"
#include "library/tactic/app_builder_tactics.h"
#include "library/tactic/subst_tactic.h"
#include "library/tactic/exact_tactic.h"
#include "library/tactic/change_tactic.h"
#include "library/tactic/assert_tactic.h"
#include "library/tactic/apply_tactic.h"
#include "library/tactic/fun_info_tactics.h"
#include "library/tactic/congr_lemma_tactics.h"
#include "library/tactic/abstract_expr_tactics.h"
#include "library/tactic/elaborate.h"
#include "library/tactic/defeq_simplifier/init_module.h"
#include "library/tactic/simplifier/init_module.h"

namespace lean {
void initialize_tactic_module() {
    initialize_tactic_state();
    initialize_intro_tactic();
    initialize_revert_tactic();
    initialize_rename_tactic();
    initialize_clear_tactic();
    initialize_app_builder_tactics();
    initialize_subst_tactic();
    initialize_exact_tactic();
    initialize_change_tactic();
    initialize_assert_tactic();
    initialize_apply_tactic();
    initialize_fun_info_tactics();
    initialize_congr_lemma_tactics();
    initialize_abstract_expr_tactics();
    initialize_elaborate();
    initialize_defeq_simplifier_module();
    initialize_simplifier_module();
}
void finalize_tactic_module() {
    finalize_defeq_simplifier_module();
    finalize_simplifier_module();
    finalize_elaborate();
    finalize_abstract_expr_tactics();
    finalize_congr_lemma_tactics();
    finalize_fun_info_tactics();
    finalize_apply_tactic();
    finalize_assert_tactic();
    finalize_change_tactic();
    finalize_exact_tactic();
    finalize_subst_tactic();
    finalize_app_builder_tactics();
    finalize_clear_tactic();
    finalize_rename_tactic();
    finalize_revert_tactic();
    finalize_intro_tactic();
    finalize_tactic_state();
}
}
