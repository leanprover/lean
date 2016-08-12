/-
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura
-/
prelude
import init.meta.tactic init.meta.format init.function

structure param_info :=
(is_implicit      : bool)
(is_inst_implicit : bool)
(is_prop          : bool)
(has_fwd_deps     : bool)
(back_deps        : list nat) -- previous parameters it depends on

open format list decidable

private meta_definition ppfield {A : Type} [has_to_format A] (fname : string) (v : A) : format :=
group $ to_fmt fname ++ space ++ to_fmt ":=" ++ space ++ nest (length fname + 4) (to_fmt v)

private meta_definition concat_fields (f₁ f₂ : format) : format :=
if       is_nil f₁ = tt then f₂
else if  is_nil f₂ = tt then f₁
else f₁ ++ to_fmt "," ++ line ++ f₂

local infix `+++`:65 := concat_fields

meta_definition param_info.to_format : param_info → format
| (param_info.mk i ii p d ds) :=
group ∘ cbrace $
  when i  "implicit" +++
  when ii "inst_implicit" +++
  when p  "prop" +++
  when d  "has_fwd_deps" +++
  when (to_bool (length ds > 0)) (to_fmt "back_deps := " ++ to_fmt ds)

attribute [instance]
meta_definition param_info.has_to_format : has_to_format param_info :=
has_to_format.mk param_info.to_format

structure fun_info :=
(params      : list param_info)
(result_deps : list nat) -- parameters the result type depends on

meta_definition fun_info_to_format : fun_info → format
| (fun_info.mk ps ds) :=
group ∘ dcbrace $
  ppfield "params" ps +++
  ppfield "result_deps" ds

attribute [instance]
meta_definition fun_info_has_to_format : has_to_format fun_info :=
has_to_format.mk fun_info_to_format

/-
  specialized is true if the result of fun_info has been specifialized
  using this argument.
  For example, consider the function

             f : Pi (A : Type), A -> A

  Now, suppse we request get_specialize fun_info for the application

         f unit a

  fun_info_manager returns two param_info objects:
  1) specialized = true
  2) is_subsingleton = true

  Note that, in general, the second argument of f is not a subsingleton,
  but it is in this particular case/specialization.

  \remark This bit is only set if it is a dependent parameter.

   Moreover, we only set is_specialized IF another parameter
   becomes a subsingleton -/
structure subsingleton_info :=
(specialized     : bool)
(is_subsingleton : bool)

meta_definition subsingleton_info_to_format : subsingleton_info → format
| (subsingleton_info.mk s ss) :=
group ∘ cbrace $
  when s  "specialized" +++
  when ss "subsingleton"

attribute [instance]
meta_definition subsingleton_info_has_to_format : has_to_format subsingleton_info :=
has_to_format.mk subsingleton_info_to_format

namespace tactic
meta_constant get_fun_info_core   : transparency → expr → tactic fun_info
/- (get_fun_info fn n) return information assuming the function has only n arguments.
   The tactic fail if n > length (params (get_fun_info fn)) -/
meta_constant get_fun_info_n_core : transparency → expr → nat → tactic fun_info

meta_constant get_subsingleton_info_core : transparency → expr → tactic (list subsingleton_info)
meta_constant get_subsingleton_info_n_core : transparency → expr → nat → tactic (list subsingleton_info)

/- (get_spec_subsingleton_info t) return subsingleton parameter
   information for the function application t of the form
      (f a_1 ... a_n).
   This tactic is more precise than (get_subsingleton_info f) and (get_subsingleton_info_n f n)

    Example: given (f : Pi (A : Type), A -> A), \c get_spec_subsingleton_info for

    f unit b

    returns a fun_info with two param_info
    1) specialized = tt
    2) is_subsingleton = tt

    The second argument is marked as subsingleton only because the resulting information
    is taking into account the first argument. -/
meta_constant get_spec_subsingleton_info_core : transparency → expr → tactic (list subsingleton_info)
meta_constant get_spec_prefix_size_core : transparency → expr → nat → tactic nat

meta_definition get_fun_info : expr → tactic fun_info :=
get_fun_info_core semireducible

meta_definition get_fun_info_n : expr → nat → tactic fun_info :=
get_fun_info_n_core semireducible

meta_definition get_subsingleton_info : expr → tactic (list subsingleton_info) :=
get_subsingleton_info_core semireducible

meta_definition get_subsingleton_info_n : expr → nat → tactic (list subsingleton_info) :=
get_subsingleton_info_n_core semireducible

meta_definition get_spec_subsingleton_info : expr → tactic (list subsingleton_info) :=
get_spec_subsingleton_info_core semireducible

meta_definition get_spec_prefix_size : expr → nat → tactic nat :=
get_spec_prefix_size_core semireducible
end tactic
