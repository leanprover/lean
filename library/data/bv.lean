/-
Copyright (c) 2015 Joe Hendrix. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Joe Hendrix

Basic operations on bitvectors.

This is a work-in-progress, and contains additions to other theories.
-/
import data.list
import data.tuple

namespace bv
open algebra
open bool
open eq.ops
open list
open nat
open prod
open subtype
open tuple

definition bv [reducible] (n : ℕ) := tuple bool n

-- Create a zero bitvector
definition bv_zero (n : ℕ) : bv n := replicate ff

-- Create  a bitvector with the constant one.
definition bv_one  : Π (n : ℕ), bv n
  | 0 := replicate ff
  | (succ n) := (replicate ff : bv n) ++ (tt :: nil)

definition bv_cong {a b : ℕ} : (a = b) → bv a → bv b
| c (tag x p) := tag x (c ▸ p)

section shift

  -- shift left
  definition bv_shl {n:ℕ} : bv n → ℕ → bv n
    | x i :=
       dite (i ≤ n)
            (λle,
             let r := dropn i x ++ replicate ff in
             let eq := calc (n-i) + i = n : nat.sub_add_cancel le in
             bv_cong eq r)
            (λp, bv_zero n)

  -- unsigned shift right
  definition bv_ushr {n:ℕ} : bv n → ℕ → bv n
    | x i :=
      dite (i ≤ n)
           (λle,
            let y : bv (n-i) := @firstn _ _ (n - i) (sub_le n i) x in
            let eq := calc (i+(n-i)) = (n - i) + i : add.comm
                                ...  = n           : nat.sub_add_cancel le in
            bv_cong eq (replicate ff ++ y))
           (λgt, bv_zero n)

  -- signed shift right
  definition bv_sshr {m:ℕ} : bv (succ m) → ℕ → bv (succ m)
    | x i :=
      let n := succ m in
      dite (i ≤ n)
           (λle,
            let z : bv i := replicate (head x) in
            let y : bv (n-i) := @firstn _ _ (n - i) (sub_le n i) x in
            let eq := calc (i+(n-i)) = (n-i) + i : add.comm
                                ...  = n         : nat.sub_add_cancel le in
            bv_cong eq (z ++ y))
           (λgt, bv_zero n)

end shift

section bitwise
  variable { n : ℕ }

  definition bv_not : bv n → bv n := map bnot
  definition bv_and : bv n → bv n → bv n := map₂ band
  definition bv_or  : bv n → bv n → bv n := map₂ bor
  definition bv_xor : bv n → bv n → bv n := map₂ bxor

end bitwise

section arith

  variable { n : ℕ }

  protected definition xor3 (x:bool) (y:bool) (c:bool) := bxor (bxor x y) c
  protected definition carry (x:bool) (y:bool) (c:bool) :=
    x && y || x && c || y && c

  definition bv_neg : bv n → bv n
  | x :=
    let f := λy c, (y || c, bxor y c) in
    pr₂ (mapAccumR f x ff)

  -- Add with carry (no overflow)
  definition bv_adc : bv n → bv n → bool → bv (n+1)
  | x y c :=
    let f := λx y c, (bv.carry x y c, bv.xor3 x y c) in
    let z := tuple.mapAccumR₂ f x y c in
    (pr₁ z) :: (pr₂ z)

  definition bv_add : bv n → bv n → bv n
  | x y := tail (bv_adc x y ff)

  protected definition borrow (x:bool) (y:bool) (b:bool) :=
    bnot x && y || bnot x && b || y && b

  -- Subtract with borrow
  definition bv_sbb : bv n → bv n → bool → bool × bv n
  | x y b :=
    let f := λx y c, (bv.borrow x y c, bv.xor3 x y c) in
    tuple.mapAccumR₂ f x y b

  definition bv_sub : bv n → bv n → bv n
  | x y := pr₂ (bv_sbb x y ff)

  definition bv_mul : bv n → bv n → bv n
  | (tag x px) y :=
    let f := λr b, (let r2 := bv_shl r 1 in cond b (bv_add r2 y) r2) in
    foldl f (bv_zero n) x

  definition bv_has_zero [instance] : has_zero (bv n) := has_zero.mk (bv_zero n)
  definition bv_has_one  [instance] : has_one (bv n)  := has_one.mk (bv_one n)
  definition bv_has_add  [instance] : has_add (bv n)  := has_add.mk bv_add
  definition bv_has_sub  [instance] : has_sub (bv n)  := has_sub.mk bv_sub
  definition bv_has_neg  [instance] : has_neg (bv n)  := has_neg.mk bv_neg
  definition bv_has_mul  [instance] : has_mul (bv n)  := has_mul.mk bv_mul

end arith


section from_bv
  variable {A : Type}

  protected definition fold_list_bits [p : has_add A]  [q : has_one A]
    : list bool → A → A
  | [] r := r
  | (tt::l) r := fold_list_bits l (r+r+1)
  | (ff::l) r := fold_list_bits l (r+r)

  -- Convert a bitvector to another number.
  definition from_bv [p : has_add A] [q0 : has_zero A] [q1 : has_one A] {w:nat} (v:bv w) : A :=
    bv.fold_list_bits (to_list v) 0
end from_bv

end bv
