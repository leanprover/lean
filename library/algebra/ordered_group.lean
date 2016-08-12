/-
Copyright (c) 2014 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jeremy Avigad

Partially ordered additive groups, modeled on Isabelle's library. These classes can be refined
if necessary.
-/
import algebra.group algebra.order algebra.monotone
open eq

variables {A B : Type}

/- partially ordered monoids, such as the natural numbers -/

structure ordered_cancel_comm_monoid [class] (A : Type) extends add_comm_monoid A,
  add_left_cancel_semigroup A, add_right_cancel_semigroup A, order_pair A :=
(add_le_add_left : ∀a b, le a b → ∀c, le (add c a) (add c b))
(le_of_add_le_add_left : ∀a b c, le (add a b) (add a c) → le b c)
(add_lt_add_left : ∀a b, lt a b → ∀c, lt (add c a) (add c b))
(lt_of_add_lt_add_left : ∀a b c, lt (add a b) (add a c) → lt b c)

section
  variables [ordered_cancel_comm_monoid A]
  variables {a b c d e : A}

  theorem add_lt_add_left (H : a < b) (c : A) : c + a < c + b :=
   ordered_cancel_comm_monoid.add_lt_add_left a b H c

  theorem add_lt_add_right (H : a < b) (c : A) : a + c < b + c :=
  sorry
  /-
  begin
    rewrite [add.comm, {b + _}add.comm],
    exact (add_lt_add_left H c)
  end
  -/

  theorem add_le_add_left (H : a ≤ b) (c : A) : c + a ≤ c + b :=
  ordered_cancel_comm_monoid.add_le_add_left a b H c

  theorem add_le_add_right (H : a ≤ b) (c : A) : a + c ≤ b + c :=
  (add.comm c a) ▸ (add.comm c b) ▸ (add_le_add_left H c)

  theorem add_le_add (Hab : a ≤ b) (Hcd : c ≤ d) : a + c ≤ b + d :=
  le.trans (add_le_add_right Hab c) (add_le_add_left Hcd b)

  theorem le_add_of_nonneg_right (H : b ≥ 0) : a ≤ a + b :=
  sorry
  /-
  begin
    have H1 : a + b ≥ a + 0, from add_le_add_left H a,
    rewrite add_zero at H1,
    exact H1
  end
  -/

  theorem le_add_of_nonneg_left (H : b ≥ 0) : a ≤ b + a :=
  sorry
  /-
  begin
    have H1 : 0 + a ≤ b + a, from add_le_add_right H a,
    rewrite zero_add at H1,
    exact H1
  end
  -/

  theorem add_lt_add (Hab : a < b) (Hcd : c < d) : a + c < b + d :=
  lt.trans (add_lt_add_right Hab c) (add_lt_add_left Hcd b)

  theorem add_lt_add_of_le_of_lt (Hab : a ≤ b) (Hcd : c < d) : a + c < b + d :=
  lt_of_le_of_lt (add_le_add_right Hab c) (add_lt_add_left Hcd b)

  theorem add_lt_add_of_lt_of_le (Hab : a < b) (Hcd : c ≤ d) : a + c < b + d :=
  lt_of_lt_of_le (add_lt_add_right Hab c) (add_le_add_left Hcd b)

  theorem lt_add_of_pos_right (H : b > 0) : a < a + b := add_zero a ▸ add_lt_add_left H a

  theorem lt_add_of_pos_left (H : b > 0) : a < b + a := zero_add a ▸ add_lt_add_right H a

  -- here we start using le_of_add_le_add_left.
  theorem le_of_add_le_add_left (H : a + b ≤ a + c) : b ≤ c :=
  ordered_cancel_comm_monoid.le_of_add_le_add_left a b c H

  theorem le_of_add_le_add_right (H : a + b ≤ c + b) : a ≤ c :=
  sorry -- le_of_add_le_add_left (show b + a ≤ b + c, begin rewrite [add.comm, {b + _}add.comm], exact H end)

  theorem lt_of_add_lt_add_left (H : a + b < a + c) : b < c :=
  ordered_cancel_comm_monoid.lt_of_add_lt_add_left a b c H

  theorem lt_of_add_lt_add_right (H : a + b < c + b) : a < c :=
  lt_of_add_lt_add_left ((add.comm a b) ▸ (add.comm c b) ▸ H)

  theorem add_le_add_left_iff (a b c : A) : a + b ≤ a + c ↔ b ≤ c :=
  iff.intro le_of_add_le_add_left (assume H, add_le_add_left H _)

  theorem add_le_add_right_iff (a b c : A) : a + b ≤ c + b ↔ a ≤ c :=
  iff.intro le_of_add_le_add_right (assume H, add_le_add_right H _)

  theorem add_lt_add_left_iff (a b c : A) : a + b < a + c ↔ b < c :=
  iff.intro lt_of_add_lt_add_left (assume H, add_lt_add_left H _)

  theorem add_lt_add_right_iff (a b c : A) : a + b < c + b ↔ a < c :=
  iff.intro lt_of_add_lt_add_right (assume H, add_lt_add_right H _)

  -- here we start using properties of zero.
  theorem add_nonneg (Ha : 0 ≤ a) (Hb : 0 ≤ b) : 0 ≤ a + b :=
  zero_add 0 ▸ (add_le_add Ha Hb)

  theorem add_pos (Ha : 0 < a) (Hb : 0 < b) : 0 < a + b :=
  zero_add 0 ▸ (add_lt_add Ha Hb)

  theorem add_pos_of_pos_of_nonneg (Ha : 0 < a) (Hb : 0 ≤ b) : 0 < a + b :=
  zero_add 0 ▸ (add_lt_add_of_lt_of_le Ha Hb)

  theorem add_pos_of_nonneg_of_pos (Ha : 0 ≤ a) (Hb : 0 < b) : 0 < a + b :=
  zero_add 0 ▸ (add_lt_add_of_le_of_lt Ha Hb)

  theorem add_nonpos (Ha : a ≤ 0) (Hb : b ≤ 0) : a + b ≤ 0 :=
  zero_add 0 ▸ (add_le_add Ha Hb)

  theorem add_neg (Ha : a < 0) (Hb : b < 0) : a + b < 0 :=
  zero_add 0 ▸ (add_lt_add Ha Hb)

  theorem add_neg_of_neg_of_nonpos (Ha : a < 0) (Hb : b ≤ 0) : a + b < 0 :=
  zero_add 0 ▸ (add_lt_add_of_lt_of_le Ha Hb)

  theorem add_neg_of_nonpos_of_neg (Ha : a ≤ 0) (Hb : b < 0) : a + b < 0 :=
  zero_add 0 ▸ (add_lt_add_of_le_of_lt Ha Hb)

  -- TODO: add nonpos version (will be easier with simplifier)
  theorem add_eq_zero_iff_eq_zero_and_eq_zero_of_nonneg_of_nonneg
    (Ha : 0 ≤ a) (Hb : 0 ≤ b) : a + b = 0 ↔ a = 0 ∧ b = 0 :=
  sorry
  /-
  iff.intro
    (assume Hab : a + b = 0,
      have Ha' : a ≤ 0, from
        calc
          a     = a + 0 : by rewrite add_zero
            ... ≤ a + b : add_le_add_left Hb _
            ... = 0     : Hab,
      have Haz : a = 0, from le.antisymm Ha' Ha,
      have Hb' : b ≤ 0, from
        calc
          b     = 0 + b : by rewrite zero_add
            ... ≤ a + b : by exact add_le_add_right Ha _
            ... = 0     : Hab,
      have Hbz : b = 0, from le.antisymm Hb' Hb,
      and.intro Haz Hbz)
    (assume Hab : a = 0 ∧ b = 0,
     obtain Ha' Hb', from Hab,
     by rewrite [Ha', Hb', add_zero])
  -/

  theorem le_add_of_nonneg_of_le (Ha : 0 ≤ a) (Hbc : b ≤ c) : b ≤ a + c :=
  zero_add b ▸ add_le_add Ha Hbc

  theorem le_add_of_le_of_nonneg (Hbc : b ≤ c) (Ha : 0 ≤ a) : b ≤ c + a :=
  add_zero b ▸ add_le_add Hbc Ha

  theorem lt_add_of_pos_of_le (Ha : 0 < a) (Hbc : b ≤ c) : b < a + c :=
  zero_add b ▸ add_lt_add_of_lt_of_le Ha Hbc

  theorem lt_add_of_le_of_pos (Hbc : b ≤ c) (Ha : 0 < a) : b < c + a :=
  add_zero b ▸ add_lt_add_of_le_of_lt Hbc Ha

  theorem add_le_of_nonpos_of_le (Ha : a ≤ 0) (Hbc : b ≤ c) : a + b ≤ c :=
  zero_add c ▸ add_le_add Ha Hbc

  theorem add_le_of_le_of_nonpos (Hbc : b ≤ c) (Ha : a ≤ 0) : b + a ≤ c :=
  add_zero c ▸ add_le_add Hbc Ha

  theorem add_lt_of_neg_of_le (Ha : a < 0) (Hbc : b ≤ c) : a + b < c :=
  zero_add c ▸ add_lt_add_of_lt_of_le Ha Hbc

  theorem add_lt_of_le_of_neg (Hbc : b ≤ c) (Ha : a < 0) : b + a < c :=
  add_zero c ▸ add_lt_add_of_le_of_lt Hbc Ha

  theorem lt_add_of_nonneg_of_lt (Ha : 0 ≤ a) (Hbc : b < c) : b < a + c :=
  zero_add b ▸ add_lt_add_of_le_of_lt Ha Hbc

  theorem lt_add_of_lt_of_nonneg (Hbc : b < c) (Ha : 0 ≤ a) : b < c + a :=
  add_zero b ▸ add_lt_add_of_lt_of_le Hbc Ha

  theorem lt_add_of_pos_of_lt (Ha : 0 < a) (Hbc : b < c) : b < a + c :=
  zero_add b ▸ add_lt_add Ha Hbc

  theorem lt_add_of_lt_of_pos (Hbc : b < c) (Ha : 0 < a) : b < c + a :=
  add_zero b ▸ add_lt_add Hbc Ha

  theorem add_lt_of_nonpos_of_lt (Ha : a ≤ 0) (Hbc : b < c) : a + b < c :=
  zero_add c ▸ add_lt_add_of_le_of_lt Ha Hbc

  theorem add_lt_of_lt_of_nonpos (Hbc : b < c) (Ha : a ≤ 0)  : b + a < c :=
  add_zero c ▸ add_lt_add_of_lt_of_le Hbc Ha

  theorem add_lt_of_neg_of_lt (Ha : a < 0) (Hbc : b < c) : a + b < c :=
  zero_add c ▸ add_lt_add Ha Hbc

  theorem add_lt_of_lt_of_neg (Hbc : b < c) (Ha : a < 0) : b + a < c :=
  add_zero c ▸ add_lt_add Hbc Ha

  theorem strictly_increasing_add_left (c : A) : strictly_increasing (λ x, x + c) :=
  take x₁ x₂, assume H, add_lt_add_right H c

  theorem strictly_increasing_add_right (c : A) : strictly_increasing (λ x, c + x) :=
  take x₁ x₂, assume H, add_lt_add_left H c

  theorem nondecreasing_add_left (c : A) : nondecreasing (λ x, x + c) :=
  take x₁ x₂, assume H, add_le_add_right H c

  theorem nondecreasing_add_right (c : A) : nondecreasing (λ x, c + x) :=
  take x₁ x₂, assume H, add_le_add_left H c
