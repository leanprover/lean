/*
Copyright (c) 2017 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Jared Roesch
*/
#include <string>
#include <fstream>
#include <iostream>
#include <iomanip>
#include <utility>
#include <unistd.h>
#if defined(LEAN_WINDOWS) && !defined(LEAN_CYGWIN)
#include <windows.h>
#include <Fcntl.h>
#include <io.h>
#include <tchar.h>
#include <stdio.h>
#include <strsafe.h>

#define BUFSIZE 4096
#else
#include <sys/wait.h>
#endif
#include "library/process.h"
#include "util/buffer.h"
#include "library/pipe.h"

namespace lean {

process::process(std::string n): m_proc_name(n), m_args() {
    m_args.push_back(m_proc_name);
}

process & process::arg(std::string a) {
    m_args.push_back(a);
    return *this;
}

process & process::set_stdin(stdio cfg) {
    m_stdin = optional<stdio>(cfg);
    return *this;
}

process & process::set_stdout(stdio cfg) {
    m_stdout = optional<stdio>(cfg);
    return *this;
}

process & process::set_stderr(stdio cfg) {
    m_stderr = optional<stdio>(cfg);
    return *this;
}

#if defined(LEAN_WINDOWS) && !defined(LEAN_CYGWIN)

HANDLE to_win_handle(FILE * file) {
    intptr_t handle = _get_osfhandle(fileno(file));
    return reinterpret_cast<HANDLE>(handle);
}

FILE * from_win_handle(HANDLE handle, char const * mode) {
    int fd = _open_osfhandle(reinterpret_cast<intptr_t>(handle), _O_APPEND);
    return fdopen(fd, mode);
}

void create_child_process(std::string cmd_name, HANDLE hstdin, HANDLE hstdout, HANDLE hstderr);

// TODO(@jroesch): unify this code between platforms better.
static optional<pipe> setup_stdio(SECURITY_ATTRIBUTES * saAttr, optional<stdio> cfg) {
    /* Setup stdio based on process configuration. */
    if (cfg) {
        switch (*cfg) {
        /* We should need to do nothing in this case */
        case stdio::INHERIT:
            return optional<pipe>();
        case stdio::PIPED: {
            HANDLE readh;
            HANDLE writeh;
            if (!CreatePipe(&readh, &writeh, saAttr, 0))
                throw new exception("unable to create pipe");
            return optional<pipe>(lean::pipe(readh, writeh));
        }
        case stdio::NUL: {
            /* We should map /dev/null. */
            return optional<pipe>();
        }
        default:
           lean_unreachable();
        }
    } else {
        return optional<pipe>();
    }
}

// This code is adapted from: https://msdn.microsoft.com/en-us/library/windows/desktop/ms682499(v=vs.85).aspx
child process::spawn() {
   HANDLE child_stdin = stdin;
   HANDLE child_stdout = stdout;
   HANDLE child_stderr = stderr;
   
   SECURITY_ATTRIBUTES saAttr;
   
   // Set the bInheritHandle flag so pipe handles are inherited.
   saAttr.nLength = sizeof(SECURITY_ATTRIBUTES);
   saAttr.bInheritHandle = TRUE;
   saAttr.lpSecurityDescriptor = NULL;

   auto stdin_pipe = setup_stdio(&saAttr, m_stdin);
   auto stdout_pipe = setup_stdio(&saAttr, m_stdout);
   auto stderr_pipe = setup_stdio(&saAttr, m_stderr);

   // Create a pipe for the child process's STDOUT.
   if (stdout_pipe) {
       // Ensure the read handle to the pipe for STDOUT is not inherited.
       if (!SetHandleInformation(stdout_pipe->m_read_fd, HANDLE_FLAG_INHERIT, 0))
           throw new exception("unable to configure stdout pipe");
       child_stdin = stdin_pipe->m_write_fd;
   }

   if (stderr_pipe) {
       // Ensure the read handle to the pipe for STDOUT is not inherited.
       if (!SetHandleInformation(stderr_pipe->m_read_fd, HANDLE_FLAG_INHERIT, 0))
           throw new exception("unable to configure stdout pipe");
       child_stdout = stdout_pipe->m_read_fd;
   }

   if (stdin_pipe) {
       // Ensure the write handle to the pipe for STDIN is not inherited.
       if (!SetHandleInformation(stdin_pipe->m_write_fd, HANDLE_FLAG_INHERIT, 0))
           throw new exception("unable to configure stdin pipe");
       child_stderr = stderr_pipe->m_read_fd;
   }

   std::string command;

   // This needs some thought, on Windows we must pass a command string
   // which is a valid command, that is a fully assembled command to be executed.
   //
   // We must escape the arguments to preseving spacing and other characters,
   // we might need to revisit escaping here.
   bool once_through = false;
   for (auto arg : m_args) {
       if (once_through) {
           command += " \"";
       }
       command += arg;
       if (once_through) {
           command += "\"";
       }
       once_through = true;
   }

   // Create the child process.
   create_child_process(command, child_stdin, child_stdout, child_stdout);

   if (stdin_pipe) {
       CloseHandle(stdin_pipe->m_read_fd);
   }

   if (stdout_pipe) {
       CloseHandle(stdout_pipe->m_write_fd);
   }

   if (stderr_pipe) {
       CloseHandle(stderr_pipe->m_write_fd);
   }

   return child(
       0,
       std::make_shared<handle>(from_win_handle(child_stdin, "w")),
       std::make_shared<handle>(from_win_handle(child_stdout, "r")),
       std::make_shared<handle>(from_win_handle(child_stderr, "r")));
}

void create_child_process(std::string command, HANDLE hstdin, HANDLE hstdout, HANDLE hstderr)
// Create a child process that uses the previously created pipes for STDIN and STDOUT.
{
   // TCHAR szCmdline[] =TEXT("echo \"Hello\"");
   PROCESS_INFORMATION piProcInfo;
   STARTUPINFO siStartInfo;
   BOOL bSuccess = FALSE;

   // Set up members of the PROCESS_INFORMATION structure.
   ZeroMemory( &piProcInfo, sizeof(PROCESS_INFORMATION) );

   // Set up members of the STARTUPINFO structure.
   // This structure specifies the STDIN and STDOUT handles for redirection.

   ZeroMemory( &siStartInfo, sizeof(STARTUPINFO) );
   siStartInfo.cb = sizeof(STARTUPINFO);
   siStartInfo.hStdError = hstderr;
   siStartInfo.hStdOutput = hstdout;
   siStartInfo.hStdInput = hstdin;
   siStartInfo.dwFlags |= STARTF_USESTDHANDLES;

   // Create the child process.
   // std::cout << command << std::endl;
   bSuccess = CreateProcess(
       NULL,
       const_cast<char *>(command.c_str()), // command line
       NULL,                                // process security attributes
       NULL,                                // primary thread security attributes
       TRUE,                                // handles are inherited
       0,                                   // creation flags
       NULL,                                // use parent's environment
       NULL,                                // use parent's current directory
       &siStartInfo,                        // STARTUPINFO pointer
       &piProcInfo);                        // receives PROCESS_INFORMATION

   // If an error occurs, exit the application.
   if (!bSuccess) {
       throw exception("failed to start child process");
   } else {
      // Close handles to the child process and its primary thread.
      // Some applications might keep these handles to monitor the status
      // of the child process, for example.

      CloseHandle(piProcInfo.hProcess);
      CloseHandle(piProcInfo.hThread);
   }
}

void process::run() {
     throw exception("process::run not supported on Windows");
}

#else

optional<pipe> setup_stdio(optional<stdio> cfg) {
    /* Setup stdio based on process configuration. */
    if (cfg) {
        switch (*cfg) {
        /* We should need to do nothing in this case */
        case stdio::INHERIT:
            return optional<pipe>();
        case stdio::PIPED: {
            return optional<pipe>(lean::pipe());
        }
        case stdio::NUL: {
            /* We should map /dev/null. */
            return optional<pipe>();
        }
        default:
           lean_unreachable();
        }
    } else {
        return optional<pipe>();
    }
}

child process::spawn() {
    /* Setup stdio based on process configuration. */
    auto stdin_pipe = setup_stdio(m_stdin);
    auto stdout_pipe = setup_stdio(m_stdout);
    auto stderr_pipe = setup_stdio(m_stderr);

    int pid = fork();

    if (pid == 0) {
        if (stdin_pipe) {
            dup2(stdin_pipe->m_read_fd, STDIN_FILENO);
            close(stdin_pipe->m_write_fd);
        }

        if (stdout_pipe) {
            dup2(stdout_pipe->m_write_fd, STDOUT_FILENO);
            close(stdout_pipe->m_read_fd);
        }

        if (stderr_pipe) {
            dup2(stderr_pipe->m_write_fd, STDERR_FILENO);
            close(stderr_pipe->m_read_fd);
        }

        buffer<char*> pargs;

        for (auto arg : this->m_args) {
            auto str = new char[arg.size() + 1];
            arg.copy(str, arg.size());
            str[arg.size()] = '\0';
            pargs.push_back(str);
        }

        pargs.data()[pargs.size()] = NULL;

        auto err = execvp(pargs.data()[0], pargs.data());
        if (err < 0) {
            throw std::runtime_error("executing process failed: ...");
        }
    } else if (pid == -1) {
        throw std::runtime_error("forking process failed: ...");
    }

    /* We want to setup the parent's view of the file descriptors. */
    int parent_stdin = STDIN_FILENO;
    int parent_stdout = STDOUT_FILENO;
    int parent_stderr = STDERR_FILENO;

    if (stdin_pipe) {
        close(stdin_pipe->m_read_fd);
        parent_stdin = stdin_pipe->m_write_fd;
    }

    if (stdout_pipe) {
        close(stdout_pipe->m_write_fd);
        parent_stdout = stdout_pipe->m_read_fd;
    }

    if (stderr_pipe) {
        close(stderr_pipe->m_write_fd);
        parent_stderr = stderr_pipe->m_read_fd;
    }

    return child(pid,
         std::make_shared<handle>(fdopen(parent_stdin, "w")),
         std::make_shared<handle>(fdopen(parent_stdout, "r")),
         std::make_shared<handle>(fdopen(parent_stderr, "r")));
}

void process::run() {
    child ch = spawn();
    int status;
    waitpid(ch.m_pid, &status, 0);
}

#endif

}
