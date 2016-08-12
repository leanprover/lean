/-
Copyright (c) 2014 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Jeremy Avigad, Andrew Zipperer, Haitao Zhang

Functions between subsets of finite types.
-/
import .basic
open function eq.ops

namespace set

variables {X Y Z : Type}

/- preimages -/

definition preimage {A B:Type} (f : A → B) (Y : set B) : set A := { x | f x ∈ Y }

notation f ` '- ` s := preimage f s

theorem mem_preimage_iff (f : X → Y) (a : set Y) (x : X) :
  f x ∈ a ↔ x ∈ f '- a :=
!iff.refl

theorem mem_preimage {f : X → Y} {a : set Y} {x : X} (H : f x ∈ a) :
  x ∈ f '- a := H

theorem mem_of_mem_preimage {f : X → Y} {a : set Y} {x : X} (H : x ∈ f '- a) :
  f x ∈ a :=
proof H qed

theorem preimage_comp (f : Y → Z) (g : X → Y) (a : set Z) :
  (f ∘ g) '- a = g '- (f '- a) :=
ext (take x, !iff.refl)

lemma image_subset_iff {A B : Type} {f : A → B} {X : set A} {Y : set B} :
  f ' X ⊆ Y ↔ X ⊆ f '- Y :=
@bounded_forall_image_iff A B f X Y

theorem preimage_subset {a b : set Y} (f : X → Y) (H : a ⊆ b) :
  f '- a ⊆ f '- b :=
λ x H', proof @H (f x) H' qed

theorem preimage_id (s : set Y) : (λx, x) '- s = s :=
ext (take x, !iff.refl)

theorem preimage_union (f : X → Y) (s t : set Y) :
  f '- (s ∪ t) = f '- s ∪ f '- t :=
ext (take x, !iff.refl)

theorem preimage_inter (f : X → Y) (s t : set Y) :
  f '- (s ∩ t) = f '- s ∩ f '- t :=
ext (take x, !iff.refl)

theorem preimage_compl (f : X → Y) (s : set Y) :
  f '- (-s) = -(f '- s) :=
ext (take x, !iff.refl)

theorem preimage_diff (f : X → Y) (s t : set Y) :
  f '- (s \ t) = f '- s \ f '- t :=
ext (take x, !iff.refl)

theorem image_preimage_subset (f : X → Y) (s : set Y) :
  f ' (f '- s) ⊆ s :=
take y, suppose y ∈ f ' (f '- s),
  obtain x [xfis fxeqy], from this,
  show y ∈ s, by rewrite -fxeqy; exact xfis

theorem subset_preimage_image (s : set X) (f : X → Y) :
  s ⊆ f '- (f ' s) :=
take x, suppose x ∈ s,
show f x ∈ f ' s, from mem_image_of_mem f this

