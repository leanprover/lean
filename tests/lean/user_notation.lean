open lean (parser)
open lean.parser
open interactive
open tactic

reserve prefix `unquote! `:100
@[user_notation]
meta def unquote_macro (_ : parse $ tk "unquote!") (e : parse lean.parser.pexpr) : parser pexpr :=
↑(to_expr e >>= eval_expr pexpr)

#eval unquote! ``(1 + 1)

private meta def parse_format : string → string → ℕ × pexpr
| acc [] := (0, pexpr.of_expr (reflect acc))
| acc ('{'::'{'::s) := parse_format (acc ++ "{") s
| acc ('{'::'}'::s) :=
  let (n, f) := parse_format [] s in
  (n + 1, ``(to_fmt %%(reflect acc) ++ to_fmt %%(expr.var n : pexpr) ++ %%f))
| acc (c::s) := parse_format (acc ++ [c]) s

reserve prefix `format! `:100
@[user_notation]
let (n, f) := parse_format "" s.reverse in
pure $ n.repeat (λ _ e, expr.lam `_ binder_info.default pexpr.mk_placeholder e) f
meta def format_macro (_ : parse $ tk "format!") (s : string) : parser pexpr :=

#eval format! "a{}c" "b"
-- #eval format! "{} {}" "a" "bla" -- TODO: delayed abstractions issue

reserve infix ` +⋯+ `:65
@[user_notation]
meta def upto_notation (e₁ : parse lean.parser.pexpr) (_ : parse $ tk "+⋯+") (n₂ : ℕ) : parser pexpr :=
do n₁ ← ↑(to_expr e₁ >>= eval_expr nat),
   pure $ (n₂+1-n₁).repeat (λ i e, ``(%%e + %%(reflect $ n₁ + i))) ``(0)

#check 1 +⋯+ 10
