import data.finset data.set
open set finset
set_option blast.strategy "cc"

structure finite_set [class] {T : Type} (xs : set T) :=
(to_finset : finset T) (is_equiv : to_set to_finset = xs)

attribute [instance]
definition finset_set.is_subsingleton (T : Type) (xs : set T) : subsingleton (finite_set xs) :=
begin
  constructor, intro a b,
  induction a with f₁ h₁,
  induction b with f₂ h₂,
  subst xs,
  note e := to_set.inj h₂,
  subst e
end

/- Add some instances for finite_sets -/
variable {A : Type}
attribute [instance]
definition finite_set_empty : finite_set (∅:set A) := sorry
attribute [instance]
definition finite_set_finset (fxs : finset A) : finite_set (to_set fxs) := sorry
attribute [instance]
definition finite_set_insert (xs : set A) [finite_set xs] (x : A) : finite_set (insert x xs) := sorry
attribute [instance]
definition finite_set_union (xs : set A) [finite_set xs] (ys : set A) [finite_set ys] : finite_set (xs ∪ ys) := sorry
attribute [instance]
definition finite_set_inter1 (xs : set A) [finite_set xs] (ys : set A) [decidable_pred ys] : finite_set (xs ∩ ys) := sorry
attribute [instance]
definition finite_set_inter2 (xs : set A) [finite_set xs] (ys : set A) [decidable_pred ys] : finite_set (ys ∩ xs) := sorry
attribute [instance]
definition finite_set_set_of (xs : set A) [finite_set xs] : finite_set (set.set_of xs) := sorry

/- Defined cardinality using finite_set type class -/
noncomputable definition mycard {T : Type} (xs : set T) [finite_set xs] :=
finset.card (to_finset xs)

/- Congruence closure still works :-) -/
definition tst
        (A : Type) (s₁ s₂ s₃ s₄ s₅ s₆ : set A)
        [finite_set s₁] [finite_set s₂]
        [finite_set s₃] [finite_set s₄]
        [decidable_pred s₅] [decidable_pred s₆] :
        s₁ = s₂ → s₃ = s₄ → s₆ = s₅ → mycard ((s₁ ∪ s₃) ∩ s₅) = mycard ((s₂ ∪ s₄) ∩ s₆) :=
by blast

print tst
