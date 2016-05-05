/-
Copyright (c) 2016 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Temporary file; move in Lean3.
-/
import data.set algebra.order_bigops
import data.finset data.list.sort

-- move this to init.function

section
open function
postfix `^~` :std.prec.max_plus := swap
end

-- move to algebra

theorem eq_of_inv_mul_eq_one {A : Type} {a b : A} [group A] (H : b⁻¹ * a = 1) : a = b :=
have a⁻¹ * 1 = a⁻¹, by inst_simp,
by inst_simp

-- move to init.quotient

namespace quot
open classical

variables {A : Type} [s : setoid A]

protected theorem exists_eq_mk (x : quot s) : ∃ a : A, x = ⟦a⟧ :=
quot.induction_on x (take a, exists.intro _ rfl)

protected noncomputable definition repr (x : quot s) : A := some (quot.exists_eq_mk x)

protected theorem mk_repr_eq (x : quot s) : ⟦ quot.repr x ⟧ = x :=
eq.symm (some_spec (quot.exists_eq_mk x))

open setoid
include s
protected theorem repr_mk_equiv (a : A) : quot.repr ⟦a⟧ ≈ a :=
quot.exact (by rewrite quot.mk_repr_eq)

end quot


-- move to data.set.basic

namespace set
open function

lemma inter_eq_self_of_subset {X : Type} {s t : set X} (Hst : s ⊆ t) : s ∩ t = s :=
ext (take x, iff.intro
  (assume H, !inter_subset_left H)
  (assume H, and.intro H (Hst H)))

lemma inter_eq_self_of_subset_right {X : Type} {s t : set X} (Hst : t ⊆ s) : s ∩ t = t :=
by rewrite [inter_comm]; apply inter_eq_self_of_subset Hst

proposition diff_self_inter {X : Type} (s t : set X) : s \ (s ∩ t) = s \ t :=
by rewrite [*diff_eq, compl_inter, inter_distrib_left, inter_compl_self, empty_union]

proposition diff_eq_diff {X : Type} {s t u : set X} (H : s ∩ u = s ∩ t) :
  s \ u = s \ t :=
by rewrite [-diff_self_inter, H, diff_self_inter]

-- classical
proposition inter_eq_inter_of_diff_eq_diff {X : Type} {s t u : set X} (H : s \ u = s \ t) :
  s ∩ u = s ∩ t :=
by rewrite [-compl_compl u, -compl_compl t]; apply diff_eq_diff H

proposition compl_inter_eq_compl_inter {X : Type} {s t u : set X}
    (H : u ∩ s = t ∩ s) :
  -u ∩ s = -t ∩ s :=
by rewrite [*inter_comm _ s]; apply diff_eq_diff; rewrite [*inter_comm s, H]

proposition inter_eq_inter_of_compl_inter_eq_compl_inter {X : Type} {s t u : set X}
    (H : -u ∩ s = -t ∩ s) :
  u ∩ s = t ∩ s :=
begin
  rewrite [*inter_comm _ s], apply inter_eq_inter_of_diff_eq_diff,
  rewrite [*diff_eq, *inter_comm s, H]
end

proposition singleton_subset_of_mem {X : Type} {x : X} {s : set X} (xs : x ∈ s) : '{x} ⊆ s :=
take y, assume yx,
  have y = x, from eq_of_mem_singleton yx,
  by rewrite this; exact xs

proposition mem_of_singleton_subset {X : Type} {x : X} {s : set X} (xs : '{x} ⊆ s) : x ∈ s :=
xs !mem_singleton

proposition singleton_subset_iff {X : Type} (x : X) (s : set X) : '{x} ⊆ s ↔ x ∈ s :=
iff.intro mem_of_singleton_subset singleton_subset_of_mem

lemma inter_eq_inter_left {X : Type} {s t u : set X} (H₁ : s ∩ t ⊆ u) (H₂ : s ∩ u ⊆ t) :
  s ∩ t = s ∩ u :=
eq_of_subset_of_subset
  (subset_inter (inter_subset_left _ _) H₁)
  (subset_inter (inter_subset_left _ _) H₂)

lemma inter_eq_inter_right {X : Type} {s t u : set X} (H₁ : s ∩ t ⊆ u) (H₂ : u ∩ t ⊆ s) :
  s ∩ t = u ∩ t :=
eq_of_subset_of_subset
  (subset_inter H₁ (inter_subset_right _ _))
  (subset_inter H₂ (inter_subset_right _ _))

proposition sUnion_subset {X : Type} {S : set (set X)} {t : set X} (H : ∀₀ u ∈ S, u ⊆ t) :
  ⋃₀ S ⊆ t :=
take x, assume Hx,
obtain u [uS xu], from Hx,
H uS xu

proposition subset_of_sUnion_subset {X : Type} {S : set (set X)} {t : set X}
  (H : ⋃₀ S ⊆ t) {u : set X} (Hu : u ∈ S) : u ⊆ t :=
λ x xu, H (exists.intro u (and.intro Hu xu))

proposition preimage_Union {I X Y : Type} (f : X → Y) (u : I → set Y) :
  f '- (⋃ i, u i) = ⋃ i, (f '- (u i)) :=
