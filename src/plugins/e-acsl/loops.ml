(**************************************************************************)
(*                                                                        *)
(*  This file is part of the Frama-C's E-ACSL plug-in.                    *)
(*                                                                        *)
(*  Copyright (C) 2012-2018                                               *)
(*    CEA (Commissariat à l'énergie atomique et aux énergies              *)
(*         alternatives)                                                  *)
(*                                                                        *)
(*  you can redistribute it and/or modify it under the terms of the GNU   *)
(*  Lesser General Public License as published by the Free Software       *)
(*  Foundation, version 2.1.                                              *)
(*                                                                        *)
(*  It is distributed in the hope that it will be useful,                 *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *)
(*  GNU Lesser General Public License for more details.                   *)
(*                                                                        *)
(*  See the GNU Lesser General Public License version 2.1                 *)
(*  for more details (enclosed in the file licenses/LGPLv2.1).            *)
(*                                                                        *)
(**************************************************************************)

open Cil
open Cil_types

(**************************************************************************)
(********************** Forward references ********************************)
(**************************************************************************)

let translate_named_predicate_ref
  : (kernel_function -> Env.t -> predicate -> Env.t) ref
  = Extlib.mk_fun "translate_named_predicate_ref"

let term_to_exp_ref
  : (kernel_function -> Env.t -> term -> exp * Env.t) ref
  = Extlib.mk_fun "term_to_exp_ref"

(**************************************************************************)
(************************* Loop invariants ********************************)
(**************************************************************************)

module Loop_invariants_actions = Hook.Make(struct end)

let apply_after_transformation prj =
  Project.on prj Loop_invariants_actions.apply ()

let mv_invariants env ~old stmt =
  Options.feedback ~current:true ~level:3
    "keep loop invariants attached to its loop";
  match Env.current_kf env with
  | None -> assert false
  | Some kf ->
    let filter _ ca = match ca.annot_content with
      | AInvariant(_, b, _) -> b
      | _ -> false
    in
    let l = Annotations.code_annot_emitter ~filter stmt in
    if l != [] then
      Loop_invariants_actions.extend
	(fun () ->
	  List.iter
	    (fun (ca, e) ->
	      Annotations.remove_code_annot e ~kf old ca;
	      Annotations.add_code_annot e ~kf stmt ca)
	    l)

let preserve_invariant prj env kf stmt = match stmt.skind with
  | Loop(_, ({ bstmts = stmts } as blk), loc, cont, break) ->
    let rec handle_invariants (stmts, env, _ as acc) = function
      | [] ->
	(* empty loop body: no need to verify the invariant twice *)
	acc
      | [ last ] ->
	let invariants, env = Env.pop_loop env in
	let env = Env.push env in
	let env =
    let translate_named_predicate = !translate_named_predicate_ref in
	  Project.on
	    prj
	    (List.fold_left (translate_named_predicate kf) env)
	    invariants
	in
	let blk, env =
	  Env.pop_and_get env last ~global_clear:false Env.Before
	in
	Misc.mk_block prj last blk :: stmts, env, invariants != []
      | s :: tl -> handle_invariants (s :: stmts, env, false) tl
    in
    let env = Env.set_annotation_kind env Misc.Invariant in
    let stmts, env, has_loop = handle_invariants ([], env, false) stmts in
    let new_blk = { blk with bstmts = List.rev stmts } in
    { stmt with skind = Loop([], new_blk, loc, cont, break) },
    env,
    has_loop
  | _ -> stmt, env, false

(**************************************************************************)
(**************************** Nested loops ********************************)
(**************************************************************************)

let rec mk_nested_loops ~loc mk_innermost_block kf env lscope_vars =
  let term_to_exp = !term_to_exp_ref in
  match lscope_vars with
  | [] ->
    mk_innermost_block env
  | Lscope.Lvs_quantif(t1, rel1, logic_x, rel2, t2) :: lscope_vars' ->
    let ctx =
      let ty1 = Typing.get_integer_ty t1 in
      let ty2 = Typing.get_integer_ty t2 in
      Typing.join ty1 ty2
    in
    let t_plus_one ?ty t =
      (* whenever provided, [ty] is known to be the type of the result *)
      let tone = Cil.lone ~loc () in
      let res = Logic_const.term ~loc (TBinOp(PlusA, t, tone)) Linteger in
      Extlib.may
        (fun ty ->
          Typing.unsafe_set tone ~ctx:ty ctx;
          Typing.unsafe_set t ~ctx:ty ctx;
          Typing.unsafe_set res ty)
        ty;
      res
    in
    let t1 = match rel1 with
      | Rlt ->
        let t = t_plus_one t1 in
        Typing.type_term ~use_gmp_opt:false ~ctx t;
        t
      | Rle ->
        t1
      | Rgt | Rge | Req | Rneq ->
        assert false
      in
    let t2_one, bop2 = match rel2 with
      | Rlt ->
        t2, Lt
      | Rle ->
        (* we increment the loop counter one more time (at the end of the
          loop). Thus to prevent overflow, check the type of [t2+1]
          instead of [t2]. *)
        t_plus_one t2, Le
      | Rgt | Rge | Req | Rneq ->
        assert false
    in
    Typing.type_term ~use_gmp_opt:false ~ctx t2_one;
    let ctx_one =
      let ty1 = Typing.get_integer_ty t1 in
      let ty2 = Typing.get_integer_ty t2_one in
      Typing.join ty1 ty2
    in
    let ty =
      try Typing.typ_of_integer_ty ctx_one
      with Typing.Not_an_integer -> assert false
    in
    (* loop counter corresponding to the quantified variable *)
    let var_x, x, env = Env.Logic_binding.add ~ty env logic_x in
    let lv_x = var var_x in
    let env = match ctx_one with
      | Typing.C_type _ -> env
      | Typing.Gmp -> Env.add_stmt env (Gmpz.init ~loc x)
      | Typing.Other -> assert false
    in
    (* build the inner loops and loop body *)
    let body, env =
      mk_nested_loops ~loc mk_innermost_block kf env lscope_vars'
    in
    (* initialize the loop counter to [t1] *)
    let e1, env = term_to_exp kf (Env.push env) t1 in
    let init_blk, env = Env.pop_and_get
      env
      (Gmpz.affect ~loc:e1.eloc lv_x x e1)
      ~global_clear:false
      Env.Middle
    in
    (* generate the guard [x bop t2] *)
    let block_to_stmt b = mkStmt ~valid_sid:true (Block b) in
    let tlv = Logic_const.tvar ~loc logic_x in
    let guard =
      (* must copy [t2] to force being typed again *)
      Logic_const.term ~loc
        (TBinOp(bop2, tlv, { t2 with term_node = t2.term_node } )) Linteger
    in
    Typing.type_term ~use_gmp_opt:false ~ctx:Typing.c_int guard;
    let guard_exp, env = term_to_exp kf (Env.push env) guard in
    let break_stmt = mkStmt ~valid_sid:true (Break guard_exp.eloc) in
    let guard_blk, env = Env.pop_and_get
      env
      (mkStmt
        ~valid_sid:true
        (If(
          guard_exp,
          mkBlock [ mkEmptyStmt ~loc () ],
          mkBlock [ break_stmt ],
          guard_exp.eloc)))
      ~global_clear:false
      Env.Middle
    in
    let guard = block_to_stmt guard_blk in
    (* increment the loop counter [x++];
       previous typing ensures that [x++] fits type [ty] *)
    (* TODO: should check that it does not overflow in the case of the type
       of the loop variable is __declared__ too small. *)
    let tlv_one = t_plus_one ~ty:ctx_one tlv in
    let incr, env = term_to_exp kf (Env.push env) tlv_one in
    let next_blk, env = Env.pop_and_get
      env
      (Gmpz.affect ~loc:incr.eloc lv_x x incr)
      ~global_clear:false
      Env.Middle
    in
    (* remove logic binding now that the block is constructed *)
    let env = Env.Logic_binding.remove env logic_x in
    (* generate the whole loop *)
    let start = block_to_stmt init_blk in
    let next = block_to_stmt next_blk in
    let stmt = mkStmt
      ~valid_sid:true
      (Loop(
        [],
        mkBlock (guard :: body @ [ next ]),
        loc,
        None,
        Some break_stmt))
    in
    [ start ;  stmt ], env
  | Lscope.Lvs_let(lv, t) :: lscope_vars' ->
    let ty = Typing.get_typ t in
    let vi_of_lv, exp_of_lv, env = Env.Logic_binding.add ~ty env lv in
    let e, env = term_to_exp kf env t in
    let let_stmt = Gmpz.init_set ~loc (Cil.var vi_of_lv) exp_of_lv  e in
    let stmts, env =
      mk_nested_loops ~loc mk_innermost_block kf env lscope_vars'
    in
    (* remove logic binding now that the block is constructed *)
    let env = Env.Logic_binding.remove env lv in
    (* return *)
    let_stmt :: stmts, env
  | Lscope.Lvs_formal _ :: _ ->
    Error.not_yet
      "creating nested loops from formal variable of a logic function"
  | Lscope.Lvs_global _ :: _ ->
    Error.not_yet
      "creating nested loops from global logic variable"


(*
Local Variables:
compile-command: "make"
End:
*)
