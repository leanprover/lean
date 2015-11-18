/-
Copyright (c) 2014 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Authors: Floris van Doorn, Jeremy Avigad
Subtraction on the natural numbers, as well as min, max, and distance.
-/
import .order
open eq.ops algebra

namespace nat

/- subtraction -/

protected theorem sub_zero (n : ℕ) : n - 0 = n :=
rfl

theorem sub_succ (n m : ℕ) : n - succ m = pred (n - m) :=
rfl

protected theorem zero_sub (n : ℕ) : 0 - n = 0 :=
nat.induction_on n !nat.sub_zero
  (take k : nat,
    assume IH : 0 - k = 0,
    calc
      0 - succ k = pred (0 - k) : sub_succ
             ... = pred 0       : IH
             ... = 0            : pred_zero)

theorem succ_sub_succ (n m : ℕ) : succ n - succ m = n - m :=
succ_sub_succ_eq_sub n m

protected theorem sub_self (n : ℕ) : n - n = 0 :=
nat.induction_on n !nat.sub_zero (take k IH, !succ_sub_succ ⬝ IH)

protected theorem add_sub_add_right (n k m : ℕ) : (n + k) - (m + k) = n - m :=
nat.induction_on k
  (calc
    (n + 0) - (m + 0) = n - (m + 0) : {!add_zero}
                  ... = n - m       : {!add_zero})
  (take l : nat,
    assume IH : (n + l) - (m + l) = n - m,
    calc
      (n + succ l) - (m + succ l) = succ (n + l) - (m + succ l) : {!add_succ}
                              ... = succ (n + l) - succ (m + l) : {!add_succ}
                              ... = (n + l) - (m + l)           : !succ_sub_succ
                              ... =  n - m                      : IH)
protected theorem add_sub_add_left (k n m : ℕ) : (k + n) - (k + m) = n - m :=
!add.comm ▸ !add.comm ▸ !nat.add_sub_add_right

protected theorem add_sub_cancel (n m : ℕ) : n + m - m = n :=
nat.induction_on m
  (begin rewrite add_zero end)
  (take k : ℕ,
    assume IH : n + k - k = n,
    calc
      n + succ k - succ k = succ (n + k) - succ k : add_succ
                      ... = n + k - k             : succ_sub_succ
                      ... = n                     : IH)

protected theorem add_sub_cancel_left (n m : ℕ) : n + m - n = m :=
!add.comm ▸ !nat.add_sub_cancel

protected theorem sub_sub (n m k : ℕ) : n - m - k = n - (m + k) :=
nat.induction_on k
  (calc
    n - m - 0 = n - m        : nat.sub_zero
          ... =  n - (m + 0) : add_zero)
  (take l : nat,
    assume IH : n - m - l = n - (m + l),
    calc
      n - m - succ l = pred (n - m - l)   : !sub_succ
                 ... = pred (n - (m + l)) : IH
                 ... = n - succ (m + l)   : sub_succ
                 ... = n - (m + succ l)   : by rewrite add_succ)

theorem succ_sub_sub_succ (n m k : ℕ) : succ n - m - succ k = n - m - k :=
calc
  succ n - m - succ k = succ n - (m + succ k) : nat.sub_sub
                  ... = succ n - succ (m + k) : add_succ
                  ... = n - (m + k)           : succ_sub_succ
                  ... = n - m - k             : nat.sub_sub

theorem sub_self_add (n m : ℕ) : n - (n + m) = 0 :=
calc
  n - (n + m) = n - n - m : nat.sub_sub
          ... = 0 - m     : nat.sub_self
          ... = 0         : nat.zero_sub

protected theorem sub.right_comm (m n k : ℕ) : m - n - k = m - k - n :=
calc
  m - n - k = m - (n + k) : !nat.sub_sub
        ... = m - (k + n) : {!add.comm}
        ... = m - k - n   : !nat.sub_sub⁻¹

theorem sub_one (n : ℕ) : n - 1 = pred n :=
rfl

theorem succ_sub_one (n : ℕ) : succ n - 1 = n :=
rfl

/- interaction with multiplication -/

