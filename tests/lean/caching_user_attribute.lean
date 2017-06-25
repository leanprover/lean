@[user_attribute]
meta def foo_attr : caching_user_attribute string :=
{ name     := `foo, descr := "bar",
  mk_cache := λ ns, return $ string.join (list.map (λ n, to_string n ++ "\n") ns),
  dependencies := [] }

attribute [foo] eq.refl eq.mp

set_option trace.user_attributes_cache true

run_cmd do
  s : string ← caching_user_attribute.get_cache foo_attr,
  tactic.trace s,
  s : string ← caching_user_attribute.get_cache foo_attr,
  tactic.trace s,
  tactic.set_basic_attribute `foo ``eq.mpr,
  s : string ← caching_user_attribute.get_cache foo_attr,
  tactic.trace s,
  tactic.set_basic_attribute `reducible ``eq.mp, -- should not affect [foo] cache
  s : string ← caching_user_attribute.get_cache foo_attr,
  tactic.trace s
