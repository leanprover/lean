/-
Copyright (c) 2014 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Floris van Doorn, Leonardo de Moura, Jeremy Avigad

The order relation on the natural numbers.

Note: this file has significant differences than the standard library version
-/

import .basic algebra.ordered_ring
open prod decidable sum eq sigma sigma.ops

namespace nat

/- lt and le -/

theorem le_of_lt_or_eq {m n : ℕ} (H : m < n ⊎ m = n) : m ≤ n :=
sum.rec_on H (take H1, le_of_lt H1) (take H1, H1 ▸ !le.refl)

theorem lt_or_eq_of_le {m n : ℕ} (H : m ≤ n) : m < n ⊎ m = n :=
lt.by_cases
  (assume H1 : m < n, sum.inl H1)
  (assume H1 : m = n, sum.inr H1)
  (assume H1 : m > n, absurd (lt_of_le_of_lt H H1) !lt.irrefl)

theorem le_iff_lt_or_eq (m n : ℕ) : m ≤ n ↔ m < n ⊎ m = n :=
iff.intro lt_or_eq_of_le le_of_lt_or_eq

theorem lt_of_le_and_ne {m n : ℕ} (H1 : m ≤ n) (H2 : m ≠ n) : m < n :=
sum.rec_on (lt_or_eq_of_le H1)
  (take H3 : m < n, H3)
  (take H3 : m = n, absurd H3 H2)

theorem lt_iff_le_and_ne (m n : ℕ) : m < n ↔ m ≤ n × m ≠ n :=
iff.intro
  (take H, pair (le_of_lt H) (take H1, lt.irrefl _ (H1 ▸ H)))
  (take H, lt_of_le_and_ne (pr1 H) (pr2 H))

theorem le_add_right (n k : ℕ) : n ≤ n + k :=
nat.rec_on k
  (calc n ≤ n        : le.refl n
     ...  = n + zero : add_zero)
  (λ k (ih : n ≤ n + k), calc
     n   ≤ succ (n + k) : le_succ_of_le ih
     ... = n + succ k   : add_succ)

theorem le_add_left (n m : ℕ): n ≤ m + n :=
!add.comm ▸ !le_add_right

theorem le.intro {n m k : ℕ} (h : n + k = m) : n ≤ m :=
h ▸ le_add_right n k

theorem le.elim {n m : ℕ} (h : n ≤ m) : Σk, n + k = m :=
by induction h with m h ih;exact ⟨0, idp⟩;exact ⟨succ ih.1, ap succ ih.2⟩

theorem le.total {m n : ℕ} : m ≤ n ⊎ n ≤ m :=
lt.by_cases
  (assume H : m < n, sum.inl (le_of_lt H))
  (assume H : m = n, sum.inl (H ▸ !le.refl))
  (assume H : m > n, sum.inr (le_of_lt H))

/- addition -/

theorem add_le_add_left {n m : ℕ} (H : n ≤ m) (k : ℕ) : k + n ≤ k + m :=
sigma.rec_on (le.elim H) (λ(l : ℕ) (Hl : n + l = m),
le.intro
  (calc
      k + n + l  = k + (n + l) : !add.assoc
             ... = k + m       : {Hl}))

theorem add_le_add_right {n m : ℕ} (H : n ≤ m) (k : ℕ) : n + k ≤ m + k :=
!add.comm ▸ !add.comm ▸ add_le_add_left H k

theorem le_of_add_le_add_left {k n m : ℕ} (H : k + n ≤ k + m) : n ≤ m :=
sigma.rec_on (le.elim H) (λ(l : ℕ) (Hl : k + n + l = k + m),
le.intro (add.cancel_left
  (calc
      k + (n + l)  = k + n + l : (!add.assoc)⁻¹
               ... = k + m     : Hl)))

theorem add_lt_add_left {n m : ℕ} (H : n < m) (k : ℕ) : k + n < k + m :=
lt_of_succ_le (!add_succ ▸ add_le_add_left (succ_le_of_lt H) k)

theorem add_lt_add_right {n m : ℕ} (H : n < m) (k : ℕ) : n + k < m + k :=
!add.comm ▸ !add.comm ▸ add_lt_add_left H k

