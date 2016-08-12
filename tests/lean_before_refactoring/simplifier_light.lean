-- Test [light] annotation
-- Remark: it will take some additional work to get ⁻¹ to rewrite well
-- when there is a proof obligation.
import algebra.ring algebra.field data.set data.finset
open algebra
attribute neg [light 3]
attribute inv [light 3]

attribute add.right_inv [simp]
attribute add_neg_cancel_left [simp]

attribute mul.right_inv [simp]
attribute mul_inv_cancel_left [simp]

open simplifier.unit simplifier.ac

namespace ag
universe l
constants (A : Type.{l}) (s1 : add_comm_group A) (s2 : has_one A)
attribute s1 [instance]
attribute s2 [instance]
constants (x y z w v : A)

#simplify eq env 0 x + y + - x + -y + z + -z
#simplify eq env 0 -100 + -v + -v + x + -v + y + - x + -y + z + -z + v + v + v + 100
end ag

namespace mg
universe l
constants (A : Type.{l}) (s1 : comm_group A) (s2 : has_add A)
attribute s1 [instance]
attribute s2 [instance]
constants (x y z w v : A)

#simplify eq env 0 x⁻¹ * y⁻¹ * z⁻¹ * 100⁻¹ * x * y * z * 100

end mg

namespace s
open set
universe l
constants (A : Type.{l}) (x y z v w : set A)
attribute compl [light 2]

-- TODO(dhs, leo): Where do we put this group of simp rules?
attribute union_compl_self [simp]
attribute [simp]
lemma union_comp_self_left {X : Type} (s t : set X) : s ∪ (-s ∪ t)= univ := sorry

attribute union_comm [simp]
attribute union_assoc [simp]
attribute union_left_comm [simp]

#simplify eq env 0 x ∪ y ∪ z ∪ -x

attribute inter_compl_self [simp]
attribute [simp]
lemma inter_compl_self_left {X : Type} (s t : set X) : s ∩ (-s ∩ t)= empty := sorry

attribute inter_comm [simp]
attribute inter_assoc [simp]
attribute inter_left_comm [simp]

#simplify eq env 0 x ∩ y ∩ z ∩ -x

end s
