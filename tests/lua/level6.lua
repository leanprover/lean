local l = mk_param_univ("l")
print(mk_sort(0))
print(mk_sort(1))
print(mk_sort(2))
print(mk_sort(l+2))
print(mk_sort(mk_level_max(l, 2)))
print(mk_sort(mk_level_imax(l, 2)))
assert(not pcall(function()
                    print(mk_sort(1000000000))
                 end
))
assert(not pcall(function()
                    print(mk_sort(-10))
                 end
))
print(mk_sort(l+0))
assert(not pcall(function()
                    print(mk_sort(0+l))
                 end
))
local z = mk_level_zero()
assert(is_level(z))
assert(z:is_equivalent(0))
