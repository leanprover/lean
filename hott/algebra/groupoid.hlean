-- Copyright (c) 2014 Jakob von Raumer. All rights reserved.
-- Released under Apache 2.0 license as described in the file LICENSE.
-- Author: Jakob von Raumer
-- Ported from Coq HoTT
import .precategory.basic .precategory.morphism .group

open path function prod sigma truncation morphism nat path_algebra unit

structure foo (A : Type) := (bsp : A)

structure groupoid [class] (ob : Type) extends precategory ob :=
(all_iso : Π ⦃a b : ob⦄ (f : hom a b),
  @is_iso ob (precategory.mk hom _ _ _ assoc id_left id_right) a b f)

namespace groupoid

instance [persistent] all_iso

--set_option pp.universes true
--set_option pp.implicit true
universe variable l
open precategory
definition path_groupoid (A : Type.{l})
    (H : is_trunc (nat.zero .+1) A) : groupoid.{l l} A :=
groupoid.mk
  (λ (a b : A), a ≈ b)
  (λ (a b : A), have ish : is_hset (a ≈ b), from succ_is_trunc nat.zero a b, ish)
  (λ (a b c : A) (p : b ≈ c) (q : a ≈ b), q ⬝ p)
  (λ (a : A), idpath a)
  (λ (a b c d : A) (p : c ≈ d) (q : b ≈ c) (r : a ≈ b), concat_pp_p r q p)
  (λ (a b : A) (p : a ≈ b), concat_p1 p)
  (λ (a b : A) (p : a ≈ b), concat_1p p)
  (λ (a b : A) (p : a ≈ b), @is_iso.mk A _ a b p (path.inverse p)
    !concat_pV !concat_Vp)

-- A groupoid with a contractible carrier is a group
definition group_of_contr {ob : Type} (H : is_contr ob)
  (G : groupoid ob) : group (hom (center ob) (center ob)) :=
begin
  fapply group.mk,
    intros (f, g), apply (comp f g),
    apply homH,
    intros (f, g, h), apply ((assoc f g h)⁻¹),
    apply (ID (center ob)),
    intro f, apply id_left,
    intro f, apply id_right,
    intro f, exact (morphism.inverse f),
    intro f, exact (morphism.inverse_compose f),
end

definition group_of_unit (G : groupoid unit) : group (hom ⋆ ⋆) :=
begin
  fapply group.mk,
    intros (f, g), apply (comp f g),
    apply homH,
    intros (f, g, h), apply ((assoc f g h)⁻¹),
    apply (ID ⋆),
    intro f, apply id_left,
    intro f, apply id_right,
    intro f, exact (morphism.inverse f),
    intro f, exact (morphism.inverse_compose f),
end

-- Conversely we can turn each group into a groupoid on the unit type
definition of_group (A : Type.{l}) [G : group A] : groupoid.{l l} unit :=
begin
  fapply groupoid.mk,
    intros, exact A,
    intros, apply (@group.carrier_hset A G),
    intros (a, b, c, g, h), exact (@group.mul A G g h),
    intro a, exact (@group.one A G),
    intros, exact ((@group.mul_assoc A G h g f)⁻¹),
    intros, exact (@group.mul_left_id A G f),
    intros, exact (@group.mul_right_id A G f),
    intros, apply is_iso.mk,
      apply mul_left_inv,
      apply mul_right_inv,
end

-- TODO: This is probably wrong
open equiv is_equiv
definition group_equiv {A : Type.{l}} [fx : funext]
  : group A ≃ Σ (G : groupoid.{l l} unit), @hom unit G ⋆ ⋆ ≈ A :=
sorry


end groupoid
