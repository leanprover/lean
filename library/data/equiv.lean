/-
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura

In the standard library we cannot assume the univalence axiom.
We say two types are equivalent if they are isomorphic.

Two equivalent types have the same cardinality.
-/
import data.sum data.nat
open function

structure equiv [class] (A B : Type) :=
  (to_fun    : A → B)
  (inv_fun   : B → A)
  (left_inv  : left_inverse inv_fun to_fun)
  (right_inv : right_inverse inv_fun to_fun)

namespace equiv
definition perm [reducible] (A : Type) := equiv A A

infix ` ≃ `:50 := equiv

definition fn {A B : Type} (e : equiv A B) : A → B :=
@@equiv.to_fun A B e

infixr ` ∙ `:100 := fn

definition inv {A B : Type} [e : equiv A B] : B → A :=
@@equiv.inv_fun A B e

lemma eq_of_to_fun_eq {A B : Type} : ∀ {e₁ e₂ : equiv A B}, fn e₁ = fn e₂ → e₁ = e₂
| (mk f₁ g₁ l₁ r₁) (mk f₂ g₂ l₂ r₂) h :=
  assert f₁ = f₂, from h,
  assert g₁ = g₂, from funext (λ x,
    assert f₁ (g₁ x) = f₂ (g₂ x), from eq.trans (r₁ x) (eq.symm (r₂ x)),
    have f₁ (g₁ x) = f₁ (g₂ x),   by rewrite [-h at this]; exact this,
    show g₁ x = g₂ x,             from injective_of_left_inverse l₁ this),
  by congruence; repeat assumption

protected definition refl [refl] (A : Type) : A ≃ A :=
mk (@@id A) (@@id A) (λ x, rfl) (λ x, rfl)

protected definition symm [symm] {A B : Type} : A ≃ B → B ≃ A
| (mk f g h₁ h₂) := mk g f h₂ h₁

protected definition trans [trans] {A B C : Type} : A ≃ B → B ≃ C → A ≃ C
| (mk f₁ g₁ l₁ r₁) (mk f₂ g₂ l₂ r₂) :=
  mk (f₂ ∘ f₁) (g₁ ∘ g₂)
   (show ∀ x, g₁ (g₂ (f₂ (f₁ x))) = x, by intros; rewrite [l₂, l₁]; reflexivity)
   (show ∀ x, f₂ (f₁ (g₁ (g₂ x))) = x, by intros; rewrite [r₁, r₂]; reflexivity)

abbreviation id {A : Type} := equiv.refl A

namespace ops
  postfix ⁻¹ := equiv.symm
  postfix ⁻¹ := equiv.inv
  notation e₁ ∘ e₂  := equiv.trans e₂ e₁
end ops
open equiv.ops

lemma id_apply {A : Type} (x : A) : id ∙ x = x :=
rfl

lemma compose_apply {A B C : Type} (g : B ≃ C) (f : A ≃ B) (x : A) : (g ∘ f) ∙ x = g ∙ f ∙ x :=
begin cases g, cases f, esimp end

lemma inverse_apply_apply {A B : Type} : ∀ (e : A ≃ B) (x : A), e⁻¹ ∙ e ∙ x = x
| (mk f₁ g₁ l₁ r₁) x := begin unfold [equiv.symm, fn], rewrite l₁ end

lemma eq_iff_eq_of_injective {A B : Type} {f : A → B} (inj : injective f) (a b : A) : f a = f b ↔ a = b :=
iff.intro
  (suppose f a = f b, inj this)
  (suppose a = b,     by rewrite this)

lemma apply_eq_iff_eq {A B : Type} : ∀ (f : A ≃ B) (x y : A), f ∙ x = f ∙ y ↔ x = y
| (mk f₁ g₁ l₁ r₁) x y := eq_iff_eq_of_injective (injective_of_left_inverse l₁) x y

lemma apply_eq_iff_eq_inverse_apply {A B : Type} : ∀ (f : A ≃ B) (x : A) (y : B), f ∙ x = y ↔ x = f⁻¹ ∙ y
| (mk f₁ g₁ l₁ r₁) x y :=
  begin
    esimp, unfold [equiv.symm, fn], apply iff.intro,
    suppose f₁ x = y, by subst y; rewrite l₁,
    suppose x = g₁ y, by subst x; rewrite r₁
  end