end

/- ordered cancelative commutative monoids with a decidable linear order -/

structure decidable_linear_ordered_cancel_comm_monoid [class] (A : Type)
  extends ordered_cancel_comm_monoid A, decidable_linear_order A

section
  variables [decidable_linear_ordered_cancel_comm_monoid A]
  variables {a b c d e : A}

  theorem min_add_add_left : min (a + b) (a + c) = a + min b c :=
  sorry
  /-
  eq.symm (eq_min
    (show a + min b c ≤ a + b, from add_le_add_left !min_le_left _)
    (show a + min b c ≤ a + c, from add_le_add_left !min_le_right _)
    (take d,
      assume H₁ : d ≤ a + b,
      assume H₂ : d ≤ a + c,
      decidable.by_cases
        (suppose b ≤ c, using this, by rewrite [min_eq_left this]; apply H₁)
        (suppose ¬ b ≤ c, using this,
          by rewrite [min_eq_right (le_of_lt (lt_of_not_ge this))]; apply H₂)))
  -/

  theorem min_add_add_right : min (a + c) (b + c) = min a b + c :=
  sorry -- by rewrite [add.comm a c, add.comm b c, add.comm _ c]; apply min_add_add_left

  theorem max_add_add_left : max (a + b) (a + c) = a + max b c :=
  sorry
  /-
  eq.symm (eq_max
    (add_le_add_left !le_max_left _)
    (add_le_add_left !le_max_right _)
    (take d,
      assume H₁ : a + b ≤ d,
      assume H₂ : a + c ≤ d,
      decidable.by_cases
        (suppose b ≤ c, using this, by rewrite [max_eq_right this]; apply H₂)
        (suppose ¬ b ≤ c, using this,
          by rewrite [max_eq_left (le_of_lt (lt_of_not_ge this))]; apply H₁)))
  -/

  theorem max_add_add_right : max (a + c) (b + c) = max a b + c :=
  sorry -- by rewrite [add.comm a c, add.comm b c, add.comm _ c]; apply max_add_add_left
end

/- partially ordered groups -/

structure ordered_comm_group [class] (A : Type) extends add_comm_group A, order_pair A :=
(add_le_add_left : ∀a b, le a b → ∀c, le (add c a) (add c b))
(add_lt_add_left : ∀a b, lt a b → ∀ c, lt (add c a) (add c b))

