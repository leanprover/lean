namespace foo
  constant le : nat → nat → Prop
  axiom le_trans {a b c : nat} : le a b → le b c → le a c
  attribute [trans] le_trans
  infix `<<`:50 := le
end foo

namespace foo
  theorem T {a b c d : nat} : a << b → b << c → c << d → a << d
  := assume H1 H2 H3,
     calc a  << b : H1
         ... << c : H2
         ... << d : H3
end foo
