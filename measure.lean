import data.real data.set data.nat algebra.group_bigops algebra.group_set_bigops
open real eq.ops set nat 

variable {X : Type}
variables A B : set X

namespace measure

namespace sigma_algebra

structure sigma_algebra (X : Type) :=
  (space : set X) 
  (sets : set (set X))
  (subs : (∀ S : set X, S ∈ sets → S ⊆ space))
  (entire : space ∈ sets)
  (complements : ∀ S, S ∈ sets → (-S ∈ sets))
  (unions : ∀ U : ℕ → set X, (∀ i : ℕ, (U i ∈ sets)) → Union U ∈ sets)

attribute sigma_algebra [class]
attribute sigma_algebra.sets [coercion]

abbreviation space := @sigma_algebra.space
abbreviation sets := @sigma_algebra.sets

definition measurable [M : sigma_algebra X] (S : set X) : Prop := S ∈ M

definition measurable_collection [M : sigma_algebra X] (S : set (set X)) : Prop :=  ∀ s, s ∈ S → measurable s

definition measurable_sequence [M : sigma_algebra X] (S : ℕ → set X) : Prop := ∀ i, measurable (S i)

lemma space_closed {M : sigma_algebra X} (S : set X) (MS : measurable S) :
  ∀ x : X, x ∈ S → x ∈ (space M) := 
take x, 
suppose x ∈ S,
have S ⊆ space M, from sigma_algebra.subs M S MS,
show x ∈ space M, from mem_of_subset_of_mem this `x ∈ S`

theorem empty_measurable {M : sigma_algebra X} :
  ∅ ∈ M :=
have ∀ x, x ∉ -(space M), from 
 take x,
  not.intro(
    suppose x ∈ -(space M),
    have ¬(x ∈ space M), from not_mem_of_mem_comp this,
    have measurable (-(space M)), from (sigma_algebra.complements M (space M)) (sigma_algebra.entire M),
    have x ∈ space M, from ((space_closed (-(space M)) this) x) `x ∈ -(space M)`, 
    show false, from absurd this `¬(x ∈ space M)`),
have -(space M) = ∅, from eq_empty_of_forall_not_mem this,
have -(space M) ∈ sets M, from (sigma_algebra.complements M (space M)) (sigma_algebra.entire M),
show _, from `-(space M) = ∅` ▸ this

lemma countable_com  {M : sigma_algebra X} (U : ℕ → set X) : (∀ i, U i ∈ M) → (∀ j, -(U j) ∈ M) := 
  suppose ∀ i, U i ∈ M, 
  take j, 
  show -(U j) ∈ M, from !sigma_algebra.complements !this

definition comp_family [reducible] (U : ℕ → set X) : ℕ → set X := λ i, -(U i)

prefix `-` := comp_family

section 

open classical

lemma Inter_eq (U : ℕ → set X) :
  Inter U = -(Union (-U)) := 
ext(take x, iff.intro
  (suppose x ∈ Inter U,
   show x ∈ -(Union (-U)), from 
     not.intro(
       suppose x ∈ Union (- U),
       obtain i (Hi : x ∉ (U i)), from this,
       show false, from Hi (`x ∈ Inter U` i)))        
  (suppose x ∈ -(Union (-U)),
    have ∀ i, ¬¬(x ∈ U i), from (iff.elim_left !forall_iff_not_exists) this,
    show x ∈ Inter U, from 
      take i,
      have ¬¬(x ∈ U i), from this i,
      show _, from not_not_elim this))

end 

theorem Inter_measurable {M : sigma_algebra X} (U : ℕ → set X) (Um : ∀ i, measurable (U i)) :
  measurable (Inter U) := 
have ∀ i, measurable (-(U i)), from
  take i,
  have measurable (U i), from Um i,
  show _, from !sigma_algebra.complements this,
