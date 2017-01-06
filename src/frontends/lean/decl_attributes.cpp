/*
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include "util/sexpr/option_declarations.h"
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
// ==========================================
// configuration options
static name * g_default_priority = nullptr;

unsigned get_default_priority(options const & opts) {
    return opts.get_unsigned(*g_default_priority, LEAN_DEFAULT_PRIORITY);
}
// ==========================================

void decl_attributes::parse_core(parser & p, bool compact) {
    while (true) {
        auto pos = p.pos();
        bool deleted = p.curr_is_token_or_id(get_sub_tk());
        if (deleted) {
            if (m_persistent)
                throw parser_error("cannot remove attribute globally (solution: use 'local attribute')", pos);
            p.next();
        }
        name id;
        if (p.curr_is_command()) {
            id = p.get_token_info().value();
            p.next();
        } else {
            id = p.check_id_next("invalid attribute declaration, identifier expected",
                                 break_at_pos_exception::token_context::attribute);
        }
        if (id == "priority") {
            if (deleted)
                throw parser_error("cannot remove priority attribute", pos);
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
            if (!is_attribute(p.env(), id))
                throw parser_error(sstream() << "unknown attribute [" << id << "]", pos);

            auto const & attr = get_attribute(p.env(), id);
            if (!deleted) {
                for (auto const & entry : m_entries) {
                    if (!entry.deleted() && are_incompatible(*entry.m_attr, attr)) {
                        throw parser_error(sstream() << "invalid attribute [" << id
                                                     << "], declaration was already marked with ["
                                                     << entry.m_attr->get_name()
                                                     << "]", pos);
                    }
                }
            }
            auto data = deleted ? attr_data_ptr() : attr.parse_data(p);
            m_entries = cons({&attr, data}, m_entries);
            if (id == "parsing_only")
                m_parsing_only = true;
        }
        if (p.curr_is_token(get_comma_tk())) {
            p.next();
        } else {
            p.check_token_next(get_rbracket_tk(), "invalid attribute declaration, ']' expected");
            if (compact)
                break;
            if (p.curr_is_token(get_lbracket_tk()))
                p.next();
            else
                break;
        }
    }
}

void decl_attributes::parse(parser & p) {
    if (!p.curr_is_token(get_lbracket_tk()))
        return;
    p.next();
    parse_core(p, false);
}

void decl_attributes::parse_compact(parser & p) {
    parse_core(p, true);
}

void decl_attributes::set_attribute(environment const & env, name const & attr_name) {
    if (!is_attribute(env, attr_name))
        throw exception(sstream() << "unknown attribute [" << attr_name << "]");
    auto const & attr = get_attribute(env, attr_name);
    m_entries = cons({&attr, get_default_attr_data()}, m_entries);
}

environment decl_attributes::apply(environment env, io_state const & ios, name const & d) const {
    buffer<entry> entries;
    to_buffer(m_entries, entries);
    unsigned i = entries.size();
    while (i > 0) {
        --i;
        auto const & entry = entries[i];
        if (entry.deleted()) {
            if (!entry.m_attr->is_instance(env, d))
                throw exception(sstream() << "cannot remove attribute [" << entry.m_attr->get_name()
                                          << "]: no prior declaration on " << d);
            env = entry.m_attr->unset(env, ios, d, m_persistent);
        } else {
            unsigned prio = m_prio ? *m_prio : get_default_priority(ios.get_options());
            env = entry.m_attr->set_untyped(env, ios, d, prio, entry.m_params, m_persistent);
        }
    }
    return env;
}

bool decl_attributes::ok_for_inductive_type() const {
    for (entry const & e : m_entries)
        if (e.m_attr->get_name() != "class" || e.deleted())
            return false;
    return true;
}

bool decl_attributes::has_class() const {
    for (entry const & e : m_entries)
        if (e.m_attr->get_name() == "class" && !e.deleted())
            return true;
    return false;
}

void initialize_decl_attributes() {
    g_default_priority = new name{"default_priority"};
    register_unsigned_option(*g_default_priority, LEAN_DEFAULT_PRIORITY, "default priority for attributes");
}

void finalize_decl_attributes() {
    delete g_default_priority;
}
}
