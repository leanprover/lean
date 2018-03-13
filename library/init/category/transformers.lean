/-
Copyright (c) 2016 Gabriel Ebner. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Gabriel Ebner
-/
prelude
import init.function init.coe
import init.category.monad

universes u v w

class monad_transformer (transformer : ∀ (m : Type u → Type v) [monad m], Type u → Type w) :=
(is_monad : ∀ m [monad m], monad (transformer m))
(monad_lift : ∀ m [monad m] α, m α → transformer m α)

instance transformed_monad (m t) [monad_transformer t] [monad m] : monad (t m) :=
monad_transformer.is_monad t m

class has_monad_lift (m n : Type u → Type v) :=
(monad_lift : ∀ α, m α → n α)

instance monad_transformer_lift (t m) [monad_transformer t] [monad m] : has_monad_lift m (t m) :=
⟨monad_transformer.monad_lift t m⟩

class has_monad_lift_t (m n : Type u → Type v) :=
(monad_lift : ∀ α, m α → n α)

def monad_lift {m n} [has_monad_lift_t m n] {α} : m α → n α :=
has_monad_lift_t.monad_lift n α

@[reducible] def has_monad_lift_to_has_coe {m n} [has_monad_lift_t m n] {α} : has_coe (m α) (n α) :=
⟨monad_lift⟩

instance has_monad_lift_t_trans (m n o) [has_monad_lift n o] [has_monad_lift_t m n] : has_monad_lift_t m o :=
⟨λ α (ma : m α), has_monad_lift.monad_lift o α $ has_monad_lift_t.monad_lift n α ma⟩

instance has_monad_lift_t_refl (m) [monad m] : has_monad_lift_t m m :=
⟨λ α, id⟩
