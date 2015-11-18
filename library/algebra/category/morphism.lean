/-
Copyright (c) 2014 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Floris van Doorn
-/

import .basic algebra.relation algebra.binary

open eq eq.ops category

namespace morphism
  variables {ob : Type} [C : category ob] include C
  variables {a b c : ob} {g : b ⟶ c} {f : a ⟶ b} {h : b ⟶ a}
  inductive is_section    [class] (f : a ⟶ b) : Type
  := mk : ∀{g}, g ∘ f = id → is_section f
  inductive is_retraction [class] (f : a ⟶ b) : Type
  := mk : ∀{g}, f ∘ g = id → is_retraction f
  inductive is_iso        [class] (f : a ⟶ b) : Type
  := mk : ∀{g}, g ∘ f = id → f ∘ g = id → is_iso f

  attribute is_iso [multiple_instances]

  definition retraction_of (f : a ⟶ b) [H : is_section f] : hom b a :=
  is_section.rec (λg h, g) H
  definition section_of    (f : a ⟶ b) [H : is_retraction f] : hom b a :=
  is_retraction.rec (λg h, g) H
  definition inverse       (f : a ⟶ b) [H : is_iso f] : hom b a :=
  is_iso.rec (λg h1 h2, g) H

  postfix `⁻¹` := inverse

  theorem inverse_compose (f : a ⟶ b) [H : is_iso f] : f⁻¹ ∘ f = id :=
  is_iso.rec (λg h1 h2, h1) H

  theorem compose_inverse (f : a ⟶ b) [H : is_iso f] : f ∘ f⁻¹ = id :=
  is_iso.rec (λg h1 h2, h2) H

  theorem retraction_compose (f : a ⟶ b) [H : is_section f] : retraction_of f ∘ f = id :=
  is_section.rec (λg h, h) H

  theorem compose_section (f : a ⟶ b) [H : is_retraction f] : f ∘ section_of f = id :=
  is_retraction.rec (λg h, h) H

  theorem iso_imp_retraction [instance] (f : a ⟶ b) [H : is_iso f] : is_section f :=
  is_section.mk !inverse_compose

  theorem iso_imp_section [instance] (f : a ⟶ b) [H : is_iso f] : is_retraction f :=
  is_retraction.mk !compose_inverse

  theorem id_is_iso [instance] : is_iso (ID a) :=
  is_iso.mk !id_compose !id_compose

  theorem inverse_is_iso [instance] (f : a ⟶ b) [H : is_iso f] : is_iso (f⁻¹) :=
  is_iso.mk !compose_inverse !inverse_compose

  theorem left_inverse_eq_right_inverse {f : a ⟶ b} {g g' : hom b a}
      (Hl : g ∘ f = id) (Hr : f ∘ g' = id) : g = g' :=
  calc
      g = g ∘ id        : by rewrite id_right
    ... = g ∘ f ∘ g'    : by rewrite -Hr
    ... = (g ∘ f) ∘ g'  : by rewrite assoc
    ... = id ∘ g'       : by rewrite Hl
    ... = g'            : by rewrite id_left

  theorem retraction_eq_intro [H : is_section f] (H2 : f ∘ h = id) : retraction_of f = h :=
  left_inverse_eq_right_inverse !retraction_compose H2

  theorem section_eq_intro [H : is_retraction f] (H2 : h ∘ f = id) : section_of f = h :=
  symm (left_inverse_eq_right_inverse H2 !compose_section)

  theorem inverse_eq_intro_right [H : is_iso f] (H2 : f ∘ h = id) : f⁻¹ = h :=
  left_inverse_eq_right_inverse !inverse_compose H2

  theorem inverse_eq_intro_left [H : is_iso f] (H2 : h ∘ f = id) : f⁻¹ = h :=
  symm (left_inverse_eq_right_inverse H2 !compose_inverse)

  theorem section_eq_retraction (f : a ⟶ b) [Hl : is_section f] [Hr : is_retraction f] :
      retraction_of f = section_of f :=
  retraction_eq_intro !compose_section

  theorem section_retraction_imp_iso (f : a ⟶ b) [Hl : is_section f] [Hr : is_retraction f]
      : is_iso f :=
  is_iso.mk (subst (section_eq_retraction f) (retraction_compose f)) (compose_section f)

  theorem inverse_unique (H H' : is_iso f) : @inverse _ _ _ _ f H = @inverse _ _ _ _ f H' :=
  inverse_eq_intro_left !inverse_compose

  theorem inverse_involutive (f : a ⟶ b) [H : is_iso f] : (f⁻¹)⁻¹ = f :=
  inverse_eq_intro_right !inverse_compose

  theorem retraction_of_id : retraction_of (ID a) = id :=
  retraction_eq_intro !id_compose

  theorem section_of_id : section_of (ID a) = id :=
  section_eq_intro !id_compose

  theorem iso_of_id : (ID a)⁻¹ = id :=
  inverse_eq_intro_left !id_compose

  theorem composition_is_section [instance] [Hf : is_section f] [Hg : is_section g]
      : is_section (g ∘ f) :=
  is_section.mk
    (calc
      (retraction_of f ∘ retraction_of g) ∘ g ∘ f
            = retraction_of f ∘ retraction_of g ∘ g ∘ f   : by rewrite -assoc
        ... = retraction_of f ∘ (retraction_of g ∘ g) ∘ f : by rewrite (assoc _ g f)
        ... = retraction_of f ∘ id ∘ f                    : by rewrite retraction_compose
        ... = retraction_of f ∘ f                         : by rewrite id_left
        ... = id                                          : by rewrite retraction_compose)

  theorem composition_is_retraction [instance] [Hf : is_retraction f] [Hg : is_retraction g]
      : is_retraction (g ∘ f) :=
  is_retraction.mk
    (calc
      (g ∘ f) ∘ section_of f ∘ section_of g
            = g ∘ f ∘ section_of f ∘ section_of g   : by rewrite -assoc
        ... = g ∘ (f ∘ section_of f) ∘ section_of g : by rewrite -assoc
        ... = g ∘ id ∘ section_of g                 : by rewrite compose_section
        ... = g ∘ section_of g                      : by rewrite id_left
        ... = id                                    : by rewrite compose_section)

  theorem composition_is_inverse [instance] [Hf : is_iso f] [Hg : is_iso g] : is_iso (g ∘ f) :=
  !section_retraction_imp_iso

  structure isomorphic (a b : ob) :=
    (iso : a ⟶ b)
    [is_iso : is_iso iso]

  infix `≅`:50 := morphism.isomorphic

  namespace isomorphic
  open relation
  attribute is_iso [instance]

  theorem refl  (a     : ob)                           : a ≅ a := mk id
  theorem symm  ⦃a b   : ob⦄ (H  : a ≅ b)              : b ≅ a := mk (inverse (iso H))
  theorem trans ⦃a b c : ob⦄ (H1 : a ≅ b) (H2 : b ≅ c) : a ≅ c := mk (iso H2 ∘ iso H1)

  theorem is_equivalence_eq [instance] (T : Type) : is_equivalence (isomorphic : ob → ob → Type) :=
  is_equivalence.mk refl symm trans
  end isomorphic

  inductive is_mono [class] (f : a ⟶ b) : Prop :=
  mk : (∀c (g h : hom c a), f ∘ g = f ∘ h → g = h) → is_mono f
  inductive is_epi  [class] (f : a ⟶ b) : Prop :=
  mk : (∀c (g h : hom b c), g ∘ f = h ∘ f → g = h) → is_epi f

  theorem mono_elim [H : is_mono f] {g h : c ⟶ a} (H2 : f ∘ g = f ∘ h) : g = h :=
  match H with
    is_mono.mk H3 := H3 c g h H2
  end

  theorem epi_elim [H : is_epi f] {g h : b ⟶ c} (H2 : g ∘ f = h ∘ f) : g = h :=
  match H with
    is_epi.mk H3 := H3 c g h H2
  end

  theorem section_is_mono [instance] (f : a ⟶ b) [H : is_section f] : is_mono f :=
  is_mono.mk
    (λ c g h H, calc
        g = id ∘ g                    : by rewrite id_left
      ... = (retraction_of f ∘ f) ∘ g : by rewrite -(retraction_compose f)
      ... = (retraction_of f ∘ f) ∘ h : by rewrite [-assoc, H, -assoc]
      ... = id ∘ h                    : by rewrite retraction_compose
      ... = h                         : by rewrite id_left)

  theorem retraction_is_epi [instance] (f : a ⟶ b) [H : is_retraction f] : is_epi f :=
  is_epi.mk
    (λ c g h H, calc
        g = g ∘ id                 : by rewrite id_right
      ... = g ∘ f ∘ section_of f   : by rewrite -(compose_section f)
      ... = h ∘ f ∘ section_of f   : by rewrite [assoc, H, -assoc]
      ... = h ∘ id                 : by rewrite compose_section
      ... = h                      : by rewrite id_right)

  --these theorems are now proven automatically using type classes
  --should they be instances?
  theorem id_is_mono : is_mono (ID a)
  theorem id_is_epi  : is_epi  (ID a)

  theorem composition_is_mono [instance] [Hf : is_mono f] [Hg : is_mono g] : is_mono (g ∘ f) :=
  is_mono.mk
    (λ d h₁ h₂ H,
      have H2 : g ∘ (f ∘ h₁) = g ∘ (f ∘ h₂),
      begin
        rewrite *assoc, exact H
      end,
      mono_elim (mono_elim H2))

  theorem composition_is_epi  [instance] [Hf : is_epi f] [Hg : is_epi g] : is_epi  (g ∘ f) :=
  is_epi.mk
    (λ d h₁ h₂ H,
      have H2 : (h₁ ∘ g) ∘ f = (h₂ ∘ g) ∘ f,
      begin
        rewrite -*assoc, exact H
      end,
      epi_elim (epi_elim H2))
end morphism
namespace morphism
--rewrite lemmas for inverses, modified from
--https://github.com/JasonGross/HoTT-categories/blob/master/theories/Categories/Category/Morphisms.v
  namespace iso
  section
  variables {ob : Type} [C : category ob] include C
  variables {a b c d : ob}
  variables (f : b ⟶ a) (r : c ⟶ d) (q : b ⟶ c) (p : a ⟶ b)
  variables (g : d ⟶ c)

  variable [Hq : is_iso q] include Hq
  theorem compose_pV : q ∘ q⁻¹ = id := !compose_inverse
  theorem compose_Vp : q⁻¹ ∘ q = id := !inverse_compose
  theorem compose_V_pp : q⁻¹ ∘ (q ∘ p) = p :=
  calc
    q⁻¹ ∘ (q ∘ p) = (q⁻¹ ∘ q) ∘ p : by rewrite assoc
              ... = id ∘ p        : by rewrite inverse_compose
              ... = p             : by rewrite id_left

  theorem compose_p_Vp : q ∘ (q⁻¹ ∘ g) = g :=
  calc
     q ∘ (q⁻¹ ∘ g)  = (q ∘ q⁻¹) ∘ g : by rewrite assoc
                ... = id ∘ g        : by rewrite compose_inverse
                ... = g             : by rewrite id_left

  theorem compose_pp_V : (r ∘ q) ∘ q⁻¹ = r :=
  calc
    (r ∘ q) ∘ q⁻¹ = r ∘ q ∘ q⁻¹ : by rewrite assoc
      ... = r ∘ id              : by rewrite compose_inverse
      ... = r                   : by rewrite id_right

  theorem compose_pV_p : (f ∘ q⁻¹) ∘ q = f :=
  calc
    (f ∘ q⁻¹) ∘ q = f ∘ q⁻¹ ∘ q : by rewrite assoc
              ... = f ∘ id      : by rewrite inverse_compose
              ... = f           : by rewrite id_right

  theorem inv_pp [H' : is_iso p] : (q ∘ p)⁻¹ = p⁻¹ ∘ q⁻¹ :=
  inverse_eq_intro_left
    (show (p⁻¹ ∘ (q⁻¹)) ∘ q ∘ p = id, from
     by rewrite [-assoc, compose_V_pp, inverse_compose])

  theorem inv_Vp [H' : is_iso g] : (q⁻¹ ∘ g)⁻¹ = g⁻¹ ∘ q := inverse_involutive q ▸ inv_pp (q⁻¹) g
  theorem inv_pV [H' : is_iso f] : (q ∘ f⁻¹)⁻¹ = f ∘ q⁻¹ := inverse_involutive f ▸ inv_pp q (f⁻¹)
  theorem inv_VV [H' : is_iso r] : (q⁻¹ ∘ r⁻¹)⁻¹ = r ∘ q := inverse_involutive r ▸ inv_Vp q (r⁻¹)
  end
  section
  variables {ob : Type} {C : category ob} include C
  variables {d c b a : ob}
  variables {i : b ⟶ c} {f : b ⟶ a}
            {r : c ⟶ d} {q : b ⟶ c} {p : a ⟶ b}
            {g : d ⟶ c} {h : c ⟶ b}
            {x : b ⟶ d} {z : a ⟶ c}
            {y : d ⟶ b} {w : c ⟶ a}
  variable [Hq : is_iso q] include Hq

  theorem moveR_Mp (H : y = q⁻¹ ∘ g) : q ∘ y = g := H⁻¹ ▸ compose_p_Vp q g
  theorem moveR_pM (H : w = f ∘ q⁻¹) : w ∘ q = f := H⁻¹ ▸ compose_pV_p f q
  theorem moveR_Vp (H : z = q ∘ p) : q⁻¹ ∘ z = p := H⁻¹ ▸ compose_V_pp q p
  theorem moveR_pV (H : x = r ∘ q) : x ∘ q⁻¹ = r := H⁻¹ ▸ compose_pp_V r q
  theorem moveL_Mp (H : q⁻¹ ∘ g = y) : g = q ∘ y := (moveR_Mp (H⁻¹))⁻¹
  theorem moveL_pM (H : f ∘ q⁻¹ = w) : f = w ∘ q := (moveR_pM (H⁻¹))⁻¹
  theorem moveL_Vp (H : q ∘ p = z) : p = q⁻¹ ∘ z := (moveR_Vp (H⁻¹))⁻¹
  theorem moveL_pV (H : r ∘ q = x) : r = x ∘ q⁻¹ := (moveR_pV (H⁻¹))⁻¹
  theorem moveL_1V (H : h ∘ q = id) : h = q⁻¹ := (inverse_eq_intro_left H)⁻¹
  theorem moveL_V1 (H : q ∘ h = id) : h = q⁻¹ := (inverse_eq_intro_right H)⁻¹
  theorem moveL_1M (H : i ∘ q⁻¹ = id) : i = q := moveL_1V H ⬝ inverse_involutive q
  theorem moveL_M1 (H : q⁻¹ ∘ i = id) : i = q := moveL_V1 H ⬝ inverse_involutive q
  theorem moveR_1M (H : id = i ∘ q⁻¹) : q = i := (moveL_1M (H⁻¹))⁻¹
  theorem moveR_M1 (H : id = q⁻¹ ∘ i) : q = i := (moveL_M1 (H⁻¹))⁻¹
  theorem moveR_1V (H : id = h ∘ q) : q⁻¹ = h := (moveL_1V (H⁻¹))⁻¹
  theorem moveR_V1 (H : id = q ∘ h) : q⁻¹ = h := (moveL_V1 (H⁻¹))⁻¹
  end
  end iso

end morphism
