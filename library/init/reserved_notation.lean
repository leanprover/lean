/-
Copyright (c) 2014 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura, Jeremy Avigad, Floris van Doorn
-/
prelude
import init.datatypes

notation `assume` binders `,` r:(scoped f, f) := r
notation `take`   binders `,` r:(scoped f, f) := r

structure [class] has_zero   (A : Type) := (zero : A)
structure [class] has_one    (A : Type) := (one : A)
structure [class] has_add    (A : Type) := (add : A → A → A)
structure [class] has_mul    (A : Type) := (mul : A → A → A)
structure [class] has_inv    (A : Type) := (inv : A → A)
structure [class] has_neg    (A : Type) := (neg : A → A)
structure [class] has_sub    (A : Type) := (sub : A → A → A)
structure [class] has_div    (A : Type) := (div : A → A → A)
structure [class] has_dvd    (A : Type) := (dvd : A → A → Prop)
structure [class] has_mod    (A : Type) := (mod : A → A → A)
structure [class] has_le     (A : Type) := (le : A → A → Prop)
structure [class] has_lt     (A : Type) := (lt : A → A → Prop)
structure [class] has_append (A : Type) := (append : A → A → A)
structure [class] has_andthen(A : Type) := (andthen : A → A → A)

definition zero    {A : Type} [has_zero A]    : A            := has_zero.zero A
definition one     {A : Type} [has_one A]     : A            := has_one.one A
definition add     {A : Type} [has_add A]     : A → A → A    := has_add.add
definition mul     {A : Type} [has_mul A]     : A → A → A    := has_mul.mul
definition sub     {A : Type} [has_sub A]     : A → A → A    := has_sub.sub
definition div     {A : Type} [has_div A]     : A → A → A    := has_div.div
definition dvd     {A : Type} [has_dvd A]     : A → A → Prop := has_dvd.dvd
definition mod     {A : Type} [has_mod A]     : A → A → A    := has_mod.mod
definition neg     {A : Type} [has_neg A]     : A → A        := has_neg.neg
definition inv     {A : Type} [has_inv A]     : A → A        := has_inv.inv
definition le      {A : Type} [has_le A]      : A → A → Prop := has_le.le
definition lt      {A : Type} [has_lt A]      : A → A → Prop := has_lt.lt
definition append  {A : Type} [has_append A]  : A → A → A    := has_append.append
definition andthen {A : Type} [has_andthen A] : A → A → A    := has_andthen.andthen

attribute [reducible]
definition ge {A : Type} [s : has_le A] (a b : A) : Prop := le b a
attribute [reducible]
definition gt {A : Type} [s : has_lt A] (a b : A) : Prop := lt b a
definition bit0 {A : Type} [s  : has_add A] (a  : A)                 : A := add a a
definition bit1 {A : Type} [s₁ : has_one A] [s₂ : has_add A] (a : A) : A := add (bit0 a) one

attribute [pattern] zero one bit0 bit1 add

attribute [instance]
definition num_has_zero : has_zero num :=
has_zero.mk num.zero

attribute [instance]
definition num_has_one : has_one num :=
has_one.mk (num.pos pos_num.one)

attribute [instance]
definition pos_num_has_one : has_one pos_num :=
has_one.mk (pos_num.one)

namespace pos_num
  definition is_one (a : pos_num) : bool :=
  pos_num.rec_on a tt (λn r, ff) (λn r, ff)

  definition pred (a : pos_num) : pos_num :=
  pos_num.rec_on a one (λn r, bit0 n) (λn r, bool.rec_on (is_one n) (bit1 r) one)

  definition size (a : pos_num) : pos_num :=
  pos_num.rec_on a one (λn r, succ r) (λn r, succ r)

  definition add (a b : pos_num) : pos_num :=
  pos_num.rec_on a
    succ
    (λn f b, pos_num.rec_on b
      (succ (bit1 n))
      (λm r, succ (bit1 (f m)))
      (λm r, bit1 (f m)))
    (λn f b, pos_num.rec_on b
      (bit1 n)
      (λm r, bit1 (f m))
      (λm r, bit0 (f m)))
    b
end pos_num

attribute [instance]
definition pos_num_has_add : has_add pos_num :=
has_add.mk pos_num.add

