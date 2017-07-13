/*
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Jared Roesch, and Leonardo de Moura
*/
#include "util/sexpr/option_declarations.h"
#include "library/native_compiler/options.h"

#ifndef LEAN_DEFAULT_NATIVE_LIBRARY_PATH
#define LEAN_DEFAULT_NATIVE_LIBRARY_PATH ""
#endif
#ifndef LEAN_DEFAULT_NATIVE_MAIN_FN
#define LEAN_DEFAULT_NATIVE_MAIN_FN "main"
#endif
#ifndef LEAN_DEFAULT_NATIVE_INCLUDE_PATH
#define LEAN_DEFAULT_NATIVE_INCLUDE_PATH ""
#endif
#ifndef LEAN_DEFAULT_NATIVE_EMIT_DWARF
#define LEAN_DEFAULT_NATIVE_EMIT_DWARF false
#endif
#ifndef LEAN_DEFAULT_NATIVE_DYNAMIC
#define LEAN_DEFAULT_NATIVE_DYNAMIC false
#endif
#ifndef LEAN_DEFAULT_NATIVE_DUMP
#define LEAN_DEFAULT_NATIVE_DUMP ""
#endif
#ifndef LEAN_DEFAULT_NATIVE_CC
#define LEAN_DEFAULT_NATIVE_CC "g++"
#endif
#ifndef LEAN_DEFAULT_NATIVE_BINARY
#define LEAN_DEFAULT_NATIVE_BINARY ""
#endif
#ifndef LEAN_DEFAULT_NATIVE_STORE_CODE
#define LEAN_DEFAULT_NATIVE_STORE_CODE ""
#endif
#ifndef LEAN_DEFAULT_NATIVE_PROFILE
#define LEAN_DEFAULT_NATIVE_PROFILE false
#endif
#ifndef LEAN_DEFAULT_NATIVE_BACKEND
#define LEAN_DEFAULT_NATIVE_BACKEND ""
#endif

