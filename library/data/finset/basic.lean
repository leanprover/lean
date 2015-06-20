/-
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Leonardo de Moura, Jeremy Avigad

Finite sets.
-/
import data.fintype.basic data.nat data.list.perm data.subtype algebra.binary
open nat quot list subtype binary function
open [declarations] perm

definition nodup_list (A : Type) := {l : list A | nodup l}

variable {A : Type}

definition to_nodup_list_of_nodup {l : list A} (n : nodup l) : nodup_list A :=
tag l n

definition to_nodup_list [h : decidable_eq A] (l : list A) : nodup_list A :=
@to_nodup_list_of_nodup A (erase_dup l) (nodup_erase_dup l)

private definition equiv (l₁ l₂ : nodup_list A) :=
perm (elt_of l₁) (elt_of l₂)

local infix ~ := equiv

private definition equiv.refl (l : nodup_list A) : l ~ l :=
!perm.refl

private definition equiv.symm {l₁ l₂ : nodup_list A} : l₁ ~ l₂ → l₂ ~ l₁ :=
assume p, perm.symm p

private definition equiv.trans {l₁ l₂ l₃ : nodup_list A} : l₁ ~ l₂ → l₂ ~ l₃ → l₁ ~ l₃ :=
assume p₁ p₂, perm.trans p₁ p₂

definition finset.nodup_list_setoid [instance] (A : Type) : setoid (nodup_list A) :=
setoid.mk (@equiv A) (mk_equivalence (@equiv A) (@equiv.refl A) (@equiv.symm A) (@equiv.trans A))

definition finset (A : Type) : Type :=
quot (finset.nodup_list_setoid A)

namespace finset

definition to_finset_of_nodup (l : list A) (n : nodup l) : finset A :=
⟦to_nodup_list_of_nodup n⟧

definition to_finset [h : decidable_eq A] (l : list A) : finset A :=
⟦to_nodup_list l⟧

lemma to_finset_eq_of_nodup [h : decidable_eq A] {l : list A} (n : nodup l) :
  to_finset_of_nodup l n = to_finset l :=
assert P : to_nodup_list_of_nodup n = to_nodup_list l, from
  begin
    rewrite [↑to_nodup_list, ↑to_nodup_list_of_nodup],
    congruence,
    rewrite [erase_dup_eq_of_nodup n]
  end,
quot.sound (eq.subst P !setoid.refl)

definition has_decidable_eq [instance] [h : decidable_eq A] : decidable_eq (finset A) :=
λ s₁ s₂, quot.rec_on_subsingleton₂ s₁ s₂
  (λ l₁ l₂,
     match decidable_perm (elt_of l₁) (elt_of l₂) with
     | decidable.inl e := decidable.inl (quot.sound e)
     | decidable.inr n := decidable.inr (λ e : ⟦l₁⟧ = ⟦l₂⟧, absurd (quot.exact e) n)
     end)

definition mem (a : A) (s : finset A) : Prop :=
quot.lift_on s (λ l, a ∈ elt_of l)
 (λ l₁ l₂ (e : l₁ ~ l₂), propext (iff.intro
   (λ ainl₁, mem_perm e ainl₁)
   (λ ainl₂, mem_perm (perm.symm e) ainl₂)))

infix `∈` := mem
notation a ∉ b := ¬ mem a b

theorem mem_of_mem_list {a : A} {l : nodup_list A} : a ∈ elt_of l → a ∈ ⟦l⟧ :=
λ ainl, ainl

theorem mem_list_of_mem {a : A} {l : nodup_list A} : a ∈ ⟦l⟧ → a ∈ elt_of l :=
λ ainl, ainl

/- singleton -/
definition singleton (a : A) : finset A :=
to_finset_of_nodup [a] !nodup_singleton

theorem mem_singleton (a : A) : a ∈ singleton a :=
mem_of_mem_list !mem_cons

theorem eq_of_mem_singleton {x a : A} : x ∈ singleton a → x = a :=
list.mem_singleton

theorem mem_singleton_eq (x a : A) : (x ∈ singleton a) = (x = a) :=
propext (iff.intro eq_of_mem_singleton (assume H, eq.subst H !mem_singleton))

