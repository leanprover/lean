lemma simp_rule :
    forall (A B C : Type)
           (xs : list A)
           (f: A → B)
           (g: B → C), (list.map g $ (list.map f) xs) = list.map (g ∘ f) xs :=
begin
    intros,
    induction xs,
    simp [list.map],
    simp [list.map],
end

lemma simp_wildcard :
forall (A B C : Type)
(a b : list A)
(a' b' : list C)
(f : A → B)
(g h : B → C),
(list.map g $ list.map f a) = a' ->
(list.map h $ list.map f b) = b' ->
a' = list.map (g ∘ f) a ∧ b' = list.map (h ∘ f) b :=
begin
    intros,
    simp [simp_rule] at *,
    rw [a_1_1, a_2_1],
    split; reflexivity
end
