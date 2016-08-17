inductive Pair1 (A B : Type)
| mk ( ) : A → B → Pair1

check Pair1.mk

check Pair1.mk Prop Prop true false

inductive Pair2 {A : Type} (B : A → Type)
| mk ( ) : Π (a : A), B a → Pair2

check @Pair2.mk

check Pair2.mk (λx, Prop) true false

inductive Pair3 (A B : Type)
| mk : A → B → Pair3

check Pair3.mk true false
