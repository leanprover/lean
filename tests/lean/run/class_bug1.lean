inductive [class] category (ob : Type) (mor : ob → ob → Type) : Type
| mk : Π (comp : Π⦃A B C : ob⦄, mor B C → mor A B → mor A C)
           (id : Π {A : ob}, mor A A),
            (Π {A B C D : ob} {f : mor A B} {g : mor B C} {h : mor C D},
            comp h (comp g f) = comp (comp h g) f) →
           (Π {A B : ob} {f : mor A B}, comp f id = f) →
           (Π {A B : ob} {f : mor A B}, comp id f = f) →
            category

namespace category
section sec_cat
  parameter A : Type
  inductive [class] foo
  | mk : A → foo

  parameters {ob : Type} {mor : ob → ob → Type} {Cat : category ob mor}
  definition compose := category.rec (λ comp id assoc idr idl, comp) Cat
  definition id := category.rec (λ comp id assoc idr idl, id) Cat
  local infixr ∘ := compose
  inductive is_section {A B : ob} (f : mor A B) : Type
  | mk : ∀g : mor B A, g ∘ f = id → is_section
end sec_cat
end category
