/-
Copyright (c) 2017 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Gabriel Ebner
-/
import leanpkg.toml system.io

namespace leanpkg

inductive source
| path (dir_name : string) : source
| git (url rev : string) : source

namespace source

def from_toml (v : toml.value) : option source :=
(do toml.value.str dir_name ← v.lookup "path" | none,
    return $ path dir_name) <|>
(do toml.value.str url ← v.lookup "git" | none,
    toml.value.str rev ← (v.lookup "rev") | none,
    return $ git url rev) <|>
(do toml.value.str url ← v.lookup "git" | none,
    return $ git url "master")

def to_toml : ∀ (s : source), toml.value
| (path dir_name) := toml.value.table [("path", toml.value.str dir_name)]
| (git url "master") :=
  toml.value.table [("git", toml.value.str url)]
| (git url rev) :=
  toml.value.table [("git", toml.value.str url), ("rev", toml.value.str rev)]

instance : has_to_string source :=
⟨λ s, s.to_toml.to_string⟩

end source

structure dependency :=
(name : string) (src : source)

namespace dependency
instance : has_to_string dependency :=
⟨λ d, d.name ++ " = " ++ to_string d.src⟩
end dependency

structure desc :=
(name : string) (version : string)
(dependencies : list dependency)

namespace desc

def from_toml (t : toml.value) : option desc := do
pkg ← t.lookup "package",
toml.value.str n ← pkg.lookup "name" | none,
toml.value.str ver ← pkg.lookup "version" | none,
toml.value.table deps ← t.lookup "dependencies" <|> some (toml.value.table []) | none,
deps ← monad.for deps (λ ⟨n, src⟩, do src ← source.from_toml src,
                                      return $ dependency.mk n src),
return { name := n, version := ver, dependencies := deps }

def to_toml (d : desc) : toml.value :=
let pkg := toml.value.table [("name", toml.value.str d.name),
                             ("version", toml.value.str d.version)],
    deps := toml.value.table $ d.dependencies.for $ λ dep, (dep.name, dep.src.to_toml) in
toml.value.table [("package", pkg), ("dependencies", deps)]

instance : has_to_string desc :=
⟨λ d, d.to_toml.to_string⟩

def from_string (s : string) : option desc :=
match parser.run_string toml.File s with
| sum.inr toml := from_toml toml
| sum.inl _ := none
end

def from_file [io.interface] (fn : string) : io desc := do
cnts ← io.fs.read_file fn,
toml ←
  (match parser.run toml.File cnts with
  | sum.inl err :=
    io.fail $ "toml parse error in " ++ fn ++ "\n\n" ++ err
  | sum.inr res := return res
  end),
some desc ← return (from_toml toml)
  | io.fail ("cannot read description from " ++ fn ++ "\n\n" ++ toml.to_string),
return desc

end desc

def leanpkg_toml_fn := "leanpkg.toml"

end leanpkg
