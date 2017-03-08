/-
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Leonardo de Moura
-/
prelude
import init.logic init.category.applicative
universes u v

class alternative (f : Type u → Type v) extends applicative f : Type (max u+1 v) :=
(failure : Π {α : Type u}, f α)
(orelse  : Π {α : Type u}, f α → f α → f α)

section
variables {f : Type u → Type v} [alternative f] {α : Type u}

@[inline] def failure : f α :=
alternative.failure f

@[inline] def orelse : f α → f α → f α :=
alternative.orelse

infixr ` <|> `:2 := orelse

@[inline] def guard {f : Type → Type v} [alternative f] (p : Prop) [decidable p] : f unit :=
if p then pure () else failure

/- Later we define a coercion from bool to Prop, but this version will still be useful.
   Given (t : tactic bool), we can write t >>= guardb -/
@[inline] def guardb {f : Type → Type v} [alternative f] : bool → f unit
| tt := pure ()
| ff := failure

@[inline] def optional (x : f α) : f (option α) :=
some <$> x <|> pure none

end
