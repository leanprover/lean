/-
Copyright (c) 2015 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Floris van Doorn

homotopy groups of a pointed space
-/

import types.pointed .trunc_group .hott types.trunc

open nat eq pointed trunc is_trunc algebra

namespace eq

  definition phomotopy_group [constructor] (n : ℕ) (A : Type*) : Set* :=
  ptrunc 0 (Ω[n] A)

  definition homotopy_group [reducible] (n : ℕ) (A : Type*) : Type :=
  phomotopy_group n A

  notation `π*[`:95  n:0    `] `:0 A:95 := phomotopy_group n A
  notation `π[`:95 n:0 `] `:0 A:95 := homotopy_group n A

  definition group_homotopy_group [instance] [constructor] (n : ℕ) (A : Type*)
    : group (π[succ n] A) :=
  trunc_group concat inverse idp con.assoc idp_con con_idp con.left_inv

  definition comm_group_homotopy_group [constructor] (n : ℕ) (A : Type*)
    : comm_group (π[succ (succ n)] A) :=
  trunc_comm_group concat inverse idp con.assoc idp_con con_idp con.left_inv eckmann_hilton

  local attribute comm_group_homotopy_group [instance]

  definition ghomotopy_group [constructor] (n : ℕ) (A : Type*) : Group :=
  Group.mk (π[succ n] A) _

  definition cghomotopy_group [constructor] (n : ℕ) (A : Type*) : CommGroup :=
  CommGroup.mk (π[succ (succ n)] A) _

  definition fundamental_group [constructor] (A : Type*) : Group :=
  ghomotopy_group zero A

  notation `πG[`:95  n:0 ` +1] `:0 A:95 := ghomotopy_group n A
  notation `πaG[`:95 n:0 ` +2] `:0 A:95 := cghomotopy_group n A

  prefix `π₁`:95 := fundamental_group

  open equiv unit
  theorem trivial_homotopy_of_is_set (A : Type*) [H : is_set A] (n : ℕ) : πG[n+1] A = G0 :=
  begin
    apply trivial_group_of_is_contr,
    apply is_trunc_trunc_of_is_trunc,
    apply is_contr_loop_of_is_trunc,
    apply is_trunc_succ_succ_of_is_set
  end

  definition homotopy_group_succ_out (A : Type*) (n : ℕ) : πG[ n +1] A = π₁ Ω[n] A := idp

  definition homotopy_group_succ_in (A : Type*) (n : ℕ) : πG[succ n +1] A = πG[n +1] Ω A :=
  begin
    fapply Group_eq,
    { apply equiv_of_eq, exact ap (λ(X : Type*), trunc 0 X) (loop_space_succ_eq_in A (succ n))},
    { exact abstract [irreducible] begin refine trunc.rec _, intro p, refine trunc.rec _, intro q,
      rewrite [▸*,-+tr_eq_cast_ap, +trunc_transport], refine !trunc_transport ⬝ _, apply ap tr,
      apply loop_space_succ_eq_in_concat end end},
  end

  definition homotopy_group_add (A : Type*) (n m : ℕ) : πG[n+m +1] A = πG[n +1] Ω[m] A :=
  begin
    revert A, induction m with m IH: intro A,
    { reflexivity},
    { esimp [iterated_ploop_space, nat.add], refine !homotopy_group_succ_in ⬝ _, refine !IH ⬝ _,
      exact ap (ghomotopy_group n) !loop_space_succ_eq_in⁻¹}
  end

  theorem trivial_homotopy_of_is_set_loop_space {A : Type*} {n : ℕ} (m : ℕ) (H : is_set (Ω[n] A))
    : πG[m+n+1] A = G0 :=
  !homotopy_group_add ⬝ !trivial_homotopy_of_is_set

  definition phomotopy_group_functor [constructor] (n : ℕ) {A B : Type*} (f : A →* B)
    : π*[n] A →* π*[n] B :=
  ptrunc_functor 0 (apn n f)

  notation `π→*[`:95  n:0    `] `:0 f:95 := phomotopy_group_functor n f

end eq
