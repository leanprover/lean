/-
Copyright (c) 2017 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Mario Carneiro
-/

prelude
import .lemmas init.meta.well_founded_tactics

universe u

namespace nat

  def shiftl : ℕ → ℕ → ℕ
  | m 0     := m
  | m (n+1) := 2 * shiftl m n

  def shiftr : ℕ → ℕ → ℕ
  | m 0     := m
  | m (n+1) := shiftr m n / 2

  def bodd (n : ℕ) : bool := n % 2 = 1

  def test_bit (m n : ℕ) : bool := bodd (shiftr m n)

  def binary_rec {α : Type u} (f : bool → ℕ → α → α) (z : α) : ℕ → α
  | n := if n0 : n = 0 then z else let n' := shiftr n 1 in
    have n' < n, from (div_lt_iff_lt_mul _ _ dec_trivial).2 $
    by note := nat.mul_lt_mul_of_pos_left (dec_trivial : 1 < 2)
         (lt_of_le_of_ne (zero_le _) (ne.symm n0));
       rwa mul_one at this,
    f (bodd n) n' (binary_rec n')

  def size : ℕ → ℕ := binary_rec (λ_ _, succ) 0

  def bits : ℕ → list bool := binary_rec (λb _ IH, b :: IH) []

  def bit (b : bool) : ℕ → ℕ := cond b bit1 bit0

  def bitwise (f : bool → bool → bool) : ℕ → ℕ → ℕ :=
  binary_rec
    (λa m Ia, binary_rec
      (λb n _, bit (f a b) (Ia n))
      (cond (f tt ff) (bit a m) 0))
    (λb, cond (f ff tt) b 0)

  def lor   : ℕ → ℕ → ℕ := bitwise bor
  def land  : ℕ → ℕ → ℕ := bitwise band
  def ldiff : ℕ → ℕ → ℕ := bitwise (λ a b, a && bnot b)
  def lxor  : ℕ → ℕ → ℕ := bitwise bxor

end nat
