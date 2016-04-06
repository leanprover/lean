/-
Copyright (c) 2016 Jacob Gross. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jacob Gross, Jeremy Avigad

Sigma algebras.
-/
import data.set data.nat theories.topology.continuous ..move
open eq.ops set nat

structure sigma_algebra [class] (X : Type) :=
  (sets : set (set X))
  (univ_mem_sets : univ ∈ sets)
  (comp_mem_sets : ∀ {s : set X}, s ∈ sets → (-s ∈ sets))
  (cUnion_mem_sets : ∀ {s : ℕ → set X}, (∀ i, s i ∈ sets) → (⋃ i, s i) ∈ sets)

/- Closure properties -/

namespace measure_theory
open sigma_algebra

variables {X : Type} [sigma_algebra X]

definition measurable (t : set X) : Prop := t ∈ sets X

theorem measurable_univ : measurable (@univ X) :=
univ_mem_sets X

theorem measurable_compl {s : set X} (H : measurable s) : measurable (-s) :=
comp_mem_sets H

theorem measurable_of_measurable_compl {s : set X} (H : measurable (-s)) : measurable s :=
!compl_compl ▸ measurable_compl H

theorem measurable_empty : measurable (∅ : set X) :=
compl_univ ▸ measurable_compl measurable_univ

theorem measurable_cUnion {s : ℕ → set X} (H : ∀ i, measurable (s i)) :
  measurable (⋃ i, s i) :=
cUnion_mem_sets H

theorem measurable_cInter {s : ℕ → set X} (H : ∀ i, measurable (s i)) :
  measurable (⋂ i, s i) :=
have ∀ i, measurable (-(s i)), from take i, measurable_compl (H i),
have measurable (-(⋃ i, -(s i))), from measurable_compl (measurable_cUnion this),
show measurable (⋂ i, s i), by rewrite Inter_eq_comp_Union_comp; apply this

theorem measurable_union {s t : set X} (Hs : measurable s) (Ht : measurable t) :
  measurable (s ∪ t) :=
have ∀ i, measurable (bin_ext s t i), by intro i; cases i; exact Hs; exact Ht,
show measurable (s ∪ t), by rewrite -Union_bin_ext; exact measurable_cUnion this

theorem measurable_inter {s t : set X} (Hs : measurable s) (Ht : measurable t) :
  measurable (s ∩ t) :=
have ∀ i, measurable (bin_ext s t i), by intro i; cases i; exact Hs; exact Ht,
show measurable (s ∩ t), by rewrite -Inter_bin_ext; exact measurable_cInter this

theorem measurable_diff {s t : set X} (Hs : measurable s) (Ht : measurable t) :
  measurable (s \ t) :=
measurable_inter Hs (measurable_compl Ht)

