/-
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura
-/
prelude
import init.meta.tactic init.meta.format init.function

inductive congr_arg_kind
/- It is a parameter for the congruence lemma, the parameter occurs in the left and right hand sides. -/
| fixed
/- It is not a parameter for the congruence lemma, the lemma was specialized for this parameter.
   This only happens if the parameter is a subsingleton/proposition, and other parameters depend on it. -/
| fixed_no_param
/- The lemma contains three parameters for this kind of argument a_i, b_i and (eq_i : a_i = b_i).
   a_i and b_i represent the left and right hand sides, and eq_i is a proof for their equality. -/
| eq
/- congr-simp lemma contains only one parameter for this kind of argument, and congr-lemmas contains two.
   They correspond to arguments that are subsingletons/propositions. -/
| cast
/- The lemma contains three parameters for this kind of argument a_i, b_i and (eq_i : a_i == b_i).
   a_i and b_i represent the left and right hand sides, and eq_i is a proof for their heterogeneous equality. -/
| heq

structure congr_lemma :=
(type : expr) (proof : expr) (arg_kids : list congr_arg_kind)

namespace tactic
meta_constant mk_congr_simp_core   : transparency → expr → tactic congr_lemma
meta_constant mk_congr_simp_n_core : transparency → expr → nat → tactic congr_lemma
/- Create a specialized theorem using (a prefix of) the arguments of the given application. -/
meta_constant mk_specialized_congr_simp_core : transparency → expr → tactic congr_lemma

meta_constant mk_congr_core   : transparency → expr → tactic congr_lemma
meta_constant mk_congr_n_core : transparency → expr → nat → tactic congr_lemma
/- Create a specialized theorem using (a prefix of) the arguments of the given application. -/
meta_constant mk_specialized_congr_core : transparency → expr → tactic congr_lemma

meta_constant mk_hcongr_core   : transparency → expr → tactic congr_lemma
meta_constant mk_hcongr_n_core : transparency → expr → nat → tactic congr_lemma

/- If R is an equivalence relation, construct the congruence lemma
   R a1 a2 -> R b1 b2 -> (R a1 b1) <-> (R a2 b2) -/
meta_constant mk_rel_iff_congr_core : transparency → expr → tactic congr_lemma

/- Similar to mk_rel_iff_congr
   It fails if propext is not available.

   R a1 a2 -> R b1 b2 -> (R a1 b1) = (R a2 b2) -/
meta_constant mk_rel_eq_congr_core : transparency → expr → tactic congr_lemma

meta_definition mk_congr_simp : expr → tactic congr_lemma :=
mk_congr_simp_core semireducible

meta_definition mk_congr_simp_n : expr → nat → tactic congr_lemma :=
mk_congr_simp_n_core semireducible

meta_definition mk_specialized_congr_simp : expr → tactic congr_lemma :=
mk_specialized_congr_simp_core semireducible

meta_definition mk_congr : expr → tactic congr_lemma :=
mk_congr_core semireducible

meta_definition mk_congr_n : expr → nat → tactic congr_lemma :=
mk_congr_n_core semireducible

meta_definition mk_specialized_congr : expr → tactic congr_lemma :=
mk_specialized_congr_core semireducible

meta_definition mk_hcongr : expr → tactic congr_lemma :=
mk_hcongr_core semireducible

meta_definition mk_hcongr_n : expr → nat → tactic congr_lemma :=
mk_hcongr_n_core semireducible

meta_definition mk_rel_iff_congr : expr → tactic congr_lemma :=
mk_rel_iff_congr_core semireducible

meta_definition mk_rel_eq_congr : expr → tactic congr_lemma :=
mk_rel_eq_congr_core semireducible

end tactic