theorem mul_pred_left (n m : ℕ) : pred n * m = n * m - m :=
nat.induction_on n
  (calc
    pred 0 * m = 0 * m     : pred_zero
           ... = 0         : zero_mul
           ... = 0 - m     : nat.zero_sub
           ... = 0 * m - m : zero_mul)
  (take k : nat,
    assume IH : pred k * m = k * m - m,
    calc
      pred (succ k) * m = k * m          : pred_succ
                    ... = k * m + m - m  : nat.add_sub_cancel
                    ... = succ k * m - m : succ_mul)

theorem mul_pred_right (n m : ℕ) : n * pred m = n * m - n :=
calc
  n * pred m = pred m * n : mul.comm
         ... = m * n - n  : mul_pred_left
         ... = n * m - n  : mul.comm

protected theorem mul_sub_right_distrib (n m k : ℕ) : (n - m) * k = n * k - m * k :=
nat.induction_on m
  (calc
    (n - 0) * k = n * k         : nat.sub_zero
            ... = n * k - 0     : nat.sub_zero
            ... = n * k - 0 * k : zero_mul)
  (take l : nat,
    assume IH : (n - l) * k = n * k - l * k,
    calc
      (n - succ l) * k = pred (n - l) * k     : sub_succ
                   ... = (n - l) * k - k      : mul_pred_left
                   ... = n * k - l * k - k    : IH
                   ... = n * k - (l * k + k)  : nat.sub_sub
                   ... = n * k - (succ l * k) : succ_mul)

protected theorem mul_sub_left_distrib (n m k : ℕ) : n * (m - k) = n * m - n * k :=
calc
  n * (m - k) = (m - k) * n   : !mul.comm
          ... = m * n - k * n : !nat.mul_sub_right_distrib
          ... = n * m - k * n : {!mul.comm}
          ... = n * m - n * k : {!mul.comm}

protected theorem mul_self_sub_mul_self_eq (a b : nat) : a * a - b * b = (a + b) * (a - b) :=
by rewrite [nat.mul_sub_left_distrib, *right_distrib, mul.comm b a, add.comm (a*a) (a*b), 
            nat.add_sub_add_left]

theorem succ_mul_succ_eq (a : nat) : succ a * succ a = a*a + a + a + 1 :=
calc succ a * succ a = (a+1)*(a+1)     : by rewrite [add_one]
                ...  = a*a + a + a + 1 : by rewrite [right_distrib, left_distrib, one_mul, mul_one]

/- interaction with inequalities -/

theorem succ_sub {m n : ℕ} : m ≥ n → succ m - n  = succ (m - n) :=
sub_induction n m
  (take k, assume H : 0 ≤ k, rfl)
   (take k,
    assume H : succ k ≤ 0,
    absurd H !not_succ_le_zero)
  (take k l,
    assume IH : k ≤ l → succ l - k = succ (l - k),
    take H : succ k ≤ succ l,
    calc
      succ (succ l) - succ k = succ l - k             : succ_sub_succ
                         ... = succ (l - k)           : IH (le_of_succ_le_succ H)
                         ... = succ (succ l - succ k) : succ_sub_succ)

theorem sub_eq_zero_of_le {n m : ℕ} (H : n ≤ m) : n - m = 0 :=
obtain (k : ℕ) (Hk : n + k = m), from le.elim H, Hk ▸ !sub_self_add

theorem add_sub_of_le {n m : ℕ} : n ≤ m → n + (m - n) = m :=
sub_induction n m
  (take k,
    assume H : 0 ≤ k,
    calc
      0 + (k - 0) = k - 0 : zero_add
              ... = k     : nat.sub_zero)
  (take k, assume H : succ k ≤ 0, absurd H !not_succ_le_zero)
  (take k l,
    assume IH : k ≤ l → k + (l - k) = l,
    take H : succ k ≤ succ l,
    calc
      succ k + (succ l - succ k) = succ k + (l - k)   : succ_sub_succ
                             ... = succ (k + (l - k)) : succ_add
                             ... = succ l             : IH (le_of_succ_le_succ H))

theorem add_sub_of_ge {n m : ℕ} (H : n ≥ m) : n + (m - n) = n :=
calc
  n + (m - n) = n + 0 : sub_eq_zero_of_le H
          ... = n     : add_zero

protected theorem sub_add_cancel {n m : ℕ} : n ≥ m → n - m + m = n :=
!add.comm ▸ !add_sub_of_le

