/-
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura
-/
prelude
import init.meta.tactic

namespace tactic
open list nat

meta_constant simp_lemmas : Type₁

/- Create a data-structure containing all lemmas tagged as [simp].
   Lemmas with type `<lhs> <eqv_rel> <rhs>` are indexed using the head-symbol of `<lhs>`,
   computed with respect to the given transparency setting. -/
meta_constant mk_simp_lemmas_core     : transparency → tactic simp_lemmas
/- (simp_lemmas_insert_core m lemmas id lemma priority) adds the given lemma to the set simp_lemmas. -/
meta_constant simp_lemmas_insert_core : transparency → simp_lemmas → expr → tactic simp_lemmas

meta_definition mk_simp_lemmas        : tactic simp_lemmas :=
mk_simp_lemmas_core reducible

meta_definition simp_lemmas_add_extra : transparency → simp_lemmas → list expr → tactic simp_lemmas
| m sls []      := return sls
| m sls (l::ls) := do
  new_sls ← simp_lemmas_insert_core m sls l,
  simp_lemmas_add_extra m new_sls ls

/- Simplify the given expression using [simp] and [congr] lemmas.
   The first argument is a tactic to be used to discharge proof obligations.
   The second argument is the name of the relation to simplify over.
   The third argument is a list of additional expressions to be considered as simp rules.
   The fourth argument is the expression to be simplified.
   The result is the simplified expression along with a proof that the new
   expression is equivalent to the old one.
   Fails if no simplifications can be performed. -/
meta_constant simplify_core : tactic unit → name → simp_lemmas → expr → tactic (expr × expr)

meta_definition simplify (prove_fn : tactic unit) (extra_lemmas : list expr) (e : expr) : tactic (expr × expr) :=
do simp_lemmas  ← mk_simp_lemmas_core reducible,
   new_lemmas   ← simp_lemmas_add_extra reducible simp_lemmas extra_lemmas,
   e_type       ← infer_type e >>= whnf,
   rel          ← return $ if e_type = expr.prop then "iff" else "eq",
   simplify_core prove_fn rel new_lemmas e

meta_definition simplify_goal (prove_fn : tactic unit) (extra_lemmas : list expr) : tactic unit :=
do (new_target, Heq) ← target >>= simplify prove_fn extra_lemmas,
   assert "Htarget" new_target, swap,
   ns ← return (if expr.is_eq Heq ≠ none then "eq" else "iff" : name),
   Ht ← get_local "Htarget",
   mk_app (ns <.> "mpr") [Heq, Ht] >>= exact

meta_definition simp : tactic unit :=
simplify_goal failed [] >> try triv

meta_definition simp_using (Hs : list expr) : tactic unit :=
simplify_goal failed Hs >> try triv

private meta_definition is_equation : expr → bool
| (expr.pi _ _ _ b) := is_equation b
| e                 := match expr.is_eq e with some _ := tt | none := ff end

private meta_definition collect_eqs : list expr → tactic (list expr)
| []        := return []
| (H :: Hs) := do
  Eqs   ← collect_eqs Hs,
  Htype ← infer_type H >>= whnf,
  return $ if is_equation Htype = tt then H :: Eqs else Eqs

/- Simplify target using all hypotheses in the local context. -/
meta_definition simp_using_hs : tactic unit :=
local_context >>= collect_eqs >>= simp_using

meta_definition simp_core_at (prove_fn : tactic unit) (extra_lemmas : list expr) (H : expr) : tactic unit :=
do when (expr.is_local_constant H = ff) (fail "tactic simp_at failed, the given expression is not a hypothesis"),
   Htype ← infer_type H,
   (new_Htype, Heq) ← simplify prove_fn extra_lemmas Htype,
   assert (expr.local_pp_name H) new_Htype,
   ns ← return (if expr.is_eq Heq ≠ none then "eq" else "iff" : name),
   mk_app (ns <.> "mp") [Heq, H] >>= exact,
   try $ clear H

meta_definition simp_at : expr → tactic unit :=
simp_core_at failed []

meta_definition simp_at_using (Hs : list expr) : expr → tactic unit :=
simp_core_at failed Hs

meta_definition simp_at_using_hs (H : expr) : tactic unit :=
do Hs ← local_context >>= collect_eqs,
   simp_core_at failed (filter (ne H) Hs) H

meta_definition mk_eq_simp_ext (simp_ext : expr → tactic (expr × expr)) : tactic unit :=
do (lhs, rhs)     ← target >>= match_eq,
   (new_rhs, Heq) ← simp_ext lhs,
   unify rhs new_rhs,
   exact Heq

end tactic