ext (take x, !iff.refl)

-- TODO: rename "injective" to "inj"
-- TODO: turn around equality in definition of image
-- TODO: use ∀₀ in definition of injective (and define notation for ∀₀ x y ∈ s, ...)

attribute [trans] subset.trans -- really? this was never declared? And all the variants...

proposition mem_set_of_iff {X : Type} (P : X → Prop) (a : X) : a ∈ { x : X | P x } ↔ P a :=
 iff.refl _

proposition mem_set_of {X : Type} {P : X → Prop} {a : X} (Pa : P a) : a ∈ { x : X | P x } := Pa

proposition of_mem_set_of {X : Type} {P : X → Prop} {a : X} (H : a ∈ { x : X | P x }) : P a := H

proposition forallb_of_forall {X : Type} {P : X → Prop} (s : set X) (H : ∀ x, P x) :
  ∀₀ x ∈ s, P x :=
λ x xs, H x

proposition forall_of_forallb_univ {X : Type} {P : X → Prop} (H : ∀₀ x ∈ univ, P x) : ∀ x, P x :=
λ x, H trivial

proposition forallb_univ_iff_forall {X : Type} (P : X → Prop) : (∀₀ x ∈ univ, P x) ↔ ∀ x, P x :=
iff.intro forall_of_forallb_univ !forallb_of_forall

proposition forallb_of_subset {X : Type} {s t : set X} {P : X → Prop}
  (ssubt : s ⊆ t) (Ht : ∀₀ x ∈ t, P x) : ∀₀ x ∈ s, P x :=
λ x xs, Ht (ssubt xs)

proposition forallb_of_forall₂ {X Y : Type} {P : X → Y → Prop} (s : set X) (t : set Y)
  (H : ∀ x y, P x y) : ∀₀ x ∈ s, ∀₀ y ∈ t, P x y :=
λ x xs y yt, H x y

proposition forall_of_forallb_univ₂ {X Y : Type} {P : X → Y → Prop}
  (H : ∀₀ x ∈ univ, ∀₀ y ∈ univ, P x y) : ∀ x y, P x y :=
λ x y, H trivial trivial

proposition forallb_univ_iff_forall₂ {X Y : Type} (P : X → Y → Prop) :
  (∀₀ x ∈ univ, ∀₀ y ∈ univ, P x y) ↔ ∀ x y, P x y :=
iff.intro forall_of_forallb_univ₂ !forallb_of_forall₂

proposition forallb_of_subset₂ {X Y : Type} {s₁ t₁ : set X} {s₂ t₂ : set Y} {P : X → Y → Prop}
    (ssubt₁ : s₁ ⊆ t₁) (ssubt₂ : s₂ ⊆ t₂) (Ht : ∀₀ x ∈ t₁, ∀₀ y ∈ t₂, P x y) :
  ∀₀ x ∈ s₁, ∀₀ y ∈ s₂, P x y :=
λ x xs y ys, Ht (ssubt₁ xs) (ssubt₂ ys)

theorem maps_to_univ {X Y : Type} (f : X → Y) (a : set X) : maps_to f a univ :=
take x, assume H, trivial

