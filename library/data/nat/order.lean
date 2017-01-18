/-
Copyright (c) 2014 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Floris van Doorn, Leonardo de Moura, Jeremy Avigad

The order relation on the natural numbers.

This is a minimal port of functions from the lean2 library.
-/

namespace nat

/- min -/

theorem zero_min (a : ℕ) : min 0 a = 0 := min_eq_left (zero_le a)

theorem min_zero (a : ℕ) : min a 0 = 0 := min_eq_right (zero_le a)

end nat