theorem lt_add_of_pos_right {n k : ℕ} (H : k > 0) : n < n + k :=
!add_zero ▸ add_lt_add_left H n

/- multiplication -/

theorem mul_le_mul_left {n m : ℕ} (H : n ≤ m) (k : ℕ) : k * n ≤ k * m :=
sigma.rec_on (le.elim H) (λ(l : ℕ) (Hl : n + l = m),
have H2 : k * n + k * l = k * m, by rewrite [-mul.left_distrib, Hl],
le.intro H2)

theorem mul_le_mul_right {n m : ℕ} (H : n ≤ m) (k : ℕ) : n * k ≤ m * k :=
!mul.comm ▸ !mul.comm ▸ (mul_le_mul_left H k)

theorem mul_le_mul {n m k l : ℕ} (H1 : n ≤ k) (H2 : m ≤ l) : n * m ≤ k * l :=
le.trans (mul_le_mul_right H1 m) (mul_le_mul_left H2 k)

theorem mul_lt_mul_of_pos_left {n m k : ℕ} (H : n < m) (Hk : k > 0) : k * n < k * m :=
have H2 : k * n < k * n + k, from lt_add_of_pos_right Hk,
have H3 : k * n + k ≤ k * m, from !mul_succ ▸ mul_le_mul_left (succ_le_of_lt H) k,
lt_of_lt_of_le H2 H3

theorem mul_lt_mul_of_pos_right {n m k : ℕ} (H : n < m) (Hk : k > 0) : n * k < m * k :=
!mul.comm ▸ !mul.comm ▸ mul_lt_mul_of_pos_left H Hk

/- nat is an instance of a linearly ordered semiring -/

section
  open [classes] algebra

  protected definition linear_ordered_semiring [instance] [reducible] :
    algebra.linear_ordered_semiring nat :=
  ⦃ algebra.linear_ordered_semiring, nat.comm_semiring,
    add_left_cancel            := @@add.cancel_left,
    add_right_cancel           := @@add.cancel_right,
    lt                         := lt,
    le                         := le,
    le_refl                    := le.refl,
    le_trans                   := @@le.trans,
    le_antisymm                := @@le.antisymm,
    le_total                   := @@le.total,
    le_iff_lt_or_eq            := @@le_iff_lt_or_eq,
    lt_iff_le_and_ne           := lt_iff_le_and_ne,
    add_le_add_left            := @@add_le_add_left,
    le_of_add_le_add_left      := @@le_of_add_le_add_left,
    zero_ne_one                := ne.symm (succ_ne_zero zero),
    mul_le_mul_of_nonneg_left  := (take a b c H1 H2, mul_le_mul_left H1 c),
    mul_le_mul_of_nonneg_right := (take a b c H1 H2, mul_le_mul_right H1 c),
    mul_lt_mul_of_pos_left     := @@mul_lt_mul_of_pos_left,
    mul_lt_mul_of_pos_right    := @@mul_lt_mul_of_pos_right ⦄

  migrate from algebra with nat
    replacing has_le.ge → ge, has_lt.gt → gt
    hiding pos_of_mul_pos_left, pos_of_mul_pos_right, lt_of_mul_lt_mul_left, lt_of_mul_lt_mul_right
end

