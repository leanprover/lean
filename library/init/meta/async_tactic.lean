/-
Copyright (c) 2017 Gabriel Ebner. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Gabriel Ebner
-/
prelude
import init.meta.tactic
import init.meta.interactive

namespace tactic

private meta def run_or_fail {α} (s : tactic_state) (tac : tactic α) : α :=
match tac s with
| (tactic_result.success a s) := a
| (tactic_result.exception .α fmt _ s') :=
  undefined_core $ to_string $ fmt () ++ format.line ++ to_fmt s'
end

meta def run_async {α : Type} (tac : tactic α) : tactic (task α) := do
s ← read, return $ task.delay $ λ _,
  match tac s with
  | (tactic_result.success a s) := a
  | (tactic_result.exception .α fmt _ s') :=
    undefined_core $ to_string $ fmt () ++ format.line ++ to_fmt s'
  end

meta def prove_goal_async (tac : tactic unit) : tactic unit := do
ctx ← local_context, revert_lst ctx,
tgt ← target, tgt ← instantiate_mvars tgt,
env ← get_env, tgt ← return $ env^.unfold_untrusted_macros tgt,
when tgt^.has_meta_var (fail $ "goal contains metavariables"),
params ← return tgt^.collect_univ_params,
lemma_name ← new_aux_decl_name,
proof ← run_async (do
  goal_meta ← mk_meta_var tgt,
  set_goals [goal_meta],
  monad.for' ctx (λc, intro c^.local_pp_name),
  tac,
  proof ← instantiate_mvars goal_meta,
  proof ← return $ env^.unfold_untrusted_macros proof,
  when proof^.has_meta_var $ fail "async proof failed: contains metavariables",
  return proof),
add_decl $ declaration.thm lemma_name params tgt proof,
exact (expr.const lemma_name (params^.for level.param))

namespace interactive
open interactive.types

/-- Proves the first goal asynchronously as a separate lemma. -/
meta def async (tac : irtactic) : tactic unit :=
prove_goal_async tac

end interactive
end tactic
