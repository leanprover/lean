-- Copyright (c) 2014 Microsoft Corporation. All rights reserved.
-- Released under Apache 2.0 license as described in the file LICENSE.
-- Author: Jeremy Avigad

-- TODO: add notation for negation (in the sense of homotopy type theory)

-- Empty type
-- ----------

import logic.core.cast

inductive empty : Type

namespace empty
  theorem elim [protected] (A : Type) (H : empty) : A :=
  rec (λe, A) H

end empty

theorem false.to_empty (H : false) : empty :=
cast (false_elim H) true

theorem false.rec_type (A : Type) (H : false) : A :=
empty_rec (λx,A) (false_to_empty H)
