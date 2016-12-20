/*
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include <string>
#include "library/attribute_manager.h"
#include "library/kernel_serializer.h"
#include "library/trace.h"
#include "library/constants.h"
#include "library/module.h"
#include "library/tactic/eqn_lemmas.h"

namespace lean {
struct eqn_lemmas_ext : public environment_extension {
    name_map<list<simp_lemma>> m_lemmas;
    eqn_lemmas_ext() {}
};

struct eqn_lemmas_ext_reg {
    unsigned m_ext_id;
    eqn_lemmas_ext_reg() { m_ext_id = environment::register_extension(std::make_shared<eqn_lemmas_ext>()); }
};

static eqn_lemmas_ext_reg * g_ext = nullptr;

static eqn_lemmas_ext const & get_extension(environment const & env) {
    return static_cast<eqn_lemmas_ext const &>(env.get_extension(g_ext->m_ext_id));
}
static environment update(environment const & env, eqn_lemmas_ext const & ext) {
    return env.update(g_ext->m_ext_id, std::make_shared<eqn_lemmas_ext>(ext));
}

environment add_eqn_lemma_core(environment const & env, name const & eqn_lemma) {
    type_context ctx(env, transparency_mode::None);
    simp_lemmas lemmas = add(ctx, simp_lemmas(), eqn_lemma, LEAN_DEFAULT_PRIORITY);
    optional<simp_lemma> new_lemma;
    lemmas.for_each([&](name const & r, simp_lemma const & sl) {
            if (r != get_eq_name())
                throw exception("invalid equation lemma, it must produce an equality");
            if (new_lemma)
                throw exception("invalid equality lemma, lemma produced more than one equation lemma");
            else
                new_lemma = sl;
        });
    if (!new_lemma)
        throw exception("invalid equation lemma, unexpected form");
    expr const & fn = get_app_fn(new_lemma->get_lhs());
    if (!is_constant(fn))
        throw exception("invalid equality lemma, invalid lhs");
    name const & fn_name = const_name(fn);
    eqn_lemmas_ext ext = get_extension(env);
    if (list<simp_lemma> const * l = ext.m_lemmas.find(fn_name))
        ext.m_lemmas.insert(fn_name, cons(*new_lemma, *l));
    else
        ext.m_lemmas.insert(fn_name, to_list(*new_lemma));
    return update(env, ext);
}

struct eqn_lemmas_modification : public modification {
    LEAN_MODIFICATION("EqnL")

    name m_lemma;

    eqn_lemmas_modification() {}
    eqn_lemmas_modification(name const & lemma) : m_lemma(lemma) {}

    void perform(environment & env) const override {
        env = add_eqn_lemma_core(env, m_lemma);
    }

    void serialize(serializer & s) const override {
        s << m_lemma;
    }

    static std::shared_ptr<modification const> deserialize(deserializer & d) {
        return std::make_shared<eqn_lemmas_modification>(read_name(d));
    }
};

environment add_eqn_lemma(environment const & env, name const & eqn_lemma) {
    return module::add_and_perform(env, std::make_shared<eqn_lemmas_modification>(eqn_lemma));
}

void get_eqn_lemmas_for(environment const & env, name const & cname, bool refl_only, buffer<simp_lemma> & result) {
    eqn_lemmas_ext const & ext = get_extension(env);
    if (auto lemmas = ext.m_lemmas.find(cname)) {
        for (simp_lemma const & sl : *lemmas) {
            if (!refl_only || sl.is_refl())
                result.push_back(sl);
        }
    }
}

bool has_eqn_lemmas(environment const & env, name const & cname) {
    eqn_lemmas_ext const & ext = get_extension(env);
    return ext.m_lemmas.contains(cname);
}

void initialize_eqn_lemmas() {
    g_ext            = new eqn_lemmas_ext_reg();
    eqn_lemmas_modification::init();
}

void finalize_eqn_lemmas() {
    eqn_lemmas_modification::finalize();
    delete g_ext;
}
}
