/*
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include "library/attribute_manager.h"
#include "library/constants.h"
#include "library/normalize.h"
#include "library/num.h"
#include "library/typed_expr.h"
#include "frontends/lean/decl_attributes.h"
#include "frontends/lean/parser.h"
#include "frontends/lean/tokens.h"
#include "frontends/lean/util.h"

namespace lean {
void decl_attributes::parse(parser & p) {
    if (!p.curr_is_token(get_lbracket_tk()))
        return;
    p.next();
    while (true) {
        auto pos = p.pos();
        auto name = p.check_id_next("invalid attribute declaration, identifier expected");
        if (name == "priority") {
            auto pos = p.pos();
            expr pre_val = p.parse_expr();
            pre_val = mk_typed_expr(mk_constant(get_num_name()), pre_val);
            expr val = p.elaborate(list<expr>(), pre_val).first;
            val = normalize(p.env(), val);
            if (optional<mpz> mpz_val = to_num_core(val)) {
                if (!mpz_val->is_unsigned_int())
                    throw parser_error("invalid 'priority', argument does not fit in a machine integer", pos);
                m_prio = optional<unsigned>(mpz_val->get_unsigned_int());
            } else {
                throw parser_error("invalid 'priority', argument does not evaluate to a numeral", pos);
            }
        } else {
            if (!is_attribute(name))
                throw parser_error(sstream() << "unknown attribute [" << name << "]", pos);

            auto const & attr = get_attribute(name);
            for (auto const & entry : m_entries) {
                if (are_incompatible(*entry.m_attr, attr)) {
                    throw parser_error(sstream() << "invalid attribute [" << name
                                                 << "], declaration was already marked with [" << entry.m_attr->get_name()
                                                 << "]", pos);
                }
            }
            auto data = attr.parse_data(p);
            m_entries = cons({&attr, data}, m_entries);
            if (name == "parsing_only")
                m_parsing_only = true;
        }
        if (p.curr_is_token(get_comma_tk())) {
            p.next();
        } else {
            p.check_token_next(get_rbracket_tk(), "invalid attribute declaration, ']' expected");
            if (p.curr_is_token(get_lbracket_tk()))
                p.next();
            else
                break;
        }
    }
}

environment decl_attributes::apply(environment env, io_state const & ios, name const & d) const {
    buffer<entry> entries;
    to_buffer(m_entries, entries);
    unsigned i = entries.size();
    while (i > 0) {
        --i;
        auto const & entry = entries[i];
        unsigned prio = m_prio ? *m_prio : LEAN_DEFAULT_PRIORITY;
        env = entry.m_attr->set_untyped(env, ios, d, prio, entry.m_params, m_persistent);
    }
    return env;
}

bool decl_attributes::ok_for_inductive_type() const {
    for (entry const & e : m_entries)
        if (e.m_attr->get_name() != "class")
            return false;
    return true;
}

bool decl_attributes::has_class() const {
    for (entry const & e : m_entries)
        if (e.m_attr->get_name() == "class")
            return true;
    return false;
}

}
