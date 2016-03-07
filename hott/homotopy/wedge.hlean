/-
Copyright (c) 2016 Jakob von Raumer. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jakob von Raumer, Ulrik Buchholtz

The Wedge Sum of Two pType Types
-/
import hit.pointed_pushout .connectedness

open eq pushout pointed unit trunc_index

definition pwedge (A B : Type*) : Type* := ppushout (pconst punit A) (pconst punit B)

namespace wedge

  -- TODO maybe find a cleaner proof
  protected definition unit (A : Type*) : A ≃* pwedge punit A :=
  begin
    fapply pequiv_of_pmap,
    { fapply pmap.mk, intro a, apply pinr a, apply respect_pt },
    { fapply is_equiv.adjointify, intro x, fapply pushout.elim_on x,
      exact λ x, Point A, exact id, intro u, reflexivity,
      intro x, fapply pushout.rec_on x, intro u, cases u, esimp, apply (glue unit.star)⁻¹,
      intro a, reflexivity,
      intro u, cases u, esimp, apply eq_pathover,
      refine _ ⬝hp !ap_id⁻¹, fapply eq_hconcat, apply ap_compose inr,
      krewrite elim_glue, fapply eq_hconcat, apply ap_idp, apply square_of_eq,
      apply con.left_inv,
      intro a, reflexivity},
  end
end wedge

open trunc is_trunc is_conn function

namespace wedge_extension
section
  -- The wedge connectivity lemma (Lemma 8.6.2)
  parameters {A B : Type*} (n m : ℕ)
             [cA : is_conn n A] [cB : is_conn m B]
             (P : A → B → (m + n)-Type)
             (f : Πa : A, P a pt)
             (g : Πb : B, P pt b)
             (p : f pt = g pt)

  include cA cB
  private definition Q (a : A) : (n.-1)-Type :=
  trunctype.mk
    (fiber (λs : (Πb : B, P a b), s (Point B)) (f a))
    abstract begin
      refine @is_conn.elim_general (m.-1) _ _ _ (λb, trunctype.mk (P a b) _) (f a),
      rewrite [-succ_add_succ, of_nat_add_of_nat], intro b, apply trunctype.struct
    end end

  private definition Q_sec : Πa : A, Q a :=
  is_conn.elim Q (fiber.mk g p⁻¹)

  protected definition ext : Π(a : A)(b : B), P a b :=
  λa, fiber.point (Q_sec a)

  protected definition β_left (a : A) : ext a (Point B) = f a :=
  fiber.point_eq (Q_sec a)

  private definition coh_aux : Σq : ext (Point A) = g,
    β_left (Point A) = ap (λs : (Πb : B, P (Point A) b), s (Point B)) q ⬝ p⁻¹ :=
  equiv.to_fun (fiber.fiber_eq_equiv (Q_sec (Point A)) (fiber.mk g p⁻¹))
               (is_conn.elim_β Q (fiber.mk g p⁻¹))

  protected definition β_right (b : B) : ext (Point A) b = g b :=
  apd10 (sigma.pr1 coh_aux) b

  private definition lem : β_left (Point A) = β_right (Point B) ⬝ p⁻¹ :=
  begin
    unfold β_right, unfold β_left,
    krewrite (apd10_eq_ap_eval (sigma.pr1 coh_aux) (Point B)),
    exact sigma.pr2 coh_aux,
  end

  protected definition coh
    : (β_left (Point A))⁻¹ ⬝ β_right (Point B) = p :=
  by rewrite [lem,con_inv,inv_inv,con.assoc,con.left_inv]

end
end wedge_extension
