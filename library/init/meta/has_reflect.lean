/-
Copyright (c) 2017 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Sebastian Ullrich
-/
prelude
import init.meta.expr init.util

@[reducible] meta def {u} has_reflect (α : Sort u) := Π a : α, reflected a

meta instance bool.reflect : has_reflect bool
| tt := `(tt)
| ff := `(ff)

section
local attribute [semireducible] reflected

meta instance nat.reflect : has_reflect ℕ
| n := if n = 0 then `(0 : ℕ)
       else if n = 1 then `(1 : ℕ)
       else if n % 2 = 0 then `(bit0 %%(nat.reflect (n / 2)) : ℕ)
       else `(bit1 %%(nat.reflect (n / 2)) : ℕ)

meta instance unsigned.reflect : has_reflect unsigned
| ⟨n, pr⟩ := `(unsigned.of_nat' n)

end

meta instance name.reflect : has_reflect name
| name.anonymous        := `(name.anonymous)
| (name.mk_string  s n) := `(λ n, name.mk_string  s n).subst (name.reflect n)
| (name.mk_numeral i n) := `(λ n, name.mk_numeral i n).subst (name.reflect n)

meta instance list.reflect {α : Type} [has_reflect α] [reflected α] : has_reflect (list α)
| []     := `([])
| (h::t) := `(λ t, h :: t).subst (list.reflect t)

meta instance option.reflect {α : Type} [has_reflect α] [reflected α] : has_reflect (option α)
| (some x) := `(_)
| none     := `(_)

meta instance unit.reflect : has_reflect unit
| () := `(_)

meta instance prod.reflect {α β : Type} [has_reflect α] [reflected α] [has_reflect β] [reflected β]
  : has_reflect (α × β)
| ⟨x, y⟩ := `(_)

meta instance pos.reflect : has_reflect pos
| ⟨l, c⟩ := `(_)

meta def reflect_to_format {α} {a : α} (h : reflected a) : format :=
to_fmt (reflect a).to_expr

meta instance reflected.has_to_format {α} (a : α) : has_to_format (reflected a) :=
⟨reflect_to_format⟩