definition false_equiv_empty : empty ≃ false :=
mk (λ e, empty.rec _ e) (λ h, false.rec _ h) (λ e, empty.rec _ e) (λ h, false.rec _ h)

definition arrow_congr [congr] {A₁ B₁ A₂ B₂ : Type} : A₁ ≃ A₂ → B₁ ≃ B₂ → (A₁ → B₁) ≃ (A₂ → B₂)
| (mk f₁ g₁ l₁ r₁) (mk f₂ g₂ l₂ r₂) :=
  mk
   (λ (h : A₁ → B₁) (a : A₂), f₂ (h (g₁ a)))
   (λ (h : A₂ → B₂) (a : A₁), g₂ (h (f₁ a)))
   (λ h, funext (λ a, by rewrite [l₁, l₂]; reflexivity))
   (λ h, funext (λ a, by rewrite [r₁, r₂]; reflexivity))

section
open unit
definition arrow_unit_equiv_unit [simp] (A : Type) : (A → unit) ≃ unit :=
mk (λ f, star) (λ u, (λ f, star))
   (λ f, funext (λ x, by cases (f x); reflexivity))
   (λ u, by cases u; reflexivity)

definition unit_arrow_equiv [simp] (A : Type) : (unit → A) ≃ A :=
mk (λ f, f star) (λ a, (λ u, a))
   (λ f, funext (λ x, by cases x; reflexivity))
   (λ u, rfl)

definition empty_arrow_equiv_unit [simp] (A : Type) : (empty → A) ≃ unit :=
mk (λ f, star) (λ u, λ e, empty.rec _ e)
   (λ f, funext (λ x, empty.rec _ x))
   (λ u, by cases u; reflexivity)

definition false_arrow_equiv_unit [simp] (A : Type) : (false → A) ≃ unit :=
calc (false → A) ≃ (empty → A) : arrow_congr false_equiv_empty !equiv.refl
             ... ≃ unit        : empty_arrow_equiv_unit
end

definition prod_congr [congr] {A₁ B₁ A₂ B₂ : Type} : A₁ ≃ A₂ → B₁ ≃ B₂ → (A₁ × B₁) ≃ (A₂ × B₂)
| (mk f₁ g₁ l₁ r₁) (mk f₂ g₂ l₂ r₂) :=
  mk
    (λ p, match p with (a₁, b₁) := (f₁ a₁, f₂ b₁) end)
    (λ p, match p with (a₂, b₂) := (g₁ a₂, g₂ b₂) end)
    (λ p, begin cases p, esimp, rewrite [l₁, l₂], reflexivity end)
    (λ p, begin cases p, esimp, rewrite [r₁, r₂], reflexivity end)

definition prod_comm [simp] (A B : Type) : (A × B) ≃ (B × A) :=
mk (λ p, match p with (a, b) := (b, a) end)
   (λ p, match p with (b, a) := (a, b) end)
   (λ p, begin cases p, esimp end)
   (λ p, begin cases p, esimp end)

definition prod_assoc [simp] (A B C : Type) : ((A × B) × C) ≃ (A × (B × C)) :=
mk (λ t, match t with ((a, b), c) := (a, (b, c)) end)
   (λ t, match t with (a, (b, c)) := ((a, b), c) end)
   (λ t, begin cases t with ab c, cases ab, esimp end)
   (λ t, begin cases t with a bc, cases bc, esimp end)

section
open unit prod.ops
definition prod_unit_right [simp] (A : Type) : (A × unit) ≃ A :=
mk (λ p, p.1)
   (λ a, (a, star))
   (λ p, begin cases p with a u, cases u, esimp end)
   (λ a, rfl)

definition prod_unit_left [simp] (A : Type) : (unit × A) ≃ A :=
calc (unit × A) ≃ (A × unit) : prod_comm
            ... ≃ A          : prod_unit_right

definition prod_empty_right [simp] (A : Type) : (A × empty) ≃ empty :=
mk (λ p, empty.rec _ p.2) (λ e, empty.rec _ e) (λ p, empty.rec _ p.2)  (λ e, empty.rec _ e)

definition prod_empty_left [simp] (A : Type) : (empty × A) ≃ empty :=
calc (empty × A) ≃ (A × empty) : prod_comm
             ... ≃ empty       : prod_empty_right
end