definition decidable_mem [instance] [h : decidable_eq A] : ∀ (a : A) (s : finset A), decidable (a ∈ s) :=
λ a s, quot.rec_on_subsingleton s
  (λ l, match list.decidable_mem a (elt_of l) with
        | decidable.inl p := decidable.inl (mem_of_mem_list p)
        | decidable.inr n := decidable.inr (λ p, absurd (mem_list_of_mem p) n)
        end)

theorem mem_to_finset [h : decidable_eq A] {a : A} {l : list A} : a ∈ l → a ∈ to_finset l :=
λ ainl, mem_erase_dup ainl

theorem mem_to_finset_of_nodup {a : A} {l : list A} (n : nodup l) : a ∈ l → a ∈ to_finset_of_nodup l n :=
λ ainl, ainl

/- extensionality -/
theorem ext {s₁ s₂ : finset A} : (∀ a, a ∈ s₁ ↔ a ∈ s₂) → s₁ = s₂ :=
quot.induction_on₂ s₁ s₂ (λ l₁ l₂ e, quot.sound (perm_ext (has_property l₁) (has_property l₂) e))

/- empty -/
definition empty : finset A :=
to_finset_of_nodup [] nodup_nil

notation `∅` := !empty

theorem not_mem_empty (a : A) : a ∉ ∅ :=
λ aine : a ∈ ∅, aine

theorem mem_empty_iff (x : A) : x ∈ ∅ ↔ false :=
iff.mp' !iff_false_iff_not !not_mem_empty

theorem mem_empty_eq (x : A) : x ∈ ∅ = false :=
propext !mem_empty_iff

theorem eq_empty_of_forall_not_mem {s : finset A} (H : ∀x, ¬ x ∈ s) : s = ∅ :=
ext (take x, iff_false_intro (H x))

/- universe -/
definition univ [h : fintype A] : finset A :=
to_finset_of_nodup (@fintype.elems A h) (@fintype.unique A h)

theorem mem_univ [h : fintype A] (x : A) : x ∈ univ :=
fintype.complete x

theorem mem_univ_eq [h : fintype A] (x : A) : x ∈ univ = true := propext (iff_true_intro !mem_univ)

/- card -/
definition card (s : finset A) : nat :=
quot.lift_on s
  (λ l, length (elt_of l))
  (λ l₁ l₂ p, length_eq_length_of_perm p)

theorem card_empty : card (@empty A) = 0 :=
rfl

theorem card_singleton (a : A) : card (singleton a) = 1 :=
rfl

/- insert -/
section insert
variable [h : decidable_eq A]
include h

definition insert (a : A) (s : finset A) : finset A :=
quot.lift_on s
  (λ l, to_finset_of_nodup (insert a (elt_of l)) (nodup_insert a (has_property l)))
  (λ (l₁ l₂ : nodup_list A) (p : l₁ ~ l₂), quot.sound (perm_insert a p))

-- set builder notation
notation `{[`:max a:(foldr `,` (x b, insert x b) ∅) `]}`:0 := a
-- notation `⦃` a:(foldr `,` (x b, insert x b) ∅) `⦄` := a

theorem mem_insert (a : A) (s : finset A) : a ∈ insert a s :=
quot.induction_on s
 (λ l : nodup_list A, mem_to_finset_of_nodup _ !list.mem_insert)

theorem mem_insert_of_mem {a : A} {s : finset A} (b : A) : a ∈ s → a ∈ insert b s :=
quot.induction_on s
 (λ (l : nodup_list A) (ainl : a ∈ ⟦l⟧), mem_to_finset_of_nodup _ (list.mem_insert_of_mem _ ainl))

theorem eq_or_mem_of_mem_insert {x a : A} {s : finset A} : x ∈ insert a s → x = a ∨ x ∈ s :=
quot.induction_on s (λ l : nodup_list A, λ H, list.eq_or_mem_of_mem_insert H)

theorem mem_of_mem_insert_of_ne {x a : A} {s : finset A} : x ∈ insert a s → x ≠ a → x ∈ s :=
λ xin xne, or.elim (eq_or_mem_of_mem_insert xin) (by contradiction) id

theorem mem_insert_eq (x a : A) (s : finset A) : x ∈ insert a s = (x = a ∨ x ∈ s) :=
propext (iff.intro
  (!eq_or_mem_of_mem_insert)
  (assume H, or.elim H
    (assume H' : x = a, eq.subst (eq.symm H') !mem_insert)
    (assume H' : x ∈ s, !mem_insert_of_mem H')))

