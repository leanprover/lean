/*
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include <string>
#include "util/lean_path.h"
#include "library/module.h"
#include "library/util.h"
#include "api/decl.h"
#include "api/string.h"
#include "api/exception.h"
#include "api/ios.h"
#include "api/lean_env.h"
#include "api/lean_module.h"
using namespace lean; // NOLINT
lean_bool lean_env_import(lean_env env, lean_ios ios, lean_list_name modules, lean_env * r, lean_exception * ex) {
    LEAN_TRY;
    check_nonnull(env);
    check_nonnull(ios);
    check_nonnull(modules);
    auto new_env = to_env_ref(env);
    for (name const & n : to_list_name_ref(modules)) {
        new_env = import_module(new_env, "", {n, optional<unsigned>()}, mk_olean_loader());
    }
    *r = of_env(new environment(new_env));
    LEAN_CATCH;
}

lean_bool lean_env_export(lean_env env, char const * fname, lean_exception * ex) {
    LEAN_TRY;
    check_nonnull(env);
    std::ofstream out(fname, std::ofstream::binary);
    export_module(out, to_env_ref(env));
    LEAN_CATCH;
}

lean_bool lean_get_std_path(char const ** r, lean_exception * ex) {
    LEAN_TRY;
    *r = mk_string(get_lean_path());
    LEAN_CATCH;
}
