[msys2]: http://msys2.github.io
[pacman]: https://wiki.archlinux.org/index.php/pacman

Lean for Windows
----------------

A native Lean binary for Windows can be generated using [msys2].
It is easy to install all dependencies, it produces native
64/32-binaries, and supports a C++11 compiler.


## Installing dependencies

[The official webpage of msys2][msys2] provides one-click installers.
We assume that you install [msys2][msys2] at `c:\msys64`.
Once installed it, you should run the "MSYS2 MinGW 64-bit shell" from the start menu.
It has a package management system, [pacman][pacman], which is used in Arch Linux.

Here are the commands to install all dependencies needed to compile Lean on your machine.

```bash
pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-mpfr mingw-w64-x86_64-ninja mingw-w64-x86_64-cmake git
```

## Build Lean

In the [msys2] shell, execute the following commands.

```bash
git clone https://github.com/leanprover/lean
cd lean
mkdir build && cd build
cmake ../src -G Ninja
ninja
```
