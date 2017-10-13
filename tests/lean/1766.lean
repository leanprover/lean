inductive is_some (x : option nat) : Prop
  | mk : ∀ value : nat, x = some value → is_some

def value_1 (x : option nat) (H : is_some x)
   : nat :=
begin
   destruct x; intros,
   {destruct H, -- ERROR: `is_some` can only eliminate into Prop
    intros, clear a_2, rw a at a_1, contradiction},
   {assumption}
end

def value_2 (x : option nat) (H : is_some x)
   : x = x :=
begin
   destruct x,
   {intro h, destruct H,
    intros _ h', rw h at h'},
   {intros, refl}
end

inductive is_some' (x : option nat) : Type
  | mk : ∀ value : nat, x = some value → is_some'

def value_3 (x : option nat) (H : is_some' x)
   : nat :=
begin
   destruct x,
   {intro h, destruct H,
    intros _ h' _, rw h at h', contradiction},
   {intros, assumption}
end
