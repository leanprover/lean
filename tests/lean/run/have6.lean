prelude
definition Prop : Type.{1} := Type.{0}
constant and : Prop → Prop → Prop
infixl `∧`:25 := and
constant and_intro : forall (a b : Prop), a → b → a ∧ b
constants a b c d : Prop
axiom Ha : a
axiom Hb : b
axiom Hc : c
#check
  have a ∧ b, from and_intro a b Ha Hb,
  have b ∧ a, from and_intro b a Hb Ha,
  have H : a ∧ b, from and_intro a b Ha Hb,
  have H : a ∧ b, from and_intro a b Ha Hb,
  have a ∧ b, from and_intro a b Ha Hb,
  have b ∧ a, from and_intro b a Hb Ha,
  have H : a ∧ b, from and_intro a b Ha Hb,
  have H : a ∧ b, from and_intro a b Ha Hb,
    Ha