section
open sum
definition sum_congr [congr] {A₁ B₁ A₂ B₂ : Type} : A₁ ≃ A₂ → B₁ ≃ B₂ → (A₁ + B₁) ≃ (A₂ + B₂)
| (mk f₁ g₁ l₁ r₁) (mk f₂ g₂ l₂ r₂) :=
  mk
   (λ s, match s with inl a₁ := inl (f₁ a₁) | inr b₁ := inr (f₂ b₁) end)
   (λ s, match s with inl a₂ := inl (g₁ a₂) | inr b₂ := inr (g₂ b₂) end)
   (λ s, begin cases s, {esimp, rewrite l₁, reflexivity}, {esimp, rewrite l₂, reflexivity} end)
   (λ s, begin cases s, {esimp, rewrite r₁, reflexivity}, {esimp, rewrite r₂, reflexivity} end)

open bool unit
definition bool_equiv_unit_sum_unit : bool ≃ (unit + unit) :=
mk (λ b, match b with tt := inl star | ff := inr star end)
   (λ s, match s with inl star := tt | inr star := ff end)
   (λ b, begin cases b, esimp, esimp end)
   (λ s, begin cases s with u u, {cases u, esimp}, {cases u, esimp} end)

definition sum_comm [simp] (A B : Type) : (A + B) ≃ (B + A) :=
mk (λ s, match s with inl a := inr a | inr b := inl b end)
   (λ s, match s with inl b := inr b | inr a := inl a end)
   (λ s, begin cases s, esimp, esimp end)
   (λ s, begin cases s, esimp, esimp end)

definition sum_assoc [simp] (A B C : Type) : ((A + B) + C) ≃ (A + (B + C)) :=
mk (λ s, match s with inl (inl a) := inl a | inl (inr b) := inr (inl b) | inr c := inr (inr c) end)
   (λ s, match s with inl a := inl (inl a) | inr (inl b) := inl (inr b) | inr (inr c) := inr c end)
   (λ s, begin cases s with ab c, cases ab, repeat esimp end)
   (λ s, begin cases s with a bc, esimp, cases bc, repeat esimp end)

definition sum_empty_right [simp] (A : Type) : (A + empty) ≃ A :=
mk (λ s, match s with inl a := a | inr e := empty.rec _ e end)
   (λ a, inl a)
   (λ s, begin cases s with a e, esimp, exact empty.rec _ e end)
   (λ a, rfl)

definition sum_empty_left [simp] (A : Type) : (empty + A) ≃ A :=
calc (empty + A) ≃ (A + empty) : sum_comm
          ...    ≃ A           : sum_empty_right
end

section
open prod.ops
definition arrow_prod_equiv_prod_arrow (A B C : Type) : (C → A × B) ≃ ((C → A) × (C → B)) :=
mk (λ f, (λ c, (f c).1, λ c, (f c).2))
   (λ p, λ c, (p.1 c, p.2 c))
   (λ f, funext (λ c, begin esimp, cases f c, esimp end))
   (λ p, begin cases p, esimp end)

definition arrow_arrow_equiv_prod_arrow (A B C : Type) : (A → B → C) ≃ (A × B → C) :=
mk (λ f, λ p, f p.1 p.2)
   (λ f, λ a b, f (a, b))
   (λ f, rfl)
   (λ f, funext (λ p, begin cases p, esimp end))

open sum
definition sum_arrow_equiv_prod_arrow (A B C : Type) : ((A + B) → C) ≃ ((A → C) × (B → C)) :=
mk (λ f, (λ a, f (inl a), λ b, f (inr b)))
   (λ p, (λ s, match s with inl a := p.1 a | inr b := p.2 b end))
   (λ f, funext (λ s, begin cases s, esimp, esimp end))
   (λ p, begin cases p, esimp end)

definition sum_prod_distrib (A B C : Type) : ((A + B) × C) ≃ ((A × C) + (B × C)) :=
mk (λ p, match p with (inl a, c) := inl (a, c) | (inr b, c) := inr (b, c) end)
   (λ s, match s with inl (a, c) := (inl a, c) | inr (b, c) := (inr b, c) end)
   (λ p, begin cases p with ab c, cases ab, repeat esimp end)
   (λ s, begin cases s with ac bc, cases ac, esimp, cases bc, esimp end)

definition prod_sum_distrib (A B C : Type) : (A × (B + C)) ≃ ((A × B) + (A × C)) :=
calc (A × (B + C)) ≃ ((B + C) × A)       : prod_comm
             ...   ≃ ((B × A) + (C × A)) : sum_prod_distrib
             ...   ≃ ((A × B) + (A × C)) : sum_congr !prod_comm !prod_comm

