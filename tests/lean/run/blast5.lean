set_option blast.init_depth 10

example (a b : nat) : a = b → b = a :=
by blast

example (a b c : nat) : a = b → a = c → b = c :=
by blast

example (p : nat → Prop) (a b c : nat) : a = b → a = c → p b → p c :=
by blast
