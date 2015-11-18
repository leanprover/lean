open nat

section
  inductive NatA :=
  | a : NatA
  | s : NatA → NatA

  open NatA

  definition foo (n : nat) : NatA :=
  nat.rec_on n a (λ n' r, s r)

  local attribute foo [coercion]

  check let a : nat := 10 in s a

end