theorem ordered_comm_group.le_of_add_le_add_left [ordered_comm_group A] {a b c : A}
  (H : a + b ≤ a + c) : b ≤ c :=
have H' : -a + (a + b) ≤ -a + (a + c), from ordered_comm_group.add_le_add_left _ _ H _,
sorry -- by rewrite *neg_add_cancel_left at H'; exact H'

theorem ordered_comm_group.lt_of_add_lt_add_left [ordered_comm_group A] {a b c : A}
  (H : a + b < a + c) : b < c :=
have H' : -a + (a + b) < -a + (a + c), from ordered_comm_group.add_lt_add_left _ _ H _,
sorry -- by rewrite *neg_add_cancel_left at H'; exact H'

attribute [instance]
definition ordered_comm_group.to_ordered_cancel_comm_monoid [s : ordered_comm_group A] : ordered_cancel_comm_monoid A :=
⦃ ordered_cancel_comm_monoid, s,
  add_left_cancel       := @add.left_cancel A _,
  add_right_cancel      := @add.right_cancel A _,
  le_of_add_le_add_left := @ordered_comm_group.le_of_add_le_add_left A _,
  lt_of_add_lt_add_left := @ordered_comm_group.lt_of_add_lt_add_left A _⦄

section
  variables [ordered_comm_group A] (a b c d e : A)

  theorem neg_le_neg {a b : A} (H : a ≤ b) : -b ≤ -a :=
  have H1 : 0 ≤ -a + b, from add.left_inv a ▸ add_le_add_left H (-a),
  add_neg_cancel_right (-a) b ▸ zero_add (-b) ▸ add_le_add_right H1 (-b)

  theorem le_of_neg_le_neg {a b : A} (H : -b ≤ -a) : a ≤ b :=
  neg_neg a ▸ neg_neg b ▸ neg_le_neg H

  theorem neg_le_neg_iff_le : -a ≤ -b ↔ b ≤ a :=
  iff.intro le_of_neg_le_neg neg_le_neg

  theorem nonneg_of_neg_nonpos {a : A} (H : -a ≤ 0) : 0 ≤ a :=
  le_of_neg_le_neg (symm neg_zero ▸ H)

  theorem neg_nonpos_of_nonneg {a : A} (H : 0 ≤ a) : -a ≤ 0 :=
  neg_zero ▸ neg_le_neg H

  theorem neg_nonpos_iff_nonneg : -a ≤ 0 ↔ 0 ≤ a :=
  iff.intro nonneg_of_neg_nonpos neg_nonpos_of_nonneg

  theorem nonpos_of_neg_nonneg {a : A} (H : 0 ≤ -a) : a ≤ 0 :=
  le_of_neg_le_neg (symm neg_zero ▸ H)

  theorem neg_nonneg_of_nonpos {a : A} (H : a ≤ 0) : 0 ≤ -a :=
  neg_zero ▸ neg_le_neg H

  theorem neg_nonneg_iff_nonpos : 0 ≤ -a ↔ a ≤ 0 :=
  iff.intro nonpos_of_neg_nonneg neg_nonneg_of_nonpos

  theorem neg_lt_neg {a b : A} (H : a < b) : -b < -a :=
  have H1 : 0 < -a + b, from add.left_inv a ▸ add_lt_add_left H (-a),
  add_neg_cancel_right (-a) b ▸ zero_add (-b) ▸ add_lt_add_right H1 (-b)

  theorem lt_of_neg_lt_neg {a b : A} (H : -b < -a) : a < b :=
  neg_neg a ▸ neg_neg b ▸ neg_lt_neg H

  theorem neg_lt_neg_iff_lt : -a < -b ↔ b < a :=
  iff.intro lt_of_neg_lt_neg neg_lt_neg

  theorem pos_of_neg_neg {a : A} (H : -a < 0) : 0 < a :=
  lt_of_neg_lt_neg (symm neg_zero ▸ H)

  theorem neg_neg_of_pos {a : A} (H : 0 < a) : -a < 0 :=
  neg_zero ▸ neg_lt_neg H

  theorem neg_neg_iff_pos : -a < 0 ↔ 0 < a :=
  iff.intro pos_of_neg_neg neg_neg_of_pos

  theorem neg_of_neg_pos {a : A} (H : 0 < -a) : a < 0 :=
  lt_of_neg_lt_neg (symm neg_zero ▸ H)

  theorem neg_pos_of_neg {a : A} (H : a < 0) : 0 < -a :=
  neg_zero ▸ neg_lt_neg H

  theorem neg_pos_iff_neg : 0 < -a ↔ a < 0 :=
  iff.intro neg_of_neg_pos neg_pos_of_neg

  theorem le_neg_iff_le_neg : a ≤ -b ↔ b ≤ -a := neg_neg a ▸ neg_le_neg_iff_le (-a) b

  theorem le_neg_of_le_neg {a b : A} : a ≤ -b → b ≤ -a := iff.mp (le_neg_iff_le_neg a b)

  theorem neg_le_iff_neg_le : -a ≤ b ↔ -b ≤ a := neg_neg b ▸ neg_le_neg_iff_le a (-b)

  theorem neg_le_of_neg_le {a b : A} : -a ≤ b → -b ≤ a := iff.mp (neg_le_iff_neg_le a b)

  theorem lt_neg_iff_lt_neg : a < -b ↔ b < -a := neg_neg a ▸ neg_lt_neg_iff_lt (-a) b

  theorem lt_neg_of_lt_neg {a b : A} : a < -b → b < -a := iff.mp (lt_neg_iff_lt_neg a b)

  theorem neg_lt_iff_neg_lt : -a < b ↔ -b < a := neg_neg b ▸ neg_lt_neg_iff_lt a (-b)

  theorem neg_lt_of_neg_lt {a b : A} : -a < b → -b < a := iff.mp (neg_lt_iff_neg_lt a b)

  theorem sub_nonneg_iff_le : 0 ≤ a - b ↔ b ≤ a := sub_self b ▸ add_le_add_right_iff b (-b) a

  theorem sub_nonneg_of_le {a b : A} : b ≤ a → 0 ≤ a - b := iff.mpr (sub_nonneg_iff_le a b)

  theorem le_of_sub_nonneg {a b : A} : 0 ≤ a - b → b ≤ a := iff.mp (sub_nonneg_iff_le a b)

  theorem sub_nonpos_iff_le : a - b ≤ 0 ↔ a ≤ b := sub_self b ▸ add_le_add_right_iff a (-b) b

  theorem sub_nonpos_of_le {a b : A} : a ≤ b → a - b ≤ 0 := iff.mpr (sub_nonpos_iff_le a b)

  theorem le_of_sub_nonpos {a b : A} : a - b ≤ 0 → a ≤ b := iff.mp (sub_nonpos_iff_le a b)

  theorem sub_pos_iff_lt : 0 < a - b ↔ b < a := sub_self b ▸ add_lt_add_right_iff b (-b) a

  theorem sub_pos_of_lt {a b : A} : b < a → 0 < a - b := iff.mpr (sub_pos_iff_lt a b)

  theorem lt_of_sub_pos {a b : A} : 0 < a - b → b < a := iff.mp (sub_pos_iff_lt a b)

  theorem sub_neg_iff_lt : a - b < 0 ↔ a < b := sub_self b ▸ add_lt_add_right_iff a (-b) b

  theorem sub_neg_of_lt {a b : A} : a < b → a - b < 0 := iff.mpr (sub_neg_iff_lt a b)

  theorem lt_of_sub_neg {a b : A} : a - b < 0 → a < b := iff.mp (sub_neg_iff_lt a b)

  theorem add_le_iff_le_neg_add : a + b ≤ c ↔ b ≤ -a + c :=
  have H: a + b ≤ c ↔ -a + (a + b) ≤ -a + c, from iff.symm (add_le_add_left_iff (-a) (a + b) c),
  neg_add_cancel_left a b ▸ H

  theorem add_le_of_le_neg_add {a b c : A} : b ≤ -a + c → a + b ≤ c :=
  iff.mpr (add_le_iff_le_neg_add a b c)

  theorem le_neg_add_of_add_le {a b c : A} : a + b ≤ c → b ≤ -a + c :=
  iff.mp (add_le_iff_le_neg_add a b c)

  theorem add_le_iff_le_sub_left : a + b ≤ c ↔ b ≤ c - a :=
  sorry -- by rewrite [sub_eq_add_neg, {c+_}add.comm]; apply add_le_iff_le_neg_add

  theorem add_le_of_le_sub_left {a b c : A} : b ≤ c - a → a + b ≤ c :=
  iff.mpr (add_le_iff_le_sub_left a b c)

  theorem le_sub_left_of_add_le {a b c : A} : a + b ≤ c → b ≤ c - a :=
  iff.mp (add_le_iff_le_sub_left a b c)

  theorem add_le_iff_le_sub_right : a + b ≤ c ↔ a ≤ c - b :=
  have H: a + b ≤ c ↔ a + b - b ≤ c - b, from iff.symm (add_le_add_right_iff (a + b) (-b) c),
  add_neg_cancel_right a b ▸ H

  theorem add_le_of_le_sub_right {a b c : A} : a ≤ c - b → a + b ≤ c :=
  iff.mpr (add_le_iff_le_sub_right a b c)

  theorem le_sub_right_of_add_le {a b c : A} : a + b ≤ c → a ≤ c - b :=
  iff.mp (add_le_iff_le_sub_right a b c)

  theorem le_add_iff_neg_add_le : a ≤ b + c ↔ -b + a ≤ c :=
  have H: a ≤ b + c ↔ -b + a ≤ -b + (b + c), from iff.symm (add_le_add_left_iff (-b) a (b + c)),
  sorry -- by rewrite neg_add_cancel_left at H; exact H

  theorem le_add_of_neg_add_le {a b c : A} : -b + a ≤ c → a ≤ b + c :=
  iff.mpr (le_add_iff_neg_add_le a b c)

  theorem neg_add_le_of_le_add {a b c : A} : a ≤ b + c → -b + a ≤ c :=
  iff.mp (le_add_iff_neg_add_le a b c)

  theorem le_add_iff_sub_left_le : a ≤ b + c ↔ a - b ≤ c :=
  sorry -- by rewrite [sub_eq_add_neg, {a+_}add.comm]; apply le_add_iff_neg_add_le

  theorem le_add_of_sub_left_le {a b c : A} : a - b ≤ c → a ≤ b + c :=
  iff.mpr (le_add_iff_sub_left_le a b c)

  theorem sub_left_le_of_le_add {a b c : A} : a ≤ b + c → a - b ≤ c :=
  iff.mp (le_add_iff_sub_left_le a b c)

  theorem le_add_iff_sub_right_le : a ≤ b + c ↔ a - c ≤ b :=
  have H: a ≤ b + c ↔ a - c ≤ b + c - c, from iff.symm (add_le_add_right_iff a (-c) (b + c)),
  sorry -- by rewrite [sub_eq_add_neg (b+c) c at H, add_neg_cancel_right at H]; exact H

  theorem le_add_of_sub_right_le {a b c : A} : a - c ≤ b → a ≤ b + c :=
  iff.mpr $ le_add_iff_sub_right_le a b c

  theorem sub_right_le_of_le_add {a b c : A} : a ≤ b + c → a - c ≤ b :=
  iff.mp $ le_add_iff_sub_right_le a b c

  theorem le_add_iff_neg_add_le_left : a ≤ b + c ↔ -b + a ≤ c :=
  have H: a ≤ b + c ↔ -b + a ≤ -b + (b + c), from iff.symm $ add_le_add_left_iff (-b) a (b + c),
  sorry -- by rewrite neg_add_cancel_left at H; exact H

  theorem le_add_of_neg_add_le_left {a b c : A} : -b + a ≤ c → a ≤ b + c :=
  iff.mpr $ le_add_iff_neg_add_le_left a b c

  theorem neg_add_le_left_of_le_add {a b c : A} : a ≤ b + c → -b + a ≤ c :=
  iff.mp $ le_add_iff_neg_add_le_left a b c

  theorem le_add_iff_neg_add_le_right : a ≤ b + c ↔ -c + a ≤ b :=
  sorry -- by rewrite add.comm; apply le_add_iff_neg_add_le_left

  theorem le_add_of_neg_add_le_right {a b c : A} : -c + a ≤ b → a ≤ b + c :=
  iff.mpr $ le_add_iff_neg_add_le_right a b c

  theorem neg_add_le_right_of_le_add {a b c : A} : a ≤ b + c → -c + a ≤ b :=
  iff.mp $ le_add_iff_neg_add_le_right a b c

  theorem le_add_iff_neg_le_sub_left : c ≤ a + b ↔ -a ≤ b - c :=
  have H : c ≤ a + b ↔ -a + c ≤ b, from le_add_iff_neg_add_le c a b,
  have H' : -a + c ≤ b ↔ -a ≤ b - c, from add_le_iff_le_sub_right (-a) c b,
  iff.trans H H'

  theorem le_add_of_neg_le_sub_left {a b c : A} : -a ≤ b - c → c ≤ a + b :=
  iff.mpr $ le_add_iff_neg_le_sub_left a b c

  theorem neg_le_sub_left_of_le_add {a b c : A} : c ≤ a + b → -a ≤ b - c :=
  iff.mp $ le_add_iff_neg_le_sub_left a b c

  theorem le_add_iff_neg_le_sub_right : c ≤ a + b ↔ -b ≤ a - c :=
  sorry -- by rewrite add.comm; apply le_add_iff_neg_le_sub_left

  theorem le_add_of_neg_le_sub_right {a b c : A} : -b ≤ a - c → c ≤ a + b :=
  iff.mpr $ le_add_iff_neg_le_sub_right a b c

  theorem neg_le_sub_right_of_le_add {a b c : A} : c ≤ a + b → -b ≤ a - c :=
  iff.mp $ le_add_iff_neg_le_sub_right a b c

  theorem add_lt_iff_lt_neg_add_left : a + b < c ↔ b < -a + c :=
  have H: a + b < c ↔ -a + (a + b) < -a + c, from iff.symm $ add_lt_add_left_iff (-a) (a + b) c,
  sorry -- begin rewrite neg_add_cancel_left at H, exact H end

  theorem add_lt_of_lt_neg_add_left {a b c : A} : b < -a + c → a + b < c :=
  iff.mpr $ add_lt_iff_lt_neg_add_left a b c

  theorem lt_neg_add_left_of_add_lt {a b c : A} : a + b < c → b < -a + c :=
  iff.mp $ add_lt_iff_lt_neg_add_left a b c

  theorem add_lt_iff_lt_neg_add_right : a + b < c ↔ a < -b + c :=
  sorry -- by rewrite add.comm; apply add_lt_iff_lt_neg_add_left

  theorem add_lt_of_lt_neg_add_right {a b c : A} : a < -b + c → a + b < c :=
  iff.mpr $ add_lt_iff_lt_neg_add_right a b c

  theorem lt_neg_add_right_of_add_lt {a b c : A} : a + b < c → a < -b + c :=
  iff.mp $ add_lt_iff_lt_neg_add_right a b c

  theorem add_lt_iff_lt_sub_left : a + b < c ↔ b < c - a :=
  sorry
  /-
  begin
    rewrite [sub_eq_add_neg, {c+_}add.comm],
    apply add_lt_iff_lt_neg_add_left
  end
  -/

  theorem add_lt_of_lt_sub_left {a b c : A} : b < c - a → a + b < c :=
  iff.mpr $ add_lt_iff_lt_sub_left a b c

  theorem lt_sub_left_of_add_lt {a b c : A} : a + b < c → b < c - a :=
  iff.mp $ add_lt_iff_lt_sub_left a b c

  theorem add_lt_iff_lt_sub_right : a + b < c ↔ a < c - b :=
  sorry
  /-
  have H: a + b < c ↔ a + b - b < c - b, from iff.symm (!add_lt_add_right_iff),
  by rewrite [sub_eq_add_neg at H, add_neg_cancel_right at H]; exact H
  -/

  theorem add_lt_of_lt_sub_right {a b c : A} : a < c - b → a + b < c :=
  iff.mpr $ add_lt_iff_lt_sub_right a b c

  theorem lt_sub_right_of_add_lt {a b c : A} : a + b < c → a < c - b :=
  iff.mp $ add_lt_iff_lt_sub_right a b c

  theorem lt_add_iff_neg_add_lt_left : a < b + c ↔ -b + a < c :=
  sorry
  /-
  have H: a < b + c ↔ -b + a < -b + (b + c), from iff.symm (!add_lt_add_left_iff),
  by rewrite neg_add_cancel_left at H; exact H
  -/

  theorem lt_add_of_neg_add_lt_left {a b c : A} : -b + a < c → a < b + c :=
  iff.mpr $ lt_add_iff_neg_add_lt_left a b c

  theorem neg_add_lt_left_of_lt_add {a b c : A} : a < b + c → -b + a < c :=
  iff.mp $ lt_add_iff_neg_add_lt_left a b c

  theorem lt_add_iff_neg_add_lt_right : a < b + c ↔ -c + a < b :=
  sorry -- by rewrite add.comm; apply lt_add_iff_neg_add_lt_left

  theorem lt_add_of_neg_add_lt_right {a b c : A} : -c + a < b → a < b + c :=
  iff.mpr $ lt_add_iff_neg_add_lt_right a b c

  theorem neg_add_lt_right_of_lt_add {a b c : A} : a < b + c → -c + a < b :=
  iff.mp $ lt_add_iff_neg_add_lt_right a b c

  theorem lt_add_iff_sub_lt_left : a < b + c ↔ a - b < c :=
  sorry -- by rewrite [sub_eq_add_neg, {a + _}add.comm]; apply lt_add_iff_neg_add_lt_left

  theorem lt_add_of_sub_lt_left {a b c : A} : a - b < c → a < b + c :=
  iff.mpr $ lt_add_iff_sub_lt_left a b c

  theorem sub_lt_left_of_lt_add {a b c : A} : a < b + c → a - b < c :=
  iff.mp $ lt_add_iff_sub_lt_left a b c

  theorem lt_add_iff_sub_lt_right : a < b + c ↔ a - c < b :=
  sorry -- by rewrite add.comm; apply lt_add_iff_sub_lt_left

  theorem lt_add_of_sub_lt_right {a b c : A} : a - c < b → a < b + c :=
  iff.mpr $ lt_add_iff_sub_lt_right a b c

  theorem sub_lt_right_of_lt_add {a b c : A} : a < b + c → a - c < b :=
  iff.mp $ lt_add_iff_sub_lt_right a b c

  theorem sub_lt_of_sub_lt {a b c : A} : a - b < c → a - c < b :=
  sorry
  /-
    begin
      intro H,
      apply sub_lt_left_of_lt_add,
      apply lt_add_of_sub_lt_right H
    end
  -/

  theorem sub_le_of_sub_le {a b c : A} : a - b ≤ c → a - c ≤ b :=
  sorry
  /-
    begin
      intro H,
      apply sub_left_le_of_le_add,
      apply le_add_of_sub_right_le H
    end
  -/

  -- TODO: the Isabelle library has varations on a + b ≤ b ↔ a ≤ 0
  theorem le_iff_le_of_sub_eq_sub {a b c d : A} (H : a - b = c - d) : a ≤ b ↔ c ≤ d :=
  calc
    a ≤ b ↔ a - b ≤ 0   : iff.symm (sub_nonpos_iff_le a b)
      ... = (c - d ≤ 0) : sorry -- by rewrite H
      ... ↔ c ≤ d       : sub_nonpos_iff_le c d

  theorem lt_iff_lt_of_sub_eq_sub {a b c d : A} (H : a - b = c - d) : a < b ↔ c < d :=
  calc
    a < b ↔ a - b < 0   : iff.symm (sub_neg_iff_lt a b)
      ... = (c - d < 0) : sorry -- by rewrite H
      ... ↔ c < d       : sub_neg_iff_lt c d

  theorem sub_le_sub_left {a b : A} (H : a ≤ b) (c : A) : c - b ≤ c - a :=
  add_le_add_left (neg_le_neg H) c

  theorem sub_le_sub_right {a b : A} (H : a ≤ b) (c : A) : a - c ≤ b - c := add_le_add_right H (-c)

  theorem sub_le_sub {a b c d : A} (Hab : a ≤ b) (Hcd : c ≤ d) : a - d ≤ b - c :=
  add_le_add Hab (neg_le_neg Hcd)

  theorem sub_lt_sub_left {a b : A} (H : a < b) (c : A) : c - b < c - a :=
  add_lt_add_left (neg_lt_neg H) c

  theorem sub_lt_sub_right {a b : A} (H : a < b) (c : A) : a - c < b - c := add_lt_add_right H (-c)

  theorem sub_lt_sub {a b c d : A} (Hab : a < b) (Hcd : c < d) : a - d < b - c :=
  add_lt_add Hab (neg_lt_neg Hcd)

  theorem sub_lt_sub_of_le_of_lt {a b c d : A} (Hab : a ≤ b) (Hcd : c < d) : a - d < b - c :=
  add_lt_add_of_le_of_lt Hab (neg_lt_neg Hcd)

  theorem sub_lt_sub_of_lt_of_le {a b c d : A} (Hab : a < b) (Hcd : c ≤ d) : a - d < b - c :=
  add_lt_add_of_lt_of_le Hab (neg_le_neg Hcd)

  theorem sub_le_self (a : A) {b : A} (H : b ≥ 0) : a - b ≤ a :=
  sorry
  /-
  calc
    a - b = a + -b : rfl
      ... ≤ a + 0  : add_le_add_left (neg_nonpos_of_nonneg H) _
      ... = a      : by rewrite add_zero
  -/

  theorem sub_lt_self (a : A) {b : A} (H : b > 0) : a - b < a :=
  calc
    a - b = a + -b : rfl
      ... < a + 0  : add_lt_add_left (neg_neg_of_pos H) _
      ... = a      : sorry -- by rewrite add_zero

  theorem add_le_add_three {a b c d e f : A} (H1 : a ≤ d) (H2 : b ≤ e) (H3 : c ≤ f) :
        a + b + c ≤ d + e + f :=
  sorry
  /-
  begin
    apply le.trans,
    apply add_le_add,
    apply add_le_add,
    repeat assumption,
    apply le.refl
  end
  -/

  theorem sub_le_of_nonneg {b : A} (H : b ≥ 0) : a - b ≤ a :=
  add_le_of_le_of_nonpos (le.refl a) (neg_nonpos_of_nonneg H)

  theorem sub_lt_of_pos {b : A} (H : b > 0) : a - b < a :=
  add_lt_of_le_of_neg (le.refl a) (neg_neg_of_pos H)

  theorem neg_add_neg_le_neg_of_pos {a : A} (H : a > 0) : -a + -a ≤ -a :=
  neg_add a a ▸ neg_le_neg (le_add_of_nonneg_left (le_of_lt H))

  variable (A)
  theorem strictly_decreasing_neg : strictly_decreasing (λ x : A, -x) :=
  @neg_lt_neg A _

  variable {A}

  section
    variable [strict_order B]

    theorem strictly_decreasing_neg_of_strictly_increasing {f : B → A}
      (H : strictly_increasing f) : strictly_decreasing (λ x, - f x) :=
    strictly_decreasing_comp_dec_inc (strictly_decreasing_neg A) H

    theorem strictly_increasing_neg_of_strictly_decreasing {f : B → A}
      (H : strictly_decreasing f) : strictly_increasing (λ x, - f x) :=
    strictly_increasing_comp_dec_dec (strictly_decreasing_neg A) H

    theorem strictly_decreasing_of_strictly_increasing_neg {f : B → A}
      (H : strictly_increasing (λ x, - f x)) : strictly_decreasing f :=
    strictly_decreasing_of_strictly_increasing_comp_right (left_inverse_neg A)
        (strictly_decreasing_neg A) H

    theorem strictly_increasing_of_strictly_decreasing_neg {f : B → A}
      (H : strictly_decreasing (λ x, - f x)) : strictly_increasing f :=
    strictly_increasing_of_strictly_decreasing_comp_right (left_inverse_neg A)
        (strictly_decreasing_neg A) H

    theorem strictly_decreasing_neg_iff {f : B → A} :
      strictly_decreasing (λ x, - f x) ↔ strictly_increasing f :=
    iff.intro strictly_increasing_of_strictly_decreasing_neg
       strictly_decreasing_neg_of_strictly_increasing

    theorem strictly_increasing_neg_iff {f : B → A} :
      strictly_increasing (λ x, - f x) ↔ strictly_decreasing f :=
    iff.intro strictly_decreasing_of_strictly_increasing_neg
       strictly_increasing_neg_of_strictly_decreasing

    theorem strictly_decreasing_neg_of_strictly_increasing' {f : A → B}
      (H : strictly_increasing f) : strictly_decreasing (λ x, f (-x)) :=
    strictly_decreasing_comp_inc_dec H (strictly_decreasing_neg A)

    theorem strictly_increasing_neg_of_strictly_decreasing' {f : A → B}
      (H : strictly_decreasing f) : strictly_increasing (λ x, f (-x)) :=
    strictly_increasing_comp_dec_dec H (strictly_decreasing_neg A)

    theorem strictly_decreasing_of_strictly_increasing_neg' {f : A → B}
      (H : strictly_increasing (λ x, f (-x))) : strictly_decreasing f :=
    strictly_decreasing_of_strictly_increasing_comp_left (left_inverse_neg A)
        (strictly_decreasing_neg A) H

    theorem strictly_increasing_of_strictly_decreasing_neg' {f : A → B}
      (H : strictly_decreasing (λ x, f (-x))) : strictly_increasing f :=
    strictly_increasing_of_strictly_decreasing_comp_left (left_inverse_neg A)
        (strictly_decreasing_neg A) H

    theorem strictly_decreasing_neg_iff' {f : A → B} :
      strictly_decreasing (λ x, f (-x)) ↔ strictly_increasing f :=
    iff.intro strictly_increasing_of_strictly_decreasing_neg'
       strictly_decreasing_neg_of_strictly_increasing'

    theorem strictly_increasing_neg_iff' {f : A → B} :
      strictly_increasing (λ x, f (-x)) ↔ strictly_decreasing f :=
    iff.intro strictly_decreasing_of_strictly_increasing_neg'
       strictly_increasing_neg_of_strictly_decreasing'
  end

  section
    variable [weak_order B]

    theorem nondecreasing_of_neg_nonincreasing {f : B → A} (H : nonincreasing (λ x, -f x)) :
      nondecreasing f :=
    take a₁ a₂, suppose a₁ ≤ a₂, le_of_neg_le_neg (H this)

    theorem nonincreasing_neg {f : B → A} (H : nondecreasing f) : nonincreasing (λ x, -f x) :=
    take a₁ a₂, suppose a₁ ≤ a₂, neg_le_neg (H this)

    theorem nonincreasing_neg_iff (f : B → A) : nonincreasing (λ x, - f x) ↔ nondecreasing f :=
    iff.intro nondecreasing_of_neg_nonincreasing nonincreasing_neg

    theorem nonincreasing_of_neg_nondecreasing {f : B → A} (H : nondecreasing (λ x, -f x)) :
      nonincreasing f :=
    take a₁ a₂, suppose a₁ ≤ a₂, le_of_neg_le_neg (H this)

    theorem nondecreasing_neg {f : B → A} (H : nonincreasing f) : nondecreasing (λ x, -f x) :=
    take a₁ a₂, suppose a₁ ≤ a₂, neg_le_neg (H this)

    theorem nondecreasing_neg_iff (f : B → A) : nondecreasing (λ x, - f x) ↔ nonincreasing f :=
    iff.intro nonincreasing_of_neg_nondecreasing nondecreasing_neg

    theorem nondecreasing_of_neg_nonincreasing' {f : A → B} (H : nonincreasing (λ x, f (-x))) :
      nondecreasing f :=
    take a₁ a₂, suppose a₁ ≤ a₂,
    have f(-(-a₁)) ≤ f(-(-a₂)), from H (neg_le_neg this),
    sorry -- by rewrite *neg_neg at this; exact this

    theorem nonincreasing_neg' {f : A → B} (H : nondecreasing f) : nonincreasing (λ x, f (-x)) :=
    take a₁ a₂, suppose a₁ ≤ a₂, H (neg_le_neg this)

    theorem nonincreasing_neg_iff' (f : A → B) : nonincreasing (λ x, f (- x)) ↔ nondecreasing f :=
    iff.intro nondecreasing_of_neg_nonincreasing' nonincreasing_neg'

    theorem nonincreasing_of_neg_nondecreasing' {f : A → B} (H : nondecreasing (λ x, f (-x))) :
      nonincreasing f :=
    take a₁ a₂, suppose a₁ ≤ a₂,
    have f(-(-a₁)) ≥ f(-(-a₂)), from H (neg_le_neg this),
    sorry -- by rewrite *neg_neg at this; exact this

    theorem nondecreasing_neg' {f : A → B} (H : nonincreasing f) : nondecreasing (λ x, f (-x)) :=
    take a₁ a₂, suppose a₁ ≤ a₂, H (neg_le_neg this)

    theorem nondecreasing_neg_iff' (f : A → B) : nondecreasing (λ x, f (- x)) ↔ nonincreasing f :=
    iff.intro nonincreasing_of_neg_nondecreasing' nondecreasing_neg'
  end
