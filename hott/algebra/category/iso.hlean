/-
Copyright (c) 2015 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Floris van Doorn, Jakob von Raumer
-/

import .precategory types.sigma arity

open eq category prod equiv is_equiv sigma sigma.ops is_trunc

namespace iso
  structure split_mono [class] {ob : Type} [C : precategory ob] {a b : ob} (f : a ⟶ b) :=
    {retraction_of : b ⟶ a}
    (retraction_comp : retraction_of ∘ f = id)
  structure split_epi [class] {ob : Type} [C : precategory ob] {a b : ob} (f : a ⟶ b) :=
    {section_of : b ⟶ a}
    (comp_section : f ∘ section_of = id)
  structure is_iso [class] {ob : Type} [C : precategory ob] {a b : ob} (f : a ⟶ b) :=
    (inverse : b ⟶ a)
    (left_inverse  : inverse ∘ f = id)
    (right_inverse : f ∘ inverse = id)

  attribute is_iso.inverse [quasireducible]

  attribute is_iso [multiple_instances]
  open split_mono split_epi is_iso
  abbreviation retraction_of [unfold 6] := @split_mono.retraction_of
  abbreviation retraction_comp [unfold 6] := @split_mono.retraction_comp
  abbreviation section_of [unfold 6] := @split_epi.section_of
  abbreviation comp_section [unfold 6] := @split_epi.comp_section
  abbreviation inverse [unfold 6] := @is_iso.inverse
  abbreviation left_inverse [unfold 6] := @is_iso.left_inverse
  abbreviation right_inverse [unfold 6] := @is_iso.right_inverse
  postfix ⁻¹ := inverse
  --a second notation for the inverse, which is not overloaded
  postfix [parsing_only] `⁻¹ʰ`:std.prec.max_plus := inverse -- input using \-1h

  variables {ob : Type} [C : precategory ob]
  variables {a b c : ob} {g : b ⟶ c} {f : a ⟶ b} {h : b ⟶ a}
  include C

  definition split_mono_of_is_iso [constructor] [instance] [priority 300] [reducible]
    (f : a ⟶ b) [H : is_iso f] : split_mono f :=
  split_mono.mk !left_inverse

  definition split_epi_of_is_iso [constructor] [instance] [priority 300] [reducible]
    (f : a ⟶ b) [H : is_iso f] : split_epi f :=
  split_epi.mk !right_inverse

  definition is_iso_id [constructor] [instance] [priority 500] (a : ob) : is_iso (ID a) :=
  is_iso.mk _ !id_id !id_id

  definition is_iso_inverse [constructor] [instance] [priority 200] (f : a ⟶ b) {H : is_iso f}
    : is_iso f⁻¹ :=
  is_iso.mk _ !right_inverse !left_inverse

  theorem left_inverse_eq_right_inverse {f : a ⟶ b} {g g' : hom b a}
      (Hl : g ∘ f = id) (Hr : f ∘ g' = id) : g = g' :=
  by rewrite [-(id_right g), -Hr, assoc, Hl, id_left]

  theorem retraction_eq [H : split_mono f] (H2 : f ∘ h = id) : retraction_of f = h :=
  left_inverse_eq_right_inverse !retraction_comp H2

  theorem section_eq [H : split_epi f] (H2 : h ∘ f = id) : section_of f = h :=
  (left_inverse_eq_right_inverse H2 !comp_section)⁻¹

  theorem inverse_eq_right [H : is_iso f] (H2 : f ∘ h = id) : f⁻¹ = h :=
  left_inverse_eq_right_inverse !left_inverse H2

  theorem inverse_eq_left [H : is_iso f] (H2 : h ∘ f = id) : f⁻¹ = h :=
  (left_inverse_eq_right_inverse H2 !right_inverse)⁻¹

  theorem retraction_eq_section (f : a ⟶ b) [Hl : split_mono f] [Hr : split_epi f] :
      retraction_of f = section_of f :=
  retraction_eq !comp_section

  definition is_iso_of_split_epi_of_split_mono [constructor] (f : a ⟶ b)
    [Hl : split_mono f] [Hr : split_epi f] : is_iso f :=
  is_iso.mk _ ((retraction_eq_section f) ▸ (retraction_comp f)) (comp_section f)

  theorem inverse_unique (H H' : is_iso f) : @inverse _ _ _ _ f H = @inverse _ _ _ _ f H' :=
  inverse_eq_left !left_inverse

  theorem inverse_involutive (f : a ⟶ b) [H : is_iso f] [H : is_iso (f⁻¹)]
    : (f⁻¹)⁻¹ = f :=
  inverse_eq_right !left_inverse

  theorem inverse_eq_inverse {f g : a ⟶ b} [H : is_iso f] [H : is_iso g] (p : f = g)
    : f⁻¹ = g⁻¹ :=
  by cases p;apply inverse_unique

  theorem retraction_id (a : ob) : retraction_of (ID a) = id :=
  retraction_eq !id_id

  theorem section_id (a : ob) : section_of (ID a) = id :=
  section_eq !id_id

  theorem id_inverse (a : ob) [H : is_iso (ID a)] : (ID a)⁻¹ = id :=
  inverse_eq_left !id_id

  definition split_mono_comp [constructor] [instance] [priority 150] (g : b ⟶ c) (f : a ⟶ b)
    [Hf : split_mono f] [Hg : split_mono g] : split_mono (g ∘ f) :=
  split_mono.mk
    (show (retraction_of f ∘ retraction_of g) ∘ g ∘ f = id,
     by rewrite [-assoc, assoc _ g f, retraction_comp, id_left, retraction_comp])

  definition split_epi_comp [constructor] [instance] [priority 150] (g : b ⟶ c) (f : a ⟶ b)
    [Hf : split_epi f] [Hg : split_epi g] : split_epi (g ∘ f) :=
  split_epi.mk
    (show (g ∘ f) ∘ section_of f ∘ section_of g = id,
     by rewrite [-assoc, {f ∘ _}assoc, comp_section, id_left, comp_section])

  definition is_iso_comp [constructor] [instance] [priority 150] (g : b ⟶ c) (f : a ⟶ b)
    [Hf : is_iso f] [Hg : is_iso g] : is_iso (g ∘ f) :=
  !is_iso_of_split_epi_of_split_mono

  theorem is_hprop_is_iso [instance] (f : hom a b) : is_hprop (is_iso f) :=
  begin
    apply is_hprop.mk, intro H H',
    cases H with g li ri, cases H' with g' li' ri',
    fapply (apd0111 (@is_iso.mk ob C a b f)),
      apply left_inverse_eq_right_inverse,
        apply li,
        apply ri',
      apply is_hprop.elim,
      apply is_hprop.elim,
  end
end iso open iso

/- isomorphic objects -/
structure iso {ob : Type} [C : precategory ob] (a b : ob) :=
  (to_hom : hom a b)
  (struct : is_iso to_hom)

  infix ` ≅ `:50 := iso
  notation c ` ≅[`:50 C:0 `] `:0 c':50 := @iso C _ c c'
  attribute iso.struct [instance] [priority 2000]

namespace iso
  variables {ob : Type} [C : precategory ob]
  variables {a b c : ob} {g : b ⟶ c} {f : a ⟶ b} {h : b ⟶ a}
  include C

  attribute to_hom [coercion]

  protected definition MK [constructor] (f : a ⟶ b) (g : b ⟶ a)
    (H1 : g ∘ f = id) (H2 : f ∘ g = id) :=
  @(mk f) (is_iso.mk _ H1 H2)

  variable {C}
  definition to_inv [reducible] [unfold 5] (f : a ≅ b) : b ⟶ a := (to_hom f)⁻¹
  definition to_left_inverse  [unfold 5] (f : a ≅ b) : (to_hom f)⁻¹ ∘ (to_hom f) = id :=
  left_inverse  (to_hom f)
  definition to_right_inverse [unfold 5] (f : a ≅ b) : (to_hom f) ∘ (to_hom f)⁻¹ = id :=
  right_inverse (to_hom f)

  variable [C]
  protected definition refl [constructor] (a : ob) : a ≅ a :=
  mk (ID a) _

  protected definition symm [constructor] ⦃a b : ob⦄ (H : a ≅ b) : b ≅ a :=
  mk (to_hom H)⁻¹ _

  protected definition trans [constructor] ⦃a b c : ob⦄ (H1 : a ≅ b) (H2 : b ≅ c) : a ≅ c :=
  mk (to_hom H2 ∘ to_hom H1) _

  infixl ` ⬝i `:75 := iso.trans
  postfix [parsing_only] `⁻¹ⁱ`:(max + 1) := iso.symm

  definition change_hom [constructor] (H : a ≅ b) (f : a ⟶ b) (p : to_hom H = f) : a ≅ b :=
  iso.MK f (to_inv H) (p ▸ to_left_inverse H) (p ▸ to_right_inverse H)

  definition change_inv [constructor] (H : a ≅ b) (g : b ⟶ a) (p : to_inv H = g) : a ≅ b :=
  iso.MK (to_hom H) g (p ▸ to_left_inverse H) (p ▸ to_right_inverse H)

  definition iso_mk_eq {f f' : a ⟶ b} [H : is_iso f] [H' : is_iso f'] (p : f = f')
      : iso.mk f _ = iso.mk f' _ :=
  apd011 iso.mk p !is_hprop.elim

  variable {C}
  definition iso_eq {f f' : a ≅ b} (p : to_hom f = to_hom f') : f = f' :=
  by (cases f; cases f'; apply (iso_mk_eq p))
  variable [C]

  -- The structure for isomorphism can be characterized up to equivalence by a sigma type.
  protected definition sigma_char ⦃a b : ob⦄ : (Σ (f : hom a b), is_iso f) ≃ (a ≅ b) :=
  begin
    fapply (equiv.mk),
      {intro S, apply iso.mk, apply (S.2)},
      {fapply adjointify,
        {intro p, cases p with f H, exact sigma.mk f H},
        {intro p, cases p, apply idp},
        {intro S, cases S, apply idp}},
  end

  -- The type of isomorphisms between two objects is a set
  definition is_hset_iso [instance] : is_hset (a ≅ b) :=
  begin
    apply is_trunc_is_equiv_closed,
      apply equiv.to_is_equiv (!iso.sigma_char),
  end

  definition iso_of_eq [unfold 5] (p : a = b) : a ≅ b :=
  eq.rec_on p (iso.refl a)

  definition hom_of_eq [reducible] [unfold 5] (p : a = b) : a ⟶ b :=
  iso.to_hom (iso_of_eq p)

  definition inv_of_eq [reducible] [unfold 5] (p : a = b) : b ⟶ a :=
  iso.to_inv (iso_of_eq p)

  definition iso_of_eq_inv (p : a = b) : iso_of_eq p⁻¹ = iso.symm (iso_of_eq p) :=
  eq.rec_on p idp

  theorem hom_of_eq_inv (p : a = b) : hom_of_eq p⁻¹ = inv_of_eq p :=
  eq.rec_on p idp

  theorem inv_of_eq_inv (p : a = b) : inv_of_eq p⁻¹ = hom_of_eq p :=
  eq.rec_on p idp

  definition iso_of_eq_con (p : a = b) (q : b = c)
    : iso_of_eq (p ⬝ q) = iso.trans (iso_of_eq p) (iso_of_eq q) :=
  eq.rec_on q (eq.rec_on p (iso_eq !id_id⁻¹))

  section
    open funext
    variables {X : Type} {x y : X} {F G : X → ob}
    definition transport_hom_of_eq (p : F = G) (f : hom (F x) (F y))
      : p ▸ f = hom_of_eq (apd10 p y) ∘ f ∘ inv_of_eq (apd10 p x) :=
    by induction p; exact !id_leftright⁻¹

    definition transport_hom_of_eq_right (p : x = y) (f : hom c (F x))
      : p ▸ f = hom_of_eq (ap F p) ∘ f :=
    by induction p; exact !id_left⁻¹

    definition transport_hom_of_eq_left (p : x = y) (f : hom (F x) c)
      : p ▸ f = f ∘ inv_of_eq (ap F p) :=
    by induction p; exact !id_right⁻¹

    definition transport_hom (p : F ~ G) (f : hom (F x) (F y))
      : eq_of_homotopy p ▸ f = hom_of_eq (p y) ∘ f ∘ inv_of_eq (p x) :=
    calc
      eq_of_homotopy p ▸ f =
        hom_of_eq (apd10 (eq_of_homotopy p) y) ∘ f ∘ inv_of_eq (apd10 (eq_of_homotopy p) x)
          : transport_hom_of_eq
        ... = hom_of_eq (p y) ∘ f ∘ inv_of_eq (p x) : {right_inv apd10 p}
  end

  structure mono [class] (f : a ⟶ b) :=
    (elim : ∀c (g h : hom c a), f ∘ g = f ∘ h → g = h)
  structure epi  [class] (f : a ⟶ b) :=
    (elim : ∀c (g h : hom b c), g ∘ f = h ∘ f → g = h)

  definition mono_of_split_mono [instance] (f : a ⟶ b) [H : split_mono f] : mono f :=
  mono.mk
    (λ c g h H,
      calc
        g = id ∘ g                    : by rewrite id_left
      ... = (retraction_of f ∘ f) ∘ g : by rewrite retraction_comp
      ... = (retraction_of f ∘ f) ∘ h : by rewrite [-assoc, H, -assoc]
      ... = id ∘ h                    : by rewrite retraction_comp
      ... = h                         : by rewrite id_left)

  definition epi_of_split_epi [instance] (f : a ⟶ b) [H : split_epi f] : epi f :=
  epi.mk
    (λ c g h H,
      calc
        g = g ∘ id               : by rewrite id_right
      ... = g ∘ f ∘ section_of f : by rewrite -(comp_section f)
      ... = h ∘ f ∘ section_of f : by rewrite [assoc, H, -assoc]
      ... = h ∘ id               : by rewrite comp_section
      ... = h                    : by rewrite id_right)

  definition mono_comp [instance] (g : b ⟶ c) (f : a ⟶ b) [Hf : mono f] [Hg : mono g]
    : mono (g ∘ f) :=
  mono.mk
    (λ d h₁ h₂ H,
    have H2 : g ∘ (f ∘ h₁) = g ∘ (f ∘ h₂),
    begin
      rewrite *assoc, exact H
    end,
    !mono.elim (!mono.elim H2))

  definition epi_comp  [instance] (g : b ⟶ c) (f : a ⟶ b) [Hf : epi f] [Hg : epi g]
    : epi  (g ∘ f) :=
  epi.mk
    (λ d h₁ h₂ H,
    have H2 : (h₁ ∘ g) ∘ f = (h₂ ∘ g) ∘ f,
    begin
      rewrite -*assoc, exact H
    end,
    !epi.elim (!epi.elim H2))

end iso

attribute iso.refl [refl]
attribute iso.symm [symm]
attribute iso.trans [trans]

namespace iso
  /-
  rewrite lemmas for inverses, modified from
  https://github.com/JasonGross/HoTT-categories/blob/master/theories/Categories/Category/Morphisms.v
  -/
  section
  variables {ob : Type} [C : precategory ob] include C
  variables {a b c d : ob}                         (f : b ⟶ a)
                           (r : c ⟶ d) (q : b ⟶ c) (p : a ⟶ b)
                           (g : d ⟶ c)
  variable [Hq : is_iso q] include Hq
  theorem comp.right_inverse : q ∘ q⁻¹ = id := !right_inverse
  theorem comp.left_inverse : q⁻¹ ∘ q = id := !left_inverse

  theorem inverse_comp_cancel_left : q⁻¹ ∘ (q ∘ p) = p :=
   by rewrite [assoc, left_inverse, id_left]
  theorem comp_inverse_cancel_left : q ∘ (q⁻¹ ∘ g) = g :=
   by rewrite [assoc, right_inverse, id_left]
  theorem comp_inverse_cancel_right : (r ∘ q) ∘ q⁻¹ = r :=
  by rewrite [-assoc, right_inverse, id_right]
  theorem inverse_comp_cancel_right : (f ∘ q⁻¹) ∘ q = f :=
  by rewrite [-assoc, left_inverse, id_right]

  theorem comp_inverse [Hp : is_iso p] [Hpq : is_iso (q ∘ p)] : (q ∘ p)⁻¹ʰ = p⁻¹ʰ ∘ q⁻¹ʰ :=
  inverse_eq_left
    (show (p⁻¹ʰ ∘ q⁻¹ʰ) ∘ q ∘ p = id, from
     by rewrite [-assoc, inverse_comp_cancel_left, left_inverse])

  theorem inverse_comp_inverse_left [H' : is_iso g] : (q⁻¹ ∘ g)⁻¹ = g⁻¹ ∘ q :=
  inverse_involutive q ▸ comp_inverse q⁻¹ g

  theorem inverse_comp_inverse_right [H' : is_iso f] : (q ∘ f⁻¹)⁻¹ = f ∘ q⁻¹ :=
  inverse_involutive f ▸ comp_inverse q f⁻¹

  theorem inverse_comp_inverse_inverse [H' : is_iso r] : (q⁻¹ ∘ r⁻¹)⁻¹ = r ∘ q :=
  inverse_involutive r ▸ inverse_comp_inverse_left q r⁻¹
  end

  section
  variables {ob : Type} {C : precategory ob} include C
  variables {d           c           b           a : ob}
             {r' : c ⟶ d} {i : b ⟶ c} {f : b ⟶ a}
              {r : c ⟶ d} {q : b ⟶ c} {p : a ⟶ b}
              {g : d ⟶ c} {h : c ⟶ b} {p' : a ⟶ b}
                   {x : b ⟶ d} {z : a ⟶ c}
                   {y : d ⟶ b} {w : c ⟶ a}
  variable [Hq : is_iso q] include Hq

  theorem comp_eq_of_eq_inverse_comp (H : y = q⁻¹ ∘ g) : q ∘ y = g :=
  H⁻¹ ▸ comp_inverse_cancel_left q g
  theorem comp_eq_of_eq_comp_inverse (H : w = f ∘ q⁻¹) : w ∘ q = f :=
  H⁻¹ ▸ inverse_comp_cancel_right f q
  theorem eq_comp_of_inverse_comp_eq (H : q⁻¹ ∘ g = y) : g = q ∘ y :=
  (comp_eq_of_eq_inverse_comp H⁻¹)⁻¹
  theorem eq_comp_of_comp_inverse_eq (H : f ∘ q⁻¹ = w) : f = w ∘ q :=
  (comp_eq_of_eq_comp_inverse H⁻¹)⁻¹
  variable {Hq}
  theorem inverse_comp_eq_of_eq_comp (H : z = q ∘ p) : q⁻¹ ∘ z = p :=
  H⁻¹ ▸ inverse_comp_cancel_left q p
  theorem comp_inverse_eq_of_eq_comp (H : x = r ∘ q) : x ∘ q⁻¹ = r :=
  H⁻¹ ▸ comp_inverse_cancel_right r q
  theorem eq_inverse_comp_of_comp_eq (H : q ∘ p = z) : p = q⁻¹ ∘ z :=
  (inverse_comp_eq_of_eq_comp H⁻¹)⁻¹
  theorem eq_comp_inverse_of_comp_eq (H : r ∘ q = x) : r = x ∘ q⁻¹ :=
  (comp_inverse_eq_of_eq_comp H⁻¹)⁻¹

  theorem eq_inverse_of_comp_eq_id' (H : h ∘ q = id) : h = q⁻¹ := (inverse_eq_left H)⁻¹
  theorem eq_inverse_of_comp_eq_id (H : q ∘ h = id) : h = q⁻¹ := (inverse_eq_right H)⁻¹
  theorem inverse_eq_of_id_eq_comp (H : id = h ∘ q) : q⁻¹ = h :=
  (eq_inverse_of_comp_eq_id' H⁻¹)⁻¹
  theorem inverse_eq_of_id_eq_comp' (H : id = q ∘ h) : q⁻¹ = h :=
  (eq_inverse_of_comp_eq_id H⁻¹)⁻¹
  variable [Hq]
  theorem eq_of_comp_inverse_eq_id (H : i ∘ q⁻¹ = id) : i = q :=
  eq_inverse_of_comp_eq_id' H ⬝ inverse_involutive q
  theorem eq_of_inverse_comp_eq_id (H : q⁻¹ ∘ i = id) : i = q :=
  eq_inverse_of_comp_eq_id H ⬝ inverse_involutive q
  theorem eq_of_id_eq_comp_inverse (H : id = i ∘ q⁻¹) : q = i := (eq_of_comp_inverse_eq_id H⁻¹)⁻¹
  theorem eq_of_id_eq_inverse_comp (H : id = q⁻¹ ∘ i) : q = i := (eq_of_inverse_comp_eq_id H⁻¹)⁻¹

  variables (q)
  theorem comp.cancel_left  (H : q ∘ p = q ∘ p') : p = p' :=
  by rewrite [-inverse_comp_cancel_left q, H, inverse_comp_cancel_left q]
  theorem comp.cancel_right (H : r ∘ q = r' ∘ q) : r = r' :=
  by rewrite [-comp_inverse_cancel_right _ q, H, comp_inverse_cancel_right _ q]
  end
end iso
