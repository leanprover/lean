/-
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Leonardo de Moura
-/
prelude
import init.logic init.data.nat.basic
open decidable list

notation h :: t  := cons h t
notation `[` l:(foldr `, ` (h t, cons h t) nil `]`) := l

universe variables u v

instance (α : Type u) : inhabited (list α) :=
⟨list.nil⟩

variables {α : Type u} {β : Type v}

namespace list
protected def append : list α → list α → list α
| []       l := l
| (h :: s) t := h :: (append s t)

instance : has_append (list α) :=
⟨list.append⟩

protected def mem : α → list α → Prop
| a []       := false
| a (b :: l) := a = b ∨ mem a l

instance : has_mem α list :=
⟨list.mem⟩

instance decidable_mem [decidable_eq α] (a : α) : ∀ (l : list α), decidable (a ∈ l)
| []     := is_false not_false
| (b::l) :=
  if h₁ : a = b then is_true (or.inl h₁)
  else match decidable_mem l with
  | is_true  h₂ := is_true (or.inr h₂)
  | is_false h₂ := is_false (not_or h₁ h₂)
  end

def concat : list α → α → list α
| []     a := [a]
| (b::l) a := b :: concat l a

instance : has_emptyc (list α) :=
⟨list.nil⟩

protected def insert [decidable_eq α] (a : α) (l : list α) : list α :=
if a ∈ l then l else concat l a

instance [decidable_eq α] : has_insert α list :=
⟨list.insert⟩

protected def union [decidable_eq α] : list α → list α → list α
| l₁ []      := l₁
| l₁ (a::l₂) := union (insert a l₁) l₂

instance [decidable_eq α] : has_union (list α) :=
⟨list.union⟩

protected def inter [decidable_eq α] : list α → list α → list α
| []      l₂ := []
| (a::l₁) l₂ := if a ∈ l₂ then a :: inter l₁ l₂ else inter l₁ l₂

instance [decidable_eq α] : has_inter (list α) :=
⟨list.inter⟩

def length : list α → nat
| []       := 0
| (a :: l) := length l + 1

open option nat

def nth : list α → nat → option α
| []       n     := none
| (a :: l) 0     := some a
| (a :: l) (n+1) := nth l n

def head [inhabited α] : list α → α
| []       := default α
| (a :: l) := a

def tail : list α → list α
| []       := []
| (a :: l) := l

def reverse : list α → list α
| []       := []
| (a :: l) := concat (reverse l) a

def map (f : α → β) : list α → list β
| []       := []
| (a :: l) := f a :: map l

def for : list α → (α → β) → list β :=
flip map

def join : list (list α) → list α
| []        := []
| (l :: ls) := append l (join ls)

def filter (p : α → Prop) [decidable_pred p] : list α → list α
| []     := []
| (a::l) := if p a then a :: filter l else filter l

def dropn : ℕ → list α → list α
| 0 a := a
| (succ n) [] := []
| (succ n) (x::r) := dropn n r

def taken : ℕ → list α → list α
| 0 a := []
| (succ n) [] := []
| (succ n) (x :: r) := x :: taken n r

definition foldl (f : α → β → α) : α → list β → α
| a []       := a
| a (b :: l) := foldl (f a b) l

definition foldr (f : α → β → β) : β → list α → β
| b []       := b
| b (a :: l) := f a (foldr b l)

definition any (l : list α) (p : α → bool) : bool :=
foldr (λ a r, p a || r) ff l

definition all (l : list α) (p : α → bool) : bool :=
foldr (λ a r, p a && r) tt l

def zip : list α → list β → list (prod α β)
| []      _       := []
| _       []      := []
| (x::xs) (y::ys) := (prod.mk x y) :: zip xs ys

def repeat (a : α) : ℕ → list α
| 0 := []
| (succ n) := a :: repeat n

def iota : ℕ → list ℕ
| 0 := []
| (succ n) := iota n ++ [succ n]

end list
