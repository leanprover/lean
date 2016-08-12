import data.finset
open bool nat list finset

attribute finset [class]

attribute [instance]
definition fin_nat : finset nat :=
to_finset [0]

attribute [instance]
definition fin_bool : finset bool :=
to_finset [tt, ff]

definition tst (A : Type) [s : finset A] : finset A :=
s

example : tst nat = to_finset [0] :=
rfl

example : tst bool = to_finset [ff, tt] :=
dec_trivial

example : tst bool = to_finset [tt, ff] :=
rfl