theorem insert_empty_eq (a : A) : {[ a ]} = singleton a := rfl

theorem insert_eq_of_mem {a : A} {s : finset A} (H : a ∈ s) : insert a s = s :=
ext
  take x,
  begin
    rewrite [!mem_insert_eq],
    show x = a ∨ x ∈ s ↔ x ∈ s, from
      iff.intro
        (assume H1, or.elim H1
           (assume H2 : x = a, eq.subst (eq.symm H2) H)
           (assume H2, H2))
        (assume H1, or.inr H1)
  end

theorem card_insert_of_mem {a : A} {s : finset A} : a ∈ s → card (insert a s) = card s :=
quot.induction_on s
  (λ (l : nodup_list A) (ainl : a ∈ ⟦l⟧), list.length_insert_of_mem ainl)

theorem card_insert_of_not_mem {a : A} {s : finset A} : a ∉ s → card (insert a s) = card s + 1 :=
quot.induction_on s
  (λ (l : nodup_list A) (nainl : a ∉ ⟦l⟧), list.length_insert_of_not_mem nainl)

theorem card_insert_le (a : A) (s : finset A) :
  card (insert a s) ≤ card s + 1 :=
decidable.by_cases
  (assume H : a ∈ s, by rewrite [card_insert_of_mem H]; apply le_succ)
  (assume H : a ∉ s, by rewrite [card_insert_of_not_mem H])

lemma non_empty_of_card_succ {s : finset A} {n : nat} : card s = succ n → s ≠ ∅ :=
by intros; substvars; contradiction

protected theorem induction [recursor 6] {P : finset A → Prop}
    (H1 : P empty)
    (H2 : ∀ ⦃a : A⦄, ∀{s : finset A}, a ∉ s → P s → P (insert a s)) :
  ∀s, P s :=
take s,
quot.induction_on s
 (take u,
  subtype.destruct u
   (take l,
    list.induction_on l
      (assume nodup_l, H1)
      (take a l',
        assume IH nodup_al',
        have anl' : a ∉ l', from not_mem_of_nodup_cons nodup_al',
        assert H3 : list.insert a l' = a :: l', from insert_eq_of_not_mem anl',
        assert nodup_l' : nodup l', from nodup_of_nodup_cons nodup_al',
        assert P_l' : P (quot.mk (subtype.tag l' nodup_l')), from IH nodup_l',
        assert H4 : P (insert a (quot.mk (subtype.tag l' nodup_l'))), from H2 anl' P_l',
        begin
          revert nodup_al',
          rewrite [-H3],
          intros,
          apply H4
        end)))

protected theorem induction_on {P : finset A → Prop} (s : finset A)
    (H1 : P empty)
    (H2 : ∀ ⦃a : A⦄, ∀ {s : finset A}, a ∉ s → P s → P (insert a s)) :
  P s :=
finset.induction H1 H2 s

theorem exists_of_not_empty {s : finset A} : s ≠ ∅ → ∃ a : A, a ∈ s :=
begin
  induction s with a s nin ih,
    {intro h, exact absurd rfl h},
    {intro h, existsi a, apply mem_insert}
end

theorem eq_empty_of_card_eq_zero {s : finset A} (H : card s = 0) : s = ∅ :=
begin
  induction s with a s' H1 IH,
  { reflexivity },
  { rewrite (card_insert_of_not_mem H1) at H, apply nat.no_confusion H}
end

end insert

/- erase -/
section erase
variable [h : decidable_eq A]
include h

definition erase (a : A) (s : finset A) : finset A :=
quot.lift_on s
  (λ l, to_finset_of_nodup (erase a (elt_of l)) (nodup_erase_of_nodup a (has_property l)))
  (λ (l₁ l₂ : nodup_list A) (p : l₁ ~ l₂), quot.sound (erase_perm_erase_of_perm a p))

theorem mem_erase (a : A) (s : finset A) : a ∉ erase a s :=
quot.induction_on s
  (λ l, list.mem_erase_of_nodup _ (has_property l))

theorem card_erase_of_mem {a : A} {s : finset A} : a ∈ s → card (erase a s) = pred (card s) :=
quot.induction_on s (λ l ainl, list.length_erase_of_mem ainl)

theorem card_erase_of_not_mem {a : A} {s : finset A} : a ∉ s → card (erase a s) = card s :=
quot.induction_on s (λ l nainl, list.length_erase_of_not_mem nainl)

