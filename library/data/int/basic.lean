/-
Copyright (c) 2014 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Floris van Doorn, Jeremy Avigad

The integers, with addition, multiplication, and subtraction. The representation of the integers is
chosen to compute efficiently.

To faciliate proving things about these operations, we show that the integers are a quotient of
ℕ × ℕ with the usual equivalence relation, ≡, and functions

  abstr : ℕ × ℕ → ℤ
  repr : ℤ → ℕ × ℕ

satisfying:

  abstr_repr (a : ℤ) : abstr (repr a) = a
  repr_abstr (p : ℕ × ℕ) : repr (abstr p) ≡ p
  abstr_eq (p q : ℕ × ℕ) : p ≡ q → abstr p = abstr q

For example, to "lift" statements about add to statements about padd, we need to prove the
following:

  repr_add (a b : ℤ) : repr (a + b) = padd (repr a) (repr b)
  padd_congr (p p' q q' : ℕ × ℕ) (H1 : p ≡ p') (H2 : q ≡ q') : padd p q ≡ p' q'

-/
import data.nat.basic data.nat.order data.nat.sub data.prod
import algebra.relation algebra.binary algebra.ordered_ring
open eq.ops
open prod relation nat
open decidable binary
open algebra

/- the type of integers -/

inductive int : Type :=
| of_nat : nat → int
| neg_succ_of_nat : nat → int

notation `ℤ` := int
definition int.of_num [coercion] [reducible] [constructor] (n : num) : ℤ :=
int.of_nat (nat.of_num n)

namespace int

attribute int.of_nat [coercion]

notation `-[1+ ` n `]` := int.neg_succ_of_nat n    -- for pretty-printing output

protected definition prio : num := num.pred nat.prio

definition int_has_zero [reducible] [instance] [priority int.prio] : has_zero int :=
has_zero.mk (of_nat 0)

definition int_has_one [reducible] [instance] [priority int.prio] : has_one int :=
has_one.mk (of_nat 1)

theorem of_nat_zero : of_nat (0:nat) = (0:int) :=
rfl

theorem of_nat_one : of_nat (1:nat) = (1:int) :=
rfl

/- definitions of basic functions -/

definition neg_of_nat : ℕ → ℤ
| 0        := 0
| (succ m) := -[1+ m]

definition sub_nat_nat (m n : ℕ) : ℤ :=
match (n - m : nat) with
  | 0        := of_nat (m - n)  -- m ≥ n
  | (succ k) := -[1+ k]         -- m < n, and n - m = succ k
end

protected definition neg (a : ℤ) : ℤ :=
int.cases_on a neg_of_nat succ

protected definition add : ℤ → ℤ → ℤ
| (of_nat m) (of_nat n) := m + n
| (of_nat m) -[1+ n]    := sub_nat_nat m (succ n)
| -[1+ m]    (of_nat n) := sub_nat_nat n (succ m)
| -[1+ m]    -[1+ n]    := neg_of_nat (succ m + succ n)

protected definition mul : ℤ → ℤ → ℤ
| (of_nat m) (of_nat n) := m * n
| (of_nat m) -[1+ n]    := neg_of_nat (m * succ n)
| -[1+ m]    (of_nat n) := neg_of_nat (succ m * n)
| -[1+ m]    -[1+ n]    := succ m * succ n

/- notation -/

definition int_has_add [reducible] [instance] [priority int.prio] : has_add int := has_add.mk int.add
definition int_has_neg [reducible] [instance] [priority int.prio] : has_neg int := has_neg.mk int.neg
definition int_has_mul [reducible] [instance] [priority int.prio] : has_mul int := has_mul.mk int.mul

lemma mul_of_nat_of_nat   (m n : nat) : of_nat m * of_nat n = of_nat (m * n) :=
rfl

lemma mul_of_nat_neg_succ_of_nat (m n : nat) : of_nat m * -[1+ n] = neg_of_nat (m * succ n) :=
rfl

lemma mul_neg_succ_of_nat_of_nat (m n : nat) : -[1+ m] * of_nat n = neg_of_nat (succ m * n) :=
rfl

lemma mul_neg_succ_of_nat_neg_succ_of_nat (m n : nat) : -[1+ m] * -[1+ n] = succ m * succ n :=
rfl

/- some basic functions and properties -/

theorem of_nat.inj {m n : ℕ} (H : of_nat m = of_nat n) : m = n :=
int.no_confusion H imp.id

theorem eq_of_of_nat_eq_of_nat {m n : ℕ} (H : of_nat m = of_nat n) : m = n :=
of_nat.inj H

theorem of_nat_eq_of_nat_iff (m n : ℕ) : of_nat m = of_nat n ↔ m = n :=
iff.intro of_nat.inj !congr_arg

