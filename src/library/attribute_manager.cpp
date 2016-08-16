/*
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include <vector>
#include <string>
#include <algorithm>
#include <unordered_map>
#include "util/priority_queue.h"
#include "util/sstream.h"
#include "library/attribute_manager.h"
#include "library/scoped_ext.h"

namespace lean {

static std::unordered_map<std::string, attribute_ptr> * g_attributes;
static std::vector<pair<std::string, std::string>> * g_incomp = nullptr;

static std::string * g_key = nullptr;

void register_attribute(attribute_ptr attr) {
    lean_assert(!is_attribute(attr->get_name().c_str()));
    (*g_attributes)[attr->get_name()] = attr;
}

bool is_attribute(std::string const & attr) {
    return g_attributes->find(attr) != g_attributes->end();
}

[[ noreturn ]] void throw_unknown_attribute(std::string const & attr) {
    throw exception(sstream() << "unknown attribute '" << attr << "'");
}

attribute const & get_attribute(std::string const & attr) {
    auto it = g_attributes->find(attr);
    if (it != g_attributes->end())
        return *it->second;
    throw_unknown_attribute(attr);
}

struct attr_record {
    name          m_decl;
    attr_data_ptr m_data;

    attr_record() {}
    attr_record(name decl, attr_data_ptr data):
            m_decl(decl), m_data(data) {}

    unsigned hash() const {
        unsigned h = m_decl.hash();
        if (m_data)
            h = ::lean::hash(h, m_data->hash());
        return h;
    }
};

struct attr_record_cmp {
    int operator()(attr_record const & r1, attr_record const & r2) const {
        // Adding a new record with different arguments should override the old one
        return quick_cmp(r1.m_decl, r2.m_decl);
    }
};

struct attr_entry {
    std::string m_attr;
    unsigned    m_prio;
    attr_record m_record;

    attr_entry() {}
    attr_entry(std::string const & attr, unsigned prio, attr_record const & record):
            m_attr(attr), m_prio(prio), m_record(record) {}
};

typedef priority_queue<attr_record, attr_record_cmp> attr_records;
typedef name_map<attr_records> attr_state;

struct attr_config {
    typedef attr_state state;
    typedef attr_entry entry;
    static void add_entry(environment const &, io_state const &, state & s, entry const & e) {
        attr_records m;
        if (auto q = s.find(e.m_attr))
            m = *q;
        m.insert(e.m_record, e.m_prio);
        s.insert(e.m_attr, m);
    }
    static std::string const & get_serialization_key() {
        return *g_key;
    }
    static void write_entry(serializer & s, entry const & e) {
        s << e.m_attr << e.m_prio << e.m_record.m_decl;
        lean_assert(e.m_record.m_data);
        get_attribute(e.m_attr).write_entry(s, *e.m_record.m_data);
    }
    static entry read_entry(deserializer & d) {
        entry e;
        d >> e.m_attr >> e.m_prio >> e.m_record.m_decl;
        e.m_record.m_data = get_attribute(e.m_attr).read_entry(d);
        return e;
    }
    static optional<unsigned> get_fingerprint(entry const & e) {
        return optional<unsigned>(hash(hash(name(e.m_attr).hash(), e.m_record.hash()), e.m_prio));
    }
};

template class scoped_ext<attr_config>;
typedef scoped_ext<attr_config> attribute_ext;

environment attribute::set_core(environment const & env, io_state const & ios, name const & n, unsigned prio,
                                attr_data_ptr data, bool persistent) const {
    return attribute_ext::add_entry(env, ios, attr_entry(m_id, prio, attr_record(n, data)), persistent);
}
attr_data_ptr attribute::get(environment const & env, name const & n) const {
    if (auto records = attribute_ext::get_state(env).find(m_id))
        if (auto record = records->get_key({n, {}}))
            return record->m_data;
    return {};
}

unsigned attribute::get_prio(environment const & env, name const & n) const {
    if (auto records = attribute_ext::get_state(env).find(get_name()))
        if (auto prio = records->get_prio({n, {}}))
            return prio.value();
    return LEAN_DEFAULT_PRIORITY;
}

void attribute::get_instances(environment const & env, buffer<name> & r) const {
    if (auto records = attribute_ext::get_state(env).find(m_id))
        records->for_each([&](attr_record const & rec) { r.push_back(rec.m_decl); });
}

attr_data_ptr attribute::parse_data(abstract_parser &) const {
    return lean::attr_data_ptr(new attr_data);
}

environment basic_attribute::set(environment const & env, io_state const & ios, name const & n, unsigned prio,
                                 bool persistent) const {
    auto env2 = set_core(env, ios, n, prio, attr_data_ptr(new attr_data), persistent);
    if (m_on_set)
        env2 = m_on_set(env2, ios, n, prio, persistent);
    return env2;
}

attr_data_ptr indices_attribute::parse_data(abstract_parser & p) const {
    buffer<unsigned> vs;
    while (!p.curr_is_token("]")) {
        auto pos = p.pos();
        unsigned v = p.parse_small_nat();
        if (v == 0)
            throw parser_error("invalid attribute parameter, value must be positive", pos);
        vs.push_back(v - 1);
    }
    return attr_data_ptr(new indices_attribute_data(to_list(vs)));
}

void register_incompatible(char const * attr1, char const * attr2) {
    lean_assert(is_attribute(attr1));
    lean_assert(is_attribute(attr2));
    std::string s1(attr1);
    std::string s2(attr2);
    if (s1 > s2)
        std::swap(s1, s2);
    g_incomp->emplace_back(s1, s2);
}

void get_attributes(buffer<attribute const *> & r) {
    for (auto const & p : *g_attributes) {
        r.push_back(&*p.second);
    }
}

void get_attribute_tokens(buffer<char const *> & r) {
    for (auto const & p : *g_attributes) {
        r.push_back(p.second->get_token().c_str());
    }
}

attribute const * get_attribute_from_token(char const * tk) {
    for (auto const & p : *g_attributes) {
        if (p.second->get_token() == tk)
            return &*p.second;
    }
    return nullptr;
}

bool has_attribute(environment const & env, char const * attr, name const & d) {
    return static_cast<bool>(get_attribute(attr).get(env, d));
}

void get_attribute_instances(environment const & env, char const * attr, buffer<name> & r) {
    return get_attribute(attr).get_instances(env, r);
}

priority_queue<name, name_quick_cmp> get_attribute_instances_by_prio(environment const & env, name const & attr) {
    priority_queue<name, name_quick_cmp> q;
    auto recs = attribute_ext::get_state(env).find(attr);
    recs->for_each([&](attr_record const & rec) { q.insert(rec.m_decl, recs->get_prio(rec).value()); });
    return q;
}

environment set_attribute(environment const & env, io_state const & ios, char const * name,
                          lean::name const & d, unsigned prio, list<unsigned> const & params, bool persistent) {
    auto const & attr = get_attribute(name);
    lean_assert(dynamic_cast<indices_attribute const *>(&attr));
    return static_cast<indices_attribute const &>(attr).set(env, ios, d, prio, {params}, persistent);
}

environment set_attribute(environment const & env, io_state const & ios, char const * name, lean::name const & d,
                          unsigned prio, bool persistent) {
    auto const & attr = get_attribute(name);
    lean_assert(dynamic_cast<basic_attribute const *>(&attr));
    return static_cast<basic_attribute const &>(attr).set(env, ios, d, prio, persistent);
}
environment set_attribute(environment const & env, io_state const & ios, char const * attr,
                          name const & d, bool persistent) {
    return set_attribute(env, ios, attr, d, LEAN_DEFAULT_PRIORITY, persistent);
}

unsigned get_attribute_prio(environment const & env, std::string const & attr, name const & d) {
    return get_attribute(attr).get_prio(env, d);
}

list<unsigned> get_attribute_params(environment const & env, std::string const & attr, name const & d) {
    if (auto attribute = dynamic_cast<indices_attribute const *>(&get_attribute(attr))) {
        auto data = attribute->get_data(env, d);
        lean_assert(data);
        return data->m_idxs;
    }
    return list<unsigned>();
}

bool are_incompatible(attribute const * attr1, attribute const * attr2) {
    std::string s1(attr1->get_name());
    std::string s2(attr2->get_name());
    if (s1 > s2)
        std::swap(s1, s2);
    return std::find(g_incomp->begin(), g_incomp->end(), mk_pair(s1, s2)) != g_incomp->end();
}

void initialize_attribute_manager() {
    g_attributes = new std::unordered_map<std::string, attribute_ptr>;
    g_incomp     = new std::vector<pair<std::string, std::string>>();
    g_key        = new std::string("ATTR");
    attribute_ext::initialize();
}

void finalize_attribute_manager() {
    attribute_ext::finalize();
    delete g_key;
    delete g_incomp;
    delete g_attributes;
}
}