theorem sub_add_of_le {n m : ℕ} : n ≤ m → n - m + m = m :=
!add.comm ▸ add_sub_of_ge

theorem sub.cases {P : ℕ → Prop} {n m : ℕ} (H1 : n ≤ m → P 0) (H2 : ∀k, m + k = n -> P k)
  : P (n - m) :=
or.elim !le.total
  (assume H3 : n ≤ m, (sub_eq_zero_of_le H3)⁻¹ ▸ (H1 H3))
  (assume H3 : m ≤ n, H2 (n - m) (add_sub_of_le H3))

theorem exists_sub_eq_of_le {n m : ℕ} (H : n ≤ m) : ∃k, m - k = n :=
obtain (k : ℕ) (Hk : n + k = m), from le.elim H,
exists.intro k
  (calc
    m - k = n + k - k : by rewrite Hk
      ... = n         : nat.add_sub_cancel)

protected theorem add_sub_assoc {m k : ℕ} (H : k ≤ m) (n : ℕ) : n + m - k = n + (m - k) :=
have l1 : k ≤ m → n + m - k = n + (m - k), from
  sub_induction k m
    (take m : ℕ,
      assume H : 0 ≤ m,
      calc
        n + m - 0 = n + m       : nat.sub_zero
              ... = n + (m - 0) : nat.sub_zero)
    (take k : ℕ, assume H : succ k ≤ 0, absurd H !not_succ_le_zero)
    (take k m,
      assume IH : k ≤ m → n + m - k = n + (m - k),
      take H : succ k ≤ succ m,
      calc
        n + succ m - succ k = succ (n + m) - succ k : add_succ
                        ... = n + m - k             : succ_sub_succ
                        ... = n + (m - k)           : IH (le_of_succ_le_succ H)
                        ... = n + (succ m - succ k) : succ_sub_succ),
l1 H

theorem le_of_sub_eq_zero {n m : ℕ} : n - m = 0 → n ≤ m :=
sub.cases
  (assume H1 : n ≤ m, assume H2 : 0 = 0, H1)
  (take k : ℕ,
    assume H1 : m + k = n,
    assume H2 : k = 0,
    have H3 : n = m, from !add_zero ▸ H2 ▸ H1⁻¹,
    H3 ▸ !le.refl)

theorem sub_sub.cases {P : ℕ → ℕ → Prop} {n m : ℕ} (H1 : ∀k, n = m + k -> P k 0)
  (H2 : ∀k, m = n + k → P 0 k) : P (n - m) (m - n) :=
or.elim !le.total
  (assume H3 : n ≤ m,
    (sub_eq_zero_of_le H3)⁻¹ ▸  (H2 (m - n) (add_sub_of_le H3)⁻¹))
  (assume H3 : m ≤ n,
    (sub_eq_zero_of_le H3)⁻¹ ▸ (H1 (n - m) (add_sub_of_le H3)⁻¹))

protected theorem sub_eq_of_add_eq {n m k : ℕ} (H : n + m = k) : k - n = m :=
have H2 : k - n + n = m + n, from
  calc
    k - n + n = k     : nat.sub_add_cancel (le.intro H)
          ... = n + m : H⁻¹
          ... = m + n : !add.comm,
add.right_cancel H2

protected theorem eq_sub_of_add_eq {a b c : ℕ} (H : a + c = b) : a = b - c :=
(nat.sub_eq_of_add_eq (!add.comm ▸ H))⁻¹

protected theorem sub_eq_of_eq_add {a b c : ℕ} (H : a = c + b) : a - b = c :=
nat.sub_eq_of_add_eq (!add.comm ▸ H⁻¹)

protected theorem sub_le_sub_right {n m : ℕ} (H : n ≤ m) (k : ℕ) : n - k ≤ m - k :=
obtain (l : ℕ) (Hl : n + l = m), from le.elim H,
or.elim !le.total
  (assume H2 : n ≤ k, (sub_eq_zero_of_le H2)⁻¹ ▸ !zero_le)
  (assume H2 : k ≤ n,
    have H3 : n - k + l = m - k, from
      calc
        n - k + l = l + (n - k) : add.comm
              ... = l + n - k   : nat.add_sub_assoc H2 l
              ... = n + l - k   : add.comm
              ... = m - k       : Hl,
    le.intro H3)