theorem erase_empty (a : A) : erase a ∅ = ∅ :=
rfl

theorem ne_of_mem_erase {a b : A} {s : finset A} : b ∈ erase a s → b ≠ a :=
by intro h beqa; subst b; exact absurd h !mem_erase

theorem mem_of_mem_erase {a b : A} {s : finset A} : b ∈ erase a s → b ∈ s :=
quot.induction_on s (λ l bin, mem_of_mem_erase bin)

theorem mem_erase_of_ne_of_mem {a b : A} {s : finset A} : a ≠ b → a ∈ s → a ∈ erase b s :=
quot.induction_on s (λ l n ain, list.mem_erase_of_ne_of_mem n ain)

open decidable
theorem erase_insert (a : A) (s : finset A) : a ∉ s → erase a (insert a s) = s :=
λ anins, finset.ext (λ b, by_cases
  (λ beqa : b = a, iff.intro
    (λ bin, by subst b; exact absurd bin !mem_erase)
    (λ bin, by subst b; contradiction))
  (λ bnea : b ≠ a, iff.intro
    (λ bin,
       assert bin' : b ∈ insert a s, from mem_of_mem_erase bin,
       mem_of_mem_insert_of_ne bin' bnea)
    (λ bin,
      have bin' : b ∈ insert a s, from mem_insert_of_mem _ bin,
      mem_erase_of_ne_of_mem bnea bin')))

theorem insert_erase {a : A} {s : finset A} : a ∈ s → insert a (erase a s) = s :=
λ ains, finset.ext (λ b, by_cases
  (λ beqa : b = a, iff.intro
    (λ bin, by subst b; assumption)
    (λ bin, by subst b; apply mem_insert))
  (λ bnea : b ≠ a, iff.intro
    (λ bin, mem_of_mem_erase (mem_of_mem_insert_of_ne bin bnea))
    (λ bin, mem_insert_of_mem _ (mem_erase_of_ne_of_mem bnea bin))))
end erase

/- union -/
section union
variable [h : decidable_eq A]
include h

definition union (s₁ s₂ : finset A) : finset A :=
quot.lift_on₂ s₁ s₂
  (λ l₁ l₂,
    to_finset_of_nodup (list.union (elt_of l₁) (elt_of l₂))
                       (nodup_union_of_nodup_of_nodup (has_property l₁) (has_property l₂)))
  (λ v₁ v₂ w₁ w₂ p₁ p₂, quot.sound (perm_union p₁ p₂))

notation s₁ ∪ s₂ := union s₁ s₂

theorem mem_union_left {a : A} {s₁ : finset A} (s₂ : finset A) : a ∈ s₁ → a ∈ s₁ ∪ s₂ :=
quot.induction_on₂ s₁ s₂ (λ l₁ l₂ ainl₁, list.mem_union_left _ ainl₁)

theorem mem_union_l {a : A} {s₁ : finset A} {s₂ : finset A} : a ∈ s₁ → a ∈ s₁ ∪ s₂ :=
mem_union_left s₂

theorem mem_union_right {a : A} {s₂ : finset A} (s₁ : finset A) : a ∈ s₂ → a ∈ s₁ ∪ s₂ :=
quot.induction_on₂ s₁ s₂ (λ l₁ l₂ ainl₂, list.mem_union_right _ ainl₂)

theorem mem_union_r {a : A} {s₂ : finset A} {s₁ : finset A} : a ∈ s₂ → a ∈ s₁ ∪ s₂ :=
mem_union_right s₁

theorem mem_or_mem_of_mem_union {a : A} {s₁ s₂ : finset A} : a ∈ s₁ ∪ s₂ → a ∈ s₁ ∨ a ∈ s₂ :=
quot.induction_on₂ s₁ s₂ (λ l₁ l₂ ainl₁l₂, list.mem_or_mem_of_mem_union ainl₁l₂)

theorem mem_union_iff (a : A) (s₁ s₂ : finset A) : a ∈ s₁ ∪ s₂ ↔ a ∈ s₁ ∨ a ∈ s₂ :=
iff.intro
 (λ h, mem_or_mem_of_mem_union h)
 (λ d, or.elim d
   (λ i, mem_union_left _ i)
   (λ i, mem_union_right _ i))

theorem mem_union_eq (a : A) (s₁ s₂ : finset A) : (a ∈ s₁ ∪ s₂) = (a ∈ s₁ ∨ a ∈ s₂) :=
propext !mem_union_iff

theorem union.comm (s₁ s₂ : finset A) : s₁ ∪ s₂ = s₂ ∪ s₁ :=
ext (λ a, by rewrite [*mem_union_eq]; exact or.comm)

theorem union.assoc (s₁ s₂ s₃ : finset A) : (s₁ ∪ s₂) ∪ s₃ = s₁ ∪ (s₂ ∪ s₃) :=
ext (λ a, by rewrite [*mem_union_eq]; exact or.assoc)

theorem union_self (s : finset A) : s ∪ s = s :=
ext (λ a, iff.intro
  (λ ain, or.elim (mem_or_mem_of_mem_union ain) (λ i, i) (λ i, i))
  (λ i, mem_union_left _ i))

theorem union_empty (s : finset A) : s ∪ ∅ = s :=
ext (λ a, iff.intro
  (λ ain : a ∈ s ∪ ∅, or.elim (mem_or_mem_of_mem_union ain) (λ i, i) (λ i, absurd i !not_mem_empty))
  (λ i   : a ∈ s, mem_union_left _ i))

theorem empty_union (s : finset A) : ∅ ∪ s = s :=
calc ∅ ∪ s = s ∪ ∅ : union.comm
       ... = s     : union_empty

theorem insert_eq (a : A) (s : finset A) : insert a s = singleton a ∪ s :=
ext (take x,
  calc
    x ∈ insert a s ↔ x ∈ insert a s            : iff.refl
               ... = (x = a ∨ x ∈ s)           : mem_insert_eq
               ... = (x ∈ singleton a ∨ x ∈ s) : mem_singleton_eq
               ... = (x ∈ {[ a ]} ∪ s)         : mem_union_eq)

theorem insert_union (a : A) (s t : finset A) : insert a (s ∪ t) = insert a s ∪ t :=
by rewrite [*insert_eq, union.assoc]
end union

/- inter -/
section inter
variable [h : decidable_eq A]
include h

definition inter (s₁ s₂ : finset A) : finset A :=
quot.lift_on₂ s₁ s₂
  (λ l₁ l₂,
    to_finset_of_nodup (list.inter (elt_of l₁) (elt_of l₂))
                       (nodup_inter_of_nodup _ (has_property l₁)))
  (λ v₁ v₂ w₁ w₂ p₁ p₂, quot.sound (perm_inter p₁ p₂))

notation s₁ ∩ s₂ := inter s₁ s₂

theorem mem_of_mem_inter_left {a : A} {s₁ s₂ : finset A} : a ∈ s₁ ∩ s₂ → a ∈ s₁ :=
quot.induction_on₂ s₁ s₂ (λ l₁ l₂ ainl₁l₂, list.mem_of_mem_inter_left ainl₁l₂)

theorem mem_of_mem_inter_right {a : A} {s₁ s₂ : finset A} : a ∈ s₁ ∩ s₂ → a ∈ s₂ :=
quot.induction_on₂ s₁ s₂ (λ l₁ l₂ ainl₁l₂, list.mem_of_mem_inter_right ainl₁l₂)

theorem mem_inter {a : A} {s₁ s₂ : finset A} : a ∈ s₁ → a ∈ s₂ → a ∈ s₁ ∩ s₂ :=
quot.induction_on₂ s₁ s₂ (λ l₁ l₂ ainl₁ ainl₂, list.mem_inter_of_mem_of_mem ainl₁ ainl₂)

theorem mem_inter_iff (a : A) (s₁ s₂ : finset A) : a ∈ s₁ ∩ s₂ ↔ a ∈ s₁ ∧ a ∈ s₂ :=
iff.intro
 (λ h, and.intro (mem_of_mem_inter_left h) (mem_of_mem_inter_right h))
 (λ h, mem_inter (and.elim_left h) (and.elim_right h))

theorem mem_inter_eq (a : A) (s₁ s₂ : finset A) : (a ∈ s₁ ∩ s₂) = (a ∈ s₁ ∧ a ∈ s₂) :=
propext !mem_inter_iff

theorem inter.comm (s₁ s₂ : finset A) : s₁ ∩ s₂ = s₂ ∩ s₁ :=
ext (λ a, by rewrite [*mem_inter_eq]; exact and.comm)

theorem inter.assoc (s₁ s₂ s₃ : finset A) : (s₁ ∩ s₂) ∩ s₃ = s₁ ∩ (s₂ ∩ s₃) :=
ext (λ a, by rewrite [*mem_inter_eq]; exact and.assoc)

theorem inter_self (s : finset A) : s ∩ s = s :=
ext (λ a, iff.intro
  (λ h, mem_of_mem_inter_right h)
  (λ h, mem_inter h h))

theorem inter_empty (s : finset A) : s ∩ ∅ = ∅ :=
ext (λ a, iff.intro
  (λ h : a ∈ s ∩ ∅, absurd (mem_of_mem_inter_right h) !not_mem_empty)
  (λ h : a ∈ ∅,     absurd h !not_mem_empty))

theorem empty_inter (s : finset A) : ∅ ∩ s = ∅ :=
calc ∅ ∩ s = s ∩ ∅ : inter.comm
       ... = ∅     : inter_empty

theorem singleton_inter_of_mem {a : A} {s : finset A} (H : a ∈ s) :
  singleton a ∩ s = singleton a :=
ext (take x,
  begin
    rewrite [mem_inter_eq, !mem_singleton_eq],
    exact iff.intro
      (assume H1 : x = a ∧ x ∈ s, and.left H1)
      (assume H1 : x = a, and.intro H1 (eq.subst (eq.symm H1) H))
  end)

theorem singleton_inter_of_not_mem {a : A} {s : finset A} (H : a ∉ s) :
  singleton a ∩ s = ∅ :=
ext (take x,
  begin
    rewrite [mem_inter_eq, !mem_singleton_eq, mem_empty_eq],
    exact iff.intro
      (assume H1 : x = a ∧ x ∈ s, H (eq.subst (and.left H1) (and.right H1)))
      (false.elim)
  end)
end inter

/- distributivity laws -/
section inter
variable [h : decidable_eq A]
include h

theorem inter.distrib_left (s t u : finset A) : s ∩ (t ∪ u) = (s ∩ t) ∪ (s ∩ u) :=
ext (take x, by rewrite [mem_inter_eq, *mem_union_eq, *mem_inter_eq]; apply and.distrib_left)

theorem inter.distrib_right (s t u : finset A) : (s ∪ t) ∩ u = (s ∩ u) ∪ (t ∩ u) :=
ext (take x, by rewrite [mem_inter_eq, *mem_union_eq, *mem_inter_eq]; apply and.distrib_right)

theorem union.distrib_left (s t u : finset A) : s ∪ (t ∩ u) = (s ∪ t) ∩ (s ∪ u) :=
ext (take x, by rewrite [mem_union_eq, *mem_inter_eq, *mem_union_eq]; apply or.distrib_left)

theorem union.distrib_right (s t u : finset A) : (s ∩ t) ∪ u = (s ∪ u) ∩ (t ∪ u) :=
ext (take x, by rewrite [mem_union_eq, *mem_inter_eq, *mem_union_eq]; apply or.distrib_right)
end inter

/- disjoint -/
-- Mainly for internal use; library will use s₁ ∩ s₂ = ∅. Note that it does not require decidable equality.
definition disjoint (s₁ s₂ : finset A) : Prop :=
quot.lift_on₂ s₁ s₂ (λ l₁ l₂, disjoint (elt_of l₁) (elt_of l₂))
  (λ v₁ v₂ w₁ w₂ p₁ p₂, propext (iff.intro
    (λ d₁ a (ainw₁ : a ∈ elt_of w₁),
      have ainv₁  : a ∈ elt_of v₁, from mem_perm (perm.symm p₁) ainw₁,
      have nainv₂ : a ∉ elt_of v₂, from disjoint_left d₁ ainv₁,
      not_mem_perm p₂ nainv₂)
    (λ d₂ a (ainv₁ : a ∈ elt_of v₁),
      have ainw₁  : a ∈ elt_of w₁, from mem_perm p₁ ainv₁,
      have nainw₂ : a ∉ elt_of w₂, from disjoint_left d₂ ainw₁,
      not_mem_perm (perm.symm p₂) nainw₂)))

theorem disjoint.elim {s₁ s₂ : finset A} {x : A} :
  disjoint s₁ s₂ → x ∈ s₁ → x ∈ s₂ → false :=
quot.induction_on₂ s₁ s₂ (take u₁ u₂, assume H H1 H2, H x H1 H2)

theorem disjoint.intro {s₁ s₂ : finset A} : (∀{x : A}, x ∈ s₁ → x ∈ s₂ → false) → disjoint s₁ s₂ :=
quot.induction_on₂ s₁ s₂ (take u₁ u₂, assume H, H)

theorem inter_eq_empty_of_disjoint [h : decidable_eq A] {s₁ s₂ : finset A} (H : disjoint s₁ s₂) : s₁ ∩ s₂ = ∅ :=
ext (take x, iff_false_intro (assume H1,
  disjoint.elim H (mem_of_mem_inter_left H1) (mem_of_mem_inter_right H1)))

theorem disjoint_of_inter_eq_empty [h : decidable_eq A] {s₁ s₂ : finset A} (H : s₁ ∩ s₂ = ∅) : disjoint s₁ s₂ :=
disjoint.intro (take x H1 H2,
  have H3 : x ∈ s₁ ∩ s₂, from mem_inter H1 H2,
  !not_mem_empty (eq.subst H H3))

theorem disjoint.comm {s₁ s₂ : finset A} : disjoint s₁ s₂ → disjoint s₂ s₁ :=
quot.induction_on₂ s₁ s₂ (λ l₁ l₂ d, list.disjoint.comm d)

theorem inter_eq_empty [h : decidable_eq A] {s₁ s₂ : finset A}
    (H : ∀x : A, x ∈ s₁ → x ∈ s₂ → false) : s₁ ∩ s₂ = ∅ :=
inter_eq_empty_of_disjoint (disjoint.intro H)

/- subset -/
definition subset (s₁ s₂ : finset A) : Prop :=
quot.lift_on₂ s₁ s₂
  (λ l₁ l₂, sublist (elt_of l₁) (elt_of l₂))
  (λ v₁ v₂ w₁ w₂ p₁ p₂, propext (iff.intro
    (λ s₁ a i, mem_perm p₂ (s₁ a (mem_perm (perm.symm p₁) i)))
    (λ s₂ a i, mem_perm (perm.symm p₂) (s₂ a (mem_perm p₁ i)))))

infix `⊆` := subset

theorem empty_subset (s : finset A) : ∅ ⊆ s :=
quot.induction_on s (λ l, list.nil_sub (elt_of l))

theorem subset_univ [h : fintype A] (s : finset A) : s ⊆ univ :=
quot.induction_on s (λ l a i, fintype.complete a)

theorem subset.refl (s : finset A) : s ⊆ s :=
quot.induction_on s (λ l, list.sub.refl (elt_of l))

theorem subset.trans {s₁ s₂ s₃ : finset A} : s₁ ⊆ s₂ → s₂ ⊆ s₃ → s₁ ⊆ s₃ :=
quot.induction_on₃ s₁ s₂ s₃ (λ l₁ l₂ l₃ h₁ h₂, list.sub.trans h₁ h₂)

theorem mem_of_subset_of_mem {s₁ s₂ : finset A} {a : A} : s₁ ⊆ s₂ → a ∈ s₁ → a ∈ s₂ :=
quot.induction_on₂ s₁ s₂ (λ l₁ l₂ h₁ h₂, h₁ a h₂)

theorem subset_of_forall {s₁ s₂ : finset A} : (∀x, x ∈ s₁ → x ∈ s₂) → s₁ ⊆ s₂ :=
quot.induction_on₂ s₁ s₂ (λ l₁ l₂ H, H)

theorem subset_insert [h : decidable_eq A] (s : finset A) (a : A) : s ⊆ insert a s :=
subset_of_forall (take x, assume H : x ∈ s, mem_insert_of_mem _ H)

theorem eq_of_subset_of_subset {s₁ s₂ : finset A} (H₁ : s₁ ⊆ s₂) (H₂ : s₂ ⊆ s₁) : s₁ = s₂ :=
ext (take x, iff.intro (assume H, mem_of_subset_of_mem H₁ H) (assume H, mem_of_subset_of_mem H₂ H))

section
variable [decA : decidable_eq A]
include decA

theorem erase_subset_erase_of_subset {a : A} {s₁ s₂ : finset A} : s₁ ⊆ s₂ → erase a s₁ ⊆ erase a s₂ :=
λ is_sub, subset_of_forall (λ b bin,
  mem_erase_of_ne_of_mem (ne_of_mem_erase bin) (mem_of_subset_of_mem is_sub (mem_of_mem_erase bin)))
end

/- upto -/
section upto
definition upto (n : nat) : finset nat :=
to_finset_of_nodup (list.upto n) (nodup_upto n)

theorem card_upto : ∀ n, card (upto n) = n :=
list.length_upto

theorem lt_of_mem_upto {n a : nat} : a ∈ upto n → a < n :=
list.lt_of_mem_upto

theorem mem_upto_succ_of_mem_upto {n a : nat} : a ∈ upto n → a ∈ upto (succ n) :=
list.mem_upto_succ_of_mem_upto

theorem mem_upto_of_lt {n a : nat} : a < n → a ∈ upto n :=
list.mem_upto_of_lt

theorem mem_upto_iff (a n : nat) : a ∈ upto n ↔ a < n :=
iff.intro lt_of_mem_upto mem_upto_of_lt

theorem mem_upto_eq (a n : nat) : a ∈ upto n = (a < n) :=
propext !mem_upto_iff
end upto

/- useful rules for calculations with quantifiers -/
theorem exists_mem_empty_iff {A : Type} (P : A → Prop) : (∃ x, x ∈ ∅ ∧ P x) ↔ false :=
iff.intro
  (assume H,
    obtain x (H1 : x ∈ ∅ ∧ P x), from H,
    !not_mem_empty (and.left H1))
  (assume H, false.elim H)

theorem exists_mem_empty_eq {A : Type} (P : A → Prop) : (∃ x, x ∈ ∅ ∧ P x) = false :=
propext !exists_mem_empty_iff

theorem exists_mem_insert_iff {A : Type} [d : decidable_eq A]
    (a : A) (s : finset A) (P : A → Prop) :
  (∃ x, x ∈ insert a s ∧ P x) ↔ P a ∨ (∃ x, x ∈ s ∧ P x) :=
iff.intro
  (assume H,
    obtain x [H1 H2], from H,
    or.elim (eq_or_mem_of_mem_insert H1)
      (assume H3 : x = a, or.inl (eq.subst H3 H2))
      (assume H3 : x ∈ s, or.inr (exists.intro x (and.intro H3 H2))))
  (assume H,
    or.elim H
      (assume H1 : P a, exists.intro a (and.intro !mem_insert H1))
      (assume H1 : ∃ x, x ∈ s ∧ P x,
        obtain x [H2 H3], from H1,
        exists.intro x (and.intro (!mem_insert_of_mem H2) H3)))

theorem exists_mem_insert_eq {A : Type} [d : decidable_eq A] (a : A) (s : finset A) (P : A → Prop) :
  (∃ x, x ∈ insert a s ∧ P x) = (P a ∨ (∃ x, x ∈ s ∧ P x)) :=
propext !exists_mem_insert_iff

theorem forall_mem_empty_iff {A : Type} (P : A → Prop) : (∀ x, x ∈ ∅ → P x) ↔ true :=
iff.intro
  (assume H, trivial)
  (assume H, take x, assume H', absurd H' !not_mem_empty)

theorem forall_mem_empty_eq {A : Type} (P : A → Prop) : (∀ x, x ∈ ∅ → P x) = true :=
propext !forall_mem_empty_iff

theorem forall_mem_insert_iff {A : Type} [d : decidable_eq A]
    (a : A) (s : finset A) (P : A → Prop) :
  (∀ x, x ∈ insert a s → P x) ↔ P a ∧ (∀ x, x ∈ s → P x) :=
iff.intro
  (assume H, and.intro (H _ !mem_insert) (take x, assume H', H _ (!mem_insert_of_mem H')))
  (assume H, take x, assume H' : x ∈ insert a s,
    or.elim (eq_or_mem_of_mem_insert H')
      (assume H1 : x = a, eq.subst (eq.symm H1) (and.left H))
      (assume H1 : x ∈ s, and.right H _ H1))

theorem forall_mem_insert_eq {A : Type} [d : decidable_eq A] (a : A) (s : finset A) (P : A → Prop) :
  (∀ x, x ∈ insert a s → P x) = (P a ∧ (∀ x, x ∈ s → P x)) :=
propext !forall_mem_insert_iff

end finset
