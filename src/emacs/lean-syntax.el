;; Copyright (c) 2013, 2014 Microsoft Corporation. All rights reserved.
;; Released under Apache 2.0 license as described in the file LICENSE.
;;
;; Author: Leonardo de Moura
;;         Soonho Kong
;;

(require 'rx)

(defconst lean-keywords
  '("import" "reducible" "irreducible" "tactic_hint" "protected" "private" "opaque" "definition" "renaming"
    "hiding" "exposing" "parameter" "parameters" "begin" "proof" "qed" "conjecture" "constant" "constants"
    "hypothesis" "lemma" "corollary" "variable" "variables" "print" "theorem"
    "context" "open" "as" "export" "axiom" "inductive" "with" "structure" "universe" "universes"
    "alias" "help" "environment" "options" "precedence" "reserve" "postfix" "prefix" "calc_trans" "calc_subst" "calc_refl"
    "infix" "infixl" "infixr" "notation" "eval" "check" "exit" "coercion" "end"
    "using" "namespace" "instance" "class" "section"
    "set_option" "add_rewrite" "extends" "include" "omit" "classes" "instances" "coercions" "raw")
  "lean keywords")

(defconst lean-syntax-table
  (let ((st (make-syntax-table)))
    ;; Matching parens
    (modify-syntax-entry ?\[ "(]" st)
    (modify-syntax-entry ?\] ")[" st)
    (modify-syntax-entry ?\{ "(}" st)
    (modify-syntax-entry ?\} "){" st)

    ;; comment
    (modify-syntax-entry ?/ "_ 14nb" st)
    (modify-syntax-entry ?- "_ 123" st)
    (modify-syntax-entry ?\n ">" st)

    ;; Word constituent
    (--map (modify-syntax-entry it "w" st)
           (list ?a ?b ?c ?d ?e ?f ?g ?h ?i ?j ?k ?l ?m
                 ?n ?o ?p ?q ?r ?s ?t ?u ?v ?w ?x ?y ?z
                 ?A ?B ?C ?D ?E ?F ?G ?H ?I ?J ?K ?L ?M
                 ?N ?O ?P ?Q ?R ?S ?T ?U ?V ?W ?X ?Y ?Z))
    (--map (modify-syntax-entry it "w" st)
           (list ?0 ?1 ?2 ?3 ?4 ?5 ?6 ?7 ?8 ?9))
    (--map (modify-syntax-entry it "w" st)
           (list ?α ?β ?γ ?δ ?ε ?ζ ?η ?θ ?ι ?κ ;;?λ
                 ?μ ?ν ?ξ ?ο ?π ?ρ ?ς ?σ ?τ ?υ
                 ?φ ?χ ?ψ ?ω))
    (--map (modify-syntax-entry it "w" st)
           (list ?ϊ ?ϋ ?ό ?ύ ?ώ ?Ϗ ?ϐ ?ϑ ?ϒ ?ϓ ?ϔ ?ϕ ?ϖ
                 ?ϗ ?Ϙ ?ϙ ?Ϛ ?ϛ ?Ϝ ?ϝ ?Ϟ ?ϟ ?Ϡ ?ϡ ?Ϣ ?ϣ
                 ?Ϥ ?ϥ ?Ϧ ?ϧ ?Ϩ ?ϩ ?Ϫ ?ϫ ?Ϭ ?ϭ ?Ϯ ?ϯ ?ϰ
                 ?ϱ ?ϲ ?ϳ ?ϴ ?ϵ ?϶ ?Ϸ ?ϸ ?Ϲ ?Ϻ ?ϻ))
    (--map (modify-syntax-entry it "w" st)
           (list ?ἀ ?ἁ ?ἂ ?ἃ ?ἄ ?ἅ ?ἆ ?ἇ ?Ἀ ?Ἁ ?Ἂ ?Ἃ ?Ἄ
                 ?Ἅ ?Ἆ ?Ἇ ?ἐ ?ἑ ?ἒ ?ἓ ?ἔ ?ἕ ?἖ ?἗ ?Ἐ ?Ἑ
                 ?Ἒ ?Ἓ ?Ἔ ?Ἕ ?἞ ?἟ ?ἠ ?ἡ ?ἢ ?ἣ ?ἤ ?ἥ
                 ?ἦ ?ἧ ?Ἠ ?Ἡ ?Ἢ ?Ἣ ?Ἤ ?Ἥ ?Ἦ ?Ἧ ?ἰ ?ἱ
                 ?ἲ ?ἳ ?ἴ ?ἵ ?ἶ ?ἷ ?Ἰ ?Ἱ ?Ἲ ?Ἳ ?Ἴ ?Ἵ ?Ἶ ?Ἷ
                 ?ὀ ?ὁ ?ὂ ?ὃ ?ὄ ?ὅ ?὆ ?὇ ?Ὀ ?Ὁ ?Ὂ ?Ὃ
                 ?Ὄ ?Ὅ ?὎ ?὏ ?ὐ ?ὑ ?ὒ ?ὓ ?ὔ ?ὕ ?ὖ ?ὗ
                 ?὘ ?Ὑ ?὚ ?Ὓ ?὜ ?Ὕ ?὞ ?Ὗ ?ὠ ?ὡ ?ὢ
                 ?ὣ ?ὤ ?ὥ ?ὦ ?ὧ ?Ὠ ?Ὡ ?Ὢ ?Ὣ ?Ὤ ?Ὥ ?Ὦ
                 ?Ὧ ?ὰ ?ά ?ὲ ?έ ?ὴ ?ή ?ὶ ?ί ?ὸ ?ό ?ὺ ?ύ ?ὼ
                 ?ώ ?὾ ?὿ ?ᾀ ?ᾁ ?ᾂ ?ᾃ ?ᾄ ?ᾅ ?ᾆ ?ᾇ ?ᾈ
                 ?ᾉ ?ᾊ ?ᾋ ?ᾌ ?ᾍ ?ᾎ ?ᾏ ?ᾐ ?ᾑ ?ᾒ ?ᾓ ?ᾔ
                 ?ᾕ ?ᾖ ?ᾗ ?ᾘ ?ᾙ ?ᾚ ?ᾛ ?ᾜ ?ᾝ ?ᾞ ?ᾟ ?ᾠ ?ᾡ ?ᾢ
                 ?ᾣ ?ᾤ ?ᾥ ?ᾦ ?ᾧ ?ᾨ ?ᾩ ?ᾪ ?ᾫ ?ᾬ ?ᾭ ?ᾮ ?ᾯ ?ᾰ
                 ?ᾱ ?ᾲ ?ᾳ ?ᾴ ?᾵ ?ᾶ ?ᾷ ?Ᾰ ?Ᾱ ?Ὰ ?Ά ?ᾼ ?᾽
                 ?ι ?᾿ ?῀ ?῁ ?ῂ ?ῃ ?ῄ ?῅ ?ῆ ?ῇ ?Ὲ ?Έ ?Ὴ
                 ?Ή ?ῌ ?῍ ?῎ ?῏ ?ῐ ?ῑ ?ῒ ?ΐ ?῔ ?῕ ?ῖ ?ῗ
                 ?Ῐ ?Ῑ ?Ὶ ?Ί ?῜ ?῝ ?῞ ?῟ ?ῠ ?ῡ ?ῢ ?ΰ ?ῤ ?ῥ
                 ?ῦ ?ῧ ?Ῠ ?Ῡ ?Ὺ ?Ύ ?Ῥ ?῭ ?΅ ?` ?῰ ?῱ ?ῲ ?ῳ
                 ?ῴ ?῵ ?ῶ ?ῷ ?Ὸ ?Ό ?Ὼ ?Ώ ?ῼ ?´ ?῾))
    (--map (modify-syntax-entry it "w" st)
           (list ?℀ ?℁ ?ℂ ?℃ ?℄ ?℅ ?℆ ?ℇ ?℈ ?℉ ?ℊ ?ℋ ?ℌ ?ℍ ?ℎ
                 ?ℏ ?ℐ ?ℑ ?ℒ ?ℓ ?℔ ?ℕ ?№ ?℗ ?℘ ?ℙ ?ℚ ?ℛ ?ℜ ?ℝ
                 ?℞ ?℟ ?℠ ?℡ ?™ ?℣ ?ℤ ?℥ ?Ω ?℧ ?ℨ ?℩ ?K ?Å ?ℬ
                 ?ℭ ?℮ ?ℯ ?ℰ ?ℱ ?Ⅎ ?ℳ ?ℴ ?ℵ ?ℶ ?ℷ ?ℸ ?ℹ ?℺ ?℻
                 ?ℼ ?ℽ ?ℾ ?ℿ ?⅀ ?⅁ ?⅂ ?⅃ ?⅄ ?ⅅ ?ⅆ ?ⅇ ?ⅈ ?ⅉ ?⅊
                 ?⅋ ?⅌ ?⅍ ?ⅎ ?⅏))
    (modify-syntax-entry ?' "w" st)
    (modify-syntax-entry ?_ "w" st)

    ;; Lean operator chars
    (mapc #'(lambda (ch) (modify-syntax-entry ch "_" st))
          "!#$%&*+.<=>@^|~:")

    ;; Whitespace is whitespace
    (modify-syntax-entry ?\  " " st)
    (modify-syntax-entry ?\t " " st)

    ;; Strings
    (modify-syntax-entry ?\" "\"" st)
    (modify-syntax-entry ?\\ "/" st)
    st))

(defconst lean-font-lock-defaults
  `((;; Keywords
     (,(rx word-start (or "calc" "have" "obtains" "show" "by" "in" "let" "forall" "fun"
                            "exists" "if" "then" "else" "assume" "take" "obtain" "from") word-end)
      . font-lock-keyword-face)
     ;; String
     ("\"[^\"]*\"" . 'font-lock-string-face)
     ;; Constants
     (,(rx (or "#" "@" "->" "∼" "↔" "/" "==" "=" ":=" "<->" "/\\" "\\/" "∧" "∨" "≠" "<" ">" "≤" "≥" "¬" "<=" ">=" "⁻¹" "⬝" "▸" "+" "*" "-" "/")) . 'font-lock-constant-face)
     (,(rx (or "λ" "→" "∃" "∀" ":=")) . 'font-lock-constant-face )
     ;; universe/inductive/theorem... "names"
     (,(rx word-start
           (group (or "inductive" "theorem" "axiom" "lemma" "hypothesis" "definition" "constant"))
           word-end
           (zero-or-more (or whitespace "(" "{" "["))
           (group (zero-or-more (not (any " \t\n\r\.")))))
      (2 'font-lock-function-name-face))
     ("\\(set_option\\)[ \t]*\\([^ \t\n]*\\)" (2 'font-lock-constant-face))
     ;; place holder
     (,(rx symbol-start "_" symbol-end) . 'font-lock-preprocessor-face)
     ;; modifiers
     (,(rx (or "\[persistent\]" "\[notation\]" "\[visible\]" "\[instance\]" "\[class\]"
               "\[coercion\]" "\[reducible\]" "\[off\]" "\[none\]" "\[on\]")) . 'font-lock-doc-face)
     (,(rx "\[priority" (zero-or-more (not (any "\]"))) "\]") . font-lock-doc-face)
     ;; tactics
     (,(rx (not (any "\.")) word-start
           (or "\\b.*_tac" "Cond" "or_else" "then" "try" "when" "assumption" "rapply" "apply" "rename" "intro" "intros"
               "generalize" "back" "beta" "done" "exact" "repeat")
           word-end)
      . 'font-lock-constant-face)
     ;; Types
     (,(rx word-start (or "Prop" "Type" "Type'" "Type₊" "Type₁" "Type₂" "Type₃") word-end) . 'font-lock-type-face)
     ;; sorry
     (,(rx word-start "sorry" word-end) . 'font-lock-warning-face)
     ;; extra-keywords
     (,(rx (or "∎")) . 'font-lock-keyword-face)
     ;; lean-keywords
     (, (concat "\\(" (regexp-opt lean-keywords 'words) "\\)")
        (1 'font-lock-keyword-face)))))
(provide 'lean-syntax)
