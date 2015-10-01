/*
Copyright (c) 2014 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include <cstdlib>
#include <string>
#include "util/debug.h"

namespace lean {
bool is_utf8_next(unsigned char c) { return (c & 0xC0) == 0x80; }

unsigned get_utf8_size(unsigned char c) {
    if ((c & 0x80) == 0)
        return 1;
    else if ((c & 0xE0) == 0xC0)
        return 2;
    else if ((c & 0xF0) == 0xE0)
        return 3;
    else if ((c & 0xF8) == 0xF0)
        return 4;
    else if ((c & 0xFC) == 0xF8)
        return 5;
    else if ((c & 0xFE) == 0xFC)
        return 6;
    else if (c == 0xFF)
        return 1;
    else
        return 0;
}

size_t utf8_strlen(char const * str) {
    size_t r = 0;
    while (*str != 0) {
        unsigned sz = get_utf8_size(*str);
        r++;
        str += sz;
    }
    return r;
}

char const * get_utf8_last_char(char const * str) {
    char const * r;
    lean_assert(*str != 0);
    do {
        r = str;
        unsigned sz = get_utf8_size(*str);
        str += sz;
    } while (*str != 0);
    return r;
}

std::string utf8_trim(std::string const & s) {
    int start = -1, stop = -1;
    for (unsigned i = 0; i < s.size(); i += get_utf8_size(s[i])) {
        if (s[i] == ' ') {
            if (stop == -1)
                stop = i;
        } else {
            if (start == -1)
                start = i;
            stop = -1;
        }
    }
    if (stop == -1)
        stop = s.size();
    return s.substr(start, stop - start);
}
}