definition bool_prod_equiv_sum (A : Type) : (bool × A) ≃ (A + A) :=
calc (bool × A) ≃ ((unit + unit) × A)       : prod_congr bool_equiv_unit_sum_unit !equiv.refl
        ...     ≃ (A × (unit + unit))       : prod_comm
        ...     ≃ ((A × unit) + (A × unit)) : prod_sum_distrib
        ...     ≃ (A + A)                   : sum_congr !prod_unit_right !prod_unit_right
end

section
open sum nat unit prod.ops
definition nat_equiv_nat_sum_unit : nat ≃ (nat + unit) :=
mk (λ n, match n with zero := inr star | succ a := inl a end)
   (λ s, match s with inl n := succ n | inr star := zero end)
   (λ n, begin cases n, repeat esimp end)
   (λ s, begin cases s with a u, esimp, {cases u, esimp} end)

definition nat_sum_unit_equiv_nat [simp] : (nat + unit) ≃ nat :=
equiv.symm nat_equiv_nat_sum_unit

definition nat_prod_nat_equiv_nat [simp] : (nat × nat) ≃ nat :=
mk (λ p, mkpair p.1 p.2)
   (λ n, unpair n)
   (λ p, begin cases p, apply unpair_mkpair end)
   (λ n, mkpair_unpair n)

definition nat_sum_bool_equiv_nat [simp] : (nat + bool) ≃ nat :=
calc (nat + bool) ≃ (nat + (unit + unit)) : sum_congr !equiv.refl bool_equiv_unit_sum_unit
             ...  ≃ ((nat + unit) + unit) : sum_assoc
             ...  ≃ (nat + unit)          : sum_congr nat_sum_unit_equiv_nat !equiv.refl
             ...  ≃ nat                   : nat_sum_unit_equiv_nat

