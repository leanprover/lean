/*
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#pragma once
#include "library/blast/action_result.h"
#include "library/blast/gexpr.h"

namespace lean {
namespace blast {
action_result backward_action(list<gexpr> const & lemmas, bool prop_only_branches = true);
action_result constructor_action(bool prop_only_branches = true);
}}