have measurable (Union (-U)), from !sigma_algebra.unions this,
have measurable (-(Union (-U))), from !sigma_algebra.complements this,
show _, from !Inter_eq⁻¹ ▸ this

definition bin_extension [reducible] [M : sigma_algebra X] : ℕ → set X := 
  λ i, if i ≤ 1 then (if i = 0 then A else B) else ∅

lemma extension_measurable {M : sigma_algebra X} (HA : measurable A) (HB : measurable B) :
   ∀ i : ℕ, measurable (bin_extension A B i) :=
take i,
if H : i ≤ 1 then 
  if H1 : i = 0 then 
    by rewrite[↑bin_extension, if_pos H, if_pos H1]; exact HA
  else 
    by rewrite[↑bin_extension, if_pos H, if_neg H1]; exact HB
else 
  by rewrite[↑bin_extension, if_neg H]; exact empty_measurable

lemma bin_union {M : sigma_algebra X} (HA : measurable A) (HB : measurable B) : 
  measurable (A ∪ B) :=
have H : Union (bin_extension A B) =  A ∪ B, from (ext(take x, iff.intro 
  (suppose x ∈ Union (bin_extension A B), 
   obtain i (Hi : x ∈ (bin_extension A B) i), from this,
   assert i ≤ 1, from not_not_elim
     (not.intro(
       suppose ¬(i ≤ 1),
       have (bin_extension A B) i = ∅, by rewrite[↑bin_extension, if_neg this],
       have x ∈ ∅, from this ▸ Hi,
       show false, from absurd this !not_mem_empty)),
   show x ∈ A ∪ B, from 
     if Hp : i ≤ 1 then
         if Hpp : i = 0 then
           have (bin_extension A B) i = A, by rewrite[↑bin_extension, if_pos Hp, if_pos Hpp],
           have x ∈ A, from this ▸ Hi,
           show x ∈ A ∪ B, from !mem_union_left this
         else 
           have (bin_extension A B) i = B, by rewrite[↑bin_extension, if_pos Hp, if_neg Hpp],
           have x ∈ B, from this ▸ Hi,
           show x ∈ A ∪ B, from !mem_union_right this 
      else
         have (bin_extension A B) i = ∅, by rewrite[↑bin_extension, if_neg Hp],
         have x ∈ ∅, from this ▸ Hi,
         show x ∈ A ∪ B, from !not.elim !not_mem_empty this)
   (suppose x ∈ A ∪ B,
     assert A ∪ B ⊆ Union (bin_extension A B), from
     take x,
     suppose x ∈ A ∪ B,
       or.elim 
         (mem_or_mem_of_mem_union `x ∈ A ∪ B`) 
         (suppose x ∈ A, exists.intro 0 this)
         (suppose x ∈ B, exists.intro 1 this),
    show x ∈ Union (bin_extension A B), from (!mem_of_subset_of_mem this) `x ∈ A ∪ B`))),
have ∀ i, measurable ((bin_extension A B) i), from !extension_measurable HA HB,
have measurable (Union (bin_extension A B)), from !sigma_algebra.unions this,
show measurable (A ∪ B), from H ▸ this 

definition bin_extension' : ℕ → set X := λ i, if i = 0 then A else B

