/*
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Gabriel Ebner
*/
#pragma once
#include <string>
#include "kernel/pos_info_provider.h"

namespace lean {

enum message_severity { INFORMATION, WARNING, ERROR };

class message {
    std::string      m_file_name;
    pos_info         m_pos;
    message_severity m_severity;
    std::string      m_caption, m_text;
public:
    message(std::string const & file_name, pos_info const & pos,
            message_severity severity, std::string const & caption, std::string const & text) :
            m_file_name(file_name), m_pos(pos),
            m_severity(severity), m_caption(caption), m_text(text) {}
    message(std::string const & file_name, pos_info const & pos,
            message_severity severity, std::string const & text) :
            message(file_name, pos, severity, std::string(), text) {}
    message(std::string const & file_name, pos_info const & pos,
            message_severity severity) :
            message(file_name, pos, severity, std::string()) {}
    message(parser_exception const & ex);

    std::string get_file_name() const { return m_file_name; }
    pos_info get_pos() const { return m_pos; }
    message_severity get_severity() const { return m_severity; }
    std::string get_caption() const { return m_caption; }
    std::string get_text() const { return m_text; }
};

}