section port_algebra
  open [classes] algebra
  theorem add_pos_left : Π{a : ℕ}, 0 < a → Πb : ℕ, 0 < a + b :=
    take a H b, @@algebra.add_pos_of_pos_of_nonneg _ _ a b H !zero_le
  theorem add_pos_right : Π{a : ℕ}, 0 < a → Πb : ℕ, 0 < b + a :=
    take a H b, !add.comm ▸ add_pos_left H b
  theorem add_eq_zero_iff_eq_zero_and_eq_zero : Π{a b : ℕ},
    a + b = 0 ↔ a = 0 × b = 0 :=
    take a b : ℕ,
      @@algebra.add_eq_zero_iff_eq_zero_and_eq_zero_of_nonneg_of_nonneg _ _ a b !zero_le !zero_le
  theorem le_add_of_le_left : Π{a b c : ℕ}, b ≤ c → b ≤ a + c :=
    take a b c H, @@algebra.le_add_of_nonneg_of_le _ _ a b c !zero_le H
  theorem le_add_of_le_right : Π{a b c : ℕ}, b ≤ c → b ≤ c + a :=
    take a b c H, @@algebra.le_add_of_le_of_nonneg _ _ a b c H !zero_le
  theorem lt_add_of_lt_left : Π{b c : ℕ}, b < c → Πa, b < a + c :=
    take b c H a, @@algebra.lt_add_of_nonneg_of_lt _ _ a b c !zero_le H
  theorem lt_add_of_lt_right : Π{b c : ℕ}, b < c → Πa, b < c + a :=
    take b c H a, @@algebra.lt_add_of_lt_of_nonneg _ _ a b c H !zero_le
  theorem lt_of_mul_lt_mul_left : Π{a b c : ℕ}, c * a < c * b → a < b :=
    take a b c H, @@algebra.lt_of_mul_lt_mul_left _ _ a b c H !zero_le
  theorem lt_of_mul_lt_mul_right : Π{a b c : ℕ}, a * c < b * c → a < b :=
    take a b c H, @@algebra.lt_of_mul_lt_mul_right _ _ a b c H !zero_le
  theorem pos_of_mul_pos_left : Π{a b : ℕ}, 0 < a * b → 0 < b :=
    take a b H, @@algebra.pos_of_mul_pos_left _ _ a b H !zero_le
  theorem pos_of_mul_pos_right : Π{a b : ℕ}, 0 < a * b → 0 < a :=
    take a b H, @@algebra.pos_of_mul_pos_right _ _ a b H !zero_le
end port_algebra

theorem zero_le_one : 0 ≤ 1 := dec_trivial
theorem zero_lt_one : 0 < 1 := dec_trivial

/- properties specific to nat -/

theorem lt_intro {n m k : ℕ} (H : succ n + k = m) : n < m :=
lt_of_succ_le (le.intro H)

theorem lt_elim {n m : ℕ} (H : n < m) : Σk, succ n + k = m :=
le.elim (succ_le_of_lt H)

theorem lt_add_succ (n m : ℕ) : n < n + succ m :=
lt_intro !succ_add_eq_succ_add

theorem eq_zero_of_le_zero {n : ℕ} (H : n ≤ 0) : n = 0 :=
obtain (k : ℕ) (Hk : n + k = 0), from le.elim H,
eq_zero_of_add_eq_zero_right Hk

/- succ and pred -/

theorem lt_iff_succ_le (m n : nat) : m < n ↔ succ m ≤ n :=
iff.rfl

theorem self_le_succ (n : ℕ) : n ≤ succ n :=
le.intro !add_one

theorem succ_le_or_eq_of_le {n m : ℕ} (H : n ≤ m) : succ n ≤ m ⊎ n = m :=
sum.rec_on (lt_or_eq_of_le H)
  (assume H1 : n < m, sum.inl (succ_le_of_lt H1))
  (assume H1 : n = m, sum.inr H1)

theorem pred_le_of_le_succ {n m : ℕ} : n ≤ succ m → pred n ≤ m :=
nat.cases_on n
  (assume H, !pred_zero⁻¹ ▸ zero_le m)
  (take n',
    assume H : succ n' ≤ succ m,
    have H1 : n' ≤ m, from le_of_succ_le_succ H,
    !pred_succ⁻¹ ▸ H1)

theorem succ_le_of_le_pred {n m : ℕ} : succ n ≤ m → n ≤ pred m :=
nat.cases_on m
  (assume H, absurd H !not_succ_le_zero)
  (take m',
    assume H : succ n ≤ succ m',
    have H1 : n ≤ m', from le_of_succ_le_succ H,
    !pred_succ⁻¹ ▸ H1)

theorem pred_le_pred_of_le {n m : ℕ} : n ≤ m → pred n ≤ pred m :=
nat.cases_on n
  (assume H, pred_zero⁻¹ ▸ zero_le (pred m))
  (take n',
    assume H : succ n' ≤ m,
    !pred_succ⁻¹ ▸ succ_le_of_le_pred H)

theorem lt_of_pred_lt_pred {n m : ℕ} (H : pred n < pred m) : n < m :=
lt_of_not_le
  (take H1 : m ≤ n,
    not_lt_of_le (pred_le_pred_of_le H1) H)