theorem inter_preimage_subset (s : set X) (t : set Y) (f : X → Y) :
  s ∩ f '- t ⊆ f '- (f ' s ∩ t) :=
take x, assume H : x ∈ s ∩ f '- t,
mem_preimage (show f x ∈ f ' s ∩ t,
  from and.intro (mem_image_of_mem f (and.left H)) (mem_of_mem_preimage (and.right H)))

theorem union_preimage_subset (s : set X) (t : set Y) (f : X → Y) :
  s ∪ f '- t ⊆ f '- (f ' s ∪ t) :=
take x, assume H : x ∈ s ∪ f '- t,
mem_preimage (show f x ∈ f ' s ∪ t,
  from or.elim H
    (suppose x ∈ s, or.inl (mem_image_of_mem f this))
    (suppose x ∈ f '- t, or.inr (mem_of_mem_preimage this)))

theorem image_inter (f : X → Y) (s : set X) (t : set Y) :
  f ' s ∩ t = f ' (s ∩ f '- t) :=
ext (take y, iff.intro
  (suppose y ∈ f ' s ∩ t,
    obtain [x [xs fxeqy]] yt, from this,
    have x ∈ s ∩ f '- t,
      from and.intro xs (mem_preimage (show f x ∈ t, by rewrite fxeqy; exact yt)),
    mem_image this fxeqy)
  (suppose y ∈ f ' (s ∩ f '- t),
    obtain x [[xs xfit] fxeqy], from this,
    and.intro (mem_image xs fxeqy)
      (show y ∈ t, by rewrite -fxeqy; exact mem_of_mem_preimage xfit)))

theorem image_union_supset (f : X → Y) (s : set X) (t : set Y) :
  f ' s ∪ t ⊇ f ' (s ∪ f '- t) :=
take y, assume H,
obtain x [xmem fxeqy], from H,
or.elim xmem
  (suppose x ∈ s, or.inl (mem_image this fxeqy))
  (suppose x ∈ f '- t, or.inr (show y ∈ t, by rewrite -fxeqy; exact mem_of_mem_preimage this))

/- maps to -/

attribute [reducible]
definition maps_to (f : X → Y) (a : set X) (b : set Y) : Prop := ∀⦃x⦄, x ∈ a → f x ∈ b

theorem maps_to_of_eq_on {f1 f2 : X → Y} {a : set X} {b : set Y} (eq_on_a : eq_on f1 f2 a)
    (maps_to_f1 : maps_to f1 a b) :
  maps_to f2 a b :=
take x,
assume xa : x ∈ a,
have H : f1 x ∈ b, from maps_to_f1 xa,
show f2 x ∈ b, from eq_on_a xa ▸ H

theorem maps_to_comp {g : Y → Z} {f : X → Y} {a : set X} {b : set Y} {c : set Z}
   (H1 : maps_to g b c) (H2 : maps_to f a b) : maps_to (g ∘ f) a c :=
take x, assume H : x ∈ a, H1 (H2 H)

theorem maps_to_univ_univ (f : X → Y) : maps_to f univ univ :=
take x, assume H, trivial

theorem image_subset_of_maps_to_of_subset {f : X → Y} {a : set X} {b : set Y} (mfab : maps_to f a b)
    {c : set X} (csuba : c ⊆ a) :
  f ' c ⊆ b :=
take y,
suppose y ∈ f ' c,
obtain x [(xc : x ∈ c) (yeq : f x = y)], from this,
have x ∈ a, from csuba `x ∈ c`,
have f x ∈ b, from mfab this,
show y ∈ b, from yeq ▸ this

theorem image_subset_of_maps_to {f : X → Y} {a : set X} {b : set Y} (mfab : maps_to f a b) :
  f ' a ⊆ b :=
image_subset_of_maps_to_of_subset mfab (subset.refl a)

/- injectivity -/

attribute [reducible]
definition inj_on (f : X → Y) (a : set X) : Prop :=
∀⦃x1 x2 : X⦄, x1 ∈ a → x2 ∈ a → f x1 = f x2 → x1 = x2

theorem inj_on_empty (f : X → Y) : inj_on f ∅ :=
  take x₁ x₂, assume H₁ H₂ H₃, false.elim H₁

theorem inj_on_of_eq_on {f1 f2 : X → Y} {a : set X} (eq_f1_f2 : eq_on f1 f2 a)
    (inj_f1 : inj_on f1 a) :
  inj_on f2 a :=
take x1 x2 : X,
assume ax1 : x1 ∈ a,
assume ax2 : x2 ∈ a,
assume H : f2 x1 = f2 x2,
have H' : f1 x1 = f1 x2, from eq_f1_f2 ax1 ⬝ H ⬝ (eq_f1_f2 ax2)⁻¹,
show x1 = x2, from inj_f1 ax1 ax2 H'

theorem inj_on_comp {g : Y → Z} {f : X → Y} {a : set X} {b : set Y}
    (fab : maps_to f a b) (Hg : inj_on g b) (Hf: inj_on f a) :
  inj_on (g ∘ f) a :=
take x1 x2 : X,
assume x1a : x1 ∈ a,
assume x2a : x2 ∈ a,
have  fx1b : f x1 ∈ b, from fab x1a,
have  fx2b : f x2 ∈ b, from fab x2a,
assume  H1 : g (f x1) = g (f x2),
have    H2 : f x1 = f x2, from Hg fx1b fx2b H1,
show x1 = x2, from Hf x1a x2a H2

theorem inj_on_of_inj_on_of_subset {f : X → Y} {a b : set X} (H1 : inj_on f b) (H2 : a ⊆ b) :
  inj_on f a :=
take x1 x2 : X, assume (x1a : x1 ∈ a) (x2a : x2 ∈ a),
assume H : f x1 = f x2,
show x1 = x2, from H1 (H2 x1a) (H2 x2a) H

lemma injective_iff_inj_on_univ {f : X → Y} : injective f ↔ inj_on f univ :=
iff.intro
  (assume H, take x₁ x₂, assume ax₁ ax₂, H x₁ x₂)
  (assume H : inj_on f univ,
     take x₁ x₂ Heq,
     show x₁ = x₂, from H trivial trivial Heq)

/- surjectivity -/

attribute [reducible]
definition surj_on (f : X → Y) (a : set X) (b : set Y) : Prop := b ⊆ f ' a

theorem surj_on_of_eq_on {f1 f2 : X → Y} {a : set X} {b : set Y} (eq_f1_f2 : eq_on f1 f2 a)
    (surj_f1 : surj_on f1 a b) :
  surj_on f2 a b :=
take y, assume H : y ∈ b,
obtain x (H1 : x ∈ a ∧ f1 x = y), from surj_f1 H,
have H2 : x ∈ a, from and.left H1,
have H3 : f2 x = y, from (eq_f1_f2 H2)⁻¹ ⬝ and.right H1,
exists.intro x (and.intro H2 H3)

theorem surj_on_comp {g : Y → Z} {f : X → Y} {a : set X} {b : set Y} {c : set Z}
  (Hg : surj_on g b c) (Hf: surj_on f a b) :
  surj_on (g ∘ f) a c :=
take z,
assume zc : z ∈ c,
obtain y (H1 : y ∈ b ∧ g y = z), from Hg zc,
obtain x (H2 : x ∈ a ∧ f x = y), from Hf (and.left H1),
show ∃x, x ∈ a ∧ g (f x) = z, from
  exists.intro x
    (and.intro
      (and.left H2)
      (calc
        g (f x) = g y : {and.right H2}
            ... = z   : and.right H1))

lemma surjective_iff_surj_on_univ {f : X → Y} : surjective f ↔ surj_on f univ univ :=
iff.intro
  (assume H, take y, assume Hy,
    obtain x Hx, from H y,
    mem_image trivial Hx)
  (assume H, take y,
    obtain x H1x H2x, from H y trivial,
    exists.intro x H2x)

lemma image_eq_of_maps_to_of_surj_on {f : X → Y} {a : set X} {b : set Y}
    (H1 : maps_to f a b) (H2 : surj_on f a b) :
  f ' a = b :=
eq_of_subset_of_subset (image_subset_of_maps_to H1) H2

/- bijectivity -/

attribute [reducible]
definition bij_on (f : X → Y) (a : set X) (b : set Y) : Prop :=
maps_to f a b ∧ inj_on f a ∧ surj_on f a b

lemma maps_to_of_bij_on {f : X → Y} {a : set X} {b : set Y} (H : bij_on f a b) :
      maps_to f a b :=
and.left H

lemma inj_on_of_bij_on {f : X → Y} {a : set X} {b : set Y} (H : bij_on f a b) :
      inj_on f a :=
and.left (and.right H)

lemma surj_on_of_bij_on {f : X → Y} {a : set X} {b : set Y} (H : bij_on f a b) :
      surj_on f a b :=
and.right (and.right H)

lemma bij_on.mk {f : X → Y} {a : set X} {b : set Y}
                (H₁ : maps_to f a b) (H₂ : inj_on f a) (H₃ : surj_on f a b) :
      bij_on f a b :=
and.intro H₁ (and.intro H₂ H₃)

theorem bij_on_of_eq_on {f1 f2 : X → Y} {a : set X} {b : set Y} (eqf : eq_on f1 f2 a)
     (H : bij_on f1 a b) : bij_on f2 a b :=
match H with and.intro Hmap (and.intro Hinj Hsurj) :=
  and.intro
    (maps_to_of_eq_on eqf Hmap)
    (and.intro
      (inj_on_of_eq_on eqf Hinj)
      (surj_on_of_eq_on eqf Hsurj))
end

lemma image_eq_of_bij_on {f : X → Y} {a : set X} {b : set Y} (bfab : bij_on f a b) :
  f ' a = b :=
image_eq_of_maps_to_of_surj_on (and.left bfab) (and.right (and.right bfab))

theorem bij_on_comp {g : Y → Z} {f : X → Y} {a : set X} {b : set Y} {c : set Z}
  (Hg : bij_on g b c) (Hf: bij_on f a b) :
  bij_on (g ∘ f) a c :=
match Hg with and.intro Hgmap (and.intro Hginj Hgsurj) :=
  match Hf with and.intro Hfmap (and.intro Hfinj Hfsurj) :=
    and.intro
      (maps_to_comp Hgmap Hfmap)
      (and.intro
        (inj_on_comp Hfmap Hginj Hfinj)
        (surj_on_comp Hgsurj Hfsurj))
  end
end

lemma bijective_iff_bij_on_univ {f : X → Y} : bijective f ↔ bij_on f univ univ :=
iff.intro
  (assume H,
    obtain Hinj Hsurj, from H,
    and.intro (maps_to_univ_univ f)
      (and.intro
        (iff.mp !injective_iff_inj_on_univ Hinj)
        (iff.mp !surjective_iff_surj_on_univ Hsurj)))
 (assume H,
    obtain Hmaps Hinj Hsurj, from H,
      (and.intro
        (iff.mpr !injective_iff_inj_on_univ Hinj)
        (iff.mpr !surjective_iff_surj_on_univ Hsurj)))

/- left inverse -/

-- g is a left inverse to f on a
attribute [reducible]
definition left_inv_on (g : Y → X) (f : X → Y) (a : set X) : Prop :=
∀₀ x ∈ a, g (f x) = x

theorem left_inv_on_of_eq_on_left {g1 g2 : Y → X} {f : X → Y} {a : set X} {b : set Y}
  (fab : maps_to f a b) (eqg : eq_on g1 g2 b) (H : left_inv_on g1 f a) : left_inv_on g2 f a :=
take x,
assume xa : x ∈ a,
calc
  g2 (f x) = g1 (f x) : (eqg (fab xa))⁻¹
       ... = x        : H xa

theorem left_inv_on_of_eq_on_right {g : Y → X} {f1 f2 : X → Y} {a : set X}
  (eqf : eq_on f1 f2 a) (H : left_inv_on g f1 a) : left_inv_on g f2 a :=
take x,
assume xa : x ∈ a,
calc
  g (f2 x) = g (f1 x) : {(eqf xa)⁻¹}
       ... = x        : H xa

theorem inj_on_of_left_inv_on {g : Y → X} {f : X → Y} {a : set X} (H : left_inv_on g f a) :
  inj_on f a :=
take x1 x2,
assume x1a : x1 ∈ a,
assume x2a : x2 ∈ a,
assume H1 : f x1 = f x2,
calc
  x1     = g (f x1) : H x1a
     ... = g (f x2) : H1
     ... = x2       : H x2a

theorem left_inv_on_comp {f' : Y → X} {g' : Z → Y} {g : Y → Z} {f : X → Y}
   {a : set X} {b : set Y} (fab : maps_to f a b)
    (Hf : left_inv_on f' f a) (Hg : left_inv_on g' g b) : left_inv_on (f' ∘ g') (g ∘ f) a :=
take x : X,
assume xa : x ∈ a,
have fxb : f x ∈ b, from fab xa,
calc
  f' (g' (g (f x))) = f' (f x) : Hg fxb
                ... = x        : Hf xa

/- right inverse -/

-- g is a right inverse to f on a
attribute [reducible]
definition right_inv_on (g : Y → X) (f : X → Y) (b : set Y) : Prop :=
left_inv_on f g b

theorem right_inv_on_of_eq_on_left {g1 g2 : Y → X} {f : X → Y} {a : set X} {b : set Y}
  (eqg : eq_on g1 g2 b) (H : right_inv_on g1 f b) : right_inv_on g2 f b :=
left_inv_on_of_eq_on_right eqg H

theorem right_inv_on_of_eq_on_right {g : Y → X} {f1 f2 : X → Y} {a : set X} {b : set Y}
  (gba : maps_to g b a) (eqf : eq_on f1 f2 a) (H : right_inv_on g f1 b) : right_inv_on g f2 b :=
left_inv_on_of_eq_on_left gba eqf H

theorem surj_on_of_right_inv_on {g : Y → X} {f : X → Y} {a : set X} {b : set Y}
    (gba : maps_to g b a) (H : right_inv_on g f b) :
  surj_on f a b :=
take y,
assume yb : y ∈ b,
have gya : g y ∈ a, from gba yb,
have H1 : f (g y) = y, from H yb,
exists.intro (g y) (and.intro gya H1)

theorem right_inv_on_comp {f' : Y → X} {g' : Z → Y} {g : Y → Z} {f : X → Y}
   {c : set Z} {b : set Y} (g'cb : maps_to g' c b)
    (Hf : right_inv_on f' f b) (Hg : right_inv_on g' g c) : right_inv_on (f' ∘ g') (g ∘ f) c :=
left_inv_on_comp g'cb Hg Hf

theorem right_inv_on_of_inj_on_of_left_inv_on {f : X → Y} {g : Y → X} {a : set X} {b : set Y}
    (fab : maps_to f a b) (gba : maps_to g b a) (injf : inj_on f a) (lfg : left_inv_on f g b) :
  right_inv_on f g a :=
take x, assume xa : x ∈ a,
have H : f (g (f x)) = f x, from lfg (fab xa),
injf (gba (fab xa)) xa H

theorem eq_on_of_left_inv_of_right_inv {g1 g2 : Y → X} {f : X → Y} {a : set X} {b : set Y}
  (g2ba : maps_to g2 b a) (Hg1 : left_inv_on g1 f a) (Hg2 : right_inv_on g2 f b) : eq_on g1 g2 b :=
take y,
assume yb : y ∈ b,
calc
  g1 y = g1 (f (g2 y)) : {(Hg2 yb)⁻¹}
   ... = g2 y          : Hg1 (g2ba yb)

theorem left_inv_on_of_surj_on_right_inv_on {f : X → Y} {g : Y → X} {a : set X} {b : set Y}
    (surjf : surj_on f a b) (rfg : right_inv_on f g a) :
  left_inv_on f g b :=
take y, assume yb : y ∈ b,
obtain x (xa : x ∈ a) (Hx : f x = y), from surjf yb,
calc
  f (g y) = f (g (f x)) : Hx
      ... = f x         : rfg xa
      ... = y           : Hx

/- inverses -/

-- g is an inverse to f viewed as a map from a to b
attribute [reducible]
definition inv_on (g : Y → X) (f : X → Y) (a : set X) (b : set Y) : Prop :=
left_inv_on g f a ∧ right_inv_on g f b

theorem bij_on_of_inv_on {g : Y → X} {f : X → Y} {a : set X} {b : set Y} (fab : maps_to f a b)
  (gba : maps_to g b a) (H : inv_on g f a b) : bij_on f a b :=
and.intro fab
  (and.intro
    (inj_on_of_left_inv_on (and.left H))
    (surj_on_of_right_inv_on gba (and.right H)))

end set