theorem neg_succ_of_nat.inj {m n : ℕ} (H : neg_succ_of_nat m = neg_succ_of_nat n) : m = n :=
int.no_confusion H imp.id

theorem neg_succ_of_nat_eq (n : ℕ) : -[1+ n] = -(n + 1) := rfl

private definition has_decidable_eq₂ : Π (a b : ℤ), decidable (a = b)
| (of_nat m) (of_nat n) := decidable_of_decidable_of_iff
    (nat.has_decidable_eq m n) (iff.symm (of_nat_eq_of_nat_iff m n))
| (of_nat m) -[1+ n]    := inr (by contradiction)
| -[1+ m]    (of_nat n) := inr (by contradiction)
| -[1+ m]    -[1+ n]    := if H : m = n then
    inl (congr_arg neg_succ_of_nat H) else inr (not.mto neg_succ_of_nat.inj H)

definition has_decidable_eq [instance] [priority int.prio] : decidable_eq ℤ := has_decidable_eq₂

theorem of_nat_add (n m : nat) : of_nat (n + m) = of_nat n + of_nat m := rfl

theorem of_nat_succ (n : ℕ) : of_nat (succ n) = of_nat n + 1 := rfl

theorem of_nat_mul (n m : ℕ) : of_nat (n * m) = of_nat n * of_nat m := rfl

theorem sub_nat_nat_of_ge {m n : ℕ} (H : m ≥ n) : sub_nat_nat m n = of_nat (m - n) :=
show sub_nat_nat m n = nat.cases_on 0 (m -[nat] n) _, from (sub_eq_zero_of_le H) ▸ rfl

section
local attribute sub_nat_nat [reducible]
theorem sub_nat_nat_of_lt {m n : ℕ} (H : m < n) : sub_nat_nat m n = -[1+ pred (n - m)] :=
have H1 : n - m = succ (pred (n - m)), from eq.symm (succ_pred_of_pos (nat.sub_pos_of_lt H)),
show sub_nat_nat m n = nat.cases_on (succ (nat.pred (n - m))) (m -[nat] n) _, from H1 ▸ rfl
end

definition nat_abs (a : ℤ) : ℕ := int.cases_on a function.id succ

theorem nat_abs_of_nat (n : ℕ) : nat_abs n = n := rfl

