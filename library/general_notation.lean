-- Copyright (c) 2014 Microsoft Corporation. All rights reserved.
-- Released under Apache 2.0 license as described in the file LICENSE.
-- Author: Leonardo de Moura, Jeremy Avigad

-- general_notation
-- ================

-- General operations
-- ------------------

notation `assume` binders `,` r:(scoped f, f) := r
notation `take`   binders `,` r:(scoped f, f) := r

-- Global declarations of right binding strength
-- ---------------------------------------------

-- If a module reassigns these, it will be incompatible with other modules that adhere to these
-- conventions.

-- ### Logical operations and relations
reserve prefix `¬`:40
reserve infixr `∧`:35
reserve infixr `/\`:35
reserve infixr `‌\/`:30
reserve infixr `∨`:30
reserve infix `<->`:25
reserve infix `↔`:25
reserve infix `=`:50
reserve infix `≠`:50
reserve infix `≈`:50
reserve infix `∼`:50

reserve postfix `⁻¹`:100
reserve infixl `⬝`:75
reserve infixr `▸`:75

-- ### types and type constructors

reserve infixl `⊎`:25
reserve infixl `×`:30

-- ### arithmetic operations

reserve infixl `+`:65
reserve infixl `-`:65
reserve infixl `*`:70
reserve infixl `div`:70
reserve infixl `mod`:70

reserve infix `<=`:50
reserve infix `≤`:50
reserve infix `<`:50
reserve infix `>=`:50
reserve infix `≥`:50
reserve infix `>`:50

-- ### boolean operations

reserve infixl `&&`:70
reserve infixl `||`:65

-- ### set operations

reserve infix `∈`:50
reserve infixl `∩`:70
reserve infixl `∪`:65

-- ### other symbols
precedence `|`:55
reserve notation | a:55 |
reserve infixl `++`:65
reserve infixr `::`:65

-- Yet another trick to anotate an expression with a type
definition is_typeof (A : Type) (a : A) : A := a

notation `typeof` t `:` T  := is_typeof T t
