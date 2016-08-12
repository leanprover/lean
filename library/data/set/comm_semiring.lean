/-
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Leonardo de Moura

(set A) is an instance of a commutative semiring
-/
import data.set.basic algebra.ring
open set

attribute [instance]
definition set_comm_semiring (A : Type) : comm_semiring (set A) :=
⦃ comm_semiring,
  add           := union,
  mul           := inter,
  zero          := empty,
  one           := univ,
  add_assoc     := union_assoc,
  add_comm      := union_comm,
  zero_add      := empty_union,
  add_zero      := union_empty,
  mul_assoc     := inter_assoc,
  mul_comm      := inter_comm,
  zero_mul      := empty_inter,
  mul_zero      := inter_empty,
  one_mul       := univ_inter,
  mul_one       := inter_univ,
  left_distrib  := inter_distrib_left,
  right_distrib := inter_distrib_right
⦄
