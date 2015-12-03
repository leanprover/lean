/*
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include "library/blast/blast.h"
#include "library/blast/options.h"
#include "library/blast/choice_point.h"
#include "library/blast/simple_actions.h"
#include "library/blast/proof_expr.h"
#include "library/blast/intros_action.h"
#include "library/blast/subst_action.h"
#include "library/blast/backward/backward_action.h"
#include "library/blast/backward/backward_strategy.h"
#include "library/blast/forward/forward_actions.h"
#include "library/blast/forward/ematch.h"
#include "library/blast/unit/unit_actions.h"
#include "library/blast/no_confusion_action.h"
#include "library/blast/simplifier/simplifier_actions.h"
#include "library/blast/recursor_action.h"
#include "library/blast/assert_cc_action.h"
#include "library/blast/strategy.h"
#include "library/blast/trace.h"

namespace lean {
namespace blast {
/** \brief Implement a simple proof strategy for blast.
    We use it mainly for testing new actions and the whole blast infra-structure. */
class simple_strategy : public strategy {
    action_result hypothesis_pre_activation(hypothesis_idx hidx) override {
        Try(assumption_contradiction_actions(hidx));
        Try(simplify_hypothesis_action(hidx));
        Try(unit_preprocess(hidx));
        Try(no_confusion_action(hidx));
        TrySolve(assert_cc_action(hidx));
        Try(discard_action(hidx));
        Try(subst_action(hidx));
        return action_result::new_branch();
    }

    action_result hypothesis_post_activation(hypothesis_idx hidx) override {
        Try(unit_propagate(hidx));
        Try(recursor_preprocess_action(hidx));
        return action_result::new_branch();
    }

    /* \brief Preprocess state
       It keeps applying intros, activating and finally simplify target.
       Return an expression if the goal has been proved during preprocessing step. */
    virtual optional<expr> preprocess() override {
        trace("* Preprocess");
        while (true) {
            if (!failed(intros_action()))
                continue;
            auto r = activate_hypothesis(true);
            if (solved(r)) return r.to_opt_expr();
            if (failed(r)) break;
        }
        TrySolveToOptExpr(assumption_action());
        TrySolveToOptExpr(simplify_target_action());
        return none_expr();
    }

    virtual action_result next_action() override {
        Try(intros_action());
        Try(activate_hypothesis(false));
        Try(trivial_action());
        Try(assumption_action());
        Try(recursor_action());
        Try(constructor_action());
        Try(ematch_action());
        TryStrategy(apply_backward_strategy());
        Try(qfc_action(list<gexpr>()));

        // TODO(Leo): add more actions...

        return action_result::failed();
    }
};

optional<expr> apply_simple_strategy() {
    return simple_strategy()();
}
}}