open decidable
definition nat_sum_nat_equiv_nat [simp] : (nat + nat) ≃ nat :=
mk (λ s, match s with inl n := 2*n | inr n := 2*n+1 end)
   (λ n, if even n then inl (n / 2) else inr ((n - 1) / 2))
   (λ s, begin
           have two_gt_0 : 2 > zero, from dec_trivial,
           cases s,
             {esimp, rewrite [if_pos (even_two_mul _), nat.mul_div_cancel_left _ two_gt_0]},
             {esimp, rewrite [if_neg (not_even_two_mul_plus_one _), nat.add_sub_cancel,
                              nat.mul_div_cancel_left _ two_gt_0]}
         end)
   (λ n, by_cases
          (λ h : even n,
            by rewrite [if_pos h]; esimp; rewrite [nat.mul_div_cancel' (dvd_of_even h)])
          (λ h : ¬ even n,
            begin
              rewrite [if_neg h], esimp,
              cases n,
                {exact absurd even_zero h},
                {rewrite [-(add_one a), nat.add_sub_cancel,
                          nat.mul_div_cancel' (dvd_of_even (even_of_odd_succ (odd_of_not_even h)))]}
            end))

definition prod_equiv_of_equiv_nat {A : Type} : A ≃ nat → (A × A) ≃ A :=
take e, calc
  (A × A) ≃ (nat × nat) : prod_congr e e
     ...  ≃ nat         : nat_prod_nat_equiv_nat
     ...  ≃ A           : equiv.symm e
end

section
open decidable
definition decidable_eq_of_equiv {A B : Type} [h : decidable_eq A] : A ≃ B → decidable_eq B
| (mk f g l r) :=
  take b₁ b₂, match h (g b₁) (g b₂) with
  | inl he := inl (assert aux : f (g b₁) = f (g b₂), from congr_arg f he,
                   begin rewrite *r at aux, exact aux end)
  | inr hn := inr (λ b₁eqb₂, by subst b₁eqb₂; exact absurd rfl hn)
  end
end

definition inhabited_of_equiv {A B : Type} [h : inhabited A] : A ≃ B → inhabited B
| (mk f g l r) := inhabited.mk (f (inhabited.value h))

section
open subtype
definition subtype_equiv_of_subtype {A B : Type} {p : A → Prop} : A ≃ B → {a : A | p a} ≃ {b : B | p b⁻¹}
| (mk f g l r) :=
  mk (λ s, match s with tag v h := tag (f v) (eq.rec_on (eq.symm (l v)) h) end)
     (λ s, match s with tag v h := tag (g v) (eq.rec_on (eq.symm (r v)) h) end)
     (λ s, begin cases s, esimp, congruence, rewrite l, reflexivity end)
     (λ s, begin cases s, esimp, congruence, rewrite r, reflexivity end)
end

section swap
variable {A : Type}
variable [h : decidable_eq A]
include h
open decidable

definition swap_core (a b r : A) : A :=
if r = a then b
else if r = b then a
else r

lemma swap_core_swap_core (r a b : A) : swap_core a b (swap_core a b r) = r :=
by_cases
  (suppose r = a, by_cases
    (suppose r = b,   begin unfold swap_core, rewrite [if_pos `r = a`, if_pos (eq.refl b), -`r = a`, -`r = b`, if_pos (eq.refl r)] end)
    (suppose ¬ r = b,
      assert b ≠ a, from assume h, begin rewrite h at this, contradiction end,
      begin unfold swap_core, rewrite [*if_pos `r = a`, if_pos (eq.refl b), if_neg `b ≠ a`, `r = a`] end))
  (suppose ¬ r = a, by_cases
    (suppose r = b,   begin unfold swap_core, rewrite [if_neg `¬ r = a`, *if_pos `r = b`, if_pos (eq.refl a), this] end)
    (suppose ¬ r = b, begin unfold swap_core, rewrite [*if_neg `¬ r = a`, *if_neg `¬ r = b`, if_neg `¬ r = a`] end))

lemma swap_core_self (r a : A) : swap_core a a r = r :=
by_cases
  (suppose r = a, begin unfold swap_core, rewrite [*if_pos this, this] end)
  (suppose r ≠ a, begin unfold swap_core, rewrite [*if_neg this] end)

lemma swap_core_comm (r a b : A) : swap_core a b r = swap_core b a r :=
by_cases
  (suppose r = a, by_cases
    (suppose r = b,   begin unfold swap_core, rewrite [if_pos `r = a`, if_pos `r = b`, -`r = a`, -`r = b`] end)
    (suppose ¬ r = b, begin unfold swap_core, rewrite [*if_pos `r = a`, if_neg `¬ r = b`] end))
  (suppose ¬ r = a, by_cases
    (suppose r = b,   begin unfold swap_core, rewrite [if_neg `¬ r = a`, *if_pos `r = b`]    end)
    (suppose ¬ r = b, begin unfold swap_core, rewrite [*if_neg `¬ r = a`, *if_neg `¬ r = b`] end))

definition swap (a b : A) : perm A :=
mk (swap_core a b)
   (swap_core a b)
   (λ x, abstract by rewrite swap_core_swap_core end)
   (λ x, abstract by rewrite swap_core_swap_core end)

lemma swap_self (a : A) : swap a a = id :=
eq_of_to_fun_eq (funext (λ x, begin unfold [swap, fn], rewrite swap_core_self end))

lemma swap_comm (a b : A) : swap a b = swap b a :=
eq_of_to_fun_eq (funext (λ x, begin unfold [swap, fn], rewrite swap_core_comm end))

lemma swap_apply_def (a b : A) (x : A) : swap a b ∙ x = if x = a then b else if x = b then a else x :=
rfl

lemma swap_apply_left (a b : A) : swap a b ∙ a = b :=
if_pos rfl

lemma swap_apply_right (a b : A) : swap a b ∙ b = a :=
by_cases
  (suppose b = a, by rewrite [swap_apply_def, this, *if_pos rfl])
  (suppose b ≠ a, by rewrite [swap_apply_def, if_pos rfl, if_neg this])

lemma swap_apply_of_ne_of_ne {a b : A} {x : A} : x ≠ a → x ≠ b → swap a b ∙ x = x :=
assume h₁ h₂, by rewrite [swap_apply_def, if_neg h₁, if_neg h₂]

lemma swap_swap (a b : A) : swap a b ∘ swap a b = id :=
eq_of_to_fun_eq (funext (λ x, begin unfold [swap, fn, equiv.trans, equiv.refl], rewrite swap_core_swap_core end))

lemma swap_compose_apply (a b : A) (π : perm A) (x : A) : (swap a b ∘ π) ∙ x = if π ∙ x = a then b else if π ∙ x = b then a else π ∙ x :=
begin cases π, reflexivity end

end swap
end equiv
