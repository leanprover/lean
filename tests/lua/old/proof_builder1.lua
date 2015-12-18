local pb = proof_builder(function(m, a)
                            print("builder...")
                            local e = m:find("main")
                            print(e)
                            return e
                         end)
assert(is_proof_builder(pb))
local a = assignment()
assert(is_assignment(a))
local m = proof_map()
assert(#m == 0)
assert(is_proof_map(m))
m:insert("main", Const("H"))
m:insert("subgoal", Const("H1"))
m:erase("subgoal")
assert(not pcall(function() m:find("subgoal") end))
print(m:find("main"))
print(pb(m, a))
assert(pb(m, a) == Const("H"))