theorem surj_on_image {X Y : Type} (f : X → Y) (a : set X) : surj_on f a (f ' a) :=
λ y Hy, Hy

theorem image_eq_univ_of_surjective {X Y : Type} {f : X → Y} (H : surjective f) :
  f ' univ = univ :=
ext (take y, iff.intro (λ H', trivial)
  (λ H', obtain x xeq, from H y,
    show y ∈ f ' univ, from mem_image trivial xeq))

proposition image_inter_subset {X Y : Type} (f : X → Y) (s t : set X) :
  f ' (s ∩ t) ⊆ f ' s ∩ f ' t :=
take y, assume ymem,
obtain x [[xs xt] (xeq : f x = y)], from ymem,
show y ∈ f ' s ∩ f ' t,
  begin
    rewrite -xeq,
    exact (and.intro (mem_image_of_mem f xs) (mem_image_of_mem f xt))
  end

--proposition image_eq_of_maps_to_of_surj_on {X Y : Type} {f : X → Y} {s : set X} {t : set Y}
--    (H : maps_to f s t) (H' : surj_on f s t) :
--  f ' s = t :=
--eq_of_subset_of_subset (image_subset_of_maps_to H) H'

proposition surj_on_of_image_eq {X Y : Type} {f : X → Y} {s : set X} {t : set Y}
    (H : f ' s = t) :
  surj_on f s t :=
by rewrite [↑surj_on, H]; apply subset.refl

proposition surjective_induction {X Y : Type} {P : Y → Prop} {f : X → Y}
    (surjf : surjective f) (H : ∀ x, P (f x)) :
  ∀ y, P y :=
take y,
obtain x (yeq : f x = y), from surjf y,
show P y, by rewrite -yeq; apply H x

proposition surjective_induction₂ {X Y : Type} {P : Y → Y → Prop} {f : X → Y}
    (surjf : surjective f) (H : ∀ x₁ x₂, P (f x₁) (f x₂)) :
  ∀ y₁ y₂, P y₁ y₂ :=
take y₁ y₂,
obtain x₁ (y₁eq : f x₁ = y₁), from surjf y₁,
obtain x₂ (y₂eq : f x₂ = y₂), from surjf y₂,
show P y₁ y₂, by rewrite [-y₁eq, -y₂eq]; apply H x₁ x₂

proposition surj_on_univ_induction {X Y : Type} {P : Y → Prop} {f : X → Y} {s : set X}
    (surjfs : surj_on f s univ) (H : ∀₀ x ∈ s, P (f x)) :
  ∀ y, P y :=
take y,
obtain x [xs (yeq : f x = y)], from surjfs trivial,
show P y, by rewrite -yeq; apply H xs

proposition surj_on_univ_induction₂ {X Y : Type} {P : Y → Y → Prop} {f : X → Y} {s : set X}
    (surjfs : surj_on f s univ) (H : ∀₀ x₁ ∈ s, ∀₀ x₂ ∈ s, P (f x₁) (f x₂)) :
  ∀ y₁ y₂, P y₁ y₂ :=
take y₁ y₂,
obtain x₁ [x₁s (y₁eq : f x₁ = y₁)], from surjfs trivial,
obtain x₂ [x₂s (y₂eq : f x₂ = y₂)], from surjfs trivial,
show P y₁ y₂, by rewrite [-y₁eq, -y₂eq]; apply H x₁s x₂s

proposition surj_on_univ_of_surjective {X Y : Type} {f : X → Y} (s : set Y) (H : surjective f) :
  surj_on f univ s :=
take y, assume ys,
obtain x yeq, from H y,
mem_image !mem_univ yeq

proposition mem_of_mem_image_of_injective {X Y : Type} {f : X → Y} {s : set X} {a : X}
    (injf : injective f) (H : f a ∈ f ' s) :
  a ∈ s :=
obtain b [bs faeq], from H,
have b = a, from injf faeq,
by rewrite -this; apply bs

proposition mem_of_mem_image_of_inj_on {X Y : Type} {f : X → Y} {s t : set X} {a : X} (Ha : a ∈ t)
    (Hs : s ⊆ t) (injft : inj_on f t) (H : f a ∈ f ' s)  :
  a ∈ s :=
obtain b [bs faeq], from H,
have b = a, from injft (Hs bs) Ha faeq,
by rewrite -this; apply bs

proposition eq_singleton_of_forall_eq {A : Type} {s : set A} {x : A} (xs : x ∈ s) (H : ∀₀ y ∈ s, y = x) :
  s = '{x} :=
ext (take y, iff.intro
  (assume ys, mem_singleton_of_eq (H ys))
  (assume yx, by rewrite (eq_of_mem_singleton yx); assumption))

proposition insert_subset {A : Type} {s t : set A} {a : A} (amem : a ∈ t) (ssubt : s ⊆ t) : insert a s ⊆ t :=
take x, assume xias,
  or.elim (eq_or_mem_of_mem_insert xias)
    (by simp)
    (take H, ssubt H)

-- move to data.set.finite

lemma finite_sUnion {A : Type} {S : set (set A)} [H : finite S] :
  (∀s, s ∈ S → finite s) → finite ⋃₀S :=
induction_on_finite S
  (by intro H; rewrite sUnion_empty; apply finite_empty)
  (take a s, assume fins anins ih h,
    begin
      rewrite sUnion_insert,
      apply finite_union,
        {apply h _ (mem_insert a s)},
      apply ih (forall_of_forall_insert h)
    end)

lemma subset_powerset_sUnion {A : Type} (S : set (set A)) : S ⊆ 𝒫 (⋃₀ S) :=
take u, suppose u ∈ S, show u ⊆ ⋃₀ S, from subset_sUnion_of_mem this

lemma finite_of_finite_sUnion {A : Type} (S : set (set A)) (H : finite ⋃₀S) : finite S :=
have finite (𝒫 (⋃₀ S)), from finite_powerset _,
show finite S, from finite_subset (subset_powerset_sUnion S)

section nat
open nat

proposition ne_empty_of_card_pos {A : Type} {s : set A} (H : card s > 0) : s ≠ ∅ :=
take H', begin rewrite [H' at H, card_empty at H], exact lt.irrefl 0 H end

lemma eq_of_card_eq_one {A : Type} {S : set A} (H : card S = 1) {x y : A} (Hx : x ∈ S) (Hy : y ∈ S) :
  x = y :=
have finite S,
  from classical.by_contradiction
    (assume nfinS, begin rewrite (card_of_not_finite nfinS) at H, contradiction end),
classical.by_contradiction
(assume H0 : x ≠ y,
  have H1 : '{x, y} ⊆ S, from insert_subset Hx (insert_subset Hy (empty_subset _)),
  have x ∉ '{y}, from assume H, H0 (eq_of_mem_singleton H),
  have 2 ≤ 1, from calc
    2 = card '{x, y} : by rewrite [card_insert_of_not_mem this,
                            card_insert_of_not_mem (not_mem_empty _), card_empty]
      ... ≤ card S   : card_le_card_of_subset H1
      ... = 1        : H,
  show false, from dec_trivial this)

proposition eq_singleton_of_card_eq_one {A : Type} {s : set A} {x : A} (H : card s = 1) (xs : x ∈ s) :
  s = '{x} :=
eq_singleton_of_forall_eq xs (take y, assume ys, eq.symm (eq_of_card_eq_one H xs ys))

proposition exists_eq_singleton_of_card_eq_one {A : Type} {s : set A} (H : card s = 1) : ∃ x, s = '{x} :=
have s ≠ ∅, from ne_empty_of_card_pos (by rewrite H; apply dec_trivial),
obtain (x : A) (xs : x ∈ s), from exists_mem_of_ne_empty this,
exists.intro x (eq_singleton_of_card_eq_one H xs)

end nat

-- move to data.set.classical_inverse (and rename file to "inverse")

theorem inv_fun_spec {X Y : Type} {f : X → Y} {a : set X} {dflt : X} {x : X} (xa : x ∈ a) :
  f (inv_fun f a dflt (f x)) = f x :=
and.right (inv_fun_pos (exists.intro x (and.intro xa rfl)))

theorem inv_fun_spec' {X Y : Type} {f : X → Y} {a : set X} {dflt : X} {x : X} (xa : x ∈ a) :
  inv_fun f a dflt (f x) ∈ a :=
and.left (inv_fun_pos (exists.intro x (and.intro xa rfl)))

end set


-- move to data.finset

namespace finset

section
  variables {A : Type} [decidable_linear_order A]

  definition finset_to_list (s : finset A) : list A :=
  quot.lift_on s
    (take l, list.sort le (subtype.elt_of l))
    (take a b, assume eqab, list.sort_eq_of_perm eqab)

  proposition to_finset_finset_to_list (s : finset A) : to_finset (finset_to_list s) = s :=
  quot.induction_on s
    begin
      intro l,
      have H : list.nodup (list.sort le (subtype.elt_of l)),
        from perm.nodup_of_perm_of_nodup (perm.symm !list.sort_perm) (subtype.has_property l),
      rewrite [↑finset_to_list, -to_finset_eq_of_nodup H],
      apply quot.sound,
      apply list.sort_perm
    end

  proposition nodup_finset_to_list (s : finset A) : list.nodup (finset_to_list s) :=
  quot.induction_on s
    (take l, perm.nodup_of_perm_of_nodup (perm.symm !list.sort_perm) (subtype.has_property l))

  proposition sorted_finset_to_list (s : finset A) : list.sorted le (finset_to_list s) :=
  quot.induction_on s
    (take l, list.sorted_of_strongly_sorted (list.strongly_sorted_sort _))
end

end finset


-- move to data.nat?

namespace nat
open finset

theorem succ_Max₀_not_mem (s : finset ℕ) : succ (Max₀ s) ∉ s :=
suppose succ (Max₀ s) ∈ s,
have succ (Max₀ s) ≤ Max₀ s, from le_Max₀ this,
show false, from not_succ_le_self this

end nat