protected theorem sub_le_sub_left {n m : ℕ} (H : n ≤ m) (k : ℕ) : k - m ≤ k - n :=
obtain (l : ℕ) (Hl : n + l = m), from le.elim H,
sub.cases
  (assume H2 : k ≤ m, !zero_le)
  (take m' : ℕ,
    assume Hm : m + m' = k,
    have H3 : n ≤ k, from le.trans H (le.intro Hm),
    have H4 : m' + l + n = k - n + n, from
      calc
        m' + l + n = n + (m' + l) : add.comm
               ... = n + (l + m') : add.comm
               ... = n + l + m'   : add.assoc
               ... = m + m'       : Hl
               ... = k            : Hm
               ... = k - n + n    : nat.sub_add_cancel H3,
    le.intro (add.right_cancel H4))

open algebra

protected theorem sub_pos_of_lt {m n : ℕ} (H : m < n) : n - m > 0 :=
assert H1 : n = n - m + m, from (nat.sub_add_cancel (le_of_lt H))⁻¹,
have   H2 : 0 + m < n - m + m, begin rewrite [zero_add, -H1], exact H end,
!lt_of_add_lt_add_right H2

protected theorem lt_of_sub_pos {m n : ℕ} (H : n - m > 0) : m < n :=
lt_of_not_ge
  (take H1 : m ≥ n,
    have H2 : n - m = 0, from sub_eq_zero_of_le H1,
    !lt.irrefl (H2 ▸ H))

protected theorem lt_of_sub_lt_sub_right {n m k : ℕ} (H : n - k < m - k) : n < m :=
lt_of_not_ge
  (assume H1 : m ≤ n,
    have H2 : m - k ≤ n - k, from nat.sub_le_sub_right H1 _,
    not_le_of_gt H H2)

protected theorem lt_of_sub_lt_sub_left {n m k : ℕ} (H : n - m < n - k) : k < m :=
lt_of_not_ge
  (assume H1 : m ≤ k,
    have H2 : n - k ≤ n - m, from nat.sub_le_sub_left H1 _,
    not_le_of_gt H H2)

protected theorem sub_lt_sub_add_sub (n m k : ℕ) : n - k ≤ (n - m) + (m - k) :=
sub.cases
  (assume H : n ≤ m, !zero_add⁻¹ ▸ nat.sub_le_sub_right H k)
  (take mn : ℕ,
    assume Hmn : m + mn = n,
    sub.cases
      (assume H : m ≤ k,
        have   H2 : n - k ≤ n - m, from nat.sub_le_sub_left H n,
        assert H3 : n - k ≤ mn, from nat.sub_eq_of_add_eq Hmn ▸ H2,
        show   n - k ≤ mn + 0,  begin rewrite add_zero, assumption end)
      (take km : ℕ,
        assume Hkm : k + km = m,
        have H : k + (mn + km) = n, from
          calc
            k + (mn + km) = k + (km + mn): add.comm
                      ... = k + km + mn  : add.assoc
                      ... = m + mn       : Hkm
                      ... = n            : Hmn,
        have H2 : n - k = mn + km, from nat.sub_eq_of_add_eq H,
        H2 ▸ !le.refl))

protected theorem sub_lt_self {m n : ℕ} (H1 : m > 0) (H2 : n > 0) : m - n < m :=
calc
  m - n = succ (pred m) - n             : succ_pred_of_pos H1
    ... = succ (pred m) - succ (pred n) : succ_pred_of_pos H2
    ... = pred m - pred n               : succ_sub_succ
    ... ≤ pred m                        : sub_le
    ... < succ (pred m)                 : lt_succ_self
    ... = m                             : succ_pred_of_pos H1

protected theorem le_sub_of_add_le {m n k : ℕ} (H : m + k ≤ n) : m ≤ n - k :=
calc
  m = m + k - k : nat.add_sub_cancel
    ... ≤ n - k : nat.sub_le_sub_right H k

protected theorem lt_sub_of_add_lt {m n k : ℕ} (H : m + k < n) (H2 : k ≤ n) : m < n - k :=
lt_of_succ_le (nat.le_sub_of_add_le (calc
    succ m + k = succ (m + k) : succ_add_eq_succ_add
           ... ≤ n            : succ_le_of_lt H))

