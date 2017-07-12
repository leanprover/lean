/-
Copyright (c) 2016 Jared Roesch. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jared Roesch
-/

import init.meta.name
import init.meta.expr

@[reducible] meta def procedure :=
  name × expr

@[reducible] def extern_fn :=
  bool × name × unsigned

meta def procedure.repr : procedure → string
| (n, e) := "def " ++ to_string n ++ " := \n" ++ to_string e -- to_string for expr does not produce string that can be parsed by Lean

meta def procedure.map_body (f : expr → expr) : procedure → procedure
| (n, e) := (n, f e)

meta instance : has_repr procedure :=
⟨procedure.repr⟩