namespace num
  open pos_num

  definition add (a b : num) : num :=
  num.rec_on a b (λpa, num.rec_on b (pos pa) (λpb, pos (pos_num.add pa pb)))
end num

attribute [instance]
definition num_has_add : has_add num :=
has_add.mk num.add

definition std.priority.default : num := 1000
definition std.priority.max     : num := 4294967295

namespace nat
  protected definition prio := num.add std.priority.default 100

  protected definition add (a b : nat) : nat :=
  nat.rec a (λ b₁ r, succ r) b

  definition of_num (n : num) : nat :=
  num.rec zero
    (λ n, pos_num.rec (succ zero) (λ n r, nat.add (nat.add r r) (succ zero)) (λ n r, nat.add r r) n) n
end nat

attribute pos_num_has_add pos_num_has_one num_has_zero num_has_one num_has_add
          [instance, priority nat.prio]

attribute [instance, priority nat.prio]
definition nat_has_zero : has_zero nat :=
has_zero.mk nat.zero

attribute [instance, priority nat.prio]
definition nat_has_one : has_one nat :=
has_one.mk (nat.succ (nat.zero))

attribute [instance, priority nat.prio]
definition nat_has_add : has_add nat :=
has_add.mk nat.add

/-
  Global declarations of right binding strength

  If a module reassigns these, it will be incompatible with other modules that adhere to these
  conventions.

  When hovering over a symbol, use "C-c C-k" to see how to input it.
-/
definition std.prec.max   : num := 1024 -- the strength of application, identifiers, (, [, etc.
definition std.prec.arrow : num := 25

/-
The next definition is "max + 10". It can be used e.g. for postfix operations that should
be stronger than application.
-/

definition std.prec.max_plus :=
num.succ (num.succ (num.succ (num.succ (num.succ (num.succ (num.succ (num.succ (num.succ
  (num.succ std.prec.max)))))))))

/- Logical operations and relations -/

reserve prefix `¬`:40
reserve prefix `~`:40
reserve infixr ` ∧ `:35
reserve infixr ` /\ `:35
reserve infixr ` \/ `:30
reserve infixr ` ∨ `:30
reserve infix ` <-> `:20
reserve infix ` ↔ `:20
reserve infix ` = `:50
reserve infix ` ≠ `:50
reserve infix ` ≈ `:50
reserve infix ` ~ `:50
reserve infix ` ≡ `:50

reserve infixl ` ⬝ `:75
reserve infixr ` ▸ `:75
reserve infixr ` ▹ `:75

/- types and type constructors -/

reserve infixr ` ⊕ `:30
reserve infixr ` × `:35

/- arithmetic operations -/

reserve infixl ` + `:65
reserve infixl ` - `:65
reserve infixl ` * `:70
reserve infixl ` / `:70
reserve infixl ` % `:70
reserve prefix `-`:100
reserve infix ` ^ `:80

reserve infixr ` ∘ `:90                 -- input with \comp
reserve postfix `⁻¹`:std.prec.max_plus  -- input with \sy or \-1 or \inv

reserve infix ` <= `:50
reserve infix ` ≤ `:50
reserve infix ` < `:50
reserve infix ` >= `:50
reserve infix ` ≥ `:50
reserve infix ` > `:50

/- boolean operations -/

reserve infixl ` && `:70
reserve infixl ` || `:65

/- set operations -/

reserve infix ` ∈ `:50
reserve infix ` ∉ `:50
reserve infixl ` ∩ `:70
reserve infixl ` ∪ `:65
reserve infix ` ⊆ `:50
reserve infix ` ⊇ `:50
reserve infix ` ' `:75   -- for the image of a set under a function
reserve infix ` '- `:75  -- for the preimage of a set under a function

/- other symbols -/

reserve infix ` ∣ `:50
reserve infixl ` ++ `:65
reserve infixr ` :: `:67
reserve infixl `; `:1

infix +    := add
infix *    := mul
infix -    := sub
infix /    := div
infix ∣    := dvd
infix %    := mod
prefix -   := neg
postfix ⁻¹ := inv
infix <=   := le
infix >=   := ge
infix ≤    := le
infix ≥    := ge
infix <    := lt
infix >    := gt
infix ++   := append
infix ;    := andthen
