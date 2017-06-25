import system.io
variable [io.interface]

#eval do
res ← io.cmd {cmd := "printenv", args := ["foo"], env := [("foo", "bar")]},
when (res ≠ "bar\n") $ io.fail $ "unexpected value for foo: " ++ res