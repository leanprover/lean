set_option trace.inductive_compiler.nested.define.failure true
set_option max_memory 1000000

inductive {u} vec (A : Type u) : nat -> Type u
| vnil : vec 0
| vcons : Pi (n : nat), A -> vec n -> vec (n+1)

namespace X1
print "simple"
inductive foo : Type
| mk : list foo -> foo

end X1

namespace X2
print "with param"
inductive {u} foo (A : Type u) : Type u
| mk : A -> list foo -> foo

end X2

namespace X3
print "with indices"
inductive {u} foo (A B : Type u) : Type u
| mk : A -> B -> vec foo 0 -> foo

end X3

namespace X4
print "with locals in indices"
inductive {u} foo (A : Type u) : Type u
| mk : Pi (n : nat), A -> vec foo n -> foo

end X4

namespace X5
print "nested-reflexive"
inductive {u} foo (A : Type u) : Type u
| mk : A -> (Pi (m : nat), vec foo m) -> foo

end X5

namespace X6
print "locals + nested-reflexive locals in indices"
inductive {u} foo (A : Type u) : Type u
| mk : Pi (n : nat), A -> (Pi (m : nat), vec foo (n + m)) -> foo

end X6

namespace X7
print "many different nestings"
inductive {u} foo (A : Type u) : Type u
| mk : Pi (n : nat), A -> list A -> prod A A -> (Pi (m : nat), vec foo (n + m)) -> vec foo n -> foo

end X7

namespace X8
print "many different nestings, some sharing"
inductive {u} foo (A : Type u) : Type u
| mk₁ : Pi (n : nat), A -> (Pi (m : nat), vec (list foo) (n + m)) -> vec foo n -> foo
| mk₂ : Pi (n : nat), A -> list A -> prod A A -> (Pi (m : nat), vec foo (n + m)) -> vec foo n -> foo

end X8

namespace X9b
print "mutual + nesting"
mutual inductive {u} foo, bar
with foo : Type u
| mk : list (list foo) -> foo
with bar : Type u
| mk : list foo -> bar

end X9b

namespace X10
print "many layers of nesting nested inductive types"

inductive wrap (A : Sort*)
| mk : A -> wrap

inductive box (A : Sort*)
| mk : A -> wrap box -> box

inductive foo (A : Sort*)
| mk : A -> box foo -> foo

inductive bar
| mk : foo bar -> bar

end X10

namespace X11
print "intro rule that introduces additional nesting"

inductive {u} wrap (A : Type u) : Type u
| mk : list A -> wrap

inductive {u} foo : Type u
| mk : wrap foo -> foo

end X11

namespace X12
print "intro rule that introduces a lot of additional nesting"

inductive wrap (A : Sort*) : Sort*
| mk : list (list A) -> wrap

inductive {u} box (A : Type u) : Type u
| mk : A -> wrap box -> box

end X12

namespace X13
print "with reducible definitions"

attribute [reducible] definition list' := @list

inductive wrap (A : Sort*) : Sort*
| mk : A -> list' A -> wrap

attribute [reducible] definition wrap' := @wrap

inductive {u} foo (A : Type u) : Type u
| mk : A -> wrap' (list' foo) -> foo

end X13

namespace X14
print "with indices in original"

inductive Foo : bool -> Type
| mk : list (Foo ff) -> Foo tt

end X14

namespace X15
print "nested inductive propositions"

universe variable l
inductive plist (A : Sort l) : Sort l
| nil : plist
| cons : A → plist → plist

inductive foo (A : Type) : ℕ → Prop
| mk : A → plist (plist (foo 0)) → foo 1

end X15

namespace X16
print "multiply nested inductive propositions"

universe variable l
inductive wrap (A : Sort l) : Sort l
| mk : A -> wrap

inductive box (A : Prop) : Prop
| mk : A -> wrap box -> box

inductive foo (A : Sort*) : Prop
| mk : A -> box foo -> foo

inductive bar : Prop
| mk : foo bar -> bar

end X16
