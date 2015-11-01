-- Copyright (c) 2014 Floris van Doorn. All rights reserved.
-- Released under Apache 2.0 license as described in the file LICENSE.
-- Author: Floris van Doorn

-- This file contains basic constructions on categories, including common categories


import .natural_transformation
import data.unit data.sigma data.prod data.empty data.bool

open eq eq.ops prod
namespace category
  namespace opposite
  section
  definition opposite [reducible] {ob : Type} (C : category ob) : category ob :=
  mk (λa b, hom b a)
     (λ a b c f g, g ∘ f)
     (λ a, id)
     (λ a b c d f g h, symm !assoc)
     (λ a b f, !id_right)
     (λ a b f, !id_left)

  definition Opposite [reducible] (C : Category) : Category := Mk (opposite C)
  --direct construction:
  -- MK C
  --    (λa b, hom b a)
  --    (λ a b c f g, g ∘ f)
  --    (λ a, id)
  --    (λ a b c d f g h, symm !assoc)
  --    (λ a b f, !id_right)
  --    (λ a b f, !id_left)

  infixr `∘op`:60 := @@compose _ (opposite _) _ _ _

  variables {C : Category} {a b c : C}

  theorem compose_op {f : hom a b} {g : hom b c} : f ∘op g = g ∘ f := rfl

  theorem op_op' {ob : Type} (C : category ob) : opposite (opposite C) = C :=
  category.rec (λ hom comp id assoc idl idr, refl (mk _ _ _ _ _ _)) C

  definition op_op : Opposite (Opposite C) = C :=
  (@@congr_arg _ _ (@@opposite C (@@opposite C C)) _ (Category.mk C) (op_op' C)) ⬝ !Category.equal

  end
  end opposite

  definition type_category [reducible] : category Type :=
  mk (λa b, a → b)
     (λ a b c, function.compose)
     (λ a, function.id)
     (λ a b c d h g f, symm (function.compose.assoc h g f))
     (λ a b f, function.compose.left_id f)
     (λ a b f, function.compose.right_id f)

  definition Type_category [reducible] : Category := Mk type_category

  section
  open decidable unit empty
  variables {A : Type} [H : decidable_eq A]
  include H
  definition set_hom [reducible] (a b : A) := decidable.rec_on (H a b) (λh, unit) (λh, empty)
  theorem set_hom_subsingleton [instance] (a b : A) : subsingleton (set_hom a b) := rec_subsingleton
  definition set_compose [reducible] {a b c : A} (g : set_hom b c) (f : set_hom a b) : set_hom a c :=
  decidable.rec_on
    (H b c)
    (λ Hbc g, decidable.rec_on
      (H a b)
      (λ Hab f, rec_on_true (trans Hab Hbc) ⋆)
      (λh f, empty.rec _ f) f)
    (λh (g : empty), empty.rec _ g) g
  omit H
  definition discrete_category (A : Type) [H : decidable_eq A] : category A :=
  mk (λa b, set_hom a b)
     (λ a b c g f, set_compose g f)
     (λ a, decidable.rec_on_true rfl ⋆)
     (λ a b c d h g f, @@subsingleton.elim (set_hom a d) _ _ _)
     (λ a b f, @@subsingleton.elim (set_hom a b) _ _ _)
     (λ a b f, @@subsingleton.elim (set_hom a b) _ _ _)
  local attribute discrete_category [reducible]
  definition Discrete_category (A : Type) [H : decidable_eq A] := Mk (discrete_category A)
    section
    local attribute discrete_category [instance]
    include H
    theorem discrete_category.endomorphism {a b : A} (f : a ⟶ b) : a = b :=
    decidable.rec_on (H a b) (λh f, h) (λh f, empty.rec _ f) f

    theorem discrete_category.discrete {a b : A} (f : a ⟶ b)
      : eq.rec_on (discrete_category.endomorphism f) f = (ID b) :=
    @@subsingleton.elim _ !set_hom_subsingleton _ _

    definition discrete_category.rec_on {P : Πa b, a ⟶ b → Type} {a b : A} (f : a ⟶ b)
        (H : ∀a, P a a id) : P a b f :=
    cast (dcongr_arg3 P rfl (discrete_category.endomorphism f)⁻¹
                            (@@subsingleton.elim _ !set_hom_subsingleton _ _))⁻¹ (H a)
    end
  end
  section
  open unit bool
  definition category_one := discrete_category unit
  definition Category_one := Mk category_one
  definition category_two := discrete_category bool
  definition Category_two := Mk category_two
  end

  namespace product
    section
    open prod
    definition prod_category [reducible] {obC obD : Type} (C : category obC) (D : category obD)
        : category (obC × obD) :=
    mk (λa b, hom (pr1 a) (pr1 b) × hom (pr2 a) (pr2 b))
       (λ a b c g f, (pr1 g ∘ pr1 f , pr2 g ∘ pr2 f) )
       (λ a, (id,id))
       (λ a b c d h g f, pair_eq !assoc    !assoc   )
       (λ a b f,         prod.eq !id_left  !id_left )
       (λ a b f,         prod.eq !id_right !id_right)

    definition Prod_category [reducible] (C D : Category) : Category := Mk (prod_category C D)
    end
  end product

  namespace ops
    notation `type`:max := Type_category
    postfix `ᵒᵖ`:max := opposite.Opposite
    infixr `×c`:30 := product.Prod_category
    attribute type_category [instance]
    attribute category_one [instance]
    attribute category_two [instance]
    attribute product.prod_category [instance]
  end ops

  open ops
  namespace opposite
  section
  open functor
  definition opposite_functor [reducible] {C D : Category} (F : C ⇒ D) : Cᵒᵖ ⇒ Dᵒᵖ :=
  @@functor.mk (Cᵒᵖ) (Dᵒᵖ)
              (λ a, F a)
              (λ a b f, F f)
              (λ a, respect_id F a)
              (λ a b c g f, by apply @@respect_comp C D)
  end
  end opposite

  namespace product
  section
  open ops functor
  definition prod_functor [reducible] {C C' D D' : Category} (F : C ⇒ D) (G : C' ⇒ D')
      : C ×c C' ⇒ D ×c D' :=
  functor.mk (λ a, pair (F (pr1 a)) (G (pr2 a)))
             (λ a b f, pair (F (pr1 f)) (G (pr2 f)))
             (λ a, pair_eq !respect_id !respect_id)
             (λ a b c g f, pair_eq !respect_comp !respect_comp)
  end
  end product

  namespace ops
  infixr `×f`:30 := product.prod_functor
  infixr `ᵒᵖᶠ`:max := opposite.opposite_functor
  end ops

  section functor_category
  variables (C D : Category)
  definition functor_category : category (functor C D) :=
  mk (λa b, natural_transformation a b)
     (λ a b c g f, natural_transformation.compose g f)
     (λ a, natural_transformation.id)
     (λ a b c d h g f, !natural_transformation.assoc)
     (λ a b f, !natural_transformation.id_left)
     (λ a b f, !natural_transformation.id_right)
  end functor_category

  namespace slice
  open sigma function
  variables {ob : Type} {C : category ob} {c : ob}
  protected definition slice_obs (C : category ob) (c : ob) := Σ(b : ob), hom b c
  variables {a b : slice.slice_obs C c}
  protected definition to_ob  (a : slice.slice_obs C c) : ob              := sigma.pr1 a
  protected definition to_ob_def (a : slice.slice_obs C c) : slice.to_ob a = sigma.pr1 a := rfl
  protected definition ob_hom (a : slice.slice_obs C c) : hom (slice.to_ob a) c := sigma.pr2 a
  -- protected theorem slice_obs_equal (H₁ : to_ob a = to_ob b)
  --     (H₂ : eq.drec_on H₁ (ob_hom a) = ob_hom b) : a = b :=
  -- sigma.equal H₁ H₂


  protected definition slice_hom (a b : slice.slice_obs C c) : Type :=
  Σ(g : hom (slice.to_ob a) (slice.to_ob b)), slice.ob_hom b ∘ g = slice.ob_hom a

  protected definition hom_hom  (f : slice.slice_hom a b) : hom (slice.to_ob a) (slice.to_ob b)                := sigma.pr1 f
  protected definition commute (f : slice.slice_hom a b) : slice.ob_hom b ∘ (slice.hom_hom f) = slice.ob_hom a := sigma.pr2 f
  -- protected theorem slice_hom_equal (f g : slice_hom a b) (H : hom_hom f = hom_hom g) : f = g :=
  -- sigma.equal H !proof_irrel

  definition slice_category (C : category ob) (c : ob) : category (slice.slice_obs C c) :=
  mk (λa b, slice.slice_hom a b)
     (λ a b c g f, sigma.mk (slice.hom_hom g ∘ slice.hom_hom f)
       (show slice.ob_hom c ∘ (slice.hom_hom g ∘ slice.hom_hom f) = slice.ob_hom a,
         proof
         calc
           slice.ob_hom c ∘ (slice.hom_hom g ∘ slice.hom_hom f) = (slice.ob_hom c ∘ slice.hom_hom g) ∘ slice.hom_hom f : !assoc
             ... = slice.ob_hom b ∘ slice.hom_hom f : {slice.commute g}
             ... = slice.ob_hom a : {slice.commute f}
         qed))
     (λ a, sigma.mk id !id_right)
     (λ a b c d h g f, dpair_eq !assoc    !proof_irrel)
     (λ a b f,         sigma.eq !id_left  !proof_irrel)
     (λ a b f,         sigma.eq !id_right !proof_irrel)
  -- We use !proof_irrel instead of rfl, to give the unifier an easier time

  -- definition slice_category {ob : Type} (C : category ob) (c : ob) : category (Σ(b : ob), hom b c)
  -- :=
  -- mk (λa b, Σ(g : hom (dpr1 a) (dpr1 b)), dpr2 b ∘ g = dpr2 a)
  --    (λ a b c g f, dpair (dpr1 g ∘ dpr1 f)
  --      (show dpr2 c ∘ (dpr1 g ∘ dpr1 f) = dpr2 a,
  --        proof
  --        calc
  --          dpr2 c ∘ (dpr1 g ∘ dpr1 f) = (dpr2 c ∘ dpr1 g) ∘ dpr1 f : !assoc
  --            ... = dpr2 b ∘ dpr1 f : {dpr2 g}
  --            ... = dpr2 a : {dpr2 f}
  --        qed))
  --    (λ a, dpair id !id_right)
  --    (λ a b c d h g f, dpair_eq    !assoc    !proof_irrel)
  --    (λ a b f,         sigma.equal !id_left  !proof_irrel)
  --    (λ a b f,         sigma.equal !id_right !proof_irrel)
  -- We use !proof_irrel instead of rfl, to give the unifier an easier time

  definition Slice_category [reducible] (C : Category) (c : C) := Mk (slice_category C c)
  open category.ops
  attribute slice_category [instance]
  variables {D : Category}
  definition forgetful (x : D) : (Slice_category D x) ⇒ D :=
  functor.mk (λ a, slice.to_ob a)
             (λ a b f, slice.hom_hom f)
             (λ a, rfl)
             (λ a b c g f, rfl)

  definition postcomposition_functor {x y : D} (h : x ⟶ y)
      : Slice_category D x ⇒ Slice_category D y :=
  functor.mk
       (λ a, sigma.mk (slice.to_ob a) (h ∘ slice.ob_hom a))
       (λ a b f,
         ⟨slice.hom_hom f,
          calc
            (h ∘ slice.ob_hom b) ∘ slice.hom_hom f = h ∘ (slice.ob_hom b ∘ slice.hom_hom f) : by rewrite assoc
                                   ... = h ∘ slice.ob_hom a               : by rewrite slice.commute⟩)
       (λ a, rfl)
       (λ a b c g f, dpair_eq rfl !proof_irrel)

  -- -- in the following comment I tried to have (A = B) in the type of a == b, but that doesn't solve the problems
  -- definition heq2 {A B : Type} (H : A = B) (a : A) (b : B) := a == b
  -- definition heq2.intro {A B : Type} {a : A} {b : B} (H : a == b) : heq2 (heq.type_eq H) a b := H
  -- definition heq2.elim {A B : Type} {a : A} {b : B} (H : A = B) (H2 : heq2 H a b) : a == b := H2
  -- definition heq2.proof_irrel {A B : Prop} (a : A) (b : B) (H : A = B) : heq2 H a b :=
  -- hproof_irrel H a b
  -- theorem functor.mk_eq2 {C D : Category} {obF obG : C → D} {homF homG idF idG compF compG}
  --    (Hob : ∀x, obF x = obG x)
  --    (Hmor : ∀(a b : C) (f : a ⟶ b), heq2 (congr_arg (λ x, x a ⟶ x b) (funext Hob)) (homF a b f) (homG a b f))
  --      : functor.mk obF homF idF compF = functor.mk obG homG idG compG :=
  -- hddcongr_arg4 functor.mk
  --             (funext Hob)
  --             (hfunext (λ a, hfunext (λ b, hfunext (λ f, !Hmor))))
  --             !proof_irrel
  --             !proof_irrel

--  set_option pp.implicit true
--  set_option pp.coercions true

  -- definition slice_functor : D ⇒ Category_of_categories :=
  -- functor.mk (λ a, Category.mk (slice_obs D a) (slice_category D a))
  --            (λ a b f, postcomposition_functor f)
  --            (λ a, functor.mk_heq
  --              (λx, sigma.equal rfl !id_left)
  --              (λb c f, sigma.hequal sorry !heq.refl (hproof_irrel sorry _ _)))
  --            (λ a b c g f, functor.mk_heq
  --                    (λx, sigma.equal (sorry ⬝ refl (dpr1 x)) sorry)
  --                    (λb c f, sorry))

  --the error message generated here is really confusing: the type of the above refl should be
  -- "@@dpr1 D (λ (a_1 : D), a_1 ⟶ a) x = @@dpr1 D (λ (a_1 : D), a_1 ⟶ c) x", but the second dpr1 is not even well-typed

  end slice

  -- section coslice
  -- open sigma

  -- definition coslice {ob : Type} (C : category ob) (c : ob) : category (Σ(b : ob), hom c b) :=
  -- mk (λa b, Σ(g : hom (dpr1 a) (dpr1 b)), g ∘ dpr2 a = dpr2 b)
  --    (λ a b c g f, dpair (dpr1 g ∘ dpr1 f)
  --      (show (dpr1 g ∘ dpr1 f) ∘ dpr2 a = dpr2 c,
  --        proof
  --        calc
  --          (dpr1 g ∘ dpr1 f) ∘ dpr2 a = dpr1 g ∘ (dpr1 f ∘ dpr2 a): symm !assoc
  --            ... = dpr1 g ∘ dpr2 b : {dpr2 f}
  --            ... = dpr2 c : {dpr2 g}
  --        qed))
  --    (λ a, dpair id !id_left)
  --    (λ a b c d h g f, dpair_eq    !assoc    !proof_irrel)
  --    (λ a b f,         sigma.equal !id_left  !proof_irrel)
  --    (λ a b f,         sigma.equal !id_right !proof_irrel)

  -- -- theorem slice_coslice_opp {ob : Type} (C : category ob) (c : ob) :
  -- --     coslice C c = opposite (slice (opposite C) c) :=
  -- -- sorry
  -- end coslice

  section arrow
  open sigma eq.ops
  -- theorem concat_commutative_squares {ob : Type} {C : category ob} {a1 a2 a3 b1 b2 b3 : ob}
  --     {f1 : a1 => b1} {f2 : a2 => b2} {f3 : a3 => b3} {g2 : a2 => a3} {g1 : a1 => a2}
  --     {h2 : b2 => b3} {h1 : b1 => b2} (H1 : f2 ∘ g1 = h1 ∘ f1) (H2 : f3 ∘ g2 = h2 ∘ f2)
  --       : f3 ∘ (g2 ∘ g1) = (h2 ∘ h1) ∘ f1 :=
  -- calc
  --   f3 ∘ (g2 ∘ g1) = (f3 ∘ g2) ∘ g1 : assoc
  --     ... = (h2 ∘ f2) ∘ g1 : {H2}
  --     ... = h2 ∘ (f2 ∘ g1) : symm assoc
  --     ... = h2 ∘ (h1 ∘ f1) : {H1}
  --     ... = (h2 ∘ h1) ∘ f1 : assoc

  -- definition arrow {ob : Type} (C : category ob) : category (Σ(a b : ob), hom a b) :=
  -- mk (λa b, Σ(g : hom (dpr1 a) (dpr1 b)) (h : hom (dpr2' a) (dpr2' b)),
  --      dpr3 b ∘ g = h ∘ dpr3 a)
  --    (λ a b c g f, dpair (dpr1 g ∘ dpr1 f) (dpair (dpr2' g ∘ dpr2' f) (concat_commutative_squares (dpr3 f) (dpr3 g))))
  --    (λ a, dpair id (dpair id (id_right ⬝ (symm id_left))))
  --    (λ a b c d h g f, dtrip_eq2   assoc    assoc    !proof_irrel)
  --    (λ a b f,         trip.equal2 id_left  id_left  !proof_irrel)
  --    (λ a b f,         trip.equal2 id_right id_right !proof_irrel)

  -- make these definitions private?
  variables {ob : Type} {C : category ob}
  protected definition arrow_obs (ob : Type) (C : category ob) := Σ(a b : ob), hom a b
  variables {a b : category.arrow_obs ob C}
  protected definition src    (a : category.arrow_obs ob C) : ob                  := sigma.pr1 a
  protected definition dst    (a : category.arrow_obs ob C) : ob                  := sigma.pr2' a
  protected definition to_hom (a : category.arrow_obs ob C) : hom (category.src a) (category.dst a) := sigma.pr3 a

  protected definition arrow_hom (a b : category.arrow_obs ob C) : Type :=
  Σ (g : hom (category.src a) (category.src b)) (h : hom (category.dst a) (category.dst b)),
    category.to_hom b ∘ g = h ∘ category.to_hom a

  protected definition hom_src (m : category.arrow_hom a b) : hom (category.src a) (category.src b) := sigma.pr1 m
  protected definition hom_dst (m : category.arrow_hom a b) : hom (category.dst a) (category.dst b) := sigma.pr2' m
  protected definition commute (m : category.arrow_hom a b) :
     category.to_hom b ∘ (category.hom_src m) = (category.hom_dst m) ∘ category.to_hom a
  := sigma.pr3 m

  definition arrow (ob : Type) (C : category ob) : category (category.arrow_obs ob C) :=
  mk (λa b, category.arrow_hom a b)
     (λ a b c g f, sigma.mk (category.hom_src g ∘ category.hom_src f) (sigma.mk (category.hom_dst g ∘ category.hom_dst f)
        (show category.to_hom c ∘ (category.hom_src g ∘ category.hom_src f) = (category.hom_dst g ∘ category.hom_dst f) ∘ category.to_hom a,
         proof
         calc
         category.to_hom c ∘ (category.hom_src g ∘ category.hom_src f) = (category.to_hom c ∘ category.hom_src g) ∘ category.hom_src f : by rewrite assoc
           ... = (category.hom_dst g ∘ category.to_hom b) ∘ category.hom_src f                     : by rewrite category.commute
           ... = category.hom_dst g ∘ (category.to_hom b ∘ category.hom_src f)                     : by rewrite assoc
           ... = category.hom_dst g ∘ (category.hom_dst f ∘ category.to_hom a)                     : by rewrite category.commute
           ... = (category.hom_dst g ∘ category.hom_dst f) ∘ category.to_hom a                     : by rewrite assoc
         qed)
       ))
     (λ a, sigma.mk id (sigma.mk id (!id_right ⬝ (symm !id_left))))
     (λ a b c d h g f, ndtrip_eq    !assoc    !assoc    !proof_irrel)
     (λ a b f,         ndtrip_equal !id_left  !id_left  !proof_irrel)
     (λ a b f,         ndtrip_equal !id_right !id_right !proof_irrel)

  end arrow

end category

  -- definition foo : category (sorry) :=
  -- mk (λa b, sorry)
  --    (λ a b c g f, sorry)
  --    (λ a, sorry)
  --    (λ a b c d h g f, sorry)
  --    (λ a b f, sorry)
  --    (λ a b f, sorry)
