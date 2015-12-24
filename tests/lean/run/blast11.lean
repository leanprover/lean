import data.nat
open algebra nat

--definition lemma1 (a b : nat) : a + b + 0 = b + a :=
--by simp

--print lemma1
set_option trace.simplifier.rewrite true
set_option trace.simplifier.perm true
print [simp]

definition lemma2 (a b c : nat) : a + b + 0 + c + a + a + b = 0 + 0 + c + a + b + a + a + b :=
by simp

print lemma2