theorem eq_zero_of_nat_abs_eq_zero : Π {a : ℤ}, nat_abs a = 0 → a = 0
| (of_nat m) H := congr_arg of_nat H
| -[1+ m']   H := absurd H !succ_ne_zero

theorem nat_abs_zero : nat_abs (0:int) = (0:nat) :=
rfl

theorem nat_abs_one : nat_abs (1:int) = (1:nat) :=
rfl

/- int is a quotient of ordered pairs of natural numbers -/

protected definition equiv (p q : ℕ × ℕ) : Prop :=  pr1 p + pr2 q = pr2 p + pr1 q

local infix ≡ := int.equiv

protected theorem equiv.refl [refl] {p : ℕ × ℕ} : p ≡ p := !add.comm

protected theorem equiv.symm [symm] {p q : ℕ × ℕ} (H : p ≡ q) : q ≡ p :=
calc
  pr1 q + pr2 p = pr2 p + pr1 q : by rewrite add.comm
    ... = pr1 p + pr2 q         : H⁻¹
    ... = pr2 q + pr1 p         : by rewrite add.comm

protected theorem equiv.trans [trans] {p q r : ℕ × ℕ} (H1 : p ≡ q) (H2 : q ≡ r) : p ≡ r :=
add.right_cancel (calc
   pr1 p + pr2 r + pr2 q = pr1 p + pr2 q + pr2 r : by rewrite add.right_comm
    ... = pr2 p + pr1 q + pr2 r                  : {H1}
    ... = pr2 p + (pr1 q + pr2 r)                : by rewrite add.assoc
    ... = pr2 p + (pr2 q + pr1 r)                : {H2}
    ... = pr2 p + pr2 q + pr1 r                  : by rewrite add.assoc
    ... = pr2 p + pr1 r + pr2 q                  : by rewrite add.right_comm)

protected theorem equiv_equiv : is_equivalence int.equiv :=
is_equivalence.mk @@equiv.refl @@equiv.symm @@equiv.trans

protected theorem equiv_cases {p q : ℕ × ℕ} (H : p ≡ q) :
    (pr1 p ≥ pr2 p ∧ pr1 q ≥ pr2 q) ∨ (pr1 p < pr2 p ∧ pr1 q < pr2 q) :=
or.elim (@@le_or_gt _ _ (pr2 p) (pr1 p))
  (suppose pr1 p ≥ pr2 p,
    have pr2 p + pr1 q ≥ pr2 p + pr2 q, from H ▸ add_le_add_right this (pr2 q),
    or.inl (and.intro `pr1 p ≥ pr2 p` (le_of_add_le_add_left this)))
  (suppose H₁ : pr1 p < pr2 p,
    have pr2 p + pr1 q < pr2 p + pr2 q, from H ▸ add_lt_add_right H₁ (pr2 q),
    or.inr (and.intro H₁ (lt_of_add_lt_add_left this)))

protected theorem equiv_of_eq {p q : ℕ × ℕ} (H : p = q) : p ≡ q := H ▸ equiv.refl

/- the representation and abstraction functions -/

definition abstr (a : ℕ × ℕ) : ℤ := sub_nat_nat (pr1 a) (pr2 a)

theorem abstr_of_ge {p : ℕ × ℕ} (H : pr1 p ≥ pr2 p) : abstr p = of_nat (pr1 p - pr2 p) :=
sub_nat_nat_of_ge H

theorem abstr_of_lt {p : ℕ × ℕ} (H : pr1 p < pr2 p) :
  abstr p = -[1+ pred (pr2 p - pr1 p)] :=
sub_nat_nat_of_lt H

definition repr : ℤ → ℕ × ℕ
| (of_nat m) := (m, 0)
| -[1+ m]    := (0, succ m)

theorem abstr_repr : Π (a : ℤ), abstr (repr a) = a
| (of_nat m) := (sub_nat_nat_of_ge (zero_le m))
| -[1+ m]    := rfl

theorem repr_sub_nat_nat (m n : ℕ) : repr (sub_nat_nat m n) ≡ (m, n) :=
nat.lt_ge_by_cases
  (take H : m < n,
    have H1 : repr (sub_nat_nat m n) = (0, n - m), by
      rewrite [sub_nat_nat_of_lt H, -(succ_pred_of_pos (nat.sub_pos_of_lt H))],
    H1⁻¹ ▸ (!zero_add ⬝ (nat.sub_add_cancel (le_of_lt H))⁻¹))
  (take H : m ≥ n,
    have H1 : repr (sub_nat_nat m n) = (m - n, 0), from sub_nat_nat_of_ge H ▸ rfl,
    H1⁻¹ ▸ ((nat.sub_add_cancel H) ⬝ !zero_add⁻¹))

theorem repr_abstr (p : ℕ × ℕ) : repr (abstr p) ≡ p :=
!prod.eta ▸ !repr_sub_nat_nat

theorem abstr_eq {p q : ℕ × ℕ} (Hequiv : p ≡ q) : abstr p = abstr q :=
or.elim (int.equiv_cases Hequiv)
  (and.rec (assume (Hp : pr1 p ≥ pr2 p) (Hq : pr1 q ≥ pr2 q),
    have H : pr1 p - pr2 p = pr1 q - pr2 q, from
      calc pr1 p - pr2 p
           = pr1 p + pr2 q - pr2 q - pr2 p   : by rewrite nat.add_sub_cancel
       ... = pr2 p + pr1 q - pr2 q - pr2 p   : Hequiv
       ... = pr2 p + (pr1 q - pr2 q) - pr2 p : nat.add_sub_assoc Hq
       ... = pr1 q - pr2 q + pr2 p - pr2 p   : by rewrite add.comm
       ... = pr1 q - pr2 q                   : by rewrite nat.add_sub_cancel,
    abstr_of_ge Hp ⬝ (H ▸ rfl) ⬝ (abstr_of_ge Hq)⁻¹))
  (and.rec (assume (Hp : pr1 p < pr2 p) (Hq : pr1 q < pr2 q),
    have H : pr2 p - pr1 p = pr2 q - pr1 q, from
      calc pr2 p - pr1 p
           = pr2 p + pr1 q - pr1 q - pr1 p   : by rewrite nat.add_sub_cancel
       ... = pr1 p + pr2 q - pr1 q - pr1 p   : Hequiv
       ... = pr1 p + (pr2 q - pr1 q) - pr1 p : nat.add_sub_assoc (le_of_lt Hq)
       ... = pr2 q - pr1 q + pr1 p - pr1 p   : by rewrite add.comm
       ... = pr2 q - pr1 q                   : by rewrite nat.add_sub_cancel,
    abstr_of_lt Hp ⬝ (H ▸ rfl) ⬝ (abstr_of_lt Hq)⁻¹))

theorem equiv_iff (p q : ℕ × ℕ) : (p ≡ q) ↔ (abstr p = abstr q) :=
iff.intro abstr_eq (assume H, equiv.trans (H ▸ equiv.symm (repr_abstr p)) (repr_abstr q))

theorem equiv_iff3 (p q : ℕ × ℕ) : (p ≡ q) ↔ ((p ≡ p) ∧ (q ≡ q) ∧ (abstr p = abstr q)) :=
iff.trans !equiv_iff (iff.symm
   (iff.trans (and_iff_right !equiv.refl) (and_iff_right !equiv.refl)))

theorem eq_abstr_of_equiv_repr {a : ℤ} {p : ℕ × ℕ} (Hequiv : repr a ≡ p) : a = abstr p :=
!abstr_repr⁻¹ ⬝ abstr_eq Hequiv

theorem eq_of_repr_equiv_repr {a b : ℤ} (H : repr a ≡ repr b) : a = b :=
eq_abstr_of_equiv_repr H ⬝ !abstr_repr

section
local attribute abstr [reducible]
local attribute dist [reducible]
theorem nat_abs_abstr : Π (p : ℕ × ℕ), nat_abs (abstr p) = dist (pr1 p) (pr2 p)
| (m, n) := nat.lt_ge_by_cases
  (assume H : m < n,
    calc
      nat_abs (abstr (m, n)) = nat_abs (-[1+ pred (n - m)]) : int.abstr_of_lt H
        ... = n - m               : succ_pred_of_pos (nat.sub_pos_of_lt H)
        ... = dist m n            : dist_eq_sub_of_le (le_of_lt H))
  (assume H : m ≥ n, (abstr_of_ge H)⁻¹ ▸ (dist_eq_sub_of_ge H)⁻¹)
end

theorem cases_of_nat_succ (a : ℤ) : (∃n : ℕ, a = of_nat n) ∨ (∃n : ℕ, a = - (of_nat (succ n))) :=
int.cases_on a (take m, or.inl (exists.intro _ rfl)) (take m, or.inr (exists.intro _ rfl))

theorem cases_of_nat (a : ℤ) : (∃n : ℕ, a = of_nat n) ∨ (∃n : ℕ, a = - of_nat n) :=
or.imp_right (Exists.rec (take n, (exists.intro _))) !cases_of_nat_succ

theorem by_cases_of_nat {P : ℤ → Prop} (a : ℤ)
    (H1 : ∀n : ℕ, P (of_nat n)) (H2 : ∀n : ℕ, P (- of_nat n)) :
  P a :=
or.elim (cases_of_nat a)
  (assume H, obtain (n : ℕ) (H3 : a = n), from H, H3⁻¹ ▸ H1 n)
  (assume H, obtain (n : ℕ) (H3 : a = -n), from H, H3⁻¹ ▸ H2 n)

theorem by_cases_of_nat_succ {P : ℤ → Prop} (a : ℤ)
    (H1 : ∀n : ℕ, P (of_nat n)) (H2 : ∀n : ℕ, P (- of_nat (succ n))) :
  P a :=
or.elim (cases_of_nat_succ a)
  (assume H, obtain (n : ℕ) (H3 : a = n), from H, H3⁻¹ ▸ H1 n)
  (assume H, obtain (n : ℕ) (H3 : a = -(succ n)), from H, H3⁻¹ ▸ H2 n)

/-
   int is a ring
-/

/- addition -/

definition padd (p q : ℕ × ℕ) : ℕ × ℕ := (pr1 p + pr1 q, pr2 p + pr2 q)

theorem repr_add : Π (a b : ℤ), repr (add a b) ≡ padd (repr a) (repr b)
| (of_nat m) (of_nat n) := !equiv.refl
| (of_nat m) -[1+ n]    :=
  begin
    change repr (sub_nat_nat m (succ n)) ≡ (m + 0, 0 + succ n),
    rewrite [zero_add, add_zero],
    apply repr_sub_nat_nat
  end
| -[1+ m]    (of_nat n) :=
  begin
    change repr (-[1+ m] + n) ≡ (0 + n, succ m + 0),
    rewrite [zero_add, add_zero],
    apply repr_sub_nat_nat
  end
| -[1+ m]    -[1+ n]    := !repr_sub_nat_nat

theorem padd_congr {p p' q q' : ℕ × ℕ} (Ha : p ≡ p') (Hb : q ≡ q') : padd p q ≡ padd p' q' :=
calc pr1 p + pr1 q + (pr2 p' + pr2 q')
        = pr1 p + pr2 p' + (pr1 q + pr2 q') : add.comm4
    ... = pr2 p + pr1 p' + (pr1 q + pr2 q') : {Ha}
    ... = pr2 p + pr1 p' + (pr2 q + pr1 q') : {Hb}
    ... = pr2 p + pr2 q + (pr1 p' + pr1 q') : add.comm4