theorem le_or_eq_succ_of_le_succ {n m : ℕ} (H : n ≤ succ m) : n ≤ m ⊎ n = succ m :=
sum_of_sum_of_imp_left (succ_le_or_eq_of_le H)
   (take H2 : succ n ≤ succ m, show n ≤ m, from le_of_succ_le_succ H2)

theorem le_pred_self (n : ℕ) : pred n ≤ n :=
nat.cases_on n
  (pred_zero⁻¹ ▸ !le.refl)
  (take k : ℕ, (!pred_succ)⁻¹ ▸ !self_le_succ)

theorem succ_pos (n : ℕ) : 0 < succ n :=
!zero_lt_succ

theorem succ_pred_of_pos {n : ℕ} (H : n > 0) : succ (pred n) = n :=
(sum_resolve_right (eq_zero_or_eq_succ_pred n) (ne.symm (ne_of_lt H)))⁻¹

theorem exists_eq_succ_of_lt {n m : ℕ} (H : n < m) : Σk, m = succ k :=
discriminate
  (take (Hm : m = 0), absurd (Hm ▸ H) !not_lt_zero)
  (take (l : ℕ) (Hm : m = succ l), sigma.mk l Hm)

theorem lt_succ_self (n : ℕ) : n < succ n :=
lt.base n

theorem le_of_lt_succ {n m : ℕ} (H : n < succ m) : n ≤ m :=
le_of_succ_le_succ (succ_le_of_lt H)

/- other forms of rec -/

protected theorem strong_induction_on {P : nat → Type} (n : ℕ) (H : Πn, (Πm, m < n → P m) → P n) :
    P n :=
