variables (A : Type)

definition f (A : Type) (a : A) := a

inductive bla (A : Type)
| mk : A → bla

structure foo (A : Type) (f : A → A) :=
(a : A)