theorem padd_comm (p q : ℕ × ℕ) : padd p q = padd q p :=
calc (pr1 p + pr1 q, pr2 p + pr2 q)
        = (pr1 q + pr1 p, pr2 p + pr2 q) : by rewrite add.comm
    ... = (pr1 q + pr1 p, pr2 q + pr2 p) : by rewrite (add.comm (pr2 p) (pr2 q))

theorem padd_assoc (p q r : ℕ × ℕ) : padd (padd p q) r = padd p (padd q r) :=
calc (pr1 p + pr1 q + pr1 r, pr2 p + pr2 q + pr2 r)
        = (pr1 p + (pr1 q + pr1 r), pr2 p + pr2 q + pr2 r)   : by rewrite add.assoc
    ... = (pr1 p + (pr1 q + pr1 r), pr2 p + (pr2 q + pr2 r)) : by rewrite add.assoc

protected theorem add_comm (a b : ℤ) : a + b = b + a :=
eq_of_repr_equiv_repr (equiv.trans !repr_add
   (equiv.symm (!padd_comm ▸ !repr_add)))

protected theorem add_assoc (a b c : ℤ) : a + b + c = a + (b + c) :=
eq_of_repr_equiv_repr (calc
         repr (a + b + c)
       ≡ padd (repr (a + b)) (repr c)           : repr_add
  ...  ≡ padd (padd (repr a) (repr b)) (repr c) : padd_congr !repr_add !equiv.refl
  ...  = padd (repr a) (padd (repr b) (repr c)) : !padd_assoc
  ...  ≡ padd (repr a) (repr (b + c))           : padd_congr !equiv.refl !repr_add
  ...  ≡ repr (a + (b + c))                     : repr_add)

