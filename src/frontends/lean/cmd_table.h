/*
Copyright (c) 2014 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#pragma once
#include <string>
#include <functional>
#include "kernel/environment.h"
#include "frontends/lean/parser_pos_provider.h"

namespace lean {
class parser;
typedef std::function<environment(parser&)> command_fn;

template<typename F>
struct cmd_info_tmpl {
    name        m_name;
    std::string m_descr;
    F           m_fn;
    bool        m_skip_token;
public:
    cmd_info_tmpl(name const & n, char const * d, F const & fn, bool skip_token = true):
        m_name(n), m_descr(d), m_fn(fn), m_skip_token(skip_token) {}
    cmd_info_tmpl() {}
    name const & get_name() const { return m_name; }
    std::string const & get_descr() const { return m_descr; }
    F const & get_fn() const { return m_fn; }
    bool const & get_skip_token() const { return m_skip_token; }
};

typedef cmd_info_tmpl<command_fn>              cmd_info;
typedef name_map<cmd_info> cmd_table;
inline void add_cmd(cmd_table & t, cmd_info const & cmd) { t.insert(cmd.get_name(), cmd); }
}
