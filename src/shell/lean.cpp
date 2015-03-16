/*
Copyright (c) 2013 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include <iostream>
#include <fstream>
#include <signal.h>
#include <cstdlib>
#include <getopt.h>
#include <string>
#include "util/stackinfo.h"
#include "util/macros.h"
#include "util/debug.h"
#include "util/sstream.h"
#include "util/interrupt.h"
#include "util/memory.h"
#include "util/script_state.h"
#include "util/thread.h"
#include "util/thread_script_state.h"
#include "util/lean_path.h"
#include "util/sexpr/options.h"
#include "util/sexpr/option_declarations.h"
#include "kernel/environment.h"
#include "kernel/kernel_exception.h"
#include "kernel/formatter.h"
#include "library/standard_kernel.h"
#include "library/hott_kernel.h"
#include "library/module.h"
#include "library/flycheck.h"
#include "library/io_state_stream.h"
#include "library/definition_cache.h"
#include "library/declaration_index.h"
#include "library/error_handling/error_handling.h"
#include "frontends/lean/parser.h"
#include "frontends/lean/pp.h"
#include "frontends/lean/server.h"
#include "frontends/lean/dependencies.h"
#include "init/init.h"
#include "version.h"
#include "githash.h" // NOLINT

using lean::script_state;
using lean::unreachable_reached;
using lean::environment;
using lean::io_state;
using lean::io_state_stream;
using lean::regular;
using lean::mk_environment;
using lean::mk_hott_environment;
using lean::set_environment;
using lean::set_io_state;
using lean::definition_cache;
using lean::pos_info;
using lean::pos_info_provider;
using lean::optional;
using lean::expr;
using lean::options;
using lean::declaration_index;
using lean::keep_theorem_mode;
using lean::module_name;

enum class input_kind { Unspecified, Lean, HLean, Lua, Trace };

static void on_ctrl_c(int ) {
    lean::request_interrupt();
}

static void display_header(std::ostream & out) {
    out << "Lean (version " << LEAN_VERSION_MAJOR << "."
        << LEAN_VERSION_MINOR << "." << LEAN_VERSION_PATCH;
    if (std::strcmp(g_githash, "GITDIR-NOTFOUND") == 0) {
        if (std::strcmp(LEAN_PACKAGE_VERSION, "NOT-FOUND") != 0) {
            out << ", package " << LEAN_PACKAGE_VERSION;
        }
    } else {
        out << ", commit " << std::string(g_githash).substr(0, 12);
    }
    out << ", " << LEAN_STR(LEAN_BUILD_TYPE) << ")\n";
}

static void display_help(std::ostream & out) {
    display_header(out);
    std::cout << "Input format:\n";
    std::cout << "  --lean            use parser for Lean default input format for files,\n";
    std::cout << "                    with unknown extension (default)\n";
    std::cout << "  --hlean           use parser for Lean default input format \n";
    std::cout << "                    and use HoTT compatible kernel for files, with unknown extension\n";
    std::cout << "  --lua             use Lua parser for files with unknown extension\n";
    std::cout << "  --server-trace    use lean server trace parser for files with unknown extension\n";
    std::cout << "Miscellaneous:\n";
    std::cout << "  --help -h         display this message\n";
    std::cout << "  --version -v      display version number\n";
    std::cout << "  --githash         display the git commit hash number used to build this binary\n";
    std::cout << "  --path            display the path used for finding Lean libraries and extensions\n";
    std::cout << "  --output=file -o  save the final environment in binary format in the given file\n";
    std::cout << "  --cpp=file -C     save the final environment as a C++ array\n";
    std::cout << "  --luahook=num -k  how often the Lua interpreter checks the interrupted flag,\n";
    std::cout << "                    it is useful for interrupting non-terminating user scripts,\n";
    std::cout << "                    0 means 'do not check'.\n";
    std::cout << "  --trust=num -t    trust level (default: max) 0 means do not trust any macro, "
              << "                    and type check all imported modules\n";
    std::cout << "  --discard -r      discard the proof of imported theorems after checking\n";
    std::cout << "  --to_axiom -X     discard proofs of all theorems after checking them, i.e.,\n";
    std::cout << "                    theorems become axioms after checking\n";
    std::cout << "  --quiet -q        do not print verbose messages\n";
#if defined(LEAN_TRACK_MEMORY)
    std::cout << "  --memory=num -M   maximum amount of memory that should be used by Lean ";
    std::cout << "                    (in megabytes)\n";
#endif
#if defined(LEAN_MULTI_THREAD)
    std::cout << "  --server          start Lean in 'server' mode\n";
    std::cout << "  --threads=num -j  number of threads used to process lean files\n";
#endif
    std::cout << "  --deps            just print dependencies of a Lean input\n";
    std::cout << "  --flycheck        print structured error message for flycheck\n";
    std::cout << "  --cache=file -c   load/save cached definitions from/to the given file\n";
    std::cout << "  --index=file -i   store index for declared symbols in the given file\n";
#if defined(LEAN_USE_BOOST)
    std::cout << "  --tstack=num -s   thread stack size in Kb\n";
#endif
    std::cout << "  -D name=value     set a configuration option (see set_option command)\n";
}

static char const * get_file_extension(char const * fname) {
    if (fname == 0)
        return 0;
    char const * last_dot = 0;
    while (true) {
        char const * tmp = strchr(fname, '.');
        if (tmp == 0) {
            return last_dot;
        }
        last_dot  = tmp + 1;
        fname = last_dot;
    }
}

static struct option g_long_options[] = {
    {"version",      no_argument,       0, 'v'},
    {"help",         no_argument,       0, 'h'},
    {"lean",         no_argument,       0, 'l'},
    {"hlean",        no_argument,       0, 'H'},
    {"lua",          no_argument,       0, 'u'},
    {"server-trace", no_argument,       0, 'R'},
    {"path",         no_argument,       0, 'p'},
    {"luahook",      required_argument, 0, 'k'},
    {"githash",      no_argument,       0, 'g'},
    {"output",       required_argument, 0, 'o'},
    {"cpp",          required_argument, 0, 'C'},
    {"memory",       required_argument, 0, 'M'},
    {"trust",        required_argument, 0, 't'},
    {"discard",      no_argument,       0, 'r'},
    {"to_axiom",     no_argument,       0, 'X'},
#if defined(LEAN_MULTI_THREAD)
    {"server",       no_argument,       0, 'S'},
    {"threads",      required_argument, 0, 'j'},
#endif
    {"quiet",        no_argument,       0, 'q'},
    {"cache",        required_argument, 0, 'c'},
    {"deps",         no_argument,       0, 'd'},
    {"flycheck",     no_argument,       0, 'F'},
    {"index",        no_argument,       0, 'i'},
#if defined(LEAN_USE_BOOST)
    {"tstack",       required_argument, 0, 's'},
#endif
    {0, 0, 0, 0}
};

#define OPT_STR "HRXFC:dD:qrlupgvhk:012t:012o:c:i:"

#if defined(LEAN_TRACK_MEMORY)
#define OPT_STR2 OPT_STR "M:012"
#else
#define OPT_STR2 OPT_STR
#endif

#if defined(LEAN_USE_BOOST) && defined(LEAN_MULTI_THREAD)
static char const * g_opt_str = OPT_STR2 "Sj:012s:012";
#elif !defined(LEAN_USE_BOOST) && defined(LEAN_MULTI_THREAD)
static char const * g_opt_str = OPT_STR2 "Sj:012";
#else
static char const * g_opt_str = OPT_STR2;
#endif

class simple_pos_info_provider : public pos_info_provider {
    char const * m_fname;
public:
    simple_pos_info_provider(char const * fname):m_fname(fname) {}
    virtual optional<pos_info> get_pos_info(expr const &) const { return optional<pos_info>(); }
    virtual char const * get_file_name() const { return m_fname; }
    virtual pos_info get_some_pos() const { return pos_info(-1, -1); }
};

options set_config_option(options const & opts, char const * in) {
    if (!in) return opts;
    while (*in && std::isspace(*in))
        ++in;
    std::string in_str(in);
    auto pos = in_str.find('=');
    if (pos == std::string::npos)
        throw lean::exception("invalid -D parameter, argument must contain '='");
    lean::name opt = lean::string_to_name(in_str.substr(0, pos));
    std::string val = in_str.substr(pos+1);
    auto decls = lean::get_option_declarations();
    auto it = decls.find(opt);
    if (it != decls.end()) {
        switch (it->second.kind()) {
        case lean::BoolOption:
            if (val == "true")
                return opts.update(opt, true);
            else if (val == "false")
                return opts.update(opt, false);
            else
                throw lean::exception(lean::sstream() << "invalid -D parameter, invalid configuration option '" << opt
                                      << "' value, it must be true/false");
        case lean::IntOption:
        case lean::UnsignedOption:
            return opts.update(opt, atoi(val.c_str()));
        default:
            throw lean::exception(lean::sstream() << "invalid -D parameter, configuration option '" << opt
                                  << "' cannot be set in the command line, use set_option command");
        }
    } else {
        throw lean::exception(lean::sstream() << "invalid -D parameter, unknown configuration option '" << opt << "'");
    }
}

static void export_as_cpp_file(std::string const & fname, char const * varname, environment const & env) {
    std::ostringstream buffer(std::ofstream::binary);
    export_module(buffer, env);
    std::string r = buffer.str();
    std::ofstream out(fname);
    out << "// automatically generated file do not edit\n";
    out << "namespace lean {\n";
    out << "    char " << varname << "[" << r.size() + 1 << "] = {";
    for (unsigned i = 0; i < r.size(); i++) {
        if (i > 0)
            out << ", ";
        out << static_cast<unsigned>(static_cast<unsigned char>(r[i]));
    }
    out << "    }\n";
    out << "}\n";
}

environment import_module(environment const & env, io_state const & ios, module_name const & mod, bool keep_proofs = true) {
    std::string base = ".";
    bool num_threads = 1;
    return import_modules(env, base, 1, &mod, num_threads, keep_proofs, ios);
}

environment import_standard(environment const & env, io_state const & ios, bool keep_proofs = true) {
    module_name std(lean::name("standard"));
    return import_module(env, ios, std, keep_proofs);
}

#if defined(LEAN_EMSCRIPTEN)
#include <emscripten/bind.h>

class emscripten_shell {
private:
    unsigned trust_lvl;
    unsigned num_threads;
    options opts;
    environment env;
    io_state ios;
    script_state S;
    set_environment set1;
    set_io_state    set2;

public:
    emscripten_shell() : trust_lvl(LEAN_BELIEVER_TRUST_LEVEL+1), num_threads(1), opts("flycheck", true),
        env(mk_environment(trust_lvl)), ios(opts, lean::mk_pretty_formatter_factory()),
        S(lean::get_thread_script_state()), set1(S, env), set2(S, ios) {
    }

    int import_module(std::string mname) {
        try {
            env = ::import_module(env, ios, lean::module_name(mname), false);
        } catch (lean::exception & ex) {
            simple_pos_info_provider pp("import_module");
            lean::display_error(diagnostic(env, ios), &pp, ex);
            return 1;
        }
        return 0;
    }

    int process_file(std::string input_filename) {
        bool ok = true;
        try {
            environment temp_env(env);
            io_state    temp_ios(ios);
            if (!parse_commands(temp_env, temp_ios, input_filename.c_str(), false, num_threads)) {
                ok = false;
            }
        } catch (lean::exception & ex) {
            simple_pos_info_provider pp(input_filename.c_str());
            ok = false;
            lean::display_error(diagnostic(env, ios), &pp, ex);
        }
        return ok ? 0 : 1;
    }
};

lean::initializer* g_init;
emscripten_shell* g_shell;

void emscripten_init() {
    g_init = new lean::initializer();
    g_shell = new emscripten_shell();
}

int emscripten_import_module(std::string mname) {
    return g_shell->import_module(mname);
}

int emscripten_process_file(std::string input_filename) {
    return g_shell->process_file(input_filename);
}

EMSCRIPTEN_BINDINGS(LEAN_JS) {
    emscripten::function("lean_init", &emscripten_init);
    emscripten::function("lean_import_module", &emscripten_import_module);
    emscripten::function("lean_process_file", &emscripten_process_file);
}

int main() {
    return 0;
}

#else
int main(int argc, char ** argv) {
    lean::initializer init;
    bool export_objects     = false;
    unsigned trust_lvl      = LEAN_BELIEVER_TRUST_LEVEL+1;
    bool server             = false;
    bool only_deps          = false;
    unsigned num_threads    = 1;
    bool use_cache          = false;
    bool gen_index          = false;
    bool export_cpp         = false;
    keep_theorem_mode tmode = keep_theorem_mode::All;
    options opts;
    std::string output;
    std::string cpp_output;
    std::string cache_name;
    std::string index_name;
    input_kind default_k = input_kind::Unspecified;
    while (true) {
        int c = getopt_long(argc, argv, g_opt_str, g_long_options, NULL);
        if (c == -1)
            break; // end of command line
        switch (c) {
        case 'j':
            num_threads = atoi(optarg);
            break;
        case 'S':
            server = true;
            break;
        case 'v':
            display_header(std::cout);
            return 0;
        case 'g':
            std::cout << g_githash << "\n";
            return 0;
        case 'h':
            display_help(std::cout);
            return 0;
        case 'l':
            default_k = input_kind::Lean;
            break;
        case 'H':
            default_k = input_kind::HLean;
            break;
        case 'u':
            default_k = input_kind::Lua;
            break;
        case 'R':
            default_k = input_kind::Trace;
            break;
        case 'k':
            script_state::set_check_interrupt_freq(atoi(optarg));
            break;
        case 'p':
            if (default_k == input_kind::HLean)
                lean::initialize_lean_path(true);
            std::cout << lean::get_lean_path() << "\n";
            return 0;
        case 's':
            lean::set_thread_stack_size(atoi(optarg)*1024);
            break;
        case 'o':
            output         = optarg;
            export_objects = true;
            break;
        case 'C':
            cpp_output = optarg;
            export_cpp = true;
            break;
        case 'c':
            cache_name = optarg;
            use_cache  = true;
            break;
        case 'i':
            index_name = optarg;
            gen_index  = true;
        case 'M':
            lean::set_max_memory_megabyte(atoi(optarg));
            opts = opts.update(lean::get_max_memory_opt_name(), atoi(optarg));
            break;
        case 't':
            trust_lvl = atoi(optarg);
            break;
        case 'r':
            tmode = keep_theorem_mode::DiscardImported;
            break;
        case 'X':
            tmode = keep_theorem_mode::DiscardAll;
            break;
        case 'q':
            opts = opts.update(lean::get_verbose_opt_name(), false);
            break;
        case 'd':
            only_deps = true;
            break;
        case 'D':
            try {
                opts = set_config_option(opts, optarg);
            } catch (lean::exception & ex) {
                std::cerr << ex.what() << std::endl;
                return 1;
            }
            break;
        case 'F':
            opts = opts.update("flycheck", true);
            break;
        default:
            std::cerr << "Unknown command line option\n";
            display_help(std::cerr);
            return 1;
        }
    }

    #if !defined(LEAN_MULTI_THREAD)
    lean_assert(!server);
    lean_assert(num_threads == 1);
    #endif

    bool has_lean  = (default_k == input_kind::Lean);
    bool has_hlean = (default_k == input_kind::HLean);
    for (int i = optind; i < argc; i++) {
        char const * ext = get_file_extension(argv[i]);
        if (ext && strcmp(ext, "lean") == 0) {
            has_lean = true;
            if (has_hlean) {
                std::cerr << ".hlean file cannot be mixed with .lean files\n";
                return 1;
            }
            if (default_k == input_kind::Unspecified)
                default_k = input_kind::Lean;
        } else if (ext && strcmp(ext, "hlean") == 0) {
            has_hlean = true;
            if (has_lean) {
                std::cerr << ".lean file cannot be mixed with .hlean files\n";
                return 1;
            }
            if (default_k == input_kind::Unspecified)
                default_k = input_kind::HLean;
        }
    }
    if (default_k == input_kind::Unspecified)
        default_k = input_kind::Lean;

    if (has_hlean)
        lean::initialize_lean_path(true);

    environment env = has_hlean ? mk_hott_environment(trust_lvl) : mk_environment(trust_lvl);
    io_state ios(opts, lean::mk_pretty_formatter_factory());
    script_state S = lean::get_thread_script_state();
    set_environment set1(S, env);
    set_io_state    set2(S, ios);
    definition_cache   cache;
    definition_cache * cache_ptr = nullptr;
    if (use_cache) {
        try {
            cache_ptr = &cache;
            std::ifstream in(cache_name, std::ifstream::binary);
            if (!in.bad() && !in.fail())
                cache.load(in);
        } catch (lean::throwable & ex) {
            cache_ptr = nullptr;
            auto out = regular(env, ios);
            // I'm using flycheck_error instead off flycheck_warning because
            // the :error-patterns at lean-flycheck.el do not work after
            // I add a rule for FLYCHECK_WARNING.
            // Same for display_error_pos vs display_warning_pos.
            lean::flycheck_error warn(out);
            if (optind < argc)
                display_error_pos(out, argv[optind], 1, 0);
            out << "failed to load cache file '" << cache_name << "', "
                << ex.what() << ". cache is going to be ignored\n";
        }
    }
    declaration_index index;
    declaration_index * index_ptr = nullptr;
    if (gen_index)
        index_ptr = &index;

    try {
        bool ok = true;
        for (int i = optind; i < argc; i++) {
            try {
                char const * ext = get_file_extension(argv[i]);
                input_kind k     = default_k;
                if (ext) {
                    if (strcmp(ext, "lean") == 0) {
                        k = input_kind::Lean;
                    } else if (strcmp(ext, "hlean") == 0) {
                        k = input_kind::HLean;
                    } else if (strcmp(ext, "lua") == 0) {
                        k = input_kind::Lua;
                    }
                }
                switch (k) {
                case input_kind::Lean:
                case input_kind::HLean:
                    if (only_deps) {
                        if (!display_deps(env, std::cout, std::cerr, argv[i]))
                            ok = false;
                    } else if (!parse_commands(env, ios, argv[i], false, num_threads,
                                               cache_ptr, index_ptr, tmode)) {
                        ok = false;
                    }
                    break;
                case input_kind::Lua:
                    lean::system_import(argv[i]);
                    break;
                case input_kind::Trace:
                    ok = lean::parse_server_trace(env, ios, argv[i]);
                    break;
                default:
                    lean_unreachable();
                    break;
                }
            } catch (lean::exception & ex) {
                simple_pos_info_provider pp(argv[i]);
                ok = false;
                lean::display_error(diagnostic(env, ios), &pp, ex);
            }
        }
        if (ok && server && (default_k == input_kind::Lean || default_k == input_kind::HLean)) {
            signal(SIGINT, on_ctrl_c);
            ios.set_option(lean::name("pp", "beta"), true);
            lean::server Sv(env, ios, num_threads);
            if (!Sv(std::cin))
                ok = false;
        }
        if (use_cache) {
            std::ofstream out(cache_name, std::ofstream::binary);
            cache.save(out);
        }
        if (gen_index) {
            std::shared_ptr<lean::file_output_channel> out(new lean::file_output_channel(index_name.c_str()));
            ios.set_regular_channel(out);
            index.save(regular(env, ios));
        }
        if (export_objects && ok) {
            std::ofstream out(output, std::ofstream::binary);
            export_module(out, env);
        }
        if (export_cpp && ok) {
            export_as_cpp_file(cpp_output, "olean_lib", env);
        }
        return ok ? 0 : 1;
    } catch (lean::throwable & ex) {
        lean::display_error(diagnostic(env, ios), nullptr, ex);
    }
    return 1;
}
#endif