protected theorem add_zero : Π (a : ℤ), a + 0 = a := int.rec (λm, rfl) (λm, rfl)

protected theorem zero_add (a : ℤ) : 0 + a = a := !int.add_comm ▸ !int.add_zero

/- negation -/

definition pneg (p : ℕ × ℕ) : ℕ × ℕ := (pr2 p, pr1 p)

-- note: this is =, not just ≡
theorem repr_neg : Π (a : ℤ), repr (- a) = pneg (repr a)
| 0        := rfl
| (succ m) := rfl
| -[1+ m]  := rfl

theorem pneg_congr {p p' : ℕ × ℕ} (H : p ≡ p') : pneg p ≡ pneg p' := eq.symm H

theorem pneg_pneg (p : ℕ × ℕ) : pneg (pneg p) = p := !prod.eta

theorem nat_abs_neg (a : ℤ) : nat_abs (-a) = nat_abs a :=
calc
  nat_abs (-a) = nat_abs (abstr (repr (-a))) : abstr_repr
    ... = nat_abs (abstr (pneg (repr a))) : repr_neg
    ... = dist (pr1 (pneg (repr a))) (pr2 (pneg (repr a))) : nat_abs_abstr
    ... = dist (pr2 (pneg (repr a))) (pr1 (pneg (repr a))) : dist.comm
    ... = nat_abs (abstr (repr a)) : nat_abs_abstr
    ... = nat_abs a : abstr_repr

theorem padd_pneg (p : ℕ × ℕ) : padd p (pneg p) ≡ (0, 0) :=
show pr1 p + pr2 p + 0 = pr2 p + pr1 p + 0, from !nat.add_comm ▸ rfl

theorem padd_padd_pneg (p q : ℕ × ℕ) : padd (padd p q) (pneg q) ≡ p :=
calc      pr1 p + pr1 q + pr2 q + pr2 p
        = pr1 p + (pr1 q + pr2 q) + pr2 p : algebra.add.assoc
    ... = pr1 p + (pr1 q + pr2 q + pr2 p) : algebra.add.assoc
    ... = pr1 p + (pr2 q + pr1 q + pr2 p) : algebra.add.comm
    ... = pr1 p + (pr2 q + pr2 p + pr1 q) : algebra.add.right_comm
    ... = pr1 p + (pr2 p + pr2 q + pr1 q) : algebra.add.comm
    ... = pr2 p + pr2 q + pr1 q + pr1 p   : algebra.add.comm

protected theorem add_left_inv (a : ℤ) : -a + a = 0 :=
have H : repr (-a + a) ≡ repr 0, from
  calc
    repr (-a + a) ≡ padd (repr (neg a)) (repr a) : repr_add
      ... = padd (pneg (repr a)) (repr a) : repr_neg
      ... ≡ repr 0 : padd_pneg,
eq_of_repr_equiv_repr H

/- nat abs -/

definition pabs (p : ℕ × ℕ) : ℕ := dist (pr1 p) (pr2 p)

theorem pabs_congr {p q : ℕ × ℕ} (H : p ≡ q) : pabs p = pabs q :=
calc
  pabs p = nat_abs (abstr p) : nat_abs_abstr
    ... = nat_abs (abstr q) : abstr_eq H
    ... = pabs q : nat_abs_abstr

