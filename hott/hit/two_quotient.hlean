 /-
Copyright (c) 2015 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Authors: Floris van Doorn
-/

import homotopy.circle eq2 algebra.e_closure cubical.squareover cubical.cube cubical.square2

open quotient eq circle sum sigma equiv function relation e_closure

  /-
    This files defines a general class of nonrecursive 2-HITs using just quotients.
    We can define any HIT X which has
    - a single 0-constructor
       f : A → X (for some type A)
    - a single 1-constructor
       e : Π{a a' : A}, R a a' → a = a' (for some (type-valued) relation R on A)
    and furthermore has 2-constructors which are all of the form
    p = p'
    where p, p' are of the form
    - refl (f a), for some a : A;
    - e r, for some r : R a a';
    - ap f q, where q : a = a' :> A;
    - inverses of such paths;
    - concatenations of such paths.

    so an example 2-constructor could be (as long as it typechecks):
      ap f q' ⬝ ((e r)⁻¹ ⬝ ap f q)⁻¹ ⬝ e r' = idp

    We first define "simple two quotients" which have as requirement that the right hand side is idp
    Then we define "two quotients" which can have an arbitrary path on the right hand side
    Then we define "truncated two quotients", which is a two quotient followed by n-truncation,
    and show that this satisfies the desired induction principle and computation rule.

    Caveat: for none of these constructions we show that the induction priniciple computes on
    2-paths. However, with truncated two quotients, if the truncation is a 1-truncation, then this
    computation rule follows automatically, since the target is a 1-type.
  -/

namespace simple_two_quotient

  section
  parameters {A : Type}
             (R : A → A → Type)
  local abbreviation T := e_closure R -- the (type-valued) equivalence closure of R
  parameter  (Q : Π⦃a⦄, T a a → Type)
  variables ⦃a a' : A⦄ {s : R a a'} {r : T a a}


  local abbreviation B := A ⊎ Σ(a : A) (r : T a a), Q r

  inductive pre_two_quotient_rel : B → B → Type :=
  | pre_Rmk {} : Π⦃a a'⦄ (r : R a a'), pre_two_quotient_rel (inl a) (inl a')
  --BUG: if {} not provided, the alias for pre_Rmk is wrong

  definition pre_two_quotient := quotient pre_two_quotient_rel

  open pre_two_quotient_rel
  local abbreviation C := quotient pre_two_quotient_rel
  protected definition j [constructor] (a : A) : C := class_of pre_two_quotient_rel (inl a)
  protected definition pre_aux [constructor] (q : Q r) : C :=
  class_of pre_two_quotient_rel (inr ⟨a, r, q⟩)
  protected definition e (s : R a a') : j a = j a' := eq_of_rel _ (pre_Rmk s)
  protected definition et (t : T a a') : j a = j a' := e_closure.elim e t
  protected definition f [unfold 7] (q : Q r) : S¹ → C :=
  circle.elim (j a) (et r)

  protected definition pre_rec [unfold 8] {P : C → Type}
    (Pj : Πa, P (j a)) (Pa : Π⦃a : A⦄ ⦃r : T a a⦄ (q : Q r), P (pre_aux q))
    (Pe : Π⦃a a' : A⦄ (s : R a a'), Pj a =[e s] Pj a') (x : C) : P x :=
  begin
    induction x with p,
    { induction p,
      { apply Pj},
      { induction a with a1 a2, induction a2, apply Pa}},
    { induction H, esimp, apply Pe},
  end

  protected definition pre_elim [unfold 8] {P : Type} (Pj : A → P)
    (Pa : Π⦃a : A⦄ ⦃r : T a a⦄, Q r → P) (Pe : Π⦃a a' : A⦄ (s : R a a'), Pj a = Pj a') (x : C)
    : P :=
  pre_rec Pj Pa (λa a' s, pathover_of_eq _ (Pe s)) x

  protected theorem rec_e {P : C → Type}
    (Pj : Πa, P (j a)) (Pa : Π⦃a : A⦄ ⦃r : T a a⦄ (q : Q r), P (pre_aux q))
    (Pe : Π⦃a a' : A⦄ (s : R a a'), Pj a =[e s] Pj a') ⦃a a' : A⦄ (s : R a a')
    : apd (pre_rec Pj Pa Pe) (e s) = Pe s :=
  !rec_eq_of_rel

  protected theorem elim_e {P : Type} (Pj : A → P) (Pa : Π⦃a : A⦄ ⦃r : T a a⦄, Q r → P)
    (Pe : Π⦃a a' : A⦄ (s : R a a'), Pj a = Pj a') ⦃a a' : A⦄ (s : R a a')
    : ap (pre_elim Pj Pa Pe) (e s) = Pe s :=
  begin
    apply eq_of_fn_eq_fn_inv !(pathover_constant (e s)),
    rewrite [▸*,-apd_eq_pathover_of_eq_ap,↑pre_elim,rec_e],
  end

  protected definition elim_et {P : Type} (Pj : A → P) (Pa : Π⦃a : A⦄ ⦃r : T a a⦄, Q r → P)
    (Pe : Π⦃a a' : A⦄ (s : R a a'), Pj a = Pj a') ⦃a a' : A⦄ (t : T a a')
    : ap (pre_elim Pj Pa Pe) (et t) = e_closure.elim Pe t :=
  ap_e_closure_elim_h e (elim_e Pj Pa Pe) t

  protected definition rec_et {P : C → Type}
    (Pj : Πa, P (j a)) (Pa : Π⦃a : A⦄ ⦃r : T a a⦄ (q : Q r), P (pre_aux q))
    (Pe : Π⦃a a' : A⦄ (s : R a a'), Pj a =[e s] Pj a') ⦃a a' : A⦄ (t : T a a')
    : apd (pre_rec Pj Pa Pe) (et t) = e_closure.elimo e Pe t :=
  ap_e_closure_elimo_h e Pe (rec_e Pj Pa Pe) t

  inductive simple_two_quotient_rel : C → C → Type :=
  | Rmk {} : Π{a : A} {r : T a a} (q : Q r) (x : circle),
      simple_two_quotient_rel (f q x) (pre_aux q)

  open simple_two_quotient_rel
  definition simple_two_quotient := quotient simple_two_quotient_rel
  local abbreviation D := simple_two_quotient
  local abbreviation i := class_of simple_two_quotient_rel
  definition incl0 (a : A) : D := i (j a)
  protected definition aux (q : Q r) : D := i (pre_aux q)
  definition incl1 (s : R a a') : incl0 a = incl0 a' := ap i (e s)
  definition inclt (t : T a a') : incl0 a = incl0 a' := e_closure.elim incl1 t

  -- "wrong" version inclt, which is ap i (p ⬝ q) instead of ap i p ⬝ ap i q
  -- it is used in the proof, because incltw is easier to work with
  protected definition incltw (t : T a a') : incl0 a = incl0 a' := ap i (et t)

  protected definition inclt_eq_incltw (t : T a a') : inclt t = incltw t :=
  (ap_e_closure_elim i e t)⁻¹

  definition incl2' (q : Q r) (x : S¹) : i (f q x) = aux q :=
  eq_of_rel simple_two_quotient_rel (Rmk q x)

  protected definition incl2w (q : Q r) : incltw r = idp :=
  (ap02 i (elim_loop (j a) (et r))⁻¹) ⬝
  (ap_compose i (f q) loop)⁻¹ ⬝
  ap_is_constant (incl2' q) loop ⬝
  !con.right_inv

  definition incl2 (q : Q r) : inclt r = idp :=
  inclt_eq_incltw r ⬝ incl2w q

  local attribute simple_two_quotient f i D incl0 aux incl1 incl2' inclt [reducible]
  local attribute i aux incl0 [constructor]

  parameters {R Q}
  protected definition rec {P : D → Type} (P0 : Π(a : A), P (incl0 a))
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a =[incl1 s] P0 a')
    (P2 : Π⦃a : A⦄ ⦃r : T a a⦄ (q : Q r),
      change_path (incl2 q) (e_closure.elimo incl1 P1 r) = idpo) (x : D) : P x :=
  begin
    induction x,
    { refine (pre_rec _ _ _ a),
      { exact P0},
      { intro a r q, exact incl2' q base ▸ P0 a},
      { intro a a' s, exact pathover_of_pathover_ap P i (P1 s)}},
    { exact abstract [irreducible] begin induction H, induction x,
      { esimp, exact pathover_tr (incl2' q base) (P0 a)},
      { apply pathover_pathover,
        esimp, fold [i, incl2' q],
        refine eq_hconcato _ _, apply _,
        { transitivity _,
          { apply ap (pathover_ap _ _),
            transitivity _, apply apd_compose2 (pre_rec P0 _ _) (f q) loop,
            apply ap (pathover_of_pathover_ap _ _),
            transitivity _, apply apd_change_path, exact !elim_loop⁻¹,
            transitivity _,
              apply ap (change_path _),
              transitivity _, apply rec_et,
              transitivity (pathover_of_pathover_ap P i (change_path (inclt_eq_incltw r)
                (e_closure.elimo incl1 (λ (a a' : A) (s : R a a'), P1 s) r))),
              apply e_closure_elimo_ap,
              exact idp,
            apply change_path_pathover_of_pathover_ap},
          esimp, transitivity _, apply pathover_ap_pathover_of_pathover_ap P i (f q),
          transitivity _, apply ap (change_path _), apply to_right_inv !pathover_compose,
          do 2 (transitivity _; exact !change_path_con⁻¹),
          transitivity _, apply ap (change_path _),
            exact (to_left_inv (change_path_equiv _ _ (incl2 q)) _)⁻¹, esimp,
          rewrite P2, transitivity _; exact !change_path_con⁻¹, apply ap (λx, change_path x _),
          rewrite [↑incl2, con_inv], transitivity _, exact !con.assoc⁻¹,
          rewrite [inv_con_cancel_right, ↑incl2w, ↑ap02, +con_inv, +ap_inv, +inv_inv, -+con.assoc,
            +con_inv_cancel_right], reflexivity},
        rewrite [change_path_con, apd_constant],
        apply squareover_change_path_left, apply squareover_change_path_right',
        apply squareover_change_path_left,
        refine change_square _ vrflo,
        symmetry, apply inv_ph_eq_of_eq_ph, rewrite [ap_is_constant_natural_square],
        apply whisker_bl_whisker_tl_eq} end end},
  end

  protected definition rec_on [reducible] {P : D → Type} (x : D) (P0 : Π(a : A), P (incl0 a))
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a =[incl1 s] P0 a')
    (P2 : Π⦃a : A⦄ ⦃r : T a a⦄ (q : Q r),
      change_path (incl2 q) (e_closure.elimo incl1 P1 r) = idpo) : P x :=
  rec P0 P1 P2 x

  theorem rec_incl1 {P : D → Type} (P0 : Π(a : A), P (incl0 a))
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a =[incl1 s] P0 a')
    (P2 : Π⦃a : A⦄ ⦃r : T a a⦄ (q : Q r),
      change_path (incl2 q) (e_closure.elimo incl1 P1 r) = idpo) ⦃a a' : A⦄ (s : R a a')
    : apd (rec P0 P1 P2) (incl1 s) = P1 s :=
  begin
    unfold [rec, incl1], refine !apd_ap ⬝ _, esimp, rewrite rec_e,
    apply to_right_inv !pathover_compose
  end

  theorem rec_inclt {P : D → Type} (P0 : Π(a : A), P (incl0 a))
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a =[incl1 s] P0 a')
    (P2 : Π⦃a : A⦄ ⦃r : T a a⦄ (q : Q r),
      change_path (incl2 q) (e_closure.elimo incl1 P1 r) = idpo) ⦃a a' : A⦄ (t : T a a')
    : apd (rec P0 P1 P2) (inclt t) = e_closure.elimo incl1 P1 t :=
  ap_e_closure_elimo_h incl1 P1 (rec_incl1 P0 P1 P2) t

  protected definition elim {P : Type} (P0 : A → P)
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a')
    (P2 : Π⦃a : A⦄ ⦃r : T a a⦄ (q : Q r), e_closure.elim P1 r = idp)
    (x : D) : P :=
  begin
    induction x,
    { refine (pre_elim _ _ _ a),
      { exact P0},
      { intro a r q, exact P0 a},
      { exact P1}},
    { exact abstract begin induction H, induction x,
      { exact idpath (P0 a)},
      { unfold f, apply eq_pathover, apply hdeg_square,
        exact abstract ap_compose (pre_elim P0 _ P1) (f q) loop ⬝
              ap _ !elim_loop ⬝
              !elim_et ⬝
              P2 q ⬝
              !ap_constant⁻¹ end} end end},
  end
  local attribute elim [unfold 8]

  protected definition elim_on {P : Type} (x : D) (P0 : A → P)
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a')
    (P2 : Π⦃a : A⦄ ⦃r : T a a⦄ (q : Q r), e_closure.elim P1 r = idp)
     : P :=
  elim P0 P1 P2 x

  definition elim_incl1 {P : Type} {P0 : A → P}
    {P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a'}
    (P2 : Π⦃a : A⦄ ⦃r : T a a⦄ (q : Q r), e_closure.elim P1 r = idp)
    ⦃a a' : A⦄ (s : R a a') : ap (elim P0 P1 P2) (incl1 s) = P1 s :=
  (ap_compose (elim P0 P1 P2) i (e s))⁻¹ ⬝ !elim_e

  definition elim_inclt {P : Type} {P0 : A → P}
    {P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a'}
    (P2 : Π⦃a : A⦄ ⦃r : T a a⦄ (q : Q r), e_closure.elim P1 r = idp)
    ⦃a a' : A⦄ (t : T a a') : ap (elim P0 P1 P2) (inclt t) = e_closure.elim P1 t :=
  ap_e_closure_elim_h incl1 (elim_incl1 P2) t

  protected definition elim_incltw {P : Type} {P0 : A → P}
    {P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a'}
    (P2 : Π⦃a : A⦄ ⦃r : T a a⦄ (q : Q r), e_closure.elim P1 r = idp)
    ⦃a a' : A⦄ (t : T a a') : ap (elim P0 P1 P2) (incltw t) = e_closure.elim P1 t :=
  (ap_compose (elim P0 P1 P2) i (et t))⁻¹ ⬝ !elim_et

  protected theorem elim_inclt_eq_elim_incltw {P : Type} {P0 : A → P}
    {P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a'}
    (P2 : Π⦃a : A⦄ ⦃r : T a a⦄ (q : Q r), e_closure.elim P1 r = idp)
    ⦃a a' : A⦄ (t : T a a')
    : elim_inclt P2 t = ap (ap (elim P0 P1 P2)) (inclt_eq_incltw t) ⬝ elim_incltw P2 t :=
  begin
    unfold [elim_inclt,elim_incltw,inclt_eq_incltw,et],
    refine !ap_e_closure_elim_h_eq ⬝ _,
    rewrite [ap_inv,-con.assoc],
    xrewrite [eq_of_square (ap_ap_e_closure_elim i (elim P0 P1 P2) e t)⁻¹ʰ],
    rewrite [↓incl1,con.assoc], apply whisker_left,
    rewrite [↑[elim_et,elim_incl1],+ap_e_closure_elim_h_eq,con_inv,↑[i,function.compose]],
    rewrite [-con.assoc (_ ⬝ _),con.assoc _⁻¹,con.left_inv,▸*,-ap_inv,-ap_con],
    apply ap (ap _),
    krewrite [-eq_of_homotopy3_inv,-eq_of_homotopy3_con]
  end

  definition elim_incl2' {P : Type} {P0 : A → P}
    {P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a'}
    (P2 : Π⦃a : A⦄ ⦃r : T a a⦄ (q : Q r), e_closure.elim P1 r = idp)
    ⦃a : A⦄ ⦃r : T a a⦄ (q : Q r) : ap (elim P0 P1 P2) (incl2' q base) = idpath (P0 a) :=
  !elim_eq_of_rel

  local attribute whisker_right [reducible]
  protected theorem elim_incl2w {P : Type} (P0 : A → P)
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a')
    (P2 : Π⦃a : A⦄ ⦃r : T a a⦄ (q : Q r), e_closure.elim P1 r = idp)
    ⦃a : A⦄ ⦃r : T a a⦄ (q : Q r)
    : square (ap02 (elim P0 P1 P2) (incl2w q)) (P2 q) (elim_incltw P2 r) idp :=
  begin
    esimp [incl2w,ap02],
    rewrite [+ap_con (ap _),▸*],
    xrewrite [-ap_compose (ap _) (ap i)],
    rewrite [+ap_inv],
    xrewrite [eq_top_of_square
               ((ap_compose_natural (elim P0 P1 P2) i (elim_loop (j a) (et r)))⁻¹ʰ⁻¹ᵛ ⬝h
               (ap_ap_compose (elim P0 P1 P2) i (f q) loop)⁻¹ʰ⁻¹ᵛ ⬝h
               ap_ap_is_constant (elim P0 P1 P2) (incl2' q) loop ⬝h
               ap_con_right_inv_sq (elim P0 P1 P2) (incl2' q base)),
               ↑[elim_incltw]],
    apply whisker_tl,
    rewrite [ap_is_constant_eq],
    xrewrite [naturality_apd_eq (λx, !elim_eq_of_rel) loop],
    rewrite [↑elim_2,rec_loop,square_of_pathover_concato_eq,square_of_pathover_eq_concato,
            eq_of_square_vconcat_eq,eq_of_square_eq_vconcat],
    apply eq_vconcat,
    { apply ap (λx, _ ⬝ eq_con_inv_of_con_eq ((_ ⬝ x ⬝ _)⁻¹ ⬝ _) ⬝ _),
      transitivity _, apply ap eq_of_square,
        apply to_right_inv !eq_pathover_equiv_square (hdeg_square (elim_1 P A R Q P0 P1 a r q P2)),
      transitivity _, apply eq_of_square_hdeg_square,
      unfold elim_1, reflexivity},
    rewrite [+con_inv,whisker_left_inv,+inv_inv,-whisker_right_inv,
             con.assoc (whisker_left _ _),con.assoc _ (whisker_right _ _),▸*,
             whisker_right_con_whisker_left _ !ap_constant],
    xrewrite [-con.assoc _ _ (whisker_right _ _)],
    rewrite [con.assoc _ _ (whisker_left _ _),idp_con_whisker_left,▸*,
             con.assoc _ !ap_constant⁻¹,con.left_inv],
    xrewrite [eq_con_inv_of_con_eq_whisker_left,▸*],
    rewrite [+con.assoc _ _ !con.right_inv,
             right_inv_eq_idp (
               (λ(x : ap (elim P0 P1 P2) (incl2' q base) = idpath
               (elim P0 P1 P2 (class_of simple_two_quotient_rel (f q base)))), x)
                (elim_incl2' P2 q)),
             ↑[whisker_left]],
    xrewrite [con2_con_con2],
    rewrite [idp_con,↑elim_incl2',con.left_inv,whisker_right_inv,↑whisker_right],
    xrewrite [con.assoc _ _ (_ ◾ _)],
    rewrite [con.left_inv,▸*,-+con.assoc,con.assoc _⁻¹,↑[elim,function.compose],con.left_inv,
             ▸*,↑j,con.left_inv,idp_con],
    apply square_of_eq, reflexivity
  end

  theorem elim_incl2 {P : Type} (P0 : A → P)
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a')
    (P2 : Π⦃a : A⦄ ⦃r : T a a⦄ (q : Q r), e_closure.elim P1 r = idp)
    ⦃a : A⦄ ⦃r : T a a⦄ (q : Q r)
    : square (ap02 (elim P0 P1 P2) (incl2 q)) (P2 q) (elim_inclt P2 r) idp :=
  begin
    rewrite [↑incl2,↑ap02,ap_con,elim_inclt_eq_elim_incltw],
    apply whisker_tl,
    apply elim_incl2w
  end

end
end simple_two_quotient

export [unfold] simple_two_quotient
attribute simple_two_quotient.j simple_two_quotient.incl0 [constructor]
attribute simple_two_quotient.rec simple_two_quotient.elim [unfold 8] [recursor 8]
--attribute simple_two_quotient.elim_type [unfold 9] -- TODO
attribute simple_two_quotient.rec_on simple_two_quotient.elim_on [unfold 5]
--attribute simple_two_quotient.elim_type_on [unfold 6] -- TODO

namespace two_quotient
  open simple_two_quotient
  section
  parameters {A : Type}
             (R : A → A → Type)
  local abbreviation T := e_closure R -- the (type-valued) equivalence closure of R
  parameter  (Q : Π⦃a a'⦄, T a a' → T a a' → Type)
  variables ⦃a a' a'' : A⦄ {s : R a a'} {t t' : T a a'}

  inductive two_quotient_Q : Π⦃a : A⦄, e_closure R a a → Type :=
  | Qmk : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄, Q t t' → two_quotient_Q (t ⬝r t'⁻¹ʳ)
  open two_quotient_Q
  local abbreviation Q2 := two_quotient_Q

  definition two_quotient := simple_two_quotient R Q2
  definition incl0 (a : A) : two_quotient := incl0 _ _ a
  definition incl1 (s : R a a') : incl0 a = incl0 a' := incl1 _ _ s
  definition inclt (t : T a a') : incl0 a = incl0 a' := e_closure.elim incl1 t
  definition incl2 (q : Q t t') : inclt t = inclt t' :=
  eq_of_con_inv_eq_idp (incl2 _ _ (Qmk R q))

  parameters {R Q}
  protected definition rec {P : two_quotient → Type} (P0 : Π(a : A), P (incl0 a))
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a =[incl1 s] P0 a')
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'),
      change_path (incl2 q) (e_closure.elimo incl1 P1 t) = e_closure.elimo incl1 P1 t')
    (x : two_quotient) : P x :=
  begin
    induction x,
    { exact P0 a},
    { exact P1 s},
    { exact abstract [irreducible] begin induction q with a a' t t' q,
      rewrite [elimo_trans (simple_two_quotient.incl1 R Q2) P1,
               elimo_symm (simple_two_quotient.incl1 R Q2) P1,
               -whisker_right_eq_of_con_inv_eq_idp (simple_two_quotient.incl2 R Q2 (Qmk R q)),
               change_path_con],
      xrewrite [change_path_cono],
      refine ap (λx, change_path _ (_ ⬝o x)) !change_path_invo ⬝ _, esimp,
      apply cono_invo_eq_idpo, apply P2 end end}
  end

  protected definition rec_on [reducible] {P : two_quotient → Type} (x : two_quotient)
    (P0 : Π(a : A), P (incl0 a))
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a =[incl1 s] P0 a')
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'),
      change_path (incl2 q) (e_closure.elimo incl1 P1 t) = e_closure.elimo incl1 P1 t') : P x :=
  rec P0 P1 P2 x

  theorem rec_incl1 {P : two_quotient → Type} (P0 : Π(a : A), P (incl0 a))
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a =[incl1 s] P0 a')
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'),
      change_path (incl2 q) (e_closure.elimo incl1 P1 t) = e_closure.elimo incl1 P1 t')
    ⦃a a' : A⦄ (s : R a a') : apd (rec P0 P1 P2) (incl1 s) = P1 s :=
  rec_incl1 _ _ _ s

  theorem rec_inclt {P : two_quotient → Type} (P0 : Π(a : A), P (incl0 a))
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a =[incl1 s] P0 a')
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'),
      change_path (incl2 q) (e_closure.elimo incl1 P1 t) = e_closure.elimo incl1 P1 t')
    ⦃a a' : A⦄ (t : T a a') : apd (rec P0 P1 P2) (inclt t) = e_closure.elimo incl1 P1 t :=
  rec_inclt _ _ _ t

  protected definition elim {P : Type} (P0 : A → P)
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a')
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'), e_closure.elim P1 t = e_closure.elim P1 t')
    (x : two_quotient) : P :=
  begin
    induction x,
    { exact P0 a},
    { exact P1 s},
    { exact abstract [unfold 10] begin induction q with a a' t t' q,
      esimp [e_closure.elim],
      apply con_inv_eq_idp, exact P2 q end end},
  end
  local attribute elim [unfold 8]

  protected definition elim_on {P : Type} (x : two_quotient) (P0 : A → P)
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a')
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'), e_closure.elim P1 t = e_closure.elim P1 t')
     : P :=
  elim P0 P1 P2 x

  definition elim_incl1 {P : Type} {P0 : A → P}
    {P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a'}
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'), e_closure.elim P1 t = e_closure.elim P1 t')
    ⦃a a' : A⦄ (s : R a a') : ap (elim P0 P1 P2) (incl1 s) = P1 s :=
  !elim_incl1

  definition elim_inclt {P : Type} {P0 : A → P}
    {P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a'}
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'), e_closure.elim P1 t = e_closure.elim P1 t')
    ⦃a a' : A⦄ (t : T a a') : ap (elim P0 P1 P2) (inclt t) = e_closure.elim P1 t :=
  ap_e_closure_elim_h incl1 (elim_incl1 P2) t

  theorem elim_incl2 {P : Type} (P0 : A → P)
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a')
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'), e_closure.elim P1 t = e_closure.elim P1 t')
    ⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t')
    : square (ap02 (elim P0 P1 P2) (incl2 q)) (P2 q) (elim_inclt P2 t) (elim_inclt P2 t') :=
  begin
    rewrite [↑[incl2,elim],ap_eq_of_con_inv_eq_idp],
    xrewrite [eq_top_of_square (elim_incl2 P0 P1 (elim_1 A R Q P P0 P1 P2) (Qmk R q))],
    xrewrite [{simple_two_quotient.elim_inclt (elim_1 A R Q P P0 P1 P2)
           (t ⬝r t'⁻¹ʳ)}
      idpath (ap_con (simple_two_quotient.elim P0 P1 (elim_1 A R Q P P0 P1 P2))
                     (inclt t) (inclt t')⁻¹ ⬝
             (simple_two_quotient.elim_inclt (elim_1 A R Q P P0 P1 P2) t ◾
             (ap_inv (simple_two_quotient.elim P0 P1 (elim_1 A R Q P P0 P1 P2))
                     (inclt t') ⬝
             inverse2 (simple_two_quotient.elim_inclt (elim_1 A R Q P P0 P1 P2) t')))),▸*],
    rewrite [-con.assoc _ _ (con_inv_eq_idp _),-con.assoc _ _ (_ ◾ _),con.assoc _ _ (ap_con _ _ _),
             con.left_inv,↑whisker_left,con2_con_con2,-con.assoc (ap_inv _ _)⁻¹,
             con.left_inv,+idp_con,eq_of_con_inv_eq_idp_con2],
    xrewrite [to_left_inv !eq_equiv_con_inv_eq_idp (P2 q)],
    apply top_deg_square
  end

  definition elim_inclt_rel [unfold_full] {P : Type} {P0 : A → P}
    {P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a'}
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'), e_closure.elim P1 t = e_closure.elim P1 t')
    ⦃a a' : A⦄ (r : R a a') : elim_inclt P2 [r] = elim_incl1 P2 r :=
  idp

  definition elim_inclt_inv [unfold_full] {P : Type} {P0 : A → P}
    {P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a'}
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'), e_closure.elim P1 t = e_closure.elim P1 t')
    ⦃a a' : A⦄ (t : T a a')
    : elim_inclt P2 t⁻¹ʳ = ap_inv (elim P0 P1 P2) (inclt t) ⬝ (elim_inclt P2 t)⁻² :=
  idp

  definition elim_inclt_con [unfold_full] {P : Type} {P0 : A → P}
    {P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a'}
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'), e_closure.elim P1 t = e_closure.elim P1 t')
    ⦃a a' a'' : A⦄ (t : T a a') (t': T a' a'')
    : elim_inclt P2 (t ⬝r t') =
        ap_con (elim P0 P1 P2) (inclt t) (inclt t') ⬝ (elim_inclt P2 t ◾ elim_inclt P2 t') :=
  idp

  definition inclt_rel [unfold_full] (r : R a a') : inclt [r] = incl1 r := idp
  definition inclt_inv [unfold_full] (t : T a a') : inclt t⁻¹ʳ = (inclt t)⁻¹ := idp
  definition inclt_con [unfold_full] (t : T a a') (t' : T a' a'')
    : inclt (t ⬝r t') = inclt t ⬝ inclt t' := idp
end
end two_quotient

attribute two_quotient.incl0 [constructor]
attribute two_quotient.rec two_quotient.elim [unfold 8] [recursor 8]
--attribute two_quotient.elim_type [unfold 9]
attribute two_quotient.rec_on two_quotient.elim_on [unfold 5]
--attribute two_quotient.elim_type_on [unfold 6]

open two_quotient is_trunc trunc

namespace trunc_two_quotient

  section
  parameters (n : ℕ₋₂) {A : Type}
             (R : A → A → Type)
  local abbreviation T := e_closure R -- the (type-valued) equivalence closure of R
  parameter (Q : Π⦃a a'⦄, T a a' → T a a' → Type)
  variables ⦃a a' a'' : A⦄ {s : R a a'} {t t' : T a a'}

  definition trunc_two_quotient := trunc n (two_quotient R Q)

  parameters {n R Q}
  definition incl0 (a : A) : trunc_two_quotient := tr (!incl0 a)
  definition incl1 (s : R a a') : incl0 a = incl0 a' := ap tr (!incl1 s)
  definition incltw (t : T a a') : incl0 a = incl0 a' := ap tr (!inclt t)
  definition inclt (t : T a a') : incl0 a = incl0 a' := e_closure.elim incl1 t
  definition incl2w (q : Q t t') : incltw t = incltw t' :=
  ap02 tr (!incl2 q)
  definition incl2 (q : Q t t') : inclt t = inclt t' :=
  !ap_e_closure_elim⁻¹ ⬝ ap02 tr (!incl2 q) ⬝ !ap_e_closure_elim

  local attribute trunc_two_quotient incl0 [reducible]
  definition is_trunc_trunc_two_quotient [instance] : is_trunc n trunc_two_quotient := _

  protected definition rec {P : trunc_two_quotient → Type} [H : Πx, is_trunc n (P x)]
    (P0 : Π(a : A), P (incl0 a))
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a =[incl1 s] P0 a')
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'),
      change_path (incl2 q) (e_closure.elimo incl1 P1 t) = e_closure.elimo incl1 P1 t')
    (x : trunc_two_quotient) : P x :=
  begin
    induction x,
    induction a,
    { exact P0 a},
    { exact !pathover_of_pathover_ap (P1 s)},
    { exact abstract [irreducible]
      by rewrite [+ e_closure_elimo_ap, ↓incl1, -P2 q, change_path_pathover_of_pathover_ap,
                  - + change_path_con, ↑incl2, con_inv_cancel_right] end}
  end

  protected definition rec_on [reducible] {P : trunc_two_quotient → Type} [H : Πx, is_trunc n (P x)]
    (x : trunc_two_quotient)
    (P0 : Π(a : A), P (incl0 a))
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a =[incl1 s] P0 a')
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'),
      change_path (incl2 q) (e_closure.elimo incl1 P1 t) = e_closure.elimo incl1 P1 t') : P x :=
  rec P0 P1 P2 x

  theorem rec_incl1 {P : trunc_two_quotient → Type} [H : Πx, is_trunc n (P x)]
    (P0 : Π(a : A), P (incl0 a))
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a =[incl1 s] P0 a')
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'),
      change_path (incl2 q) (e_closure.elimo incl1 P1 t) = e_closure.elimo incl1 P1 t')
    ⦃a a' : A⦄ (s : R a a') : apd (rec P0 P1 P2) (incl1 s) = P1 s :=
  !apd_ap ⬝ ap !pathover_ap !rec_incl1 ⬝ to_right_inv !pathover_compose (P1 s)

  theorem rec_inclt {P : trunc_two_quotient → Type} [H : Πx, is_trunc n (P x)]
    (P0 : Π(a : A), P (incl0 a))
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a =[incl1 s] P0 a')
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'),
      change_path (incl2 q) (e_closure.elimo incl1 P1 t) = e_closure.elimo incl1 P1 t')
    ⦃a a' : A⦄ (t : T a a') : apd (rec P0 P1 P2) (inclt t) = e_closure.elimo incl1 P1 t :=
  ap_e_closure_elimo_h incl1 P1 (rec_incl1 P0 P1 P2) t

  protected definition elim {P : Type} (P0 : A → P) [H : is_trunc n P]
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a')
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'), e_closure.elim P1 t = e_closure.elim P1 t')
    (x : trunc_two_quotient) : P :=
  begin
    induction x,
    induction a,
    { exact P0 a},
    { exact P1 s},
    { exact P2 q},
  end
  local attribute elim [unfold 10]

  protected definition elim_on {P : Type} [H : is_trunc n P] (x : trunc_two_quotient) (P0 : A → P)
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a')
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'), e_closure.elim P1 t = e_closure.elim P1 t')
     : P :=
  elim P0 P1 P2 x

  definition elim_incl1 {P : Type} [H : is_trunc n P] {P0 : A → P}
    {P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a'}
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'), e_closure.elim P1 t = e_closure.elim P1 t')
    ⦃a a' : A⦄ (s : R a a') : ap (elim P0 P1 P2) (incl1 s) = P1 s :=
  !ap_compose⁻¹ ⬝ !elim_incl1

  definition elim_inclt {P : Type} [H : is_trunc n P] {P0 : A → P}
    {P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a'}
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'), e_closure.elim P1 t = e_closure.elim P1 t')
    ⦃a a' : A⦄ (t : T a a') : ap (elim P0 P1 P2) (inclt t) = e_closure.elim P1 t :=
  ap_e_closure_elim_h incl1 (elim_incl1 P2) t

  open function

  theorem elim_incl2 {P : Type} [H : is_trunc n P] (P0 : A → P)
    (P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a')
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'), e_closure.elim P1 t = e_closure.elim P1 t')
    ⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t')
    : square (ap02 (elim P0 P1 P2) (incl2 q)) (P2 q) (elim_inclt P2 t) (elim_inclt P2 t') :=
  begin
    note Ht' := ap_ap_e_closure_elim tr (elim P0 P1 P2) (two_quotient.incl1 R Q) t',
    note Ht := ap_ap_e_closure_elim tr (elim P0 P1 P2) (two_quotient.incl1 R Q) t,
    note Hn := natural_square_tr (ap_compose (elim P0 P1 P2) tr) (two_quotient.incl2 R Q q),
    note H7 := eq_top_of_square (Ht⁻¹ʰ ⬝h Hn⁻¹ᵛ ⬝h Ht'), clear [Hn, Ht, Ht'],
    unfold [ap02,incl2], rewrite [+ap_con,ap_inv,-ap_compose (ap _)],
    xrewrite [H7, ↑function.compose, eq_top_of_square (elim_incl2 P0 P1 P2 q)], clear [H7],
    have H : Π(t : T a a'),
      ap_e_closure_elim (elim P0 P1 P2) (λa a' (r : R a a'), ap tr (two_quotient.incl1 R Q r)) t ⬝
      (ap_e_closure_elim_h (two_quotient.incl1 R Q)
        (λa a' (s : R a a'), ap_compose (elim P0 P1 P2) tr (two_quotient.incl1 R Q s)) t)⁻¹ ⬝
      two_quotient.elim_inclt P2 t = elim_inclt P2 t, from
        ap_e_closure_elim_h_zigzag (elim P0 P1 P2)
                                   (two_quotient.incl1 R Q)
                                   (two_quotient.elim_incl1 P2),
    rewrite [con.assoc5, con.assoc5, H t, -inv_con_inv_right, -con_inv], xrewrite [H t'],
    apply top_deg_square
  end

  definition elim_inclt_rel [unfold_full] {P : Type} [is_trunc n P] {P0 : A → P}
    {P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a'}
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'), e_closure.elim P1 t = e_closure.elim P1 t')
    ⦃a a' : A⦄ (r : R a a') : elim_inclt P2 [r] = elim_incl1 P2 r :=
  idp

  definition elim_inclt_inv [unfold_full] {P : Type} [is_trunc n P] {P0 : A → P}
    {P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a'}
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'), e_closure.elim P1 t = e_closure.elim P1 t')
    ⦃a a' : A⦄ (t : T a a')
    : elim_inclt P2 t⁻¹ʳ = ap_inv (elim P0 P1 P2) (inclt t) ⬝ (elim_inclt P2 t)⁻² :=
  idp

  definition elim_inclt_con [unfold_full] {P : Type} [is_trunc n P] {P0 : A → P}
    {P1 : Π⦃a a' : A⦄ (s : R a a'), P0 a = P0 a'}
    (P2 : Π⦃a a' : A⦄ ⦃t t' : T a a'⦄ (q : Q t t'), e_closure.elim P1 t = e_closure.elim P1 t')
    ⦃a a' a'' : A⦄ (t : T a a') (t': T a' a'')
    : elim_inclt P2 (t ⬝r t') =
        ap_con (elim P0 P1 P2) (inclt t) (inclt t') ⬝ (elim_inclt P2 t ◾ elim_inclt P2 t') :=
  idp

  definition inclt_rel [unfold_full] (r : R a a') : inclt [r] = incl1 r := idp
  definition inclt_inv [unfold_full] (t : T a a') : inclt t⁻¹ʳ = (inclt t)⁻¹ := idp
  definition inclt_con [unfold_full] (t : T a a') (t' : T a' a'')
    : inclt (t ⬝r t') = inclt t ⬝ inclt t' := idp


end
end trunc_two_quotient

attribute trunc_two_quotient.incl0 [constructor]
attribute trunc_two_quotient.rec trunc_two_quotient.elim [unfold 10] [recursor 10]
attribute trunc_two_quotient.rec_on trunc_two_quotient.elim_on [unfold 7]