have H1 : Π {n m : nat}, m < n → P m, from
  take n,
  nat.rec_on n
    (show Πm, m < 0 → P m, from take m H, absurd H !not_lt_zero)
    (take n',
      assume IH : Π {m : nat}, m < n' → P m,
      have H2: P n', from H n' @@IH,
      show Πm, m < succ n' → P m, from
        take m,
        assume H3 : m < succ n',
        sum.rec_on (lt_or_eq_of_le (le_of_lt_succ H3))
          (assume H4: m < n', IH H4)
          (assume H4: m = n', H4⁻¹ ▸ H2)),
H1 !lt_succ_self

protected theorem case_strong_induction_on {P : nat → Type} (a : nat) (H0 : P 0)
  (Hind : Π(n : nat), (Πm, m ≤ n → P m) → P (succ n)) : P a :=
nat.strong_induction_on a
  (take n,
   show (Π m, m < n → P m) → P n, from
     nat.cases_on n
       (assume H : (Πm, m < 0 → P m), show P 0, from H0)
       (take n,
         assume H : (Πm, m < succ n → P m),
         show P (succ n), from
           Hind n (take m, assume H1 : m ≤ n, H _ (lt_succ_of_le H1))))

/- pos -/

theorem by_cases_zero_pos {P : ℕ → Type} (y : ℕ) (H0 : P 0) (H1 : Π {y : nat}, y > 0 → P y) : P y :=
nat.cases_on y H0 (take y, H1 !succ_pos)

theorem eq_zero_or_pos (n : ℕ) : n = 0 ⊎ n > 0 :=
sum_of_sum_of_imp_left
  (sum.swap (lt_or_eq_of_le !zero_le))
  (take H : 0 = n, H⁻¹)

theorem pos_of_ne_zero {n : ℕ} (H : n ≠ 0) : n > 0 :=
sum.rec_on !eq_zero_or_pos (take H2 : n = 0, absurd H2 H) (take H2 : n > 0, H2)

theorem ne_zero_of_pos {n : ℕ} (H : n > 0) : n ≠ 0 :=
ne.symm (ne_of_lt H)

theorem exists_eq_succ_of_pos {n : ℕ} (H : n > 0) : Σl, n = succ l :=
exists_eq_succ_of_lt H

theorem pos_of_dvd_of_pos {m n : ℕ} (H1 : m ∣ n) (H2 : n > 0) : m > 0 :=
pos_of_ne_zero
  (assume H3 : m = 0,
    have H4 : n = 0, from eq_zero_of_zero_dvd (H3 ▸ H1),
    ne_of_lt H2 H4⁻¹)

/- multiplication -/

theorem mul_lt_mul_of_le_of_lt {n m k l : ℕ} (Hk : k > 0) (H1 : n ≤ k) (H2 : m < l) :
  n * m < k * l :=
lt_of_le_of_lt (mul_le_mul_right H1 m) (mul_lt_mul_of_pos_left H2 Hk)

theorem mul_lt_mul_of_lt_of_le {n m k l : ℕ} (Hl : l > 0) (H1 : n < k) (H2 : m ≤ l) :
  n * m < k * l :=
lt_of_le_of_lt (mul_le_mul_left H2 n) (mul_lt_mul_of_pos_right H1 Hl)

theorem mul_lt_mul_of_le_of_le {n m k l : ℕ} (H1 : n < k) (H2 : m < l) : n * m < k * l :=
have H3 : n * m ≤ k * m, from mul_le_mul_right (le_of_lt H1) m,
have H4 : k * m < k * l, from mul_lt_mul_of_pos_left H2 (lt_of_le_of_lt !zero_le H1),
lt_of_le_of_lt H3 H4

theorem eq_of_mul_eq_mul_left {m k n : ℕ} (Hn : n > 0) (H : n * m = n * k) : m = k :=
have H2 : n * m ≤ n * k, from H ▸ !le.refl,
have H3 : n * k ≤ n * m, from H ▸ !le.refl,
have H4 : m ≤ k, from le_of_mul_le_mul_left H2 Hn,
have H5 : k ≤ m, from le_of_mul_le_mul_left H3 Hn,
le.antisymm H4 H5

theorem eq_of_mul_eq_mul_right {n m k : ℕ} (Hm : m > 0) (H : n * m = k * m) : n = k :=
eq_of_mul_eq_mul_left Hm (!mul.comm ▸ !mul.comm ▸ H)

theorem eq_zero_or_eq_of_mul_eq_mul_left {n m k : ℕ} (H : n * m = n * k) : n = 0 ⊎ m = k :=
sum_of_sum_of_imp_right !eq_zero_or_pos
  (assume Hn : n > 0, eq_of_mul_eq_mul_left Hn H)

theorem eq_zero_or_eq_of_mul_eq_mul_right  {n m k : ℕ} (H : n * m = k * m) : m = 0 ⊎ n = k :=
eq_zero_or_eq_of_mul_eq_mul_left (!mul.comm ▸ !mul.comm ▸ H)

theorem eq_one_of_mul_eq_one_right {n m : ℕ} (H : n * m = 1) : n = 1 :=
have H2 : n * m > 0, from H⁻¹ ▸ !succ_pos,
have H3 : n > 0, from pos_of_mul_pos_right H2,
have H4 : m > 0, from pos_of_mul_pos_left H2,
sum.rec_on (le_or_gt n 1)
  (assume H5 : n ≤ 1,
    show n = 1, from le.antisymm H5 (succ_le_of_lt H3))
  (assume H5 : n > 1,
    have H6 : n * m ≥ 2 * 1, from mul_le_mul (succ_le_of_lt H5) (succ_le_of_lt H4),
    have H7 : 1 ≥ 2, from !mul_one ▸ H ▸ H6,
    absurd !lt_succ_self (not_lt_of_le H7))

theorem eq_one_of_mul_eq_one_left {n m : ℕ} (H : n * m = 1) : m = 1 :=
eq_one_of_mul_eq_one_right (!mul.comm ▸ H)

theorem eq_one_of_mul_eq_self_left {n m : ℕ} (Hpos : n > 0) (H : m * n = n) : m = 1 :=
eq_of_mul_eq_mul_right Hpos (H ⬝ !one_mul⁻¹)

theorem eq_one_of_mul_eq_self_right {n m : ℕ} (Hpos : m > 0) (H : m * n = m) : n = 1 :=
eq_one_of_mul_eq_self_left Hpos (!mul.comm ▸ H)

theorem eq_one_of_dvd_one {n : ℕ} (H : n ∣ 1) : n = 1 :=
dvd.elim H
  (take m,
    assume H1 : 1 = n * m,
    eq_one_of_mul_eq_one_right H1⁻¹)

end nat
