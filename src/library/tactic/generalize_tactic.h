/*
Copyright (c) 2014 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#pragma once
#include "library/tactic/elaborate.h"

namespace lean {
tactic generalize_tactic(elaborate_fn const & elab, expr const & e);
void initialize_generalize_tactic();
void finalize_generalize_tactic();
}