theorem nat_abs_eq_pabs_repr (a : ℤ) : nat_abs a = pabs (repr a) :=
calc
  nat_abs a = nat_abs (abstr (repr a)) : abstr_repr
    ... = pabs (repr a) : nat_abs_abstr

theorem nat_abs_add_le (a b : ℤ) : nat_abs (a + b) ≤ nat_abs a + nat_abs b :=
calc
  nat_abs (a + b) = pabs (repr (a + b)) : nat_abs_eq_pabs_repr
              ... = pabs (padd (repr a) (repr b)) : pabs_congr !repr_add
              ... ≤ pabs (repr a) + pabs (repr b) : dist_add_add_le_add_dist_dist
              ... = pabs (repr a) + nat_abs b     : nat_abs_eq_pabs_repr
              ... = nat_abs a + nat_abs b         : nat_abs_eq_pabs_repr

theorem nat_abs_neg_of_nat (n : nat) : nat_abs (neg_of_nat n) = n :=
begin cases n, reflexivity, reflexivity end

section
local attribute nat_abs [reducible]
theorem nat_abs_mul : Π (a b : ℤ), nat_abs (a * b) = (nat_abs a) * (nat_abs b)
| (of_nat m) (of_nat n) := rfl
| (of_nat m) -[1+ n]    := by rewrite [mul_of_nat_neg_succ_of_nat, nat_abs_neg_of_nat]
| -[1+ m]    (of_nat n) := by rewrite [mul_neg_succ_of_nat_of_nat, nat_abs_neg_of_nat]
| -[1+ m]    -[1+ n]    := rfl
end

/- multiplication -/

definition pmul (p q : ℕ × ℕ) : ℕ × ℕ :=
  (pr1 p * pr1 q + pr2 p * pr2 q, pr1 p * pr2 q + pr2 p * pr1 q)

