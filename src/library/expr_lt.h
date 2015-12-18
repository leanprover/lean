/*
Copyright (c) 2013 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#pragma once
#include "kernel/expr.h"
namespace lean {
/** \brief Total order on expressions.

    \remark If \c use_hash is true, then we use the hash_code to
    partially order expressions. Setting use_hash to false is useful
    for testing the code.
*/
bool is_lt(expr const & a, expr const & b, bool use_hash);
/** \brief Similar to is_lt, but universe level parameter names are ignored. */
bool is_lt_no_level_params(expr const & a, expr const & b);
inline bool operator<(expr const & a, expr const & b)  { return is_lt(a, b, true); }
inline bool operator>(expr const & a, expr const & b)  { return is_lt(b, a, true); }
inline bool operator<=(expr const & a, expr const & b) { return !is_lt(b, a, true); }
inline bool operator>=(expr const & a, expr const & b) { return !is_lt(a, b, true); }
struct expr_quick_cmp { int operator()(expr const & e1, expr const & e2) const { return is_lt(e1, e2, true) ? -1 : (e1 == e2 ? 0 : 1); } };
struct expr_quick_lt { bool operator()(expr const & e1, expr const & e2) const { return is_lt(e1, e2, true); } };
struct expr_cmp_no_level_params { int operator()(expr const & e1, expr const & e2) const; };
}