end

/- linear ordered group with decidable order -/

structure decidable_linear_ordered_comm_group [class] (A : Type)
    extends add_comm_group A, decidable_linear_order A :=
    (add_le_add_left : ∀ a b, le a b → ∀ c, le (add c a) (add c b))
    (add_lt_add_left : ∀ a b, lt a b → ∀ c, lt (add c a) (add c b))

definition decidable_linear_ordered_comm_group.to_ordered_comm_group
      [instance]
   (A : Type) [s : decidable_linear_ordered_comm_group A] : ordered_comm_group A :=
⦃ ordered_comm_group, s,
  le_of_lt := @le_of_lt A _,
  lt_of_le_of_lt := @lt_of_le_of_lt A _,
  lt_of_lt_of_le := @lt_of_lt_of_le A _ ⦄

definition decidable_linear_ordered_comm_group.to_decidable_linear_ordered_cancel_comm_monoid
    [instance] (A : Type) [s : decidable_linear_ordered_comm_group A] :
  decidable_linear_ordered_cancel_comm_monoid A :=
⦃ decidable_linear_ordered_cancel_comm_monoid, s,
    @ordered_comm_group.to_ordered_cancel_comm_monoid A _ ⦄

section
  variables [s : decidable_linear_ordered_comm_group A]
  variables {a b c d e : A}
  include s

  theorem max_neg_neg : max (-a) (-b) = - min a b  :=
  eq.symm (eq_max
    (show -a ≤ -(min a b), from neg_le_neg $ min_le_left a b)
    (show -b ≤ -(min a b), from neg_le_neg $ min_le_right a b)
    (take d,
      assume H₁ : -a ≤ d,
      assume H₂ : -b ≤ d,
      have H : -d ≤ min a b,
        from le_min (iff.mp (neg_le_iff_neg_le a d) H₁) (iff.mp (neg_le_iff_neg_le b d) H₂),
      show -(min a b) ≤ d, from iff.mp (neg_le_iff_neg_le d (min a b)) H))

  theorem min_eq_neg_max_neg_neg : min a b = - max (-a) (-b) :=
  sorry -- by rewrite [max_neg_neg, neg_neg]

  theorem min_neg_neg : min (-a) (-b) = - max a b :=
  sorry -- by rewrite [min_eq_neg_max_neg_neg, *neg_neg]

  theorem max_eq_neg_min_neg_neg : max a b = - min (-a) (-b) :=
  sorry -- by rewrite [min_neg_neg, neg_neg]

  /- absolute value -/
  variables {a b c}

  definition abs (a : A) : A := max a (-a)

  theorem abs_of_nonneg (H : a ≥ 0) : abs a = a :=
  have H' : -a ≤ a, from le.trans (neg_nonpos_of_nonneg H) H,
  max_eq_left H'

  theorem abs_of_pos (H : a > 0) : abs a = a :=
  abs_of_nonneg (le_of_lt H)

  theorem abs_of_nonpos (H : a ≤ 0) : abs a = -a :=
  have H' : a ≤ -a, from le.trans H (neg_nonneg_of_nonpos H),
  max_eq_right H'

  theorem abs_of_neg (H : a < 0) : abs a = -a := abs_of_nonpos (le_of_lt H)

  theorem abs_zero : abs 0 = (0:A) := abs_of_nonneg (le.refl _)

  theorem abs_neg (a : A) : abs (-a) = abs a :=
  sorry -- by rewrite [↑abs, max.comm, neg_neg]

  theorem abs_pos_of_pos (H : a > 0) : abs a > 0 :=
  sorry -- by rewrite (abs_of_pos H); exact H

  theorem abs_pos_of_neg (H : a < 0) : abs a > 0 :=
  abs_neg a ▸ abs_pos_of_pos (neg_pos_of_neg H)

  theorem abs_sub (a b : A) : abs (a - b) = abs (b - a) :=
  sorry -- by rewrite [-neg_sub, abs_neg]

  theorem ne_zero_of_abs_ne_zero {a : A} (H : abs a ≠ 0) : a ≠ 0 :=
   assume Ha, H (symm Ha ▸ abs_zero)

  /- these assume a linear order -/

  theorem eq_zero_of_neg_eq (H : -a = a) : a = 0 :=
  lt.by_cases
    (assume H1 : a < 0,
      have H2: a > 0, from H ▸ neg_pos_of_neg H1,
      absurd H1 (lt.asymm H2))
    (assume H1 : a = 0, H1)
    (assume H1 : a > 0,
      have H2: a < 0, from H ▸ neg_neg_of_pos H1,
      absurd H1 (lt.asymm H2))

  theorem abs_nonneg (a : A) : abs a ≥ 0 :=
  sorry
  /-
  or.elim (le.total 0 a)
    (assume H : 0 ≤ a, by rewrite (abs_of_nonneg H); exact H)
    (assume H : a ≤ 0,
      calc
          0 ≤ -a    : neg_nonneg_of_nonpos H
        ... = abs a : eq.symm (abs_of_nonpos H))
  -/

  theorem abs_abs (a : A) : abs (abs a) = abs a := abs_of_nonneg $ abs_nonneg a

  theorem le_abs_self (a : A) : a ≤ abs a :=
  or.elim (le.total 0 a)
    (assume H : 0 ≤ a, abs_of_nonneg H ▸ le.refl (abs a))
    (assume H : a ≤ 0, le.trans H $ abs_nonneg a)

  theorem neg_le_abs_self (a : A) : -a ≤ abs a :=
  abs_neg a ▸ le_abs_self (-a)

  theorem eq_zero_of_abs_eq_zero (H : abs a = 0) : a = 0 :=
  have H1 : a ≤ 0, from H ▸ le_abs_self a,
  have H2 : -a ≤ 0, from H ▸ abs_neg a ▸ le_abs_self (-a),
  le.antisymm H1 (nonneg_of_neg_nonpos H2)

  theorem abs_eq_zero_iff_eq_zero (a : A) : abs a = 0 ↔ a = 0 :=
  iff.intro eq_zero_of_abs_eq_zero (assume H, trans (congr_arg abs H) abs_zero)

  theorem eq_of_abs_sub_eq_zero {a b : A} (H : abs (a - b) = 0) : a = b :=
  have a - b = 0, from eq_zero_of_abs_eq_zero H,
  show a = b, from eq_of_sub_eq_zero this

  theorem abs_pos_of_ne_zero (H : a ≠ 0) : abs a > 0 :=
  or.elim (lt_or_gt_of_ne H) abs_pos_of_neg abs_pos_of_pos

  theorem abs.by_cases {P : A → Prop} {a : A} (H1 : P a) (H2 : P (-a)) : P (abs a) :=
  or.elim (le.total 0 a)
    (assume H : 0 ≤ a, symm (abs_of_nonneg H) ▸ H1)
    (assume H : a ≤ 0, symm (abs_of_nonpos H) ▸ H2)

  theorem abs_le_of_le_of_neg_le (H1 : a ≤ b) (H2 : -a ≤ b) : abs a ≤ b :=
  abs.by_cases H1 H2

  theorem abs_lt_of_lt_of_neg_lt (H1 : a < b) (H2 : -a < b) : abs a < b :=
  abs.by_cases H1 H2

  -- the triangle inequality
  section
    private lemma aux1 {a b : A} (H1 : a + b ≥ 0) (H2 : a ≥ 0) : abs (a + b) ≤ abs a + abs b :=
    sorry
    /-
    decidable.by_cases
      (assume H3 : b ≥ 0,
          calc
            abs (a + b) ≤ abs (a + b)   : !le.refl
                ... = a + b             : by rewrite (abs_of_nonneg H1)
                ... = abs a + b         : by rewrite (abs_of_nonneg H2)
                ... = abs a + abs b     : by rewrite (abs_of_nonneg H3))
      (assume H3 : ¬ b ≥ 0,
        have H4 : b ≤ 0, from le_of_lt (lt_of_not_ge H3),
        calc
          abs (a + b) = a + b     : by rewrite (abs_of_nonneg H1)
              ... = abs a + b     : by rewrite (abs_of_nonneg H2)
              ... ≤ abs a + 0     : add_le_add_left H4 _
              ... ≤ abs a + -b    : add_le_add_left (neg_nonneg_of_nonpos H4) _
              ... = abs a + abs b : by rewrite (abs_of_nonpos H4))
    -/

    private lemma aux2 {a b : A} (H1 : a + b ≥ 0) : abs (a + b) ≤ abs a + abs b :=
    sorry
    /-
    or.elim (le.total b 0)
      (assume H2 : b ≤ 0,
        have H3 : ¬ a < 0, from
          assume H4 : a < 0,
          have H5 : a + b < 0, from !add_zero ▸ add_lt_add_of_lt_of_le H4 H2,
          not_lt_of_ge H1 H5,
        aux1 H1 (le_of_not_gt H3))
      (assume H2 : 0 ≤ b,
        begin
          have H3 : abs (b + a) ≤ abs b + abs a,
          begin
            rewrite add.comm at H1,
            exact aux1 H1 H2
          end,
          rewrite [add.comm, {abs a + _}add.comm],
          exact H3
        end)
    -/

    theorem abs_add_le_abs_add_abs (a b : A) : abs (a + b) ≤ abs a + abs b :=
    sorry
    /-
    or.elim (le.total 0 (a + b))
      (assume H2 : 0 ≤ a + b, aux2 H2)
      (assume H2 : a + b ≤ 0,
        have H3 : -a + -b = -(a + b), by rewrite neg_add,
        have H4 : -(a + b) ≥ 0, from iff.mpr (neg_nonneg_iff_nonpos (a+b)) H2,
        have H5   : -a + -b ≥ 0, begin rewrite -H3 at H4, exact H4 end,
        calc
          abs (a + b) = abs (-a + -b)   : by rewrite [-abs_neg, neg_add]
              ... ≤ abs (-a) + abs (-b) : aux2 H5
              ... = abs a + abs b       : by rewrite *abs_neg)
    -/

  theorem abs_sub_abs_le_abs_sub (a b : A) : abs a - abs b ≤ abs (a - b) :=
  sorry
  /-
  have H1 : abs a - abs b + abs b ≤ abs (a - b) + abs b, from
    calc
      abs a - abs b + abs b = abs a : by rewrite sub_add_cancel
        ... = abs (a - b + b)       : by rewrite sub_add_cancel
        ... ≤ abs (a - b) + abs b   : !abs_add_le_abs_add_abs,
  le_of_add_le_add_right H1
  -/

  theorem abs_sub_le (a b c : A) : abs (a - c) ≤ abs (a - b) + abs (b - c) :=
  sorry
  /-
  calc
    abs (a - c) = abs (a - b + (b - c))     :  by rewrite [*sub_eq_add_neg, add.assoc, neg_add_cancel_left]
            ... ≤ abs (a - b) + abs (b - c) : !abs_add_le_abs_add_abs
  -/

  theorem abs_add_three (a b c : A) : abs (a + b + c) ≤ abs a + abs b + abs c :=
  sorry
  /-
    begin
      apply le.trans,
      apply abs_add_le_abs_add_abs,
      apply le.trans,
      apply add_le_add_right,
      apply abs_add_le_abs_add_abs,
      apply le.refl
    end
  -/

  theorem dist_bdd_within_interval {a b lb ub : A} (H : lb < ub) (Hal : lb ≤ a) (Hau : a ≤ ub)
        (Hbl : lb ≤ b) (Hbu : b ≤ ub) : abs (a - b) ≤ ub - lb :=
  sorry
  /-
  begin
    cases (decidable.em (b ≤ a)) with [Hba, Hba],
    rewrite (abs_of_nonneg (iff.mpr !sub_nonneg_iff_le Hba)),
    apply sub_le_sub,
    apply Hau,
    apply Hbl,
    rewrite [abs_of_neg (iff.mpr !sub_neg_iff_lt (lt_of_not_ge Hba)), neg_sub],
    apply sub_le_sub,
    apply Hbu,
    apply Hal
  end
  -/
  end
end
