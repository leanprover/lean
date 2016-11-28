/*
Copyright (c) 2014 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#pragma once
#include <iostream>
#include "library/message_buffer.h"

namespace lean {
/** \brief Auxiliary object for "inserting" delimiters for flycheck */
class flycheck_message_stream : public message_buffer {
    std::ostream & m_out;
public:
    flycheck_message_stream(std::ostream & out) : m_out(out) {}
    ~flycheck_message_stream() {}
    void report(message_bucket_id const &, message const & msg) override;
};
}
