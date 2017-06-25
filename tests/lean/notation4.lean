--
open sigma
inductive List (T : Type) : Type | nil {} : List | cons   : T → List → List open List notation h :: t  := cons h t notation `[` l:(foldr `,` (h t, cons h t) nil) `]` := l
#check ∃ (A : Type) (x y : A), x = y
#check ∃ (x : nat), x = 0
#check Σ' (x : nat), x = 10
#check Σ (A : Type), List A
