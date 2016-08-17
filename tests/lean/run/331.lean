namespace nat
  inductive less (a : nat) : nat → Prop
  | base : less (succ a)
  | step : Π {b}, less b → less (succ b)

end nat

open nat
check less.rec_on

namespace foo1
protected definition foo2.bar : nat := 10
end foo1

example : foo1.foo2.bar = 10 :=
rfl

open foo1

example : foo2.bar = 10 :=
rfl
