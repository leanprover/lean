/-
Copyright (c) 2015 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Floris van Doorn

The "equivalence closure" of a type-valued relation.
A more appropriate intuition is the type of words formed from the relation,
  and inverses, concatenations and reflexivity
-/

import .relation eq2 arity

open eq

inductive e_closure {A : Type} (R : A → A → Type) : A → A → Type :=
| of_rel : Π{a a'} (r : R a a'), e_closure R a a'
| refl : Πa, e_closure R a a
| symm : Π{a a'} (r : e_closure R a a'), e_closure R a' a
| trans : Π{a a' a''} (r : e_closure R a a') (r' : e_closure R a' a''), e_closure R a a''

namespace e_closure
  infix ` ⬝r `:75 := e_closure.trans
  postfix `⁻¹ʳ`:(max+10) := e_closure.symm
  notation `[`:max a `]`:0 := e_closure.of_rel a
  abbreviation rfl {A : Type} {R : A → A → Type} {a : A} := refl R a
end e_closure

namespace relation

section
  parameters {A : Type}
             (R : A → A → Type)
  local abbreviation T := e_closure R

  variables ⦃a a' a'' : A⦄ {s : R a a'} {r : T a a} {B C : Type}
  parameter {R}
  protected definition e_closure.elim [unfold 8] {f : A → B}
    (e : Π⦃a a' : A⦄, R a a' → f a = f a') (t : T a a') : f a = f a' :=
  begin
    induction t,
      exact e r,
      reflexivity,
      exact v_0⁻¹,
      exact v_0 ⬝ v_1
  end

  definition ap_e_closure_elim_h [unfold 12] {B C : Type} {f : A → B} {g : B → C}
    (e : Π⦃a a' : A⦄, R a a' → f a = f a')
    {e' : Π⦃a a' : A⦄, R a a' → g (f a) = g (f a')}
    (p : Π⦃a a' : A⦄ (s : R a a'), ap g (e s) = e' s) (t : T a a')
    : ap g (e_closure.elim e t) = e_closure.elim e' t :=
  begin
    induction t,
      apply p,
      reflexivity,
      exact ap_inv g (e_closure.elim e r) ⬝ inverse2 v_0,
      exact ap_con g (e_closure.elim e r) (e_closure.elim e r') ⬝ (v_0 ◾ v_1)
  end

  definition ap_e_closure_elim {B C : Type} {f : A → B} (g : B → C)
    (e : Π⦃a a' : A⦄, R a a' → f a = f a') (t : T a a')
    : ap g (e_closure.elim e t) = e_closure.elim (λa a' r, ap g (e r)) t :=
  ap_e_closure_elim_h e (λa a' s, idp) t

  definition ap_e_closure_elim_h_eq {B C : Type} {f : A → B} {g : B → C}
    (e : Π⦃a a' : A⦄, R a a' → f a = f a')
    {e' : Π⦃a a' : A⦄, R a a' → g (f a) = g (f a')}
    (p : Π⦃a a' : A⦄ (s : R a a'), ap g (e s) = e' s) (t : T a a')
    : ap_e_closure_elim_h e p t =
      ap_e_closure_elim g e t ⬝ ap (λx, e_closure.elim x t) (eq_of_homotopy3 p) :=
  begin
    fapply homotopy3.rec_on p,
    intro q, esimp at q, induction q,
    esimp, rewrite eq_of_homotopy3_id
  end

  theorem ap_ap_e_closure_elim_h {B C D : Type} {f : A → B}
    {g : B → C} (h : C → D)
    (e : Π⦃a a' : A⦄, R a a' → f a = f a')
    {e' : Π⦃a a' : A⦄, R a a' → g (f a) = g (f a')}
    (p : Π⦃a a' : A⦄ (s : R a a'), ap g (e s) = e' s) (t : T a a')
    : square (ap (ap h) (ap_e_closure_elim_h e p t))
             (ap_e_closure_elim_h e (λa a' s, ap_compose h g (e s)) t)
             (ap_compose h g (e_closure.elim e t))⁻¹
             (ap_e_closure_elim_h e' (λa a' s, (ap (ap h) (p s))⁻¹) t) :=
  begin
    induction t,
    { esimp,
      apply square_of_eq, exact !con.right_inv ⬝ !con.left_inv⁻¹},
    { apply ids},
    { rewrite [▸*,ap_con (ap h)],
      refine (transpose !ap_compose_inv)⁻¹ᵛ ⬝h _,
      rewrite [con_inv,inv_inv,-inv2_inv],
      exact !ap_inv2 ⬝v square_inv2 v_0},
    { rewrite [▸*,ap_con (ap h)],
      refine (transpose !ap_compose_con)⁻¹ᵛ ⬝h _,
      rewrite [con_inv,inv_inv,con2_inv],
      refine !ap_con2 ⬝v square_con2 v_0 v_1},
  end

  theorem ap_ap_e_closure_elim {B C D : Type} {f : A → B}
    (g : B → C) (h : C → D)
    (e : Π⦃a a' : A⦄, R a a' → f a = f a') (t : T a a')
    : square (ap (ap h) (ap_e_closure_elim g e t))
             (ap_e_closure_elim_h e (λa a' s, ap_compose h g (e s)) t)
             (ap_compose h g (e_closure.elim e t))⁻¹
             (ap_e_closure_elim h (λa a' r, ap g (e r)) t) :=
  !ap_ap_e_closure_elim_h

  open e_closure
  definition is_equivalence_e_closure : is_equivalence T :=
  begin
    constructor,
      intro a, exact rfl,
      intro a a' t, exact t⁻¹ʳ,
      intro a a' a'' t t', exact t ⬝r t',
  end

  definition e_closure.transport_left {f : A → B} (e : Π⦃a a' : A⦄, R a a' → f a = f a')
    (t : e_closure R a a') (p : a = a'')
    : e_closure.elim e (p ▸ t) = (ap f p)⁻¹ ⬝ e_closure.elim e t :=
  by induction p; exact !idp_con⁻¹

  definition e_closure.transport_right {f : A → B} (e : Π⦃a a' : A⦄, R a a' → f a = f a')
    (t : e_closure R a a') (p : a' = a'')
    : e_closure.elim e (p ▸ t) = e_closure.elim e t ⬝ (ap f p) :=
  by induction p; reflexivity

  definition e_closure.transport_lr {f : A → B} (e : Π⦃a a' : A⦄, R a a' → f a = f a')
    (t : e_closure R a a) (p : a = a')
    : e_closure.elim e (p ▸ t) = (ap f p)⁻¹ ⬝ e_closure.elim e t ⬝ (ap f p) :=
  by induction p; esimp; exact !idp_con⁻¹

  --dependent elimination:

  variables {P : B → Type} {Q : C → Type} {f : A → B} {g : B → C} {f' : Π(a : A), P (f a)}
  protected definition e_closure.elimo [unfold 6]
    (p : Π⦃a a' : A⦄, R a a' → f a = f a')
    (po : Π⦃a a' : A⦄ (s : R a a'), f' a =[p s] f' a')
    (t : T a a') : f' a =[e_closure.elim p t] f' a' :=
  begin
    induction t,
      exact po r,
      constructor,
      exact v_0⁻¹ᵒ,
      exact v_0 ⬝o v_1
  end

  definition ap_e_closure_elimo_h [unfold 12]  {g' : Πb, Q (g b)}
    (p : Π⦃a a' : A⦄, R a a' → f a = f a')
    --(po : Π⦃a a' : A⦄ (s : R a a'), f' a =[p s] f' a')
    (po : Π⦃a a' : A⦄ (s : R a a'), g' (f a) =[p s] g' (f a'))
    (q : Π⦃a a' : A⦄ (s : R a a'), apdo g' (p s) = po s)
    (t : T a a') : apdo g' (e_closure.elim p t) = e_closure.elimo p po t :=
  begin
    induction t,
      apply q,
      reflexivity,
      esimp [e_closure.elim],
      exact apdo_inv g' (e_closure.elim p r) ⬝ v_0⁻²ᵒ,
      exact apdo_con g' (e_closure.elim p r) (e_closure.elim p r') ⬝ (v_0 ◾o v_1)
  end



end
end relation
