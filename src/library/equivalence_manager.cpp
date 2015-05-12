/*
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include <string>
#include "util/optional.h"
#include "util/name.h"
#include "util/rb_map.h"
#include "library/constants.h"
#include "library/scoped_ext.h"

namespace lean {
// Check whether e is of the form (f ...) where f is a constant. If it is return f.
static name const & get_fn_const(expr const & e, char const * msg) {
    expr const & fn = get_app_fn(e);
    if (!is_constant(fn))
        throw exception(msg);
    return const_name(fn);
}

static pair<expr, unsigned> extract_arg_types_core(environment const & env, name const & f, buffer<expr> & arg_types) {
    declaration d = env.get(f);
    expr f_type = d.get_type();
    while (is_pi(f_type)) {
        arg_types.push_back(binding_domain(f_type));
        f_type = binding_body(f_type);
    }
    return mk_pair(f_type, d.get_num_univ_params());
}

static expr extract_arg_types(environment const & env, name const & f, buffer<expr> & arg_types) {
    return extract_arg_types_core(env, f, arg_types).first;
}

enum class op_kind { Subst, Trans, Refl, Symm };

struct eqv_entry {
    op_kind m_kind;
    name    m_name;
    eqv_entry() {}
    eqv_entry(op_kind k, name const & n):m_kind(k), m_name(n) {}
};

struct eqv_state {
    typedef name_map<std::tuple<name, unsigned, unsigned>> refl_table;
    typedef name_map<std::tuple<name, unsigned, unsigned>> subst_table;
    typedef name_map<std::tuple<name, unsigned, unsigned>> symm_table;
    typedef rb_map<name_pair, std::tuple<name, name, unsigned>, name_pair_quick_cmp> trans_table;
    trans_table    m_trans_table;
    refl_table     m_refl_table;
    subst_table    m_subst_table;
    symm_table     m_symm_table;
    eqv_state() {}

    void add_subst(environment const & env, name const & subst) {
        buffer<expr> arg_types;
        auto p          = extract_arg_types_core(env, subst, arg_types);
        expr r_type     = p.first;
        unsigned nunivs = p.second;
        unsigned nargs  = arg_types.size();
        if (nargs < 2)
            throw exception("invalid substitution theorem, it must have at least 2 arguments");
        name const & rop = get_fn_const(arg_types[nargs-2], "invalid substitution theorem, penultimate argument must be an operator application");
        m_subst_table.insert(rop, std::make_tuple(subst, nargs, nunivs));
    }

    void add_refl(environment const & env, name const & refl) {
        buffer<expr> arg_types;
        auto p          = extract_arg_types_core(env, refl, arg_types);
        expr r_type     = p.first;
        unsigned nunivs = p.second;
        unsigned nargs  = arg_types.size();
        if (nargs < 1)
            throw exception("invalid reflexivity rule, it must have at least 1 argument");
        name const & rop = get_fn_const(r_type, "invalid reflexivity rule, result type must be an operator application");
        m_refl_table.insert(rop, std::make_tuple(refl, nargs, nunivs));
    }

    void add_trans(environment const & env, name const & trans) {
        buffer<expr> arg_types;
        expr r_type = extract_arg_types(env, trans, arg_types);
        unsigned nargs = arg_types.size();
        if (nargs < 5)
            throw exception("invalid transitivity rule, it must have at least 5 arguments");
        name const & rop = get_fn_const(r_type, "invalid transitivity rule, result type must be an operator application");
        name const & op1 = get_fn_const(arg_types[nargs-2], "invalid transitivity rule, penultimate argument must be an operator application");
        name const & op2 = get_fn_const(arg_types[nargs-1], "invalid transitivity rule, last argument must be an operator application");
        m_trans_table.insert(name_pair(op1, op2), std::make_tuple(trans, rop, nargs));
    }

    void add_symm(environment const & env, name const & symm) {
        buffer<expr> arg_types;
        auto p          = extract_arg_types_core(env, symm, arg_types);
        expr r_type     = p.first;
        unsigned nunivs = p.second;
        unsigned nargs  = arg_types.size();
        if (nargs < 1)
            throw exception("invalid symmetry rule, it must have at least 1 argument");
        name const & rop = get_fn_const(r_type, "invalid symmetry rule, result type must be an operator application");
        m_symm_table.insert(rop, std::make_tuple(symm, nargs, nunivs));
    }
};

static name * g_eqv_name  = nullptr;
static std::string * g_key = nullptr;

struct eqv_config {
    typedef eqv_state state;
    typedef eqv_entry entry;
    static void add_entry(environment const & env, io_state const &, state & s, entry const & e) {
        switch (e.m_kind) {
        case op_kind::Refl:  s.add_refl(env, e.m_name); break;
        case op_kind::Subst: s.add_subst(env, e.m_name); break;
        case op_kind::Trans: s.add_trans(env, e.m_name); break;
        case op_kind::Symm:  s.add_symm(env, e.m_name); break;
        }
    }
    static name const & get_class_name() {
        return *g_eqv_name;
    }
    static std::string const & get_serialization_key() {
        return *g_key;
    }
    static void  write_entry(serializer & s, entry const & e) {
        s << static_cast<char>(e.m_kind) << e.m_name;
    }
    static entry read_entry(deserializer & d) {
        entry e;
        char cmd;
        d >> cmd >> e.m_name;
        e.m_kind = static_cast<op_kind>(cmd);
        return e;
    }
    static optional<unsigned> get_fingerprint(entry const &) {
        return optional<unsigned>();
    }
};

template class scoped_ext<eqv_config>;
typedef scoped_ext<eqv_config> eqv_ext;

environment add_subst(environment const & env, name const & n, bool persistent) {
    return eqv_ext::add_entry(env, get_dummy_ios(), eqv_entry(op_kind::Subst, n), persistent);
}

environment add_refl(environment const & env, name const & n, bool persistent) {
    return eqv_ext::add_entry(env, get_dummy_ios(), eqv_entry(op_kind::Refl, n), persistent);
}

environment add_symm(environment const & env, name const & n, bool persistent) {
    return eqv_ext::add_entry(env, get_dummy_ios(), eqv_entry(op_kind::Symm, n), persistent);
}

environment add_trans(environment const & env, name const & n, bool persistent) {
    return eqv_ext::add_entry(env, get_dummy_ios(), eqv_entry(op_kind::Trans, n), persistent);
}

static optional<std::tuple<name, unsigned, unsigned>> get_info(name_map<std::tuple<name, unsigned, unsigned>> const & table, name const & op) {
    if (auto it = table.find(op)) {
        return optional<std::tuple<name, unsigned, unsigned>>(*it);
    } else {
        return optional<std::tuple<name, unsigned, unsigned>>();
    }
}

optional<std::tuple<name, unsigned, unsigned>> get_refl_extra_info(environment const & env, name const & op) {
    return get_info(eqv_ext::get_state(env).m_refl_table, op);
}
optional<std::tuple<name, unsigned, unsigned>> get_subst_extra_info(environment const & env, name const & op) {
    return get_info(eqv_ext::get_state(env).m_subst_table, op);
}
optional<std::tuple<name, unsigned, unsigned>> get_symm_extra_info(environment const & env, name const & op) {
    return get_info(eqv_ext::get_state(env).m_symm_table, op);
}

optional<std::tuple<name, name, unsigned>> get_trans_extra_info(environment const & env, name const & op1, name const & op2) {
    if (auto it = eqv_ext::get_state(env).m_trans_table.find(mk_pair(op1, op2))) {
        return optional<std::tuple<name, name, unsigned>>(*it);
    } else {
        return optional<std::tuple<name, name, unsigned>>();
    }
}

optional<name> get_refl_info(environment const & env, name const & op) {
    if (auto it = get_refl_extra_info(env, op))
        return optional<name>(std::get<0>(*it));
    else
        return optional<name>();
}

optional<name> get_symm_info(environment const & env, name const & op) {
    if (auto it = get_symm_extra_info(env, op))
        return optional<name>(std::get<0>(*it));
    else
        return optional<name>();
}

optional<name> get_trans_info(environment const & env, name const & op) {
    if (auto it = get_trans_extra_info(env, op, op))
        return optional<name>(std::get<0>(*it));
    else
        return optional<name>();
}

void initialize_equivalence_manager() {
    g_eqv_name = new name("eqv");
    g_key       = new std::string("eqv");
    eqv_ext::initialize();
}

void finalize_equivalence_manager() {
    eqv_ext::finalize();
    delete g_key;
    delete g_eqv_name;
}
}
