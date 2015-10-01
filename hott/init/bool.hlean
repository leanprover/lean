/-
Copyright (c) 2014 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura
-/

prelude
import init.reserved_notation

-- this is not in init.types, because that file depends on init.num,
-- which depends on these definitions
namespace bool
  definition cond {A : Type} (b : bool) (t e : A) :=
  bool.rec_on b e t

  definition bor (a b : bool) :=
  bool.rec_on a (bool.rec_on b ff tt) tt

  infix || := bor

  definition band (a b : bool) :=
  bool.rec_on a ff (bool.rec_on b ff tt)

  infix && := band

  definition bnot (a : bool) :=
  bool.rec_on a tt ff
end bool
