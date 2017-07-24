open tactic

example (a : list nat) : a = [1, 2] → a.map nat.succ = [2, 3] :=
begin
  intros,
  guard_target list.map nat.succ a = [2, 3],
  subst a,
  dsimp [list.map],
  guard_target [nat.succ 1, nat.succ 2] = [2, 3],
  reflexivity
end
