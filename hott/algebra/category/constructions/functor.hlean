/-
Copyright (c) 2015 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Floris van Doorn, Jakob von Raumer

Functor precategory and category
-/

import ..nat_trans ..category

open eq category is_trunc nat_trans iso is_equiv category.hom

namespace functor

  definition precategory_functor [instance] [reducible] [constructor] (D C : Precategory)
    : precategory (functor C D) :=
  precategory.mk (λa b, nat_trans a b)
                 (λ a b c g f, nat_trans.compose g f)
                 (λ a, nat_trans.id)
                 (λ a b c d h g f, !nat_trans.assoc)
                 (λ a b f, !nat_trans.id_left)
                 (λ a b f, !nat_trans.id_right)

  definition Precategory_functor [reducible] [constructor] (D C : Precategory) : Precategory :=
  precategory.Mk (precategory_functor D C)

  infixr ` ^c `:80 := Precategory_functor

  section
  /- we prove that if a natural transformation is pointwise an iso, then it is an iso -/
  variables {C D : Precategory} {F G : C ⇒ D} (η : F ⟹ G) [iso : Π(a : C), is_iso (η a)]
  include iso

  definition nat_trans_inverse [constructor] : G ⟹ F :=
  nat_trans.mk
    (λc, (η c)⁻¹)
    (λc d f,
    abstract begin
      apply comp_inverse_eq_of_eq_comp,
      transitivity (natural_map η d)⁻¹ ∘ to_fun_hom G f ∘ natural_map η c,
        {apply eq_inverse_comp_of_comp_eq, symmetry, apply naturality},
        {apply assoc}
    end end)

  definition nat_trans_left_inverse : nat_trans_inverse η ∘n η = 1 :=
  begin
    fapply (apd011 nat_trans.mk),
      apply eq_of_homotopy, intro c, apply left_inverse,
    apply eq_of_homotopy, intros, apply eq_of_homotopy, intros, apply eq_of_homotopy, intros,
    apply is_hset.elim
  end

  definition nat_trans_right_inverse : η ∘n nat_trans_inverse η = 1 :=
  begin
    fapply (apd011 nat_trans.mk),
      apply eq_of_homotopy, intro c, apply right_inverse,
    apply eq_of_homotopy, intros, apply eq_of_homotopy, intros, apply eq_of_homotopy, intros,
    apply is_hset.elim
  end

  definition is_natural_iso [constructor] : is_iso η :=
  is_iso.mk _ (nat_trans_left_inverse η) (nat_trans_right_inverse η)

  variable (iso)
  definition natural_iso.mk [constructor] : F ≅ G :=
  iso.mk _ (is_natural_iso η)

  omit iso

  variables (F G)
  definition is_natural_inverse (η : Πc, F c ≅ G c)
    (nat : Π⦃a b : C⦄ (f : hom a b), G f ∘ to_hom (η a) = to_hom (η b) ∘ F f)
    {a b : C} (f : hom a b) : F f ∘ to_inv (η a) = to_inv (η b) ∘ G f :=
  let η' : F ⟹ G := nat_trans.mk (λc, to_hom (η c)) @nat in
  naturality (nat_trans_inverse η') f

  definition is_natural_inverse' (η₁ : Πc, F c ≅ G c) (η₂ : F ⟹ G) (p : η₁ ~ η₂)
    {a b : C} (f : hom a b) : F f ∘ to_inv (η₁ a) = to_inv (η₁ b) ∘ G f :=
  is_natural_inverse F G η₁ abstract λa b g, (p a)⁻¹ ▸ (p b)⁻¹ ▸ naturality η₂ g end f

  variables {F G}
  definition natural_iso.MK [constructor]
    (η : Πc, F c ⟶ G c) (p : Π(c c' : C) (f : c ⟶ c'), G f ∘ η c = η c' ∘ F f)
    (θ : Πc, G c ⟶ F c) (r : Πc, θ c ∘ η c = id) (q : Πc, η c ∘ θ c = id) : F ≅ G :=
  iso.mk (nat_trans.mk η p) (@(is_natural_iso _) (λc, is_iso.mk (θ c) (r c) (q c)))

  end

  section
  /- and conversely, if a natural transformation is an iso, it is componentwise an iso -/
  variables {A B C D : Precategory} {F G : C ⇒ D} (η : hom F G) [isoη : is_iso η] (c : C)
  include isoη
  definition componentwise_is_iso [constructor] : is_iso (η c) :=
  @is_iso.mk _ _ _ _ _ (natural_map η⁻¹ c) (ap010 natural_map ( left_inverse η) c)
                                           (ap010 natural_map (right_inverse η) c)

  local attribute componentwise_is_iso [instance]

  variable {isoη}
  definition natural_map_inverse : natural_map η⁻¹ c = (η c)⁻¹ := idp
  variable [isoη]

  definition naturality_iso {c c' : C} (f : c ⟶ c') : G f = η c' ∘ F f ∘ (η c)⁻¹ :=
  calc
    G f = (G f ∘ η c) ∘ (η c)⁻¹  : by rewrite comp_inverse_cancel_right
    ... = (η c' ∘ F f) ∘ (η c)⁻¹ : by rewrite naturality
    ... = η c' ∘ F f ∘ (η c)⁻¹   : by rewrite assoc

  definition naturality_iso' {c c' : C} (f : c ⟶ c') : (η c')⁻¹ ∘ G f ∘ η c = F f :=
  calc
   (η c')⁻¹ ∘ G f ∘ η c = (η c')⁻¹ ∘ η c' ∘ F f : by rewrite naturality
                    ... = F f                   : by rewrite inverse_comp_cancel_left

  omit isoη

  definition componentwise_iso (η : F ≅ G) (c : C) : F c ≅ G c :=
  iso.mk (natural_map (to_hom η) c)
         (@componentwise_is_iso _ _ _ _ (to_hom η) (struct η) c)

  definition componentwise_iso_id (c : C) : componentwise_iso (iso.refl F) c = iso.refl (F c) :=
  iso_eq (idpath (ID (F c)))

  definition componentwise_iso_iso_of_eq (p : F = G) (c : C)
    : componentwise_iso (iso_of_eq p) c = iso_of_eq (ap010 to_fun_ob p c) :=
  eq.rec_on p !componentwise_iso_id

  theorem naturality_iso_id {F : C ⇒ C} (η : F ≅ 1) (c : C)
    : componentwise_iso η (F c) = F (componentwise_iso η c) :=
  comp.cancel_left (to_hom (componentwise_iso η c))
    ((naturality (to_hom η)) (to_hom (componentwise_iso η c)))

  definition natural_map_hom_of_eq (p : F = G) (c : C)
    : natural_map (hom_of_eq p) c = hom_of_eq (ap010 to_fun_ob p c) :=
  eq.rec_on p idp

  definition natural_map_inv_of_eq (p : F = G) (c : C)
    : natural_map (inv_of_eq p) c = hom_of_eq (ap010 to_fun_ob p c)⁻¹ :=
  eq.rec_on p idp

  definition hom_of_eq_compose_right {H : B ⇒ C} (p : F = G)
    : hom_of_eq (ap (λx, x ∘f H) p) = hom_of_eq p ∘nf H :=
  eq.rec_on p idp

  definition inv_of_eq_compose_right {H : B ⇒ C} (p : F = G)
    : inv_of_eq (ap (λx, x ∘f H) p) = inv_of_eq p ∘nf H :=
  eq.rec_on p idp

  definition hom_of_eq_compose_left {H : D ⇒ C} (p : F = G)
    : hom_of_eq (ap (λx, H ∘f x) p) = H ∘fn hom_of_eq p :=
  by induction p; exact !fn_id⁻¹

  definition inv_of_eq_compose_left {H : D ⇒ C} (p : F = G)
    : inv_of_eq (ap (λx, H ∘f x) p) = H ∘fn inv_of_eq p :=
  by induction p; exact !fn_id⁻¹

  definition assoc_natural [constructor] (H : C ⇒ D) (G : B ⇒ C) (F : A ⇒ B)
    : H ∘f (G ∘f F) ⟹ (H ∘f G) ∘f F :=
  change_natural_map (hom_of_eq !functor.assoc)
                     (λa, id)
                     (λa, !natural_map_hom_of_eq ⬝ ap hom_of_eq !ap010_assoc)

  definition assoc_natural_rev [constructor] (H : C ⇒ D) (G : B ⇒ C) (F : A ⇒ B)
    : (H ∘f G) ∘f F ⟹ H ∘f (G ∘f F) :=
  change_natural_map (inv_of_eq !functor.assoc)
                     (λa, id)
                     (λa, !natural_map_inv_of_eq ⬝ ap (λx, hom_of_eq x⁻¹) !ap010_assoc)

  definition id_left_natural [constructor] (F : C ⇒ D) : functor.id ∘f F ⟹ F :=
  change_natural_map
    (hom_of_eq !functor.id_left)
    (λc, id)
    (λc, by induction F; exact !natural_map_hom_of_eq ⬝ ap hom_of_eq !ap010_functor_mk_eq_constant)


  definition id_left_natural_rev [constructor] (F : C ⇒ D) : F ⟹ functor.id ∘f F :=
  change_natural_map
    (inv_of_eq !functor.id_left)
    (λc, id)
    (λc, by induction F; exact !natural_map_inv_of_eq ⬝
                                 ap (λx, hom_of_eq x⁻¹) !ap010_functor_mk_eq_constant)

  definition id_right_natural [constructor] (F : C ⇒ D) : F ∘f functor.id ⟹ F :=
  change_natural_map
    (hom_of_eq !functor.id_right)
    (λc, id)
    (λc, by induction F; exact !natural_map_hom_of_eq ⬝ ap hom_of_eq !ap010_functor_mk_eq_constant)

  definition id_right_natural_rev [constructor] (F : C ⇒ D) : F ⟹ F ∘f functor.id :=
  change_natural_map
    (inv_of_eq !functor.id_right)
    (λc, id)
    (λc, by induction F; exact !natural_map_inv_of_eq ⬝
                                 ap (λx, hom_of_eq x⁻¹) !ap010_functor_mk_eq_constant)

  end

  section
  variables {C D E : Precategory} {G G' : D ⇒ E} {F F' : C ⇒ D} {J : D ⇒ D}

  definition is_iso_nf_compose [constructor] (G : D ⇒ E) (η : F ⟹ F') [H : is_iso η]
    : is_iso (G ∘fn η) :=
  is_iso.mk
    (G ∘fn @inverse (C ⇒ D) _ _ _ η _)
    abstract !fn_n_distrib⁻¹ ⬝ ap (λx, G ∘fn x) (@left_inverse  (C ⇒ D) _ _ _ η _)  ⬝ !fn_id end
    abstract !fn_n_distrib⁻¹ ⬝ ap (λx, G ∘fn x) (@right_inverse (C ⇒ D) _ _ _ η _) ⬝ !fn_id end

  definition is_iso_fn_compose [constructor] (η : G ⟹ G') (F : C ⇒ D) [H : is_iso η]
    : is_iso (η ∘nf F) :=
  is_iso.mk
    (@inverse (D ⇒ E) _ _ _ η _ ∘nf F)
    abstract !n_nf_distrib⁻¹ ⬝ ap (λx, x ∘nf F) (@left_inverse  (D ⇒ E) _ _ _ η _)  ⬝ !id_nf end
    abstract !n_nf_distrib⁻¹ ⬝ ap (λx, x ∘nf F) (@right_inverse (D ⇒ E) _ _ _ η _)  ⬝ !id_nf end

  definition functor_iso_compose [constructor] (G : D ⇒ E) (η : F ≅ F') : G ∘f F ≅ G ∘f F' :=
  iso.mk _ (is_iso_nf_compose G (to_hom η))

  definition iso_functor_compose [constructor] (η : G ≅ G') (F : C ⇒ D) : G ∘f F ≅ G' ∘f F :=
  iso.mk _ (is_iso_fn_compose (to_hom η) F)

  infixr ` ∘fi ` :62 := functor_iso_compose
  infixr ` ∘if ` :62 := iso_functor_compose


/- TODO: also needs n_nf_distrib and id_nf for these compositions
  definition nidf_compose [constructor] (η : J ⟹ 1) (F : C ⇒ D) [H : is_iso η]
    : is_iso (η ∘n1f F) :=
  is_iso.mk
   (@inverse (D ⇒ D) _ _ _ η _ ∘1nf F)
   abstract _ end
            _

  definition idnf_compose [constructor] (η : 1 ⟹ J) (F : C ⇒ D) [H : is_iso η]
    : is_iso (η ∘1nf F) :=
  is_iso.mk _
            _
            _

  definition fnid_compose [constructor] (F : D ⇒ E) (η : J ⟹ 1) [H : is_iso η]
    : is_iso (F ∘fn1 η) :=
  is_iso.mk _
            _
            _

  definition fidn_compose [constructor] (F : D ⇒ E) (η : 1 ⟹ J) [H : is_iso η]
    : is_iso (F ∘f1n η) :=
  is_iso.mk _
            _
            _
-/

  end

  namespace functor

    variables {C : Precategory} {D : Category} {F G : D ^c C}
    definition eq_of_iso_ob (η : F ≅ G) (c : C) : F c = G c :=
    by apply eq_of_iso; apply componentwise_iso; exact η

    local attribute functor.to_fun_hom [quasireducible]
    definition eq_of_iso (η : F ≅ G) : F = G :=
    begin
    fapply functor_eq,
      {exact (eq_of_iso_ob η)},
      {intro c c' f,
        esimp [eq_of_iso_ob, inv_of_eq, hom_of_eq, eq_of_iso],
        rewrite [*right_inv iso_of_eq],
        symmetry, apply @naturality_iso _ _ _ _ _ (iso.struct _)
      }
    end

    definition iso_of_eq_eq_of_iso (η : F ≅ G) : iso_of_eq (eq_of_iso η) = η :=
    begin
    apply iso_eq,
    apply nat_trans_eq,
    intro c,
    rewrite natural_map_hom_of_eq, esimp [eq_of_iso],
    rewrite ap010_functor_eq, esimp [hom_of_eq,eq_of_iso_ob],
    rewrite (right_inv iso_of_eq),
    end

    definition eq_of_iso_iso_of_eq (p : F = G) : eq_of_iso (iso_of_eq p) = p :=
    begin
    apply functor_eq2,
    intro c,
    esimp [eq_of_iso],
    rewrite ap010_functor_eq,
    esimp [eq_of_iso_ob],
    rewrite componentwise_iso_iso_of_eq,
    rewrite (left_inv iso_of_eq)
    end

    definition is_univalent (D : Category) (C : Precategory) : is_univalent (D ^c C) :=
    λF G, adjointify _ eq_of_iso
                       iso_of_eq_eq_of_iso
                       eq_of_iso_iso_of_eq

  end functor

  definition category_functor [instance] [constructor] (D : Category) (C : Precategory)
    : category (D ^c C) :=
  category.mk (D ^c C) (functor.is_univalent D C)

  definition Category_functor [constructor] (D : Category) (C : Precategory) : Category :=
  category.Mk (D ^c C) !category_functor

  --this definition is only useful if the exponent is a category,
  --  and the elaborator has trouble with inserting the coercion
  definition Category_functor' [constructor] (D C : Category) : Category :=
  Category_functor D C

  namespace ops
    infixr ` ^c2 `:35 := Category_functor
  end ops

  namespace functor
    variables {C : Precategory} {D : Category} {F G : D ^c C}

    definition eq_of_pointwise_iso (η : F ⟹ G) (iso : Π(a : C), is_iso (η a)) : F = G :=
    eq_of_iso (natural_iso.mk η iso)

   definition iso_of_eq_eq_of_pointwise_iso (η : F ⟹ G) (iso : Π(c : C), is_iso (η c))
      : iso_of_eq (eq_of_pointwise_iso η iso) = natural_iso.mk η iso :=
   !iso_of_eq_eq_of_iso

   definition hom_of_eq_eq_of_pointwise_iso (η : F ⟹ G) (iso : Π(c : C), is_iso (η c))
      : hom_of_eq (eq_of_pointwise_iso η iso) = η :=
   !hom_of_eq_eq_of_iso

   definition inv_of_eq_eq_of_pointwise_iso (η : F ⟹ G) (iso : Π(c : C), is_iso (η c))
      : inv_of_eq (eq_of_pointwise_iso η iso) = nat_trans_inverse η :=
   !inv_of_eq_eq_of_iso

  end functor

  /-
    functors involving only the functor category
    (see ..functor.curry for some other functors involving also products)
  -/

  variables {C D I : Precategory}
  definition constant2_functor [constructor] (F : I ⇒ D ^c C) (c : C) : I ⇒ D :=
  functor.mk (λi, to_fun_ob (F i) c)
             (λi j f, natural_map (F f) c)
             abstract (λi, ap010 natural_map !respect_id c ⬝ proof idp qed) end
             abstract (λi j k g f, ap010 natural_map !respect_comp c) end

  definition constant2_functor_natural [constructor] (F : I ⇒ D ^c C) {c d : C} (f : c ⟶ d)
    : constant2_functor F c ⟹ constant2_functor F d :=
  nat_trans.mk (λi, to_fun_hom (F i) f)
               (λi j k, (naturality (F k) f)⁻¹)

  definition functor_flip [constructor] (F : I ⇒ D ^c C) : C ⇒ D ^c I :=
  functor.mk (constant2_functor F)
             @(constant2_functor_natural F)
             abstract begin intros, apply nat_trans_eq, intro i, esimp, apply respect_id end end
             abstract begin intros, apply nat_trans_eq, intro i, esimp, apply respect_comp end end

  definition eval_functor [constructor] (C D : Precategory) (d : D) : C ^c D ⇒ C :=
  begin
    fapply functor.mk: esimp,
    { intro F, exact F d},
    { intro G F η, exact η d},
    { intro F, reflexivity},
    { intro H G F η θ, reflexivity},
  end

  definition precomposition_functor [constructor] {C D} (E) (F : C ⇒ D)
    : E ^c D ⇒ E ^c C :=
  begin
    fapply functor.mk: esimp,
    { intro G, exact G ∘f F},
    { intro G H η, exact η ∘nf F},
    { intro G, reflexivity},
    { intro G H I η θ, reflexivity},
  end

  definition postcomposition_functor [constructor] {C D} (E) (F : C ⇒ D)
    : C ^c E ⇒ D ^c E :=
  begin
    fapply functor.mk: esimp,
    { intro G, exact F ∘f G},
    { intro G H η, exact F ∘fn η},
    { intro G, apply fn_id},
    { intro G H I η θ, apply fn_n_distrib},
  end

  definition constant_diagram [constructor] (C D) : C ⇒ C ^c D :=
  begin
    fapply functor.mk: esimp,
    { intro c, exact constant_functor D c},
    { intro c d f, exact constant_nat_trans D f},
    { intro c, fapply nat_trans_eq, reflexivity},
    { intro c d e g f, fapply nat_trans_eq, reflexivity},
  end



end functor
