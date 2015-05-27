/-
Copyright (c) 2015 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Floris van Doorn

Declaration of mapping cylinders
-/

import .type_quotient

open type_quotient eq sum equiv equiv.ops

namespace cylinder
section

universe u
parameters {A B : Type.{u}} (f : A → B)

  local abbreviation C := B + A
  inductive cylinder_rel : C → C → Type :=
  | Rmk : Π(a : A), cylinder_rel (inl (f a)) (inr a)
  open cylinder_rel
  local abbreviation R := cylinder_rel

  definition cylinder := type_quotient cylinder_rel -- TODO: define this in root namespace

  definition base (b : B) : cylinder :=
  class_of R (inl b)

  definition top (a : A) : cylinder :=
  class_of R (inr a)

  definition seg (a : A) : base (f a) = top a :=
  eq_of_rel cylinder_rel (Rmk f a)

  protected definition rec {P : cylinder → Type}
    (Pbase : Π(b : B), P (base b)) (Ptop : Π(a : A), P (top a))
    (Pseg : Π(a : A), seg a ▸ Pbase (f a) = Ptop a) (x : cylinder) : P x :=
  begin
    induction x,
    { cases a,
        apply Pbase,
        apply Ptop},
    { cases H, apply Pseg}
  end

  protected definition rec_on [reducible] {P : cylinder → Type} (x : cylinder)
    (Pbase : Π(b : B), P (base b)) (Ptop  : Π(a : A), P (top a))
    (Pseg  : Π(a : A), seg a ▸ Pbase (f a) = Ptop a) : P x :=
  rec Pbase Ptop Pseg x

  theorem rec_seg {P : cylinder → Type}
    (Pbase : Π(b : B), P (base b)) (Ptop : Π(a : A), P (top a))
    (Pseg : Π(a : A), seg a ▸ Pbase (f a) = Ptop a)
      (a : A) : apd (rec Pbase Ptop Pseg) (seg a) = Pseg a :=
  !rec_eq_of_rel

  protected definition elim {P : Type} (Pbase : B → P) (Ptop : A → P)
    (Pseg : Π(a : A), Pbase (f a) = Ptop a) (x : cylinder) : P :=
  rec Pbase Ptop (λa, !tr_constant ⬝ Pseg a) x

  protected definition elim_on [reducible] {P : Type} (x : cylinder) (Pbase : B → P) (Ptop : A → P)
    (Pseg : Π(a : A), Pbase (f a) = Ptop a) : P :=
  elim Pbase Ptop Pseg x

  theorem elim_seg {P : Type} (Pbase : B → P) (Ptop : A → P)
    (Pseg : Π(a : A), Pbase (f a) = Ptop a)
    (a : A) : ap (elim Pbase Ptop Pseg) (seg a) = Pseg a :=
  begin
    apply (@cancel_left _ _ _ _ (tr_constant (seg a) (elim Pbase Ptop Pseg (base (f a))))),
    rewrite [-apd_eq_tr_constant_con_ap,↑elim,rec_seg],
  end

  protected definition elim_type (Pbase : B → Type) (Ptop : A → Type)
    (Pseg : Π(a : A), Pbase (f a) ≃ Ptop a) (x : cylinder) : Type :=
  elim Pbase Ptop (λa, ua (Pseg a)) x

  protected definition elim_type_on [reducible] (x : cylinder) (Pbase : B → Type) (Ptop : A → Type)
    (Pseg : Π(a : A), Pbase (f a) ≃ Ptop a) : Type :=
  elim_type Pbase Ptop Pseg x

  theorem elim_type_seg (Pbase : B → Type) (Ptop : A → Type)
    (Pseg : Π(a : A), Pbase (f a) ≃ Ptop a)
    (a : A) : transport (elim_type Pbase Ptop Pseg) (seg a) = Pseg a :=
  by rewrite [tr_eq_cast_ap_fn,↑elim_type,elim_seg];apply cast_ua_fn

end

end cylinder

attribute cylinder.base cylinder.top [constructor]
attribute cylinder.elim cylinder.rec [unfold-c 8] [recursor 8]
attribute cylinder.elim_type [unfold-c 7]
attribute cylinder.rec_on cylinder.elim_on [unfold-c 5]
attribute cylinder.elim_type_on [unfold-c 4]
