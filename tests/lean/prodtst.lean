--

inductive prod2 (A B : Type₊)
| mk : A → B → prod2

set_option pp.universes true
check @prod2
