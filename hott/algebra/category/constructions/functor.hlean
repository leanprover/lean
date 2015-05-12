/-
Copyright (c) 2015 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Module: algebra.category.constructions.functor
Authors: Floris van Doorn, Jakob von Raumer

Functor precategory and category
-/

import ..nat_trans ..category

open eq functor is_trunc nat_trans iso is_equiv

namespace category

  definition precategory_functor [instance] [reducible] (D C : Precategory)
    : precategory (functor C D) :=
  precategory.mk (λa b, nat_trans a b)
                 (λ a b c g f, nat_trans.compose g f)
                 (λ a, nat_trans.id)
                 (λ a b c d h g f, !nat_trans.assoc)
                 (λ a b f, !nat_trans.id_left)
                 (λ a b f, !nat_trans.id_right)

  definition Precategory_functor [reducible] (D C : Precategory) : Precategory :=
  precategory.Mk (precategory_functor D C)

  infixr `^c`:35 := Precategory_functor

  section
  /- we prove that if a natural transformation is pointwise an iso, then it is an iso -/
  variables {C D : Precategory} {F G : C ⇒ D} (η : F ⟹ G) [iso : Π(a : C), is_iso (η a)]
  include iso

  definition nat_trans_inverse : G ⟹ F :=
  nat_trans.mk
    (λc, (η c)⁻¹)
    (λc d f,
    begin
      apply comp_inverse_eq_of_eq_comp,
      transitivity (natural_map η d)⁻¹ ∘ to_fun_hom G f ∘ natural_map η c,
        {apply eq_inverse_comp_of_comp_eq, symmetry, apply naturality},
        {apply assoc}
    end)

  definition nat_trans_left_inverse : nat_trans_inverse η ∘n η = nat_trans.id :=
  begin
    fapply (apd011 nat_trans.mk),
      apply eq_of_homotopy, intro c, apply left_inverse,
    apply eq_of_homotopy, intros, apply eq_of_homotopy, intros, apply eq_of_homotopy, intros,
    apply is_hset.elim
  end

  definition nat_trans_right_inverse : η ∘n nat_trans_inverse η = nat_trans.id :=
  begin
    fapply (apd011 nat_trans.mk),
      apply eq_of_homotopy, intro c, apply right_inverse,
    apply eq_of_homotopy, intros, apply eq_of_homotopy, intros, apply eq_of_homotopy, intros,
    apply is_hset.elim
  end

  definition is_iso_nat_trans : is_iso η :=
  is_iso.mk (nat_trans_left_inverse η) (nat_trans_right_inverse η)

  end

  section
  /- and conversely, if a natural transformation is an iso, it is componentwise an iso -/
  variables {C D : Precategory} {F G : D ^c C} (η : hom F G) [isoη : is_iso η] (c : C)
  include isoη
  definition componentwise_is_iso : is_iso (η c) :=
  @is_iso.mk _ _ _ _ _ (natural_map η⁻¹ c) (ap010 natural_map ( left_inverse η) c)
                                           (ap010 natural_map (right_inverse η) c)

  local attribute componentwise_is_iso [instance]

  definition natural_map_inverse : natural_map η⁻¹ c = (η c)⁻¹ := idp

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
  @iso.mk _ _ _ _ (natural_map (to_hom η) c)
                  (@componentwise_is_iso _ _ _ _ (to_hom η) (struct η) c)

  definition componentwise_iso_id (c : C) : componentwise_iso (iso.refl F) c = iso.refl (F c) :=
  iso_eq (idpath (ID (F c)))

  definition componentwise_iso_iso_of_eq (p : F = G) (c : C)
    : componentwise_iso (iso_of_eq p) c = iso_of_eq (ap010 to_fun_ob p c) :=
  eq.rec_on p !componentwise_iso_id

  definition natural_map_hom_of_eq (p : F = G) (c : C)
    : natural_map (hom_of_eq p) c = hom_of_eq (ap010 to_fun_ob p c) :=
  eq.rec_on p idp

  definition natural_map_inv_of_eq (p : F = G) (c : C)
    : natural_map (inv_of_eq p) c = hom_of_eq (ap010 to_fun_ob p c)⁻¹ :=
  eq.rec_on p idp

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
        esimp [function.id],
        symmetry, apply naturality_iso
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

  definition category_functor [instance] (D : Category) (C : Precategory)
    : category (D ^c C) :=
  category.mk (D ^c C) (functor.is_univalent D C)

  definition Category_functor (D : Category) (C : Precategory) : Category :=
  category.Mk (D ^c C) !category_functor

  --this definition is only useful if the exponent is a category,
  --  and the elaborator has trouble with inserting the coercion
  definition Category_functor' (D C : Category) : Category :=
  Category_functor D C

  namespace ops
    infixr `^c2`:35 := Category_functor
  end ops


end category
