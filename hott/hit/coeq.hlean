/-
Copyright (c) 2015 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Floris van Doorn

Declaration of the coequalizer
-/

import .quotient_functor types.equiv

open quotient eq equiv equiv.ops is_trunc sigma sigma.ops

namespace coeq
section

universe u
parameters {A B : Type.{u}} (f g : A → B)

  inductive coeq_rel : B → B → Type :=
  | Rmk : Π(x : A), coeq_rel (f x) (g x)
  open coeq_rel
  local abbreviation R := coeq_rel

  definition coeq : Type := quotient coeq_rel -- TODO: define this in root namespace

  definition coeq_i (x : B) : coeq :=
  class_of R x

  /- cp is the name Coq uses. I don't know what it abbreviates, but at least it's short :-) -/
  definition cp (x : A) : coeq_i (f x) = coeq_i (g x) :=
  eq_of_rel coeq_rel (Rmk f g x)

  protected definition rec {P : coeq → Type} (P_i : Π(x : B), P (coeq_i x))
    (Pcp : Π(x : A), P_i (f x) =[cp x] P_i (g x)) (y : coeq) : P y :=
  begin
    induction y,
    { apply P_i},
    { cases H, apply Pcp}
  end

  protected definition rec_on [reducible] {P : coeq → Type} (y : coeq)
    (P_i : Π(x : B), P (coeq_i x)) (Pcp : Π(x : A), P_i (f x) =[cp x] P_i (g x)) : P y :=
  rec P_i Pcp y

  theorem rec_cp {P : coeq → Type} (P_i : Π(x : B), P (coeq_i x))
    (Pcp : Π(x : A), P_i (f x) =[cp x] P_i (g x))
      (x : A) : apdo (rec P_i Pcp) (cp x) = Pcp x :=
  !rec_eq_of_rel

  protected definition elim {P : Type} (P_i : B → P)
    (Pcp : Π(x : A), P_i (f x) = P_i (g x)) (y : coeq) : P :=
  rec P_i (λx, pathover_of_eq (Pcp x)) y

  protected definition elim_on [reducible] {P : Type} (y : coeq) (P_i : B → P)
    (Pcp : Π(x : A), P_i (f x) = P_i (g x)) : P :=
  elim P_i Pcp y

  theorem elim_cp {P : Type} (P_i : B → P) (Pcp : Π(x : A), P_i (f x) = P_i (g x))
    (x : A) : ap (elim P_i Pcp) (cp x) = Pcp x :=
  begin
    apply eq_of_fn_eq_fn_inv !(pathover_constant (cp x)),
    rewrite [▸*,-apdo_eq_pathover_of_eq_ap,↑elim,rec_cp],
  end

  protected definition elim_type (P_i : B → Type)
    (Pcp : Π(x : A), P_i (f x) ≃ P_i (g x)) (y : coeq) : Type :=
  elim P_i (λx, ua (Pcp x)) y

  protected definition elim_type_on [reducible] (y : coeq) (P_i : B → Type)
    (Pcp : Π(x : A), P_i (f x) ≃ P_i (g x)) : Type :=
  elim_type P_i Pcp y

  theorem elim_type_cp (P_i : B → Type) (Pcp : Π(x : A), P_i (f x) ≃ P_i (g x))
    (x : A) : transport (elim_type P_i Pcp) (cp x) = Pcp x :=
  by rewrite [tr_eq_cast_ap_fn,↑elim_type,elim_cp];apply cast_ua_fn

  protected definition rec_hprop {P : coeq → Type} [H : Πx, is_prop (P x)]
    (P_i : Π(x : B), P (coeq_i x)) (y : coeq) : P y :=
  rec P_i (λa, !is_prop.elimo) y

  protected definition elim_hprop {P : Type} [H : is_prop P] (P_i : B → P) (y : coeq) : P :=
  elim P_i (λa, !is_prop.elim) y

end

end coeq

attribute coeq.coeq_i [constructor]
attribute coeq.rec coeq.elim [unfold 8] [recursor 8]
attribute coeq.elim_type [unfold 7]
attribute coeq.rec_on coeq.elim_on [unfold 6]
attribute coeq.elim_type_on [unfold 5]

/- Flattening -/
namespace coeq
section
  open function

  universe u
  parameters {A B : Type.{u}} (f g : A → B) (P_i : B → Type)
             (Pcp : Πx : A, P_i (f x) ≃ P_i (g x))

  local abbreviation P := coeq.elim_type f g P_i Pcp

  local abbreviation F : sigma (P_i ∘ f) → sigma P_i :=
  λz, ⟨f z.1, z.2⟩

  local abbreviation G : sigma (P_i ∘ f) → sigma P_i :=
  λz, ⟨g z.1, Pcp z.1 z.2⟩

  local abbreviation Pr : Π⦃b b' : B⦄,
    coeq_rel f g b b' → P_i b ≃ P_i b' :=
  @coeq_rel.rec A B f g _ Pcp

  local abbreviation P' := quotient.elim_type P_i Pr

  protected definition flattening : sigma P ≃ coeq F G :=
  begin
    assert H : Πz, P z ≃ P' z,
    { intro z, apply equiv_of_eq,
      assert H1 : coeq.elim_type f g P_i Pcp = quotient.elim_type P_i Pr,
      { change
    quotient.rec P_i
      (λb b' r, coeq_rel.cases_on r (λx, pathover_of_eq (ua (Pcp x))))
  = quotient.rec P_i
      (λb b' r, pathover_of_eq (ua (coeq_rel.cases_on r Pcp))),
        assert H2 : Π⦃b b' : B⦄ (r : coeq_rel f g b b'),
    coeq_rel.cases_on r (λx, pathover_of_eq (ua (Pcp x)))
  = pathover_of_eq (ua (coeq_rel.cases_on r Pcp))
    :> P_i b =[eq_of_rel (coeq_rel f g) r] P_i b',
        { intros b b' r, cases r, reflexivity },
       rewrite (eq_of_homotopy3 H2) },
      apply ap10 H1 },
    apply equiv.trans (sigma_equiv_sigma_id H),
    apply equiv.trans !quotient.flattening.flattening_lemma,
    fapply quotient.equiv,
    { reflexivity },
    { intros bp bp',
      fapply equiv.MK,
      { intro r, induction r with b b' r p,
        induction r with x, exact coeq_rel.Rmk F G ⟨x, p⟩ },
      { esimp, intro r, induction r with xp,
        induction xp with x p,
        exact quotient.flattening.flattening_rel.mk Pr
          (coeq_rel.Rmk f g x) p },
      { esimp, intro r, induction r with xp,
        induction xp with x p, reflexivity },
      { intro r, induction r with b b' r p,
        induction r with x, reflexivity } }
  end
end
end coeq
