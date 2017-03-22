meta def get_file (fn : name) : vm format :=
do {
  d ← vm.get_decl fn,
  some n ← return (vm_decl.olean d) | failure,
  return (to_fmt n)
}
<|>
return (to_fmt "<curr file>")

meta def pos_info (fn : name) : vm format :=
do {
  d        ← vm.get_decl fn,
  some pos ← return (vm_decl.pos d) | failure,
  file     ← get_file fn,
  return (file ++ ":" ++ pos.1 ++ ":" ++ pos.2)
}
<|>
return (to_fmt "<position not available>")

@[vm_monitor]
meta def basic_monitor : vm_monitor nat :=
{ init := 1000,
  step := λ sz, do
    csz ← vm.call_stack_size,
    if sz = csz then return sz
    else do
      fn  ← vm.curr_fn,
      pos ← pos_info fn,
      vm.trace (to_fmt "[" ++ csz ++ "]: " ++ to_fmt fn ++ " @ " ++ pos),
      return csz }

set_option debugger true

def f : nat → nat
| 0     := 0
| (a+1) := f a

#eval trace "a" (f 4)