protected theorem sub_lt_of_lt_add {v n m : nat} (h₁ : v < n + m) (h₂ : n ≤ v) : v - n < m :=
have succ v ≤ n + m,   from succ_le_of_lt h₁,
have succ (v - n) ≤ m, from
  calc succ (v - n) = succ v - n : succ_sub h₂
        ...     ≤ n + m - n      : nat.sub_le_sub_right this n
        ...     = m              : nat.add_sub_cancel_left,
lt_of_succ_le this

/- distance -/

definition dist [reducible] (n m : ℕ) := (n - m) + (m - n)

theorem dist.comm (n m : ℕ) : dist n m = dist m n :=
!add.comm

theorem dist_self (n : ℕ) : dist n n = 0 :=
calc
  (n - n) + (n - n) = 0 + (n - n) : nat.sub_self
                ... = 0 + 0       : nat.sub_self
                ... = 0           : rfl

theorem eq_of_dist_eq_zero {n m : ℕ} (H : dist n m = 0) : n = m :=
have H2 : n - m = 0, from eq_zero_of_add_eq_zero_right H,
have H3 : n ≤ m, from le_of_sub_eq_zero H2,
have H4 : m - n = 0, from eq_zero_of_add_eq_zero_left H,
have H5 : m ≤ n, from le_of_sub_eq_zero H4,
le.antisymm H3 H5

theorem dist_eq_zero {n m : ℕ} (H : n = m) : dist n m = 0 :=
by substvars; rewrite [↑dist, *nat.sub_self, add_zero]

theorem dist_eq_sub_of_le {n m : ℕ} (H : n ≤ m) : dist n m = m - n :=
calc
  dist n m = 0 + (m - n) : {sub_eq_zero_of_le H}
       ... = m - n       : zero_add

theorem dist_eq_sub_of_lt {n m : ℕ} (H : n < m) : dist n m = m - n :=
dist_eq_sub_of_le (le_of_lt H)

theorem dist_eq_sub_of_ge {n m : ℕ} (H : n ≥ m) : dist n m = n - m :=
!dist.comm ▸ dist_eq_sub_of_le H

theorem dist_eq_sub_of_gt {n m : ℕ} (H : n > m) : dist n m = n - m :=
dist_eq_sub_of_ge (le_of_lt H)

theorem dist_zero_right (n : ℕ) : dist n 0 = n :=
dist_eq_sub_of_ge !zero_le ⬝ !nat.sub_zero

theorem dist_zero_left (n : ℕ) : dist 0 n = n :=
dist_eq_sub_of_le !zero_le ⬝ !nat.sub_zero

theorem dist.intro {n m k : ℕ} (H : n + m = k) : dist k n = m :=
calc
  dist k n = k - n : dist_eq_sub_of_ge (le.intro H)
           ... = m : nat.sub_eq_of_add_eq H

theorem dist_add_add_right (n k m : ℕ) : dist (n + k) (m + k) = dist n m :=
calc
  dist (n + k) (m + k) = ((n+k) - (m+k)) + ((m+k)-(n+k)) : rfl
                   ... = (n - m) + ((m + k) - (n + k))   : nat.add_sub_add_right
                   ... = (n - m) + (m - n)               : nat.add_sub_add_right

theorem dist_add_add_left (k n m : ℕ) : dist (k + n) (k + m) = dist n m :=
begin rewrite [add.comm k n, add.comm k m]; apply dist_add_add_right end

theorem dist_add_eq_of_ge {n m : ℕ} (H : n ≥ m) : dist n m + m = n :=
calc
  dist n m + m = n - m + m : {dist_eq_sub_of_ge H}
           ... = n         : nat.sub_add_cancel H

theorem dist_eq_intro {n m k l : ℕ} (H : n + m = k + l) : dist n k = dist l m :=
calc
  dist n k = dist (n + m) (k + m) : dist_add_add_right
       ... = dist (k + l) (k + m) : H
       ... = dist l m             : dist_add_add_left

theorem dist_sub_eq_dist_add_left {n m : ℕ} (H : n ≥ m) (k : ℕ) :
  dist (n - m) k = dist n (k + m) :=
have H2 : n - m + (k + m) = k + n, from
  calc
    n - m + (k + m) = n - m + (m + k) : add.comm
                ... = n - m + m + k   : add.assoc
                ... = n + k           : nat.sub_add_cancel H
                ... = k + n           : add.comm,
