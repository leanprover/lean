import algebra.ordered_field

namespace test_comm_ring

universe l
constants (A : Type.{l}) (s : linear_ordered_comm_ring A)
attribute s [instance]

constants (x y z w : A)

set_option blast.strategy "acl"

example : 0 < 1 * y + 1 → 0 < (-1) * y + -1 → false := by blast
example : 0 < 2 * y + 2 → 0 < (-1) * y + -1 → false := by blast
example : 0 < 2 * y → 0 < (-1) * y → false := by blast
example : 0 < 1 * x + 2 * y →  0 < 2 * y + (-1) * x → 0 < (-1) * y → false := by blast
example : 0 < (-3) * x + ((-7) * y + 4) → 0 < 2 * x + -3 → 0 ≤ 1 * y → false := by blast
example : 0 < 1 * w → 0 ≤ 2 * w → 0 < 3 * w → 0 < (-3) * x + ((-7) * y + 4) → 0 < 2 * x + -3 → 0 ≤ 1 * y → false := by blast

end test_comm_ring

-- TODO(dhs): depends on the numeral-inverse lemmas
/-
namespace test_field

universe l
constants (A : Type.{l}) (s : linear_ordered_field A)
attribute s [instance]

constants (x y z w : A)
constants (x_neq_0 : x ≠ 0) (y_neq_0 : y ≠ 0) (z_neq_0 : z ≠ 0) (w_neq_0 : w ≠ 0)
attribute [simp] x_neq_0 y_neq_0 z_neq_0 w_neq_0

attribute neg [light 2]
attribute inv [light 2]

open simplifier.ac simplifier.neg simplifier.unit simplifier.distrib
namespace ac
attribute add.right_inv [simp]
attribute add_neg_cancel_left [simp]

attribute division.def [simp]
attribute mul_inv_cancel [simp]
attribute field.mul_inv_cancel_left [simp]
attribute mul_inv_eq [simp]
attribute division_ring.mul_ne_zero [simp]
end ac

set_option simplify.max_steps 10000
set_option blast.strategy "acl"
set_option simplify.fuse true
set_option trace.simplifier true
#simplify eq env 0 4 * (-1 * 4⁻¹ * z * y⁻¹ * y + -1 * 4⁻¹ + -0) + 1 * 3⁻¹ * (3 * y⁻¹ * z * y + 3 + -0)


--example : 0 < 3 * y⁻¹ * z * y + 3 → 0 < (-1 * 4⁻¹) * z * y⁻¹ * y + -1 * 4⁻¹ → false := by blast
--example : 0 < 2 * 4⁻¹ * y + 3 * 6⁻¹ → 0 < (-1) * y + -1 → false := by blast
--example : 0 < 2 * y → 0 < (-1) * y → false := by blast
--example : 0 < 1 * x + 2 * y →  0 < 2 * y + (-1) * x → 0 < (-1) * y → false := by blast
--example : 0 < (-3) * x + ((-7) * y + 4) → 0 < 2 * x + -3 → 0 ≤ 1 * y → false := by blast
--example : 0 < 1 * w → 0 ≤ 2 * w → 0 < 3 * w → 0 < (-3) * x + ((-7) * y + 4) → 0 < 2 * x + -3 → 0 ≤ 1 * y → false := by blast

end test_field
-/
