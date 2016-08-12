open nat tactic
variables {A : Type}

attribute [defeq]
definition succ_eq_add (n : nat) : succ n = n + 1 :=
rfl

example (n m : nat) (H : succ (succ n) = succ m) : true :=
by do H  ← get_local `H,
      t  ← infer_type H,
      t' ← defeq_simp t,
      trace t',
      exact (expr.const `trivial [])
