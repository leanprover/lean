/-
Copyright (c) 2015 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Floris van Doorn

Theorems about algebra specific to HoTT
-/

import .group arity types.pi hprop_trunc

open equiv eq equiv.ops is_trunc

namespace algebra
  open Group has_mul has_inv
  -- we prove under which conditions two groups are equal
  universe variable l
  variables {A B : Type.{l}}
  definition group_eq {G H : group A} (same_mul' : Π(g h : A), @@mul A G g h = @@mul A H g h)
    : G = H :=
  begin
    have foo : Π(g : A), @@inv A G g = (@@inv A G g * g) * @@inv A H g,
      from λg, !mul_inv_cancel_right⁻¹,
    cases G with Gm Gs Gh1 G1 Gh2 Gh3 Gi Gh4,
    cases H with Hm Hs Hh1 H1 Hh2 Hh3 Hi Hh4,
    rewrite [↑[semigroup.to_has_mul,group.to_has_inv] at (same_mul,foo)] ,
    have same_mul : Gm = Hm, from eq_of_homotopy2 same_mul',
    cases same_mul,
    have same_one : G1 = H1, from calc
      G1 = Hm G1 H1 : Hh3
     ... = H1 : Gh2,
    have same_inv : Gi = Hi, from eq_of_homotopy (take g, calc
      Gi g = Hm (Hm (Gi g) g) (Hi g) : foo
       ... = Hm G1 (Hi g) : by rewrite Gh4
       ... = Hi g : Gh2),
    cases same_one, cases same_inv,
    have ps  : Gs  = Hs,  from !is_hprop.elim,
    have ph1 : Gh1 = Hh1, from !is_hprop.elim,
    have ph2 : Gh2 = Hh2, from !is_hprop.elim,
    have ph3 : Gh3 = Hh3, from !is_hprop.elim,
    have ph4 : Gh4 = Hh4, from !is_hprop.elim,
    cases ps, cases ph1, cases ph2, cases ph3, cases ph4, reflexivity
  end

  definition group_pathover {G : group A} {H : group B} {f : A ≃ B} : (Π(g h : A), f (g * h) = f g * f h) → G =[ua f] H :=
  begin
    revert H,
    eapply (rec_on_ua_idp' f),
    intros H resp_mul,
    esimp [equiv.refl] at resp_mul, esimp,
    apply pathover_idp_of_eq, apply group_eq,
    exact resp_mul
  end

  definition Group_eq {G H : Group} (f : carrier G ≃ carrier H)
    (resp_mul : Π(g h : G), f (g * h) = f g * f h) : G = H :=
  begin
    cases G with Gc G, cases H with Hc H,
    apply (apo011 mk (ua f)),
    apply group_pathover, exact resp_mul
  end

end algebra
