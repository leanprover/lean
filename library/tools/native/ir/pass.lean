/-
Copyright (c) 2017 Jared Roesch. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jared Roesch
-/

import tools.native.ir.internal
import tools.native.ir.procedure
import tools.native.ir.compiler

import tools.native.config

namespace native

meta structure pass :=
  (name : string)
  (transform : config → arity_map -> procedure → procedure)

meta def file_name_for_dump (p : pass) :=
  (pass.name p)

-- Unit functions get optimized away, need to talk to Leo about this one.
meta def run_pass (conf : config) (arity : arity_map) (p : pass) (proc : procedure) : (format × procedure × format) :=
  let result := pass.transform p conf arity proc in
  (repr proc, result, repr result)

meta def collect_dumps {A : Type} : list (format × A × format) → format × list A × format
| [] := (format.nil, [], format.nil)
| ((pre, body, post) :: fs) :=
  let (pre', bodies, post') := collect_dumps fs
  in (pre ++ format.line ++ format.line ++ pre',
      body :: bodies,
      post ++ format.line ++ format.line ++ post')

meta def inner_loop_debug (conf : config) (arity : arity_map) (p : pass) (es : list procedure) : list procedure :=
  let (pre, bodies, post) := collect_dumps (list.map (fun e, run_pass conf arity p e) es) in
  match native.dump_format (file_name_for_dump p ++ ".pre") pre with
  | n := match native.dump_format (file_name_for_dump p ++ ".post") post with
         | m := if n = m then bodies else bodies
         end
  end

meta def inner_loop (conf : config) (arity : arity_map) (p : pass) (es : list procedure) : list procedure :=
  if config.debug conf
  then inner_loop_debug conf arity p es
  else list.map (fun proc, pass.transform p conf arity proc) es

meta def fuse_passes (passes : list pass) : config → arity_map → procedure → procedure :=
  fun config arity,
    let transforms := list.map (fun p, pass.transform p config arity) passes in
        list.foldl (fun (f kont : procedure → procedure), fun proc, kont (f proc)) id transforms

meta def run_passes (conf : config) (arity : arity_map) (passes : list pass) (procs : list procedure) : list procedure :=
  list.map (fuse_passes passes conf arity) procs

end native
