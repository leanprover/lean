/*
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#pragma once
#include "kernel/expr.h"
#include "library/type_context.h"
#include "library/io_state_stream.h"

namespace lean {
namespace blast {

/** \brief Generalized expressions. It is a mechanism for representing
    regular expression and universe polymorphic lemmas.

    A universe polymorphic lemma can be converted into a regular expression
    by instantiating it with fresh universe meta-variables.

    We use the abstraction to provide a uniform API to some of the actions
    available in blast. */
struct gexpr {
    bool m_univ_poly;
    expr m_expr;
public:
    gexpr(name const & n):m_univ_poly(true), m_expr(mk_constant(n)) {}
    gexpr(expr const & e):m_univ_poly(false), m_expr(e) {}
    gexpr(environment const & env, name const & n):
        m_univ_poly(env.get(n).get_univ_params()), m_expr(mk_constant(n)) {}

    bool is_universe_polymorphic() const {
        return m_univ_poly;
    }

    /** \brief Convert generalized expression into a regular expression.
        If it is universe polymorphic, we accomplish that by creating
        meta-variables using \c ctx. */
    expr to_expr(type_context & ctx) const;

    /** \brief Similar to previous method, but uses \c mk_fresh_uref to
        create fresh universe meta-variables */
    expr to_expr() const;

    friend bool operator==(gexpr const & ge1, gexpr const & ge2);
    friend std::ostream const & operator<<(std::ostream const & out, gexpr const & ge);
};

bool operator==(gexpr const & ge1, gexpr const & ge2);
inline bool operator!=(gexpr const & ge1, gexpr const & ge2) { return !operator==(ge1, ge2); }
std::ostream & operator<<(std::ostream & out, gexpr const & ge);

}}
