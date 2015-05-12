/-
Copyright (c) 2015 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Module: data.rat.order
Author: Jeremy Avigad

Adds the ordering, and instantiates the rationals as an ordered field.
-/

import data.int algebra.ordered_field .basic
open quot eq.ops

/- the ordering on representations -/

namespace prerat
section int_notation
open int

variables {a b : prerat}

definition pos (a : prerat) : Prop := num a > 0

theorem pos_eq_pos_of_equiv {a b : prerat} (H1 : a ≡ b) : pos a = pos b :=
propext (iff.intro (num_pos_of_equiv H1) (num_pos_of_equiv H1⁻¹))

definition nonneg (a : prerat) : Prop := num a ≥ 0

theorem nonneg_eq_nonneg_of_equiv (H : a ≡ b) : nonneg a = nonneg b :=
have H1 : (0 = num a) = (0 = num b),
  from propext (iff.intro
    (assume H2, eq.symm (num_eq_zero_of_equiv H H2⁻¹))
    (assume H2, eq.symm (num_eq_zero_of_equiv H⁻¹ H2⁻¹))),
calc
  nonneg a = (pos a ∨ 0 = num a) : propext !le_iff_lt_or_eq
       ... = (pos b ∨ 0 = num a) : pos_eq_pos_of_equiv H
       ... = (pos b ∨ 0 = num b) : H1
       ... = nonneg b            : propext !le_iff_lt_or_eq

theorem nonneg_zero : nonneg zero := le.refl 0

theorem nonneg_add (H1 : nonneg a) (H2 : nonneg b) : nonneg (add a b) :=
show num a * denom b + num b * denom a ≥ 0,
  from add_nonneg
    (mul_nonneg H1 (le_of_lt (denom_pos b)))
    (mul_nonneg H2 (le_of_lt (denom_pos a)))

theorem nonneg_antisymm (H1 : nonneg a) (H2 : nonneg (neg a)) : a ≡ zero :=
have H3 : num a = 0, from le.antisymm (nonpos_of_neg_nonneg H2) H1,
equiv_zero_of_num_eq_zero H3

theorem nonneg_total (a : prerat) : nonneg a ∨ nonneg (neg a) :=
or.elim (le.total 0 (num a))
  (assume H : 0 ≤ num a, or.inl H)
  (assume H : 0 ≥ num a, or.inr (neg_nonneg_of_nonpos H))

theorem nonneg_of_pos (H : pos a) : nonneg a := le_of_lt H

theorem ne_zero_of_pos (H : pos a) : ¬ a ≡ zero :=
assume H', ne_of_gt H (num_eq_zero_of_equiv_zero H')

theorem pos_of_nonneg_of_ne_zero (H1 : nonneg a) (H2 : ¬ a ≡ zero) : pos a :=
have H3 : num a ≠ 0,
  from assume H' : num a = 0, H2 (equiv_zero_of_num_eq_zero H'),
lt_of_le_of_ne H1 (ne.symm H3)

theorem nonneg_mul (H1 : nonneg a) (H2 : nonneg b) : nonneg (mul a b) :=
mul_nonneg H1 H2

theorem pos_mul (H1 : pos a) (H2 : pos b) : pos (mul a b) :=
mul_pos H1 H2

end int_notation
end prerat

local attribute prerat.setoid [instance]

/- The ordering on the rationals.

   The definitions of pos and nonneg are kept private, because they are only meant for internal
   use. Users should use a > 0 and a ≥ 0 instead of pos and nonneg.
-/

namespace rat

variables {a b c : ℚ}

/- transfer properties of pos and nonneg -/

private definition pos (a : ℚ) : Prop :=
quot.lift prerat.pos @prerat.pos_eq_pos_of_equiv a

private definition nonneg (a : ℚ) : Prop :=
quot.lift prerat.nonneg @prerat.nonneg_eq_nonneg_of_equiv a

private theorem nonneg_zero : nonneg 0 := prerat.nonneg_zero

private theorem nonneg_add : nonneg a → nonneg b → nonneg (a + b) :=
quot.induction_on₂ a b @prerat.nonneg_add

private theorem nonneg_antisymm : nonneg a → nonneg (-a) → a = 0 :=
quot.induction_on a
  (take u, assume H1 H2,
    quot.sound (prerat.nonneg_antisymm H1 H2))

private theorem nonneg_total (a : ℚ) : nonneg a ∨ nonneg (-a) :=
quot.induction_on a @prerat.nonneg_total

private theorem nonneg_of_pos : pos a → nonneg a :=
quot.induction_on a @prerat.nonneg_of_pos

private theorem ne_zero_of_pos : pos a → a ≠ 0 :=
quot.induction_on a (take u, assume H1 H2, prerat.ne_zero_of_pos H1 (quot.exact H2))

private theorem pos_of_nonneg_of_ne_zero : nonneg a → ¬ a = 0 → pos a :=
quot.induction_on a
  (take u,
    assume H1 : nonneg ⟦u⟧,
    assume H2 : ⟦u⟧ ≠ 0,
    have H3 : ¬ (prerat.equiv u prerat.zero), from assume H, H2 (quot.sound H),
    prerat.pos_of_nonneg_of_ne_zero H1 H3)

