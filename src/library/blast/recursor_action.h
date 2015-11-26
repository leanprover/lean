/*
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#pragma once
#include "library/blast/action_result.h"
#include "library/blast/hypothesis.h"
namespace lean {
namespace blast {
action_result recursor_preprocess_action(hypothesis_idx hidx);
action_result recursor_action();

void initialize_recursor_action();
void finalize_recursor_action();
}}
