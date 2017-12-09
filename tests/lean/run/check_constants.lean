-- DO NOT EDIT, automatically generated file, generator scripts/gen_constants_cpp.py
import smt system.io
open tactic
meta def script_check_id (n : name) : tactic unit :=
do env ← get_env, (env^.get n >> return ()) <|> (guard $ env^.is_namespace n) <|> (attribute.get_instances n >> return ()) <|> fail ("identifier '" ++ to_string n ++ "' is not a constant, namespace nor attribute")
run_cmd script_check_id `absurd
run_cmd script_check_id `acc.cases_on
run_cmd script_check_id `acc.rec
run_cmd script_check_id `add_comm_group
run_cmd script_check_id `add_comm_semigroup
run_cmd script_check_id `add_group
run_cmd script_check_id `add_monoid
run_cmd script_check_id `and
run_cmd script_check_id `and.elim_left
run_cmd script_check_id `and.elim_right
run_cmd script_check_id `and.intro
run_cmd script_check_id `and.rec
run_cmd script_check_id `and.cases_on
run_cmd script_check_id `auto_param
run_cmd script_check_id `bit0
run_cmd script_check_id `bit1
run_cmd script_check_id `bin_tree.empty
run_cmd script_check_id `bin_tree.leaf
run_cmd script_check_id `bin_tree.node
run_cmd script_check_id `bool
run_cmd script_check_id `bool.ff
run_cmd script_check_id `bool.tt
run_cmd script_check_id `combinator.K
run_cmd script_check_id `cast
run_cmd script_check_id `cast_heq
run_cmd script_check_id `char
run_cmd script_check_id `char.mk
run_cmd script_check_id `char.ne_of_vne
run_cmd script_check_id `char.of_nat
run_cmd script_check_id `char.of_nat_ne_of_ne
run_cmd script_check_id `is_valid_char_range_1
run_cmd script_check_id `is_valid_char_range_2
run_cmd script_check_id `coe
run_cmd script_check_id `coe_fn
run_cmd script_check_id `coe_sort
run_cmd script_check_id `coe_to_lift
run_cmd script_check_id `congr
run_cmd script_check_id `congr_arg
run_cmd script_check_id `congr_fun
run_cmd script_check_id `decidable
run_cmd script_check_id `decidable.to_bool
run_cmd script_check_id `distrib
run_cmd script_check_id `dite
run_cmd script_check_id `empty
run_cmd script_check_id `Exists
run_cmd script_check_id `eq
run_cmd script_check_id `eq.cases_on
run_cmd script_check_id `eq.drec
run_cmd script_check_id `eq.mp
run_cmd script_check_id `eq.mpr
run_cmd script_check_id `eq.rec
run_cmd script_check_id `eq.refl
run_cmd script_check_id `eq.subst
run_cmd script_check_id `eq.symm
run_cmd script_check_id `eq.trans
run_cmd script_check_id `eq_of_heq
run_cmd script_check_id `eq_rec_heq
run_cmd script_check_id `eq_true_intro
run_cmd script_check_id `eq_false_intro
run_cmd script_check_id `eq_self_iff_true
run_cmd script_check_id `expr
run_cmd script_check_id `expr.subst
run_cmd script_check_id `format
run_cmd script_check_id `false
run_cmd script_check_id `false_of_true_iff_false
run_cmd script_check_id `false_of_true_eq_false
run_cmd script_check_id `true_eq_false_of_false
run_cmd script_check_id `false.rec
run_cmd script_check_id `field
run_cmd script_check_id `fin.mk
run_cmd script_check_id `fin.ne_of_vne
run_cmd script_check_id `forall_congr
run_cmd script_check_id `forall_congr_eq
run_cmd script_check_id `forall_not_of_not_exists
run_cmd script_check_id `funext
run_cmd script_check_id `has_add
run_cmd script_check_id `has_add.add
run_cmd script_check_id `has_andthen.andthen
run_cmd script_check_id `has_bind.and_then
run_cmd script_check_id `has_bind.seq
run_cmd script_check_id `has_div
run_cmd script_check_id `has_div.div
run_cmd script_check_id `has_emptyc.emptyc
run_cmd script_check_id `has_mul
run_cmd script_check_id `has_mul.mul
run_cmd script_check_id `has_insert.insert
run_cmd script_check_id `has_inv
run_cmd script_check_id `has_inv.inv
run_cmd script_check_id `has_le
run_cmd script_check_id `has_le.le
run_cmd script_check_id `has_lt
run_cmd script_check_id `has_lt.lt
run_cmd script_check_id `has_neg
run_cmd script_check_id `has_neg.neg
run_cmd script_check_id `has_one
run_cmd script_check_id `has_one.one
run_cmd script_check_id `has_orelse.orelse
run_cmd script_check_id `has_sep.sep
run_cmd script_check_id `has_sizeof
run_cmd script_check_id `has_sizeof.mk
run_cmd script_check_id `has_sub
run_cmd script_check_id `has_sub.sub
run_cmd script_check_id `has_to_format
run_cmd script_check_id `has_repr
run_cmd script_check_id `has_well_founded
run_cmd script_check_id `has_well_founded.r
run_cmd script_check_id `has_well_founded.wf
run_cmd script_check_id `has_zero
run_cmd script_check_id `has_zero.zero
run_cmd script_check_id `has_coe_t
run_cmd script_check_id `heq
run_cmd script_check_id `heq.refl
run_cmd script_check_id `heq.symm
run_cmd script_check_id `heq.trans
run_cmd script_check_id `heq_of_eq
run_cmd script_check_id `hole_command
run_cmd script_check_id `id
run_cmd script_check_id `id_rhs
run_cmd script_check_id `id_delta
run_cmd script_check_id `if_neg
run_cmd script_check_id `if_pos
run_cmd script_check_id `iff
run_cmd script_check_id `iff_false_intro
run_cmd script_check_id `iff.intro
run_cmd script_check_id `iff.mp
run_cmd script_check_id `iff.mpr
run_cmd script_check_id `iff.refl
run_cmd script_check_id `iff.symm
run_cmd script_check_id `iff.trans
run_cmd script_check_id `iff_true_intro
run_cmd script_check_id `imp_congr
run_cmd script_check_id `imp_congr_eq
run_cmd script_check_id `imp_congr_ctx
run_cmd script_check_id `imp_congr_ctx_eq
run_cmd script_check_id `implies
run_cmd script_check_id `implies_of_if_neg
run_cmd script_check_id `implies_of_if_pos
run_cmd script_check_id `int
run_cmd script_check_id `int.bit0_nonneg
run_cmd script_check_id `int.bit1_nonneg
run_cmd script_check_id `int.one_nonneg
run_cmd script_check_id `int.zero_nonneg
run_cmd script_check_id `int.bit0_pos
run_cmd script_check_id `int.bit1_pos
run_cmd script_check_id `int.one_pos
run_cmd script_check_id `int.nat_abs_zero
run_cmd script_check_id `int.nat_abs_one
run_cmd script_check_id `int.nat_abs_bit0_step
run_cmd script_check_id `int.nat_abs_bit1_nonneg_step
run_cmd script_check_id `int.ne_of_nat_ne_nonneg_case
run_cmd script_check_id `int.ne_neg_of_ne
run_cmd script_check_id `int.neg_ne_of_pos
run_cmd script_check_id `int.ne_neg_of_pos
run_cmd script_check_id `int.neg_ne_zero_of_ne
run_cmd script_check_id `int.zero_ne_neg_of_ne
run_cmd script_check_id `interactive.param_desc
run_cmd script_check_id `interactive.parse
run_cmd script_check_id `io_core
run_cmd script_check_id `monad_io_impl
run_cmd script_check_id `monad_io_terminal_impl
run_cmd script_check_id `monad_io_file_system_impl
run_cmd script_check_id `monad_io_environment_impl
run_cmd script_check_id `monad_io_process_impl
run_cmd script_check_id `monad_io_random_impl
run_cmd script_check_id `io_rand_nat
run_cmd script_check_id `io
run_cmd script_check_id `is_associative
run_cmd script_check_id `is_associative.assoc
run_cmd script_check_id `is_commutative
run_cmd script_check_id `is_commutative.comm
run_cmd script_check_id `ite
run_cmd script_check_id `lean.parser
run_cmd script_check_id `lean.parser.pexpr
run_cmd script_check_id `lean.parser.tk
run_cmd script_check_id `left_distrib
run_cmd script_check_id `left_comm
run_cmd script_check_id `le_refl
run_cmd script_check_id `linear_ordered_ring
run_cmd script_check_id `linear_ordered_semiring
run_cmd script_check_id `list
run_cmd script_check_id `list.nil
run_cmd script_check_id `list.cons
run_cmd script_check_id `match_failed
run_cmd script_check_id `monad
run_cmd script_check_id `monad_fail
run_cmd script_check_id `monoid
run_cmd script_check_id `mul_one
run_cmd script_check_id `mul_zero
run_cmd script_check_id `mul_zero_class
run_cmd script_check_id `name.anonymous
run_cmd script_check_id `name.mk_numeral
run_cmd script_check_id `name.mk_string
run_cmd script_check_id `nat
run_cmd script_check_id `nat.succ
run_cmd script_check_id `nat.zero
run_cmd script_check_id `nat.has_zero
run_cmd script_check_id `nat.has_one
run_cmd script_check_id `nat.has_add
run_cmd script_check_id `nat.add
run_cmd script_check_id `nat.cases_on
run_cmd script_check_id `nat.bit0_ne
run_cmd script_check_id `nat.bit0_ne_bit1
run_cmd script_check_id `nat.bit0_ne_zero
run_cmd script_check_id `nat.bit0_ne_one
run_cmd script_check_id `nat.bit1_ne
run_cmd script_check_id `nat.bit1_ne_bit0
run_cmd script_check_id `nat.bit1_ne_zero
run_cmd script_check_id `nat.bit1_ne_one
run_cmd script_check_id `nat.zero_ne_one
run_cmd script_check_id `nat.zero_ne_bit0
run_cmd script_check_id `nat.zero_ne_bit1
run_cmd script_check_id `nat.one_ne_zero
run_cmd script_check_id `nat.one_ne_bit0
run_cmd script_check_id `nat.one_ne_bit1
run_cmd script_check_id `nat.bit0_lt
run_cmd script_check_id `nat.bit1_lt
run_cmd script_check_id `nat.bit0_lt_bit1
run_cmd script_check_id `nat.bit1_lt_bit0
run_cmd script_check_id `nat.zero_lt_one
run_cmd script_check_id `nat.zero_lt_bit1
run_cmd script_check_id `nat.zero_lt_bit0
run_cmd script_check_id `nat.one_lt_bit0
run_cmd script_check_id `nat.one_lt_bit1
run_cmd script_check_id `nat.le_of_lt
run_cmd script_check_id `nat.le_refl
run_cmd script_check_id `ne
run_cmd script_check_id `neq_of_not_iff
run_cmd script_check_id `norm_num.add1
run_cmd script_check_id `norm_num.add1_bit0
run_cmd script_check_id `norm_num.add1_bit1_helper
run_cmd script_check_id `norm_num.add1_one
run_cmd script_check_id `norm_num.add1_zero
run_cmd script_check_id `norm_num.add_div_helper
run_cmd script_check_id `norm_num.bin_add_zero
run_cmd script_check_id `norm_num.bin_zero_add
run_cmd script_check_id `norm_num.bit0_add_bit0_helper
run_cmd script_check_id `norm_num.bit0_add_bit1_helper
run_cmd script_check_id `norm_num.bit0_add_one
run_cmd script_check_id `norm_num.bit1_add_bit0_helper
run_cmd script_check_id `norm_num.bit1_add_bit1_helper
run_cmd script_check_id `norm_num.bit1_add_one_helper
run_cmd script_check_id `norm_num.div_add_helper
run_cmd script_check_id `norm_num.div_eq_div_helper
run_cmd script_check_id `norm_num.div_helper
run_cmd script_check_id `norm_num.div_mul_helper
run_cmd script_check_id `norm_num.mk_cong
run_cmd script_check_id `norm_num.mul_bit0_helper
run_cmd script_check_id `norm_num.mul_bit1_helper
run_cmd script_check_id `norm_num.mul_div_helper
run_cmd script_check_id `norm_num.neg_add_neg_helper
run_cmd script_check_id `norm_num.neg_add_pos_helper1
run_cmd script_check_id `norm_num.neg_add_pos_helper2
run_cmd script_check_id `norm_num.neg_mul_neg_helper
run_cmd script_check_id `norm_num.neg_mul_pos_helper
run_cmd script_check_id `norm_num.neg_neg_helper
run_cmd script_check_id `norm_num.neg_zero_helper
run_cmd script_check_id `norm_num.nonneg_bit0_helper
run_cmd script_check_id `norm_num.nonneg_bit1_helper
run_cmd script_check_id `norm_num.nonzero_of_div_helper
run_cmd script_check_id `norm_num.nonzero_of_neg_helper
run_cmd script_check_id `norm_num.nonzero_of_pos_helper
run_cmd script_check_id `norm_num.one_add_bit0
run_cmd script_check_id `norm_num.one_add_bit1_helper
run_cmd script_check_id `norm_num.one_add_one
run_cmd script_check_id `norm_num.pos_add_neg_helper
run_cmd script_check_id `norm_num.pos_bit0_helper
run_cmd script_check_id `norm_num.pos_bit1_helper
run_cmd script_check_id `norm_num.pos_mul_neg_helper
run_cmd script_check_id `norm_num.sub_nat_zero_helper
run_cmd script_check_id `norm_num.sub_nat_pos_helper
run_cmd script_check_id `norm_num.subst_into_div
run_cmd script_check_id `norm_num.subst_into_prod
run_cmd script_check_id `norm_num.subst_into_subtr
run_cmd script_check_id `norm_num.subst_into_sum
run_cmd script_check_id `not
run_cmd script_check_id `not_of_iff_false
run_cmd script_check_id `not_of_eq_false
run_cmd script_check_id `of_eq_true
run_cmd script_check_id `of_iff_true
run_cmd script_check_id `opt_param
run_cmd script_check_id `or
run_cmd script_check_id `out_param
run_cmd script_check_id `punit
run_cmd script_check_id `punit.star
run_cmd script_check_id `prod.mk
run_cmd script_check_id `pprod
run_cmd script_check_id `pprod.mk
run_cmd script_check_id `pprod.fst
run_cmd script_check_id `pprod.snd
run_cmd script_check_id `propext
run_cmd script_check_id `to_pexpr
run_cmd script_check_id `quot.mk
run_cmd script_check_id `quot.lift
run_cmd script_check_id `reflected
run_cmd script_check_id `reflected.subst
run_cmd script_check_id `repr
run_cmd script_check_id `rfl
run_cmd script_check_id `right_distrib
run_cmd script_check_id `ring
run_cmd script_check_id `scope_trace
run_cmd script_check_id `set_of
run_cmd script_check_id `semiring
run_cmd script_check_id `psigma
run_cmd script_check_id `psigma.cases_on
run_cmd script_check_id `psigma.mk
run_cmd script_check_id `psigma.fst
run_cmd script_check_id `psigma.snd
run_cmd script_check_id `singleton
run_cmd script_check_id `sizeof
run_cmd script_check_id `string
run_cmd script_check_id `string.empty
run_cmd script_check_id `string.str
run_cmd script_check_id `string.empty_ne_str
run_cmd script_check_id `string.str_ne_empty
run_cmd script_check_id `string.str_ne_str_left
run_cmd script_check_id `string.str_ne_str_right
run_cmd script_check_id `subsingleton
run_cmd script_check_id `subsingleton.elim
run_cmd script_check_id `subsingleton.helim
run_cmd script_check_id `subtype
run_cmd script_check_id `subtype.mk
run_cmd script_check_id `subtype.val
run_cmd script_check_id `subtype.rec
run_cmd script_check_id `psum
run_cmd script_check_id `psum.cases_on
run_cmd script_check_id `psum.inl
run_cmd script_check_id `psum.inr
run_cmd script_check_id `tactic
run_cmd script_check_id `tactic.try
run_cmd script_check_id `tactic.triv
run_cmd script_check_id `tactic.mk_inj_eq
run_cmd script_check_id `thunk
run_cmd script_check_id `to_fmt
run_cmd script_check_id `trans_rel_left
run_cmd script_check_id `trans_rel_right
run_cmd script_check_id `true
run_cmd script_check_id `true.intro
run_cmd script_check_id `unification_hint
run_cmd script_check_id `unification_hint.mk
run_cmd script_check_id `unit
run_cmd script_check_id `unit.cases_on
run_cmd script_check_id `unit.star
run_cmd script_check_id `monad_from_pure_bind
run_cmd script_check_id `user_attribute
run_cmd script_check_id `user_attribute.parse_reflect
run_cmd script_check_id `vm_monitor
run_cmd script_check_id `partial_order
run_cmd script_check_id `well_founded.fix
run_cmd script_check_id `well_founded.fix_eq
run_cmd script_check_id `well_founded_tactics
run_cmd script_check_id `well_founded_tactics.default
run_cmd script_check_id `well_founded_tactics.rel_tac
run_cmd script_check_id `well_founded_tactics.dec_tac
run_cmd script_check_id `zero_le_one
run_cmd script_check_id `zero_lt_one
run_cmd script_check_id `zero_mul