namespace lean {
namespace native {

/* Options */
static name * g_native_library_path    = nullptr;
static name * g_native_main_fn         = nullptr;
static name * g_native_include_path    = nullptr;
static name * g_native_emit_dwarf      = nullptr;
static name * g_native_dynamic         = nullptr;
static name * g_native_dump            = nullptr;
static name * g_native_cc              = nullptr;
static name * g_native_binary          = nullptr;
static name * g_native_store_code      = nullptr;
static name * g_native_profile         = nullptr;
static name * g_native_backend         = nullptr;

char const * get_native_library_path(options const & o) {
    return o.get_string(*g_native_library_path, LEAN_DEFAULT_NATIVE_LIBRARY_PATH);
}

char const * get_native_main_fn(options const & o) {
    return o.get_string(*g_native_main_fn, LEAN_DEFAULT_NATIVE_MAIN_FN);
}

char const * get_native_include_path(options const & o) {
    return o.get_string(*g_native_include_path, LEAN_DEFAULT_NATIVE_INCLUDE_PATH);
}

bool get_native_emit_dwarf(options const & o) {
    return o.get_bool(*g_native_emit_dwarf, LEAN_DEFAULT_NATIVE_EMIT_DWARF);
}

bool get_native_dynamic(options const & o) {
    return o.get_bool(*g_native_dynamic, LEAN_DEFAULT_NATIVE_DYNAMIC);
}

char const * get_native_dump(options const & o) {
    return o.get_string(*g_native_dump, LEAN_DEFAULT_NATIVE_DUMP);
}

char const * get_native_cc(options const & o) {
    return o.get_string(*g_native_cc, LEAN_DEFAULT_NATIVE_CC);
}

char const * get_native_binary(options const & o) {
    return o.get_string(*g_native_binary, LEAN_DEFAULT_NATIVE_BINARY);
}

char const * get_native_store_code(options const & o) {
    return o.get_string(*g_native_store_code, LEAN_DEFAULT_NATIVE_STORE_CODE);
}

bool get_native_profile(options const & o) {
    return o.get_bool(*g_native_profile, LEAN_DEFAULT_NATIVE_PROFILE);
}

char const * get_native_backend(options const & o) {
    return o.get_string(*g_native_backend, LEAN_DEFAULT_NATIVE_BACKEND);
}

config::config(options const & o) {
    m_native_library_path = get_native_library_path(o);
    m_native_main_fn      = get_native_main_fn(o);
    m_native_include_path = get_native_include_path(o);
    m_native_emit_dwarf   = get_native_emit_dwarf(o);
    m_native_dynamic      = get_native_dynamic(o);
    m_native_dump         = get_native_dump(o);
    m_native_cc           = get_native_cc(o);
    m_native_binary       = get_native_binary(o);
    m_native_store_code   = get_native_store_code(o);
    m_native_profile      = get_native_profile(o);
    m_native_backend      = get_native_backend(o);
}

void config::display(std::ostream & os) {
    os << "native.library_path = " << m_native_library_path << std::endl;
}

LEAN_THREAD_PTR(config, g_native_config);

scope_config::scope_config(options const & o):
    m_old(g_native_config),
    m_config(o) {
    g_native_config = &m_config;
}

scope_config::~scope_config() {
    g_native_config = m_old;
}

config & get_config() {
    lean_assert(g_native_config);
    return *g_native_config;
}

void initialize_options() {
    g_native_library_path = new name{"native", "library_path"};
    g_native_main_fn      = new name{"native", "main"};
    g_native_include_path = new name{"native", "include_path"};
    g_native_emit_dwarf   = new name{"native", "emit_dwarf"};
    g_native_dynamic      = new name{"native", "dynamic"};
    g_native_dump         = new name{"native", "dump"};
    g_native_cc           = new name{"native", "cc"};
    g_native_binary       = new name{"native", "binary"};
    g_native_store_code   = new name{"native", "store_code"};
    g_native_profile      = new name{"native", "profile"};
    g_native_backend      = new name{"native", "backend"};

    register_string_option(*native::g_native_library_path, LEAN_DEFAULT_NATIVE_LIBRARY_PATH,
                         "(native_compiler) path used to search for native libraries, including liblean");

    register_string_option(*native::g_native_main_fn, LEAN_DEFAULT_NATIVE_MAIN_FN,
        "(native_compiler) definition used as the program entry point");

    register_string_option(*native::g_native_include_path, LEAN_DEFAULT_NATIVE_INCLUDE_PATH,
        "(native_compiler) path used to search for native headers, for example those included with Lean");

    register_bool_option(*native::g_native_emit_dwarf, LEAN_DEFAULT_NATIVE_EMIT_DWARF,
        "(native_compiler) flag controls whether dwarf debugging information is generated for the emitted code");

    register_bool_option(*native::g_native_dynamic, LEAN_DEFAULT_NATIVE_DYNAMIC,
        "(native_compiler) flag controls whether to use dynamic linking");

    register_string_option(*native::g_native_dump, LEAN_DEFAULT_NATIVE_DUMP,
        "(native_compiler) flag controls whether the native compiler dumps terms before and after every pass");

    register_string_option(*native::g_native_cc, LEAN_DEFAULT_NATIVE_CC,
        "(native_compiler) flag controls which C++ compiler is invoked");

    register_string_option(*native::g_native_binary, LEAN_DEFAULT_NATIVE_BINARY,
        "(native_compiler) flag controls the name of the final executable");

    register_string_option(*native::g_native_store_code, LEAN_DEFAULT_NATIVE_STORE_CODE,
        "(native_compiler) flag controls whether to keep & where to place the generated code");

    register_bool_option(*native::g_native_profile, LEAN_DEFAULT_NATIVE_PROFILE,
        "(native_compiler) flag controls whether to profile the native compiler");

    register_string_option(*native::g_native_backend, LEAN_DEFAULT_NATIVE_BACKEND,
        "(native_compiler) flag controls which backend to use for generating code");
}

void finalize_options() {
    delete g_native_library_path;
    delete g_native_main_fn;
    delete g_native_include_path;
    delete g_native_emit_dwarf;
    delete g_native_dynamic;
    delete g_native_dump;
    delete g_native_cc;
    delete g_native_binary;
    delete g_native_store_code;
    delete g_native_profile;
    delete g_native_backend;
}
}}