theorem repr_neg_of_nat (m : ℕ) : repr (neg_of_nat m) = (0, m) :=
nat.cases_on m rfl (take m', rfl)

-- note: we have =, not just ≡
theorem repr_mul : Π (a b : ℤ), repr (a * b) = pmul (repr a) (repr b)
| (of_nat m) (of_nat n) := calc
          (m * n + 0 * 0, m * 0 + 0) = (m * n + 0 * 0, m * 0 + 0 * n) : by rewrite *zero_mul
| (of_nat m) -[1+ n]    := calc
          repr ((m : int) * -[1+ n]) = (m * 0 + 0, m * succ n + 0 * 0) : repr_neg_of_nat
            ... = (m * 0 + 0 * succ n, m * succ n + 0 * 0) : by rewrite *zero_mul
| -[1+ m]    (of_nat n) := calc
          repr (-[1+ m] * (n:int)) = (0 + succ m * 0, succ m * n) : repr_neg_of_nat
            ... = (0 + succ m * 0, 0 + succ m * n) : nat.zero_add
            ... = (0 * n + succ m * 0, 0 + succ m * n) : by rewrite zero_mul
| -[1+ m]    -[1+ n]    := calc
          (succ m * succ n, 0) = (succ m * succ n, 0 * succ n) : by rewrite zero_mul
            ... = (0 + succ m * succ n, 0 * succ n) : nat.zero_add

theorem equiv_mul_prep {xa ya xb yb xn yn xm ym : ℕ}
  (H1 : xa + yb = ya + xb) (H2 : xn + ym = yn + xm)
: xa*xn+ya*yn+(xb*ym+yb*xm) = xa*yn+ya*xn+(xb*xm+yb*ym) :=
nat.add_right_cancel (calc
            xa*xn+ya*yn + (xb*ym+yb*xm) + (yb*xn+xb*yn + (xb*xn+yb*yn))
          = xa*xn+ya*yn + (yb*xn+xb*yn) + (xb*ym+yb*xm + (xb*xn+yb*yn)) : by rewrite add.comm4
      ... = xa*xn+ya*yn + (yb*xn+xb*yn) + (xb*xn+yb*yn + (xb*ym+yb*xm)) : by rewrite {xb*ym+yb*xm +_}nat.add_comm
      ... = xa*xn+yb*xn + (ya*yn+xb*yn) + (xb*xn+xb*ym + (yb*yn+yb*xm)) : by exact !congr_arg2 !add.comm4 !add.comm4
      ... = ya*xn+xb*xn + (xa*yn+yb*yn) + (xb*yn+xb*xm + (yb*xn+yb*ym)) : by rewrite[-+left_distrib,-+right_distrib]; exact H1 ▸ H2 ▸ rfl
      ... = ya*xn+xa*yn + (xb*xn+yb*yn) + (xb*yn+yb*xn + (xb*xm+yb*ym)) : by exact !congr_arg2 !add.comm4 !add.comm4
      ... = xa*yn+ya*xn + (xb*xn+yb*yn) + (xb*yn+yb*xn + (xb*xm+yb*ym)) : by rewrite {xa*yn + _}nat.add_comm
      ... = xa*yn+ya*xn + (xb*xn+yb*yn) + (yb*xn+xb*yn + (xb*xm+yb*ym)) : by rewrite {xb*yn + _}nat.add_comm
      ... = xa*yn+ya*xn + (yb*xn+xb*yn) + (xb*xn+yb*yn + (xb*xm+yb*ym)) : by rewrite (!add.comm4)
      ... = xa*yn+ya*xn + (yb*xn+xb*yn) + (xb*xm+yb*ym + (xb*xn+yb*yn)) : by rewrite {xb*xn+yb*yn + _}nat.add_comm
      ... = xa*yn+ya*xn + (xb*xm+yb*ym) + (yb*xn+xb*yn + (xb*xn+yb*yn)) : by rewrite add.comm4)

theorem pmul_congr {p p' q q' : ℕ × ℕ} : p ≡ p' → q ≡ q' → pmul p q ≡ pmul p' q' := equiv_mul_prep

theorem pmul_comm (p q : ℕ × ℕ) : pmul p q = pmul q p :=
show (_,_) = (_,_),
begin
  congruence,
    { congruence, repeat rewrite mul.comm },
    { rewrite algebra.add.comm, congruence, repeat rewrite mul.comm }
end

protected theorem mul_comm (a b : ℤ) : a * b = b * a :=
eq_of_repr_equiv_repr
  ((calc
    repr (a * b) = pmul (repr a) (repr b) : repr_mul
      ... = pmul (repr b) (repr a) : pmul_comm
      ... = repr (b * a) : repr_mul) ▸ !equiv.refl)

private theorem pmul_assoc_prep {p1 p2 q1 q2 r1 r2 : ℕ} :
  ((p1*q1+p2*q2)*r1+(p1*q2+p2*q1)*r2, (p1*q1+p2*q2)*r2+(p1*q2+p2*q1)*r1) =
   (p1*(q1*r1+q2*r2)+p2*(q1*r2+q2*r1), p1*(q1*r2+q2*r1)+p2*(q1*r1+q2*r2)) :=
begin
  rewrite[+left_distrib,+right_distrib,*algebra.mul.assoc],
  exact (congr_arg2 pair (!add.comm4 ⬝ (!congr_arg !nat.add_comm))
                         (!add.comm4 ⬝ (!congr_arg !nat.add_comm)))
end

theorem pmul_assoc (p q r: ℕ × ℕ) : pmul (pmul p q) r = pmul p (pmul q r) := pmul_assoc_prep

protected theorem mul_assoc (a b c : ℤ) : (a * b) * c = a * (b * c) :=
eq_of_repr_equiv_repr
  ((calc
    repr (a * b * c) = pmul (repr (a * b)) (repr c) : repr_mul
      ... = pmul (pmul (repr a) (repr b)) (repr c) : repr_mul
      ... = pmul (repr a) (pmul (repr b) (repr c)) : pmul_assoc
      ... = pmul (repr a) (repr (b * c)) : repr_mul
      ... = repr (a * (b * c)) : repr_mul) ▸ !equiv.refl)

protected theorem mul_one : Π (a : ℤ), a * 1 = a
| (of_nat m) := !int.zero_add -- zero_add happens to be def. = to this thm
| -[1+ m]    := !nat.zero_add ▸ rfl

protected theorem one_mul (a : ℤ) : 1 * a = a :=
int.mul_comm a 1 ▸ int.mul_one a

private theorem mul_distrib_prep {a1 a2 b1 b2 c1 c2 : ℕ} :
 ((a1+b1)*c1+(a2+b2)*c2,     (a1+b1)*c2+(a2+b2)*c1) =
 (a1*c1+a2*c2+(b1*c1+b2*c2), a1*c2+a2*c1+(b1*c2+b2*c1)) :=
begin
  rewrite +right_distrib, congruence,
    {rewrite add.comm4},
    {rewrite add.comm4}
end

protected theorem right_distrib (a b c : ℤ) : (a + b) * c = a * c + b * c :=
eq_of_repr_equiv_repr
  (calc
    repr ((a + b) * c) = pmul (repr (a + b)) (repr c) : repr_mul
      ... ≡ pmul (padd (repr a) (repr b)) (repr c)    : pmul_congr !repr_add equiv.refl
      ... = padd (pmul (repr a) (repr c)) (pmul (repr b) (repr c)) : mul_distrib_prep
      ... = padd (repr (a * c)) (pmul (repr b) (repr c))           : repr_mul
      ... = padd (repr (a * c)) (repr (b * c))                     : repr_mul
      ... ≡ repr (a * c + b * c)                                   : repr_add)

protected theorem left_distrib (a b c : ℤ) : a * (b + c) = a * b + a * c :=
calc
  a * (b + c) = (b + c) * a : int.mul_comm
    ... = b * a + c * a : int.right_distrib
    ... = a * b + c * a : int.mul_comm
    ... = a * b + a * c : int.mul_comm

protected theorem zero_ne_one : (0 : int) ≠ 1 :=
assume H : 0 = 1, !succ_ne_zero (of_nat.inj H)⁻¹

protected theorem eq_zero_or_eq_zero_of_mul_eq_zero {a b : ℤ} (H : a * b = 0) : a = 0 ∨ b = 0 :=
or.imp eq_zero_of_nat_abs_eq_zero eq_zero_of_nat_abs_eq_zero
  (eq_zero_or_eq_zero_of_mul_eq_zero (by rewrite [-nat_abs_mul, H]))

protected definition integral_domain [reducible] [trans_instance] : algebra.integral_domain int :=
⦃algebra.integral_domain,
  add            := int.add,
  add_assoc      := int.add_assoc,
  zero           := 0,
  zero_add       := int.zero_add,
  add_zero       := int.add_zero,
  neg            := int.neg,
  add_left_inv   := int.add_left_inv,
  add_comm       := int.add_comm,
  mul            := int.mul,
  mul_assoc      := int.mul_assoc,
  one            := 1,
  one_mul        := int.one_mul,
  mul_one        := int.mul_one,
  left_distrib   := int.left_distrib,
  right_distrib  := int.right_distrib,
  mul_comm       := int.mul_comm,
  zero_ne_one    := int.zero_ne_one,
  eq_zero_or_eq_zero_of_mul_eq_zero := @@int.eq_zero_or_eq_zero_of_mul_eq_zero⦄

definition int_has_sub [reducible] [instance] [priority int.prio] : has_sub int :=
has_sub.mk has_sub.sub

definition int_has_dvd [reducible] [instance] [priority int.prio] : has_dvd int :=
has_dvd.mk has_dvd.dvd

/- additional properties -/
theorem of_nat_sub {m n : ℕ} (H : m ≥ n) : of_nat (m - n) = of_nat m - of_nat n :=
assert m - n + n = m,     from nat.sub_add_cancel H,
begin
  symmetry,
  apply algebra.sub_eq_of_eq_add,
  rewrite [-of_nat_add, this]
end

theorem neg_succ_of_nat_eq' (m : ℕ) : -[1+ m] = -m - 1 :=
by rewrite [neg_succ_of_nat_eq, neg_add]

definition succ (a : ℤ) := a + (succ zero)
definition pred (a : ℤ) := a - (succ zero)
theorem pred_succ (a : ℤ) : pred (succ a) = a := !sub_add_cancel
theorem succ_pred (a : ℤ) : succ (pred a) = a := !add_sub_cancel

theorem neg_succ (a : ℤ) : -succ a = pred (-a) :=
by rewrite [↑succ,neg_add]

theorem succ_neg_succ (a : ℤ) : succ (-succ a) = -a :=
by rewrite [neg_succ,succ_pred]

theorem neg_pred (a : ℤ) : -pred a = succ (-a) :=
by rewrite [↑pred,neg_sub,sub_eq_add_neg,add.comm]

theorem pred_neg_pred (a : ℤ) : pred (-pred a) = -a :=
by rewrite [neg_pred,pred_succ]

theorem pred_nat_succ (n : ℕ) : pred (nat.succ n) = n := pred_succ n
theorem neg_nat_succ (n : ℕ) : -nat.succ n = pred (-n) := !neg_succ
theorem succ_neg_nat_succ (n : ℕ) : succ (-nat.succ n) = -n := !succ_neg_succ

definition rec_nat_on [unfold 2] {P : ℤ → Type} (z : ℤ) (H0 : P 0)
  (Hsucc : Π⦃n : ℕ⦄, P n → P (succ n)) (Hpred : Π⦃n : ℕ⦄, P (-n) → P (-nat.succ n)) : P z :=
int.rec (nat.rec H0 Hsucc) (λn, nat.rec H0 Hpred (nat.succ n)) z

--the only computation rule of rec_nat_on which is not definitional
theorem rec_nat_on_neg {P : ℤ → Type} (n : nat) (H0 : P zero)
  (Hsucc : Π⦃n : nat⦄, P n → P (succ n)) (Hpred : Π⦃n : nat⦄, P (-n) → P (-nat.succ n))
  : rec_nat_on (-nat.succ n) H0 Hsucc Hpred = Hpred (rec_nat_on (-n) H0 Hsucc Hpred) :=
nat.rec rfl (λn H, rfl) n

end int