dist_eq_intro H2

theorem dist_sub_eq_dist_add_right {k m : ℕ} (H : k ≥ m) (n : ℕ) :
  dist n (k - m) = dist (n + m) k :=
(dist_sub_eq_dist_add_left H n ▸ !dist.comm) ▸ !dist.comm

theorem dist.triangle_inequality (n m k : ℕ) : dist n k ≤ dist n m + dist m k :=
have (n - m) + (m - k) + ((k - m) + (m - n)) = (n - m) + (m - n) + ((m - k) + (k - m)),
begin rewrite [add.comm (k - m) (m - n),
               {n - m + _ + _}add.assoc,
               {m - k + _}add.left_comm, -add.assoc] end,
this ▸ add_le_add !nat.sub_lt_sub_add_sub !nat.sub_lt_sub_add_sub

theorem dist_add_add_le_add_dist_dist (n m k l : ℕ) : dist (n + m) (k + l) ≤ dist n k + dist m l :=
assert H : dist (n + m) (k + m) + dist (k + m) (k + l) = dist n k + dist m l,
  by rewrite [dist_add_add_left, dist_add_add_right],
by rewrite -H; apply dist.triangle_inequality

theorem dist_mul_right (n k m : ℕ) : dist (n * k) (m * k) = dist n m * k :=
assert ∀ n m, dist n m = n - m + (m - n), from take n m, rfl,
by rewrite [this, this n m, right_distrib, *nat.mul_sub_right_distrib]

theorem dist_mul_left (k n m : ℕ) : dist (k * n) (k * m) = k * dist n m :=
begin rewrite [mul.comm k n, mul.comm k m, dist_mul_right, mul.comm] end

theorem dist_mul_dist (n m k l : ℕ) : dist n m * dist k l = dist (n * k + m * l) (n * l + m * k) :=
have aux : ∀k l, k ≥ l → dist n m * dist k l = dist (n * k + m * l) (n * l + m * k), from
  take k l : ℕ,
  assume H : k ≥ l,
  have H2 : m * k ≥ m * l, from !mul_le_mul_left H,
  have H3 : n * l + m * k ≥ m * l, from le.trans H2 !le_add_left,
  calc
    dist n m * dist k l = dist n m * (k - l)       : dist_eq_sub_of_ge H
      ... = dist (n * (k - l)) (m * (k - l))       : dist_mul_right
      ... = dist (n * k - n * l) (m * k - m * l)   : by rewrite [*nat.mul_sub_left_distrib]
      ... = dist (n * k) (m * k - m * l + n * l)   : dist_sub_eq_dist_add_left (!mul_le_mul_left H)
      ... = dist (n * k) (n * l + (m * k - m * l)) : add.comm
      ... = dist (n * k) (n * l + m * k - m * l)   : nat.add_sub_assoc H2 (n * l)
      ... = dist (n * k + m * l) (n * l + m * k)   : dist_sub_eq_dist_add_right H3 _,
or.elim !le.total
  (assume H : k ≤ l, !dist.comm ▸ !dist.comm ▸ aux l k H)
  (assume H : l ≤ k, aux k l H)

lemma dist_eq_max_sub_min {i j : nat} : dist i j = (max i j) - min i j :=
or.elim (lt_or_ge i j)
  (suppose i < j, 
    by rewrite [max_eq_right_of_lt this, min_eq_left_of_lt this, dist_eq_sub_of_lt this])
  (suppose i ≥ j,
    by rewrite [max_eq_left this , min_eq_right this, dist_eq_sub_of_ge this])

lemma dist_succ {i j : nat} : dist (succ i) (succ j) = dist i j :=
by rewrite [↑dist, *succ_sub_succ]

lemma dist_le_max {i j : nat} : dist i j ≤ max i j :=
begin rewrite dist_eq_max_sub_min, apply sub_le end

lemma dist_pos_of_ne {i j : nat} : i ≠ j → dist i j > 0 :=
assume Pne, lt.by_cases
  (suppose i < j, begin rewrite [dist_eq_sub_of_lt this], apply nat.sub_pos_of_lt this end)
  (suppose i = j, by contradiction)
  (suppose i > j, begin rewrite [dist_eq_sub_of_gt this], apply nat.sub_pos_of_lt this end)

end nat