private theorem nonneg_mul : nonneg a → nonneg b → nonneg (a * b) :=
quot.induction_on₂ a b @prerat.nonneg_mul

private theorem pos_mul : pos a → pos b → pos (a * b) :=
quot.induction_on₂ a b @prerat.pos_mul

private definition decidable_pos (a : ℚ) : decidable (pos a) :=
quot.rec_on_subsingleton a (take u, int.decidable_lt 0 (prerat.num u))

/- define order in terms of pos and nonneg -/

definition lt (a b : ℚ) : Prop := pos (b - a)
definition le (a b : ℚ) : Prop := nonneg (b - a)
definition gt [reducible] (a b : ℚ) := lt b a
definition ge [reducible] (a b : ℚ) := le b a

infix <  := rat.lt
infix <= := rat.le
infix ≤  := rat.le
infix >= := rat.ge
infix ≥  := rat.ge
infix >  := rat.gt

theorem le.refl (a : ℚ) : a ≤ a :=
by rewrite [↑rat.le, sub_self]; apply nonneg_zero

theorem le.trans (H1 : a ≤ b) (H2 : b ≤ c) : a ≤ c :=
assert H3 : nonneg (c - b + (b - a)), from nonneg_add H2 H1,
begin
  revert H3,
  rewrite [↑rat.sub, add.assoc, neg_add_cancel_left],
  intro H3, apply H3
end

theorem le.antisymm (H1 : a ≤ b) (H2 : b ≤ a) : a = b :=
have H3 : nonneg (-(a - b)), from !neg_sub⁻¹ ▸ H1,
have H4 : a - b = 0, from nonneg_antisymm H2 H3,
eq_of_sub_eq_zero H4

theorem le.total (a b : ℚ) : a ≤ b ∨ b ≤ a :=
or.elim (nonneg_total (b - a))
  (assume H, or.inl H)
  (assume H, or.inr (!neg_sub ▸ H))

theorem lt_iff_le_and_ne (a b : ℚ) : a < b ↔ a ≤ b ∧ a ≠ b :=
iff.intro
  (assume H : a < b,
    have H1 : b - a ≠ 0, from ne_zero_of_pos H,
    have H2 : a ≠ b, from ne.symm (assume H', H1 (H' ▸ !sub_self)),
    and.intro (nonneg_of_pos H) H2)
  (assume H : a ≤ b ∧ a ≠ b,
    obtain aleb aneb, from H,
    have H1 : b - a ≠ 0, from (assume H', aneb (eq_of_sub_eq_zero H')⁻¹),
    pos_of_nonneg_of_ne_zero aleb H1)

theorem le_iff_lt_or_eq (a b : ℚ) : a ≤ b ↔ a < b ∨ a = b :=
iff.intro
  (assume H : a ≤ b,
    decidable.by_cases
      (assume H1 : a = b, or.inr H1)
      (assume H1 : a ≠ b, or.inl (iff.mp' !lt_iff_le_and_ne (and.intro H H1))))
  (assume H : a < b ∨ a = b,
    or.elim H
      (assume H1 : a < b, and.left (iff.mp !lt_iff_le_and_ne H1))
      (assume H1 : a = b, H1 ▸ !le.refl))

theorem add_le_add_left (H : a ≤ b) (c: ℚ) : c + a ≤ c + b :=
have H1 : c + b - (c + a) = b - a,
  by rewrite [↑sub, neg_add, -add.assoc, add.comm c, add_neg_cancel_right],
show nonneg (c + b - (c + a)), from H1⁻¹ ▸ H

theorem mul_nonneg (H1 : a ≥ 0) (H2 : b ≥ 0) : a * b ≥ 0 :=
have H : nonneg (a * b), from nonneg_mul (!sub_zero ▸ H1) (!sub_zero ▸ H2),
!sub_zero⁻¹ ▸ H

theorem mul_pos (H1 : a > 0) (H2 : b > 0) : a * b > 0 :=
have H : pos (a * b), from pos_mul (!sub_zero ▸ H1) (!sub_zero ▸ H2),
!sub_zero⁻¹ ▸ H

definition decidable_lt [instance] : decidable_rel rat.lt :=
take a b, decidable_pos (b - a)

section migrate_algebra
  open [classes] algebra

  protected definition discrete_linear_ordered_field [reducible] :
    algebra.discrete_linear_ordered_field rat :=
  ⦃algebra.discrete_linear_ordered_field,
    rat.discrete_field,
    le_refl          := le.refl,
    le_trans         := @le.trans,
    le_antisymm      := @le.antisymm,
    le_total         := @le.total,
    lt_iff_le_and_ne := @lt_iff_le_and_ne,
    le_iff_lt_or_eq  := @le_iff_lt_or_eq,
    add_le_add_left  := @add_le_add_left,
    mul_nonneg       := @mul_nonneg,
    mul_pos          := @mul_pos,
    decidable_lt     := @decidable_lt⦄

  local attribute rat.discrete_field [instance]
  local attribute rat.discrete_linear_ordered_field [instance]
  definition abs (n : rat) : rat := algebra.abs n
  definition sign (n : rat) : rat := algebra.sign n
  migrate from algebra with rat replacing abs → abs, sign → sign
end migrate_algebra
end rat
