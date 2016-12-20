/*
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include <string>
#include "util/sstream.h"
#include "kernel/kernel_exception.h"
#include "kernel/instantiate.h"
#include "kernel/inductive/inductive.h"
#include "library/util.h"
#include "library/projection.h"
#include "library/module.h"
#include "library/kernel_serializer.h"

namespace lean {
/** \brief This environment extension stores information about all projection functions
    defined in an environment object.
*/
struct projection_ext : public environment_extension {
    name_map<projection_info> m_info;
    projection_ext() {}

    std::shared_ptr<environment_extension const> union_with(environment_extension const & ext) const override {
        auto & o = static_cast<projection_ext const &>(ext);
        auto u = std::make_shared<projection_ext>();
        u->m_info = merge_prefer_first(m_info, o.m_info);
        return u;
    }
};

struct projection_ext_reg {
    unsigned m_ext_id;
    projection_ext_reg() {
        m_ext_id = environment::register_extension(std::make_shared<projection_ext>());
    }
};

static projection_ext_reg * g_ext = nullptr;
static projection_ext const & get_extension(environment const & env) {
    return static_cast<projection_ext const &>(env.get_extension(g_ext->m_ext_id));
}
static environment update(environment const & env, projection_ext const & ext) {
    return env.update(g_ext->m_ext_id, std::make_shared<projection_ext>(ext));
}

static std::string * g_proj_key = nullptr;

static environment save_projection_info_core(environment const & env, name const & p, name const & mk, unsigned nparams,
                                             unsigned i, bool inst_implicit) {
    projection_ext ext = get_extension(env);
    ext.m_info.insert(p, projection_info(mk, nparams, i, inst_implicit));
    return update(env, ext);
}

environment save_projection_info(environment const & env, name const & p, name const & mk, unsigned nparams, unsigned i, bool inst_implicit) {
    environment new_env = save_projection_info_core(env, p, mk, nparams, i, inst_implicit);
    return module::add(new_env, *g_proj_key, [=](environment const &, serializer & s) {
            s << p << mk << nparams << i << inst_implicit;
        });
}

projection_info const * get_projection_info(environment const & env, name const & p) {
    projection_ext const & ext = get_extension(env);
    return ext.m_info.find(p);
}

name_map<projection_info> const & get_projection_info_map(environment const & env) {
    return get_extension(env).m_info;
}

static void projection_info_reader(deserializer & d, environment & env) {
    name p, mk; unsigned nparams, i; bool inst_implicit;
    d >> p >> mk >> nparams >> i >> inst_implicit;
    env = save_projection_info_core(env, p, mk, nparams, i, inst_implicit);
}

/** \brief Return true iff the type named \c S can be viewed as
    a structure in the given environment.

    If not, generate an error message using \c pos.
*/
bool is_structure_like(environment const & env, name const & S) {
    optional<inductive::inductive_decl> decl = inductive::is_inductive_decl(env, S);
    if (!decl) return false;
    return length(decl->m_intro_rules) == 1 && *inductive::get_num_indices(env, S) == 0;
}

void initialize_projection() {
    g_ext      = new projection_ext_reg();
    g_proj_key = new std::string("proj");
    register_module_object_reader(*g_proj_key, projection_info_reader);
}

void finalize_projection() {
    delete g_proj_key;
    delete g_ext;
}
}