theorem measurable_insert {x : X} {s : set X} (Hx : measurable '{x}) (Hs : measurable s) :
  measurable (insert x s) :=
!insert_eq⁻¹ ▸ measurable_union Hx Hs

end measure_theory

/- Measurable functions -/

namespace measure_theory
  open sigma_algebra function
  variables {X Y Z : Type} {M : sigma_algebra X} {N : sigma_algebra Y} {L : sigma_algebra Z}

  definition measurable_fun (f : X → Y) (M : sigma_algebra X) (N : sigma_algebra Y) :=
  ∀ ⦃s⦄, s ∈ sets Y → f '- s ∈ sets X

  theorem measurable_fun_id : measurable_fun (@id X) M M :=
  take s, suppose s ∈ sets X, this

  theorem measurable_fun_comp {f : X → Y} {g : Y → Z} (Hf : measurable_fun f M N)
      (Hg : measurable_fun g N L) :
    measurable_fun (g ∘ f) M L :=
  take s, assume Hs, Hf (Hg Hs)

  section
    open classical

    theorem measurable_fun_const (c : Y) :
      measurable_fun (λ x : X, c) M N :=
    take s, assume Hs,
    if cs : c ∈ s then
      have (λx, c) '- s = @univ X, from eq_univ_of_forall (take x, mem_preimage cs),
      by rewrite this; apply measurable_univ
    else
      have (λx, c) '- s = (∅ : set X),
        from eq_empty_of_forall_not_mem (take x, assume H, cs (mem_of_mem_preimage H)),
      by rewrite this; apply measurable_empty
end

end measure_theory

/-
-- Properties of sigma algebras
-/

namespace sigma_algebra
open measure_theory
variables {X : Type}

protected theorem eq {M N : sigma_algebra X} (H : @sets X M = @sets X N) :
  M = N :=
by cases M; cases N; cases H; apply rfl

/- sigma algebra generated by a set -/

inductive sets_generated_by (G : set (set X)) : set X → Prop :=
| generators_mem : ∀ ⦃s : set X⦄, s ∈ G → sets_generated_by G s
| univ_mem       : sets_generated_by G univ
| comp_mem       : ∀ ⦃s : set X⦄, sets_generated_by G s → sets_generated_by G (-s)
| cUnion_mem     : ∀ ⦃s : ℕ → set X⦄, (∀ i, sets_generated_by G (s i)) →
                                        sets_generated_by G (⋃ i, s i)

protected definition generated_by {X : Type} (G : set (set X)) : sigma_algebra X :=
⦃sigma_algebra,
  sets            := sets_generated_by G,
  univ_mem_sets   := sets_generated_by.univ_mem G,
  comp_mem_sets   := sets_generated_by.comp_mem ,
  cUnion_mem_sets := sets_generated_by.cUnion_mem ⦄

theorem sets_generated_by_initial {G : set (set X)} {M : sigma_algebra X} (H : G ⊆ @sets _ M) :
  sets_generated_by G ⊆ @sets _ M :=
begin
  intro s Hs,
  induction Hs with s sG s Hs ssX s Hs sisX,
    {exact H sG},
    {exact measurable_univ},
    {exact measurable_compl ssX},
  exact measurable_cUnion sisX
end

theorem measurable_generated_by {G : set (set X)} :
   ∀₀ s ∈ G, @measurable _ (sigma_algebra.generated_by G) s :=
λ s H, sets_generated_by.generators_mem H

section
  variables {Y : Type} {M : sigma_algebra X}

  theorem measurable_fun_generated_by (f : X → Y) (G : set (set Y))
    (Hg : ∀₀ g ∈ G, f '- g ∈ sets X) : measurable_fun f M (sigma_algebra.generated_by G) :=
  begin
    intro A HA,
    induction HA with Hg A s setsG pre s' HsetsG HsetsG',
      exact Hg A,
      exact measurable_univ,
      rewrite [preimage_compl]; exact measurable_compl pre,
      rewrite [preimage_Union]; exact measurable_cUnion HsetsG'
  end
end

/- The collection of sigma algebras forms a complete lattice. -/

protected definition le (M N : sigma_algebra X) : Prop := @sets _ M ⊆ @sets _ N

definition sigma_algebra_has_le [instance] :
  has_le (sigma_algebra X) :=
has_le.mk sigma_algebra.le

protected theorem le_refl (M : sigma_algebra X) : M ≤ M := subset.refl (@sets _ M)

protected theorem le_trans (M N L : sigma_algebra X) : M ≤ N → N ≤ L → M ≤ L :=
assume H1, assume H2,
subset.trans H1 H2

protected theorem le_antisymm (M N : sigma_algebra X) : M ≤ N → N ≤ M → M = N :=
assume H1, assume H2,
sigma_algebra.eq (subset.antisymm H1 H2)

protected theorem generated_by_initial {G : set (set X)} {M : sigma_algebra X} (H : G ⊆ @sets X M) :
  sigma_algebra.generated_by G ≤ M :=
sets_generated_by_initial H

protected definition inf (M N : sigma_algebra X) : sigma_algebra X :=
⦃sigma_algebra,
  sets            := @sets X M ∩ @sets X N,
  univ_mem_sets   := abstract and.intro (@measurable_univ X M) (@measurable_univ X N) end,
  comp_mem_sets   := abstract take s, assume Hs, and.intro
                       (@measurable_compl X M s (and.elim_left Hs))
                       (@measurable_compl X N s (and.elim_right Hs)) end,
  cUnion_mem_sets := abstract take s, assume Hs, and.intro
                       (@measurable_cUnion X M s (λ i, and.elim_left (Hs i)))
                       (@measurable_cUnion X N s (λ i, and.elim_right (Hs i))) end⦄

protected theorem inf_le_left (M N : sigma_algebra X) : sigma_algebra.inf M N ≤ M :=
λ s, !inter_subset_left

protected theorem inf_le_right (M N : sigma_algebra X) : sigma_algebra.inf M N ≤ N :=
λ s, !inter_subset_right

protected theorem le_inf (M N L : sigma_algebra X) (H1 : L ≤ M) (H2 : L ≤ N) :
  L ≤ sigma_algebra.inf M N :=
λ s H, and.intro (H1 s H) (H2 s H)

protected definition Inf (MS : set (sigma_algebra X)) : sigma_algebra X :=
⦃sigma_algebra,
  sets            := ⋂ M ∈ MS, @sets _ M,
  univ_mem_sets   := abstract take M, assume HM, @measurable_univ X M end,
  comp_mem_sets   := abstract take s, assume Hs, take M, assume HM,
                       measurable_compl (Hs M HM) end,
  cUnion_mem_sets := abstract take s, assume Hs, take M, assume HM,
                       measurable_cUnion (λ i, Hs i M HM) end
⦄

protected theorem Inf_le {M : sigma_algebra X} {MS : set (sigma_algebra X)} (MMS : M ∈ MS) :
  sigma_algebra.Inf MS ≤ M :=
bInter_subset_of_mem MMS

protected theorem le_Inf {M : sigma_algebra X} {MS : set (sigma_algebra X)} (H : ∀₀ N ∈ MS, M ≤ N) :
  M ≤ sigma_algebra.Inf MS :=
take s, assume Hs : s ∈ @sets _ M,
take N, assume NMS : N ∈ MS,
show s ∈ @sets _ N, from H NMS s Hs

protected definition sup (M N : sigma_algebra X) : sigma_algebra X :=
sigma_algebra.generated_by (@sets _ M ∪ @sets _ N)

protected theorem le_sup_left (M N : sigma_algebra X) : M ≤ sigma_algebra.sup M N :=
take s, assume Hs : s ∈ @sets _ M,
measurable_generated_by (or.inl Hs)

protected theorem le_sup_right (M N : sigma_algebra X) : N ≤ sigma_algebra.sup M N :=
take s, assume Hs : s ∈ @sets _ N,
measurable_generated_by (or.inr Hs)

protected theorem sup_le {M N L : sigma_algebra X} (H1 : M ≤ L) (H2 : N ≤ L) :
  sigma_algebra.sup M N ≤ L :=
have @sets _ M ∪ @sets _ N ⊆ @sets _ L, from union_subset H1 H2,
sets_generated_by_initial this

protected definition Sup (MS : set (sigma_algebra X)) : sigma_algebra X :=
sigma_algebra.generated_by (⋃ M ∈ MS, @sets _ M)

protected theorem le_Sup {M : sigma_algebra X} {MS : set (sigma_algebra X)} (MMS : M ∈ MS) :
  M ≤ sigma_algebra.Sup MS :=
take s, assume Hs : s ∈ @sets _ M,
measurable_generated_by (mem_bUnion MMS Hs)

protected theorem Sup_le {N : sigma_algebra X} {MS : set (sigma_algebra X)} (H : ∀₀ M ∈ MS, M ≤ N) :
  sigma_algebra.Sup MS ≤ N :=
have (⋃ M ∈ MS, @sets _ M) ⊆ @sets _ N, from bUnion_subset H,
sets_generated_by_initial this

protected definition complete_lattice [trans_instance] :
  complete_lattice (sigma_algebra X) :=
⦃complete_lattice,
  le           := sigma_algebra.le,
  le_refl      := sigma_algebra.le_refl,
  le_trans     := sigma_algebra.le_trans,
  le_antisymm  := sigma_algebra.le_antisymm,
  inf          := sigma_algebra.inf,
  sup          := sigma_algebra.sup,
  inf_le_left  := sigma_algebra.inf_le_left,
  inf_le_right := sigma_algebra.inf_le_right,
  le_inf       := sigma_algebra.le_inf,
  le_sup_left  := sigma_algebra.le_sup_left,
  le_sup_right := sigma_algebra.le_sup_right,
  sup_le       := @sigma_algebra.sup_le X,
  Inf          := sigma_algebra.Inf,
  Sup          := sigma_algebra.Sup,
  Inf_le       := @sigma_algebra.Inf_le X,
  le_Inf       := @sigma_algebra.le_Inf X,
  le_Sup       := @sigma_algebra.le_Sup X,
  Sup_le       := @sigma_algebra.Sup_le X⦄
end sigma_algebra

/- Borel sets -/

namespace measure_theory

section
  open topology
  variables (X : Type) [topology X]

  definition borel_algebra : sigma_algebra X :=
  sigma_algebra.generated_by (opens X)

  variable {X}
  definition borel (s : set X) : Prop := @measurable _ (borel_algebra X) s

  theorem borel_of_Open {s : set X} (H : Open s) : borel s :=
  sigma_algebra.measurable_generated_by H

  theorem borel_of_closed {s : set X} (H : closed s) : borel s :=
  have borel (-s), from borel_of_Open H,
  @measurable_of_measurable_compl _ (borel_algebra X) _ this
end

/- borel functions -/

section
  open topology function
  variables {X Y Z : Type} [topology X] [topology Y] [topology Z]

  definition borel_fun (f : X → Y) := ∀ ⦃s⦄, Open s → borel (f '- s)

  theorem borel_fun_id : borel_fun (@id X) := λ s Os, borel_of_Open Os

  theorem borel_fun_of_continuous {f : X → Y} (H : continuous f) : borel_fun f :=
  λ s Os, borel_of_Open (H Os)

  theorem borel_fun_const (c : Y) : borel_fun (λ x : X, c) :=
  borel_fun_of_continuous (continuous_const c)

  theorem measurable_fun_of_borel_fun {f : X → Y} (H : borel_fun f) :
    measurable_fun f (borel_algebra X) (borel_algebra Y) :=
  sigma_algebra.measurable_fun_generated_by f (opens Y) H

  theorem borel_fun_of_measurable_fun {f : X → Y}
      (H : measurable_fun f (borel_algebra X) (borel_algebra Y)) :
    borel_fun f :=
  λ s Os, H (borel_of_Open Os)

  theorem borel_fun_iff (f : X → Y) :
    borel_fun f ↔ measurable_fun f (borel_algebra X) (borel_algebra Y) :=
  iff.intro measurable_fun_of_borel_fun borel_fun_of_measurable_fun

  theorem borel_fun_comp {f : X → Y} {g : Y → Z} (Hf : borel_fun f) (Hg : borel_fun g) :
    borel_fun (g ∘ f) :=
  λ s Os, measurable_fun_of_borel_fun Hf (Hg Os)
end

end measure_theory
