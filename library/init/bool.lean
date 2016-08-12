-- Copyright (c) 2014 Microsoft Corporation. All rights reserved.
-- Released under Apache 2.0 license as described in the file LICENSE.
-- Author: Leonardo de Moura
prelude
import init.datatypes init.reserved_notation

namespace bool
  attribute [inline]
  definition cond {A : Type} (b : bool) (t e : A) :=
  bool.rec_on b e t

  attribute [inline]
  definition bor (a b : bool) :=
  bool.rec_on a (bool.rec_on b ff tt) tt

  attribute [inline]
  definition band (a b : bool) :=
  bool.rec_on a ff (bool.rec_on b ff tt)

  attribute [inline]
  definition bnot (a : bool) :=
  bool.rec_on a tt ff
end bool

notation a || b := bool.bor a b
notation a && b := bool.band a b
