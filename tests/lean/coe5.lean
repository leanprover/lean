open tactic

attribute [instance]
definition expr_to_app : has_coe_to_fun expr :=
has_coe_to_fun.mk (expr → expr) (λ e, expr.app e)

constants f a b : expr

check f a

check f a b

check f a b a

set_option pp.coercions false

check f a b a

set_option pp.all true
set_option pp.coercions true

check f a b
