--
open nat tactic

example (a b : nat) : a = succ b → a = b + 1 :=
by do
  H ← intro `H,
  try (dunfold_at [`nat.succ] H),
  dunfold [`add, `has_add.add, `has_one.one, `nat.add, `one],
  trace_state,
  t ← target,
  expected ← to_expr ```(a = succ b),
  guard (t = expected),
  assumption
