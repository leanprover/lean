prelude
definition Prop : Type.{1} := Type.{0}
constants a b c : Prop
axiom Ha : a
axiom Hb : b
axiom Hc : c
#check have H1 : a, from Ha,
      have H2 : a, from H1,
      have H3 : a, from H2,
      have H4 : a, from H3,
      H4