lemma extension'_measurable {M : sigma_algebra X} (HA : measurable A) (HB : measurable B) :
  ∀ i : ℕ, (bin_extension' A B) i ∈ M :=
take i,
if H : i = 0 then
  by rewrite[↑bin_extension', if_pos H]; exact HA
else
  by rewrite[↑bin_extension', if_neg H]; exact HB

theorem bin_inter {M : sigma_algebra X} (HA : measurable A) (HB : measurable B) :
  measurable (A ∩ B) := 
have H : A ∩ B =  Inter (bin_extension' A B), from ext(λx, iff.intro 
    (suppose x ∈ A ∩ B,
        take i,
        if Hp : i = 0 then
          have x ∈ A, from and.elim_left `x ∈ A ∩ B`, 
          have bin_extension' A B i = A, by rewrite[↑bin_extension', if_pos Hp],
          show x ∈ bin_extension' A B i, from this⁻¹ ▸ `x ∈ A`
        else 
          have x ∈ B, from and.elim_right `x ∈ A ∩ B`,
          have bin_extension' A B i = B, by rewrite[↑bin_extension', if_neg Hp],
          show x ∈ bin_extension' A B i, from this⁻¹ ▸ `x ∈ B`)
    (suppose x ∈ Inter (bin_extension' A B) , and.intro (this 0) (this 1))), 
have measurable (Inter (bin_extension' A B)), from !Inter_measurable (!extension'_measurable HA HB),
show measurable (A ∩ B), from H⁻¹ ▸ this

theorem fin_union {M : sigma_algebra X} (S : set (set X)) (fin : finite S) : 
  measurable_collection S → measurable (sUnion S) := 
!induction_on_finite
    (suppose measurable_collection ∅,
     have sUnion ∅ = ∅, from ext (λx, iff.intro
          (suppose x ∈ sUnion ∅,
            obtain c [(hc : c ∈ ∅) (xc : x ∈ c)], from this,
            show _, from !not.elim !not_mem_empty hc)
          (suppose x ∈ ∅, !not.elim !not_mem_empty this)),
     show measurable (sUnion ∅), from this⁻¹ ▸ !empty_measurable) 
    (begin
      intro a s' fins,
      λ s₁, λ s₂, λ s₃,
      (!sUnion_insert)⁻¹ ▸ bin_union a (sUnion s') ((s₃ a) !mem_insert)
      (s₂ (take s, λ t, (s₃ s) (!mem_insert_of_mem t)))
     end) 

theorem fin_inter {M : sigma_algebra X} (S : set (set X)) {fn : finite S} : 
  measurable_collection S → measurable (sInter S) :=
show _, from !induction_on_finite
    (suppose measurable_collection ∅,
     have sInter ∅ = ∅, from ext(λx, iff.intro 
      (suppose x ∈ sInter ∅, 
        have ∀ c, c ∈ ∅ → x ∈ c, from this, 
        show x ∈ ∅, from sorry) -- need to show ∅ ∈ ∅ ?
      (suppose x ∈ ∅, !not.elim !not_mem_empty this)),
      show measurable (sInter ∅), from this⁻¹ ▸ !empty_measurable)
     (begin
       intro a s' fins,
       λ s₁, λ s₂, λ H,
         !sInter_insert⁻¹ ▸ (!bin_inter ((H a) !mem_insert) (s₂ ( λ s, λ t, (H s)
         (((λ s, λ t, !mem_of_subset_of_mem (subset_insert a s') t) s) t))))
      end)

theorem measurable_diff_measurable {A B : set X} {M : sigma_algebra X} (Am : measurable A) (Bm : measurable B) :
  measurable (A \ B) := 
have A \ B = A ∩ -B, from !diff_eq,
have measurable (-B), from !sigma_algebra.complements Bm,
have measurable (A ∩ (-B)), from !bin_inter Am this,
show  measurable (A \ B), from `A \ B = A ∩ (-B)` ▸ this

lemma measurable_insert_measurable {M : sigma_algebra X} (a : set X) (S : set (set X)) (Hm : measurable_collection (insert a S)) : 
  measurable_collection S := sorry

end sigma_algebra

namespace measure_space

open sigma_algebra

definition disjoint_seq (U : ℕ → set X) : Prop := ∀ i : ℕ, ∀ j : ℕ, i ≠ j → U i ∩ U j = ∅

definition disjoint_fam (S : set (set X)) : Prop := ∀ s, ∀ r, (s ∈ S ∧ r ∈ S) → (s ≠ r → s ∩ r = ∅)

structure measure [class] (M : sigma_algebra X) :=
  (measure : set X → ℝ)
  (measure_empty : measure ∅ = 0)
  (countable_additive : ∀ U : ℕ → set X, disjoint_seq U ∧ (∀ i, measurable (U i)) → (measure (Union U) = (set.Sum (@univ ℕ) (λi, measure (U i)))))

attribute measure.measure [coercion]

-- Need infinite series for all of this --

/- definition fin_measure {X : Type} [M : 𝔐 X] : Prop := μ (space X) < ∞ -/

lemma disjoint_bin_ext {M : sigma_algebra X} (A B : set X) (dsjt : A ∩ B = ∅)  : 
  disjoint_seq (bin_extension A B) := 
take i, take j, suppose neq : i ≠ j,
     show bin_extension A B i ∩ bin_extension A B j = ∅, from 
      decidable.by_cases
        (suppose i ≤ 1,
          decidable.by_cases
            (suppose Hipp : i = 0, 
              have HA : A = bin_extension A B i, from
                begin
                 unfold bin_extension,
                 rewrite [if_pos `i ≤ 1`, if_pos Hipp]
                end,
              decidable.by_cases
                proof 
                  suppose j ≤ 1, 
                  decidable.by_cases
                    (suppose j = 0,
                      show bin_extension A B i ∩ bin_extension A B j = ∅, from !not.elim (`j = 0`⁻¹ ▸ Hipp) neq) 
                    (suppose ¬(j = 0), 
                      have bin_extension A B j = B, from
                       begin
                          unfold bin_extension,
                          rewrite [if_pos `j ≤ 1`, if_neg this]
                       end,
                       show bin_extension A B i ∩ bin_extension A B j = ∅, from this ▸ (HA ▸ dsjt)) 
                  qed
                (suppose ¬(j ≤ 1),  ----
                  have ∅ = bin_extension A B j, from
                    begin
                     unfold bin_extension,
                     rewrite [if_neg this]
                    end,
                  show _, from !inter_empty ▸ ((HA ▸ rfl)⁻¹ ▸ this ▸ rfl)))
            (suppose ¬(i = 0), 
              have bin_extension A B i = B, from 
                begin
                  unfold bin_extension,
                  rewrite [if_pos `i ≤ 1`, if_neg `¬(i = 0)`]
                end,
              decidable.by_cases
                (suppose j ≤ 1, 
                  decidable.by_cases
                    (suppose j = 0, 
                      have bin_extension A B j = A, from
                        begin
                          unfold bin_extension,
                          rewrite [if_pos `j ≤ 1`, if_pos this]
                        end,
                      have bin_extension A B i ∩ bin_extension A B j = A ∩ B, from calc
                           bin_extension A B i ∩ bin_extension A B j = bin_extension A B i ∩ A : `bin_extension A B j = A` ▸ rfl
                                                                 ... = B ∩ A : `bin_extension A B i = B` ▸ this
                                                                 ... = A ∩ B  : !inter.comm ▸ this,
                      show _, from this ▸ dsjt)
                    (suppose ¬(j = 0),
                      have ∀ k, k ≤ 1 ∧ ¬(k = 0) → k = 1, from
                        take k, suppose k ≤ 1 ∧ ¬(k = 0),
                        not_not_elim (not_not_of_not_implies ((iff.elim_right !imp_false) (or.elim (!nat.lt_or_eq_of_le (and.elim_left this))
                          (not.intro( λ H, absurd (!eq_zero_of_le_zero (!le_of_lt_succ H)) (and.elim_right this)))))),
                      have i = j, from (this j (and.intro `j ≤ 1` `¬(j = 0)`))⁻¹ ▸ (this i (and.intro `i ≤ 1` `¬(i = 0)`)),
                      and.elim_left ((iff.elim_right !and_false) (absurd `i = j` neq))))
                (suppose ¬(j ≤ 1),
                      have bin_extension A B j = ∅, from
                        begin
                          unfold bin_extension,
                          rewrite [if_neg `¬(j ≤ 1)`]
                        end,
                      !inter_empty ▸ ((`bin_extension A B i = B` ▸ rfl) ▸ (this ▸ rfl)))))
        (suppose ¬(i ≤ 1), 
          have bin_extension A B i = ∅, from
            begin
              unfold bin_extension,
              rewrite[if_neg `¬(i ≤ 1)`]
            end,
          !empty_inter ▸ (this ▸ rfl))

theorem bin_additive {M : sigma_algebra X} {μ : measure M} (A B : set X) (s₁ : measurable A) (s₂ : measurable B) (dsjt : A ∩ B = ∅) : 
  μ (A ∪ B) = μ A + μ B := 
  have disjoint_seq (bin_extension A B) ∧ (∀ i, measurable (bin_extension A B i)), from and.intro (disjoint_bin_ext A B dsjt) (extension_measurable A B s₁ s₂),
  have H1 : μ (Union (bin_extension A B)) = set.Sum (@univ ℕ) (λi, μ (bin_extension A B i)), from !measure.countable_additive this,
  have H2 : set.Sum (@univ ℕ) (λi, μ (bin_extension A B i)) = μ A + μ B, from sorry, 
  have H3 : Union (bin_extension A B) = A ∪ B, from ext(λx, iff.intro
    (suppose x ∈ Union (bin_extension A B),
       obtain i (Hi : x ∈ bin_extension A B i), from this,
       show _, from 
         decidable.by_cases
           (suppose H1 : i ≤ 1,
             decidable.by_cases
               (suppose i = 0,
                 have bin_extension A B i = A, from 
                   begin
                     unfold bin_extension,
                     rewrite[if_pos H1, if_pos this]
                   end,
                 have x ∈ A, from this ▸ Hi,
                 show x ∈ A ∪ B, from !mem_union_left this)
               (suppose ¬(i = 0), 
                 have bin_extension A B i = B, from 
                   begin
                     unfold bin_extension,
                     rewrite[if_pos H1, if_neg this]
                   end,
                 have x ∈ B, from this ▸ Hi,
                 show x ∈ A ∪ B, from !mem_union_right this))
           (suppose ¬(i ≤ 1),
               have bin_extension A B i = ∅, from 
                 begin
                   unfold bin_extension,
                   rewrite[if_neg this]
                 end,
               have x ∈ ∅, from this ▸ Hi,
               show x ∈ A ∪ B, from !not.elim !not_mem_empty this)) 
       (suppose x ∈ A ∪ B, 
        have HA : x ∈ A → ∃ i, x ∈ bin_extension A B i, from 
          suppose x ∈ A,
          show ∃ i, x ∈ bin_extension A B i, from exists.intro 0 this,
        have HB : x ∈ B → ∃ i, x ∈ bin_extension A B i, from 
          suppose x ∈ B,
          show ∃ i, x ∈ bin_extension A B i, from exists.intro 1 this,
        show x ∈ Union (bin_extension A B), from or.elim this HA HB)),
  show μ (A ∪ B) = μ A + μ B, from H3 ▸ (H1⁻¹ ▸ H2)

lemma Sum_insert_of_not_mem' (f : (set X) → real) {a : set X} {s : set (set X)} (fins : finite s) (H : a ∉ s) :
  set.Sum (insert a s) f = f a + set.Sum s f := algebra.set.Sum_insert_of_not_mem f H

lemma dsjt_insert_dsjt_inter (s : set (set X)) (a : set X) (dsjt : disjoint_fam (insert a s)) (notin : a ∉ s) :
  a ∩ sUnion s = ∅ := 
ext(take x, iff.intro 
  (suppose x ∈ a ∩ sUnion s,
    obtain c [(cs : c ∈ s) (xc : x ∈ c)], from and.elim_right `x ∈ a ∩ sUnion s`,
    have a ≠ c, from not.intro(
      suppose a = c,
      have a ∈ s, from this⁻¹ ▸ cs,
      show false, from notin this),
    have a ∩ c = ∅, from dsjt a c (and.intro !mem_insert (!mem_insert_of_mem cs)) this,
    have x ∈ a ∩ c, from and.intro (and.elim_left `x ∈ a ∩ sUnion s`) xc,
    show x ∈ ∅, from `a ∩ c = ∅` ▸ this)
  (suppose x ∈ ∅, !not.elim !not_mem_empty this))

lemma dsjt_fam_insert_dsjt (s : set (set X)) (a : set X) (dsjt : disjoint_fam (insert a s)) :
  disjoint_fam s := 
take q, take r,
suppose q ∈ s ∧ r ∈ s,
suppose q ≠ r,
have q ∈ insert a s, from !mem_insert_of_mem (and.elim_left `q ∈ s ∧ r ∈ s`),
have r ∈ insert a s, from !mem_insert_of_mem (and.elim_right `q ∈ s ∧ r ∈ s`),
show q ∩ r = ∅, from (dsjt q r) (and.intro `q ∈ insert a s` this) `q ≠ r`

theorem fin_additive {M : sigma_algebra X} {μ : measure M} (S : set (set X)) [fin : finite S] : 
  (measurable_collection S ∧ disjoint_fam S) → μ (sUnion S) = set.Sum S μ :=
!induction_on_finite
  (suppose measurable_collection ∅ ∧ disjoint_fam ∅,
   have (sUnion ∅) = ∅, from ext(take x, iff.intro 
    (suppose x ∈ sUnion ∅,
            obtain c [(hc : c ∈ ∅) (xc : x ∈ c)], from this,
            show _, from !not.elim !not_mem_empty hc)
          (suppose x ∈ ∅, !not.elim !not_mem_empty this)),
   have μ(sUnion ∅) = 0, from (measure.measure_empty M) ▸ (this ▸ rfl),
   have set.Sum ∅ μ = 0, from !set.Sum_empty,
   show μ (sUnion ∅) = set.Sum ∅ μ, from this⁻¹ ▸ `μ(sUnion ∅) = 0`)
  (begin
    intro a s' fins,
    λ s₁, λ s₂, λ s₃,
    (Sum_insert_of_not_mem' μ fins s₁)⁻¹ ▸ ((s₂ (and.intro (!measurable_insert_measurable (and.elim_left s₃)) (dsjt_fam_insert_dsjt s' a
    (and.elim_right s₃)))) ▸ ((!bin_additive (((and.elim_left s₃) a) !mem_insert) (fin_union s' fins (!measurable_insert_measurable (and.elim_left s₃))) 
    (dsjt_insert_dsjt_inter s' a (and.elim_right s₃) s₁))  ▸ (!sUnion_insert ▸ rfl))) 
   end)

theorem measure_mon {M : sigma_algebra X} (μ : measure M) (A B : set X) (HA : measurable A) (HB : measurable B) (sub : A ⊆ B) :
  μ A ≤ μ B := sorry 

theorem sub_additive {M : sigma_algebra X} {μ : measure M} (S : set (set X)) (Ms : measurable_collection S) : 
  μ (sUnion S) ≤ set.Sum S μ := sorry

end measure_space

-- Put this in a seperate file --

namespace measurable_functions

open sigma_algebra  

/- First pass at a definition of measurable functions...
   
  * We could do this in terms of pre-images of open sets rather than measurable ones, although we do not yet have topology
(maybe use the open sets in metric space for now?)

  * Johannes Holzl suggested doing this order theoretically -- f : M(A,B) <-> f[A] ≤ B,
where f[A] is the least measure space such that f is A-measurable

-/

definition measurablefun (f : X → X) {M : sigma_algebra X} : Prop := 
  ∀ Y : set X , Y ⊆ (@univ X) → (measurable (image f Y) → measurable Y)

end measurable_functions

end measure

