/-
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura
-/
prelude
import init.meta.name init.meta.format

/- Reflect a C++ level object. The VM replaces it with the C++ implementation. -/
inductive level
| zero   : level
| succ   : level → level
| max    : level → level → level
| imax   : level → level → level
| param  : name → level
| global : name → level
| meta   : name → level

attribute [instance]
definition level.is_inhabited : inhabited level :=
inhabited.mk level.zero

/- TODO(Leo): provide a definition in Lean. -/
meta_constant level.has_decidable_eq : decidable_eq level
attribute [instance] level.has_decidable_eq
meta_constant level.lt : level → level → bool
meta_constant level.lex_lt : level → level → bool
meta_constant level.fold {A :Type} : level → A → (level → A → A) → A
/- Return the given level expression normal form -/
meta_constant level.normalize : level → level
/- Return tt iff lhs and rhs denote the same level.
   The check is done by normalization. -/
meta_constant level.eqv : level → level → bool
/- Return tt iff the first level occurs in the second -/
meta_constant level.occurs : level → level → bool
/- Replace a parameter named n with l in the first level if the list contains the pair (n, l) -/
meta_constant level.instantiate : level → list (name × level) → list level
meta_constant level.to_format : level → options → format
meta_constant level.to_string : level → string

meta_definition level.cmp (a b : level) : ordering :=
if level.lt a b = bool.tt then ordering.lt
else if a = b then ordering.eq
else ordering.gt

attribute [instance]
meta_definition level.has_to_string : has_to_string level :=
has_to_string.mk level.to_string

attribute [instance]
meta_definition level.has_to_format : has_to_format level :=
has_to_format.mk (λ l, level.to_format l options.mk)

attribute [instance]
meta_definition level.has_to_cmp : has_ordering level :=
has_ordering.mk level.cmp

meta_definition level.of_nat : nat → level
| 0            := level.zero
| (nat.succ n) := level.succ (level.of_nat n)

open decidable
meta_definition level.has_param : level → name → bool
| (level.succ l)     n  := level.has_param l n
| (level.max l₁ l₂)  n  := level.has_param l₁ n || level.has_param l₂ n
| (level.imax l₁ l₂) n  := level.has_param l₁ n || level.has_param l₂ n
| (level.param n₁)   n  := to_bool (n₁ = n)
| _                  n  := ff
