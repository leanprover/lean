/-
Copyright (c) 2015 William Peterson. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: William Peterson, Jeremy Avigad

Extended gcd, Bezout's theorem, chinese remainder theorem.
-/
import data.nat.div data.int .primes

/- Bezout's theorem -/

section Bezout

open nat int
open eq.ops well_founded decidable prod
open algebra

private definition pair_nat.lt : ℕ × ℕ → ℕ × ℕ → Prop := measure pr₂
private definition pair_nat.lt.wf : well_founded pair_nat.lt := intro_k (measure.wf pr₂) 20
local attribute pair_nat.lt.wf [instance]
local infixl `≺`:50 := pair_nat.lt

private definition gcd.lt.dec (x y₁ : ℕ) : (succ y₁, x % succ y₁) ≺ (x, succ y₁) :=
!nat.mod_lt (succ_pos y₁)

private definition egcd_rec_f (z : ℤ) : ℤ → ℤ → ℤ × ℤ := λ s t, (t, s - t * z)

definition egcd.F : Π (p₁ : ℕ × ℕ), (Π p₂ : ℕ × ℕ, p₂ ≺ p₁ → ℤ × ℤ) → ℤ × ℤ
| (x, y) := nat.cases_on y
              (λ f, (1, 0) )
              (λ y₁ (f : Π p₂, p₂ ≺ (x, succ y₁) → ℤ × ℤ),
                let bz := f (succ y₁, x % succ y₁) !gcd.lt.dec in
                prod.cases_on bz (egcd_rec_f (x / succ y₁)))

definition egcd (x y : ℕ) := fix egcd.F (pair x y)

theorem egcd_zero (x : ℕ) : egcd x 0 = (1, 0) :=
well_founded.fix_eq egcd.F (x, 0)

theorem egcd_succ (x y : ℕ) :
  egcd x (succ y) = prod.cases_on (egcd (succ y) (x % succ y)) (egcd_rec_f (x / succ y)) :=
well_founded.fix_eq egcd.F (x, succ y)

theorem egcd_of_pos (x : ℕ) {y : ℕ} (ypos : y > 0) :
  let erec := egcd y (x % y), u := pr₁ erec, v := pr₂ erec in
    egcd x y = (v, u - v * (x / y)) :=
obtain (y' : nat) (yeq : y = succ y'), from exists_eq_succ_of_pos ypos,
begin
  rewrite [yeq, egcd_succ, -prod.eta (egcd _ _)],
  esimp, unfold egcd_rec_f,
  rewrite [of_nat_div]
end

theorem egcd_prop (x y : ℕ) : (pr₁ (egcd x y)) * x + (pr₂ (egcd x y)) * y = gcd x y :=
gcd.induction x y
  (take m, by krewrite [egcd_zero, algebra.mul_zero, algebra.one_mul])
  (take m n,
    assume npos : 0 < n,
    assume IH,
    begin
      let H := egcd_of_pos m npos, esimp at H,
      rewrite H,
      esimp,
      rewrite [gcd_rec, -IH],
      rewrite [algebra.add.comm],
      rewrite [-of_nat_mod],
      rewrite [int.mod_def],
      rewrite [+algebra.mul_sub_right_distrib],
      rewrite [+algebra.mul_sub_left_distrib, *left_distrib],
      rewrite [*sub_eq_add_neg, {pr₂ (egcd n (m % n)) * of_nat m + - _}algebra.add.comm],
      rewrite [-algebra.add.assoc ,algebra.mul.assoc]
    end)

theorem Bezout_aux (x y : ℕ) : ∃ a b : ℤ, a * x + b * y = gcd x y :=
exists.intro _ (exists.intro _ (egcd_prop x y))

theorem Bezout (x y : ℤ) : ∃ a b : ℤ, a * x + b * y = gcd x y :=
obtain a' b' (H : a' * nat_abs x + b' * nat_abs y = gcd x y), from !Bezout_aux,
begin
  existsi (a' * sign x),
  existsi (b' * sign y),
  rewrite [*mul.assoc, -*abs_eq_sign_mul, -*of_nat_nat_abs],
  apply H
end
end Bezout

/-
A sample application of Bezout's theorem, namely, an alternative proof that irreducible
implies prime (dvd_or_dvd_of_prime_of_dvd_mul).
-/

namespace nat
open int algebra

example {p x y : ℕ} (pp : prime p) (H : p ∣ x * y) : p ∣ x ∨ p ∣ y :=
decidable.by_cases
  (suppose p ∣ x, or.inl this)
  (suppose ¬ p ∣ x,
    have cpx : coprime p x, from coprime_of_prime_of_not_dvd pp this,
    obtain (a b : ℤ) (Hab : a * p + b * x = gcd p x), from Bezout_aux p x,
    assert a * p * y + b * x * y = y,
      by rewrite [-right_distrib, Hab, ↑coprime at cpx, cpx, int.one_mul],
    have p ∣ y,
      begin
        apply dvd_of_of_nat_dvd_of_nat,
        rewrite [-this],
        apply @@dvd_add,
          {apply dvd_mul_of_dvd_left,
            apply dvd_mul_of_dvd_right,
            apply dvd.refl},
          {rewrite mul.assoc,
            apply dvd_mul_of_dvd_right,
            apply of_nat_dvd_of_nat_of_dvd H}
      end,
    or.inr this)

end nat
