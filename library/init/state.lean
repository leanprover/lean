/-
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura
-/
prelude
import init.logic init.monad init.alternative init.prod

definition state (S : Type) (A : Type) := S → A × S

section
variables {S A B : Type}

definition state_fmap [inline] (f : A → B) (a : state S A) : state S B :=
λ s, match a s with (a', s') := (f a', s') end

definition state_return [inline] (a : A) : state S A :=
λ s, (a, s)

definition state_bind [inline] (a : state S A) (b : A → state S B) : state S B :=
λ s, match a s with (a', s') := b a' s' end

definition state_is_monad [instance] (S : Type) : monad (state S) :=
monad.mk (@state_fmap S) (@state_return S) (@state_bind S)
end

namespace state
definition read [inline] {S A : Type} : state S S :=
λ s, (s, s)

definition write [inline] {S : Type} : S → state S unit :=
λ s' s, ((), s')
end state

definition stateT (S : Type) (m : Type → Type) [monad m] (A : Type) := S → m (A × S)

definition stateT_fmap.{l} {S : Type} {m : Type → Type} [monad m] {A B : Type.{l}} (f : A → B) (a : stateT S m A) : stateT S m B :=
λ s, @monad.bind m _ _ _ (a s) (λ p : A × S, match p with (a', s') := return (f a', s') end)

definition stateT_return {S : Type} {m : Type → Type} [monad m] {A : Type} (a : A) : stateT S m A :=
λ s, @monad.ret m _ _ (a, s)

definition stateT_bind.{l} {S : Type} {m : Type → Type} [monad m] {A B : Type.{l}} (a : stateT S m A) (b : A → stateT S m B) : stateT S m B :=
λ s, @monad.bind m _ _ _ (a s) (λ p : A × S, match p with (a', s') := b a' s' end)

definition stateT_is_monad [instance] (S : Type) (m : Type → Type) [monad m] : monad (stateT S m) :=
monad.mk (@stateT_fmap S m _) (@stateT_return S m _) (@stateT_bind S m _)

namespace stateT
definition read {S : Type} {m : Type → Type} [monad m] : stateT S m S :=
λ s, return (s, s)

definition write {S : Type} {m : Type → Type} [monad m] : S → stateT S m unit :=
λ s' s, return ((), s')
end stateT
