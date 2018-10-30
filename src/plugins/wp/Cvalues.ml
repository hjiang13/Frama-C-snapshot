(**************************************************************************)
(*                                                                        *)
(*  This file is part of WP plug-in of Frama-C.                           *)
(*                                                                        *)
(*  Copyright (C) 2007-2018                                               *)
(*    CEA (Commissariat a l'energie atomique et aux energies              *)
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

(* -------------------------------------------------------------------------- *)
(* --- Lifting Operations over Memory Values                              --- *)
(* -------------------------------------------------------------------------- *)

open Cil_types
open Ctypes
open Qed
open Lang
open Lang.F
open Sigs
open Definitions

(* -------------------------------------------------------------------------- *)
(* --- C Constants                                                        --- *)
(* -------------------------------------------------------------------------- *)

let ainf = Some e_zero
let asup n = Some (e_int (n-1))
let arange k n = p_and (p_leq e_zero k) (p_lt k (e_int n))

let equation = function
  | Set(a,b) -> p_equal a b
  | Assert p -> p

let rec constant = function
  | CInt64(z,_,_) -> e_bigint z
  | CChr c -> e_int64 (Ctypes.char c)
  | CReal(f,_,_) -> Cfloat.code_lit f
  | CEnum e -> constant_exp e.eival
  | CStr _ | CWStr _ -> Warning.error "String constants not yet implemented"

and logic_constant = function
  | Integer(z,_) -> e_bigint z
  | LChr c -> e_int64 (Ctypes.char c)
  | LReal r -> Cfloat.acsl_lit r
  | LEnum e -> constant_exp e.eival
  | LStr _ | LWStr _ -> Warning.error "String constants not yet implemented"

and constant_exp e =
  let e = Cil.constFold true e in
  match e.enode with
  | Const c -> constant c
  | _ -> Warning.error "constant(%a)" Printer.pp_exp e

and constant_term t =
  let e = Cil.constFoldTerm true t in
  match e.term_node with
  | TConst c -> logic_constant c
  | _ -> Warning.error "constant(%a)" Printer.pp_term t

(* -------------------------------------------------------------------------- *)

(* The type contains C-integers *)
let rec is_constrained typ =
  is_constrained_obj (Ctypes.object_of typ)

and is_constrained_obj = function
  | C_int _ -> true
  | C_float _ -> false
  | C_pointer _ -> false
  | C_array a -> is_constrained a.arr_element
  | C_comp c -> is_constrained_comp c

and is_constrained_comp c =
  List.exists (fun f -> is_constrained f.ftype) c.cfields

module type CASES =
sig
  val prefix : string
  val natural : bool
  (* natural: all types are constrained, but only with their natural values *)
  (* otherwise: only atomic types are constrained *)
  val is_int : c_int -> term -> pred
  val is_float : c_float -> term -> pred
  val is_pointer : term -> pred
end

module STRUCTURAL(C : CASES) =
struct

  let constrained_elt ty = C.natural || is_constrained ty

  let constrained_comp c = C.natural || is_constrained_comp c

  let model_int fmt i =
    if C.natural
    then Format.pp_print_string fmt "int"
    else Ctypes.pp_int fmt i

  let array_name te ds =
    let dim = List.length ds in
    match te with
    | C_int i ->
        Format.asprintf "%sArray%d_%a" C.prefix dim model_int i
    | C_float _ ->
        Format.asprintf "%sArray%d_float" C.prefix dim
    | C_pointer _ ->
        Format.asprintf "%sArray%d_pointer" C.prefix dim
    | C_comp c ->
        Format.asprintf "%sArray%d%s" C.prefix dim (Lang.comp_id c)
    | C_array _ ->
        Wp_parameters.fatal "Unflatten array (%s %a)" C.prefix Ctypes.pretty te

  let rec is_obj obj t =
    match obj with
    | C_int i -> C.is_int i t
    | C_float f -> C.is_float f t
    | C_pointer _ty -> C.is_pointer t
    | C_comp c ->
        if constrained_comp c then is_record c t else p_true
    | C_array a ->
        if constrained_elt a.arr_element
        then
          let te,ds = Ctypes.array_dimensions a in
          is_array te ds t
        else p_true

  and is_typ typ t = is_obj (Ctypes.object_of typ) t

  and is_record c s =
    Definitions.call_pred
      (Lang.generated_p (C.prefix ^ Lang.comp_id c))
      (fun lfun ->
         let basename = if c.cstruct then "S" else "U" in
         let s = Lang.freshvar ~basename (Lang.tau_of_comp c) in
         let def = p_all
             (fun f -> is_typ f.ftype (e_getfield (e_var s) (Lang.Cfield f)))
             c.cfields
         in {
           d_lfun = lfun ; d_types = 0 ; d_params = [s] ;
           d_cluster = Definitions.compinfo c ;
           d_definition = Predicate(Def,def) ;
         })
      [s]

  and is_array te ds t =
    Definitions.call_pred
      (Lang.generated_p (array_name te ds))
      (fun lfun ->
         let x = Lang.freshvar ~basename:"T" (Matrix.tau te ds) in
         let ks = List.map (fun _d -> Lang.freshvar ~basename:"k" Logic.Int) ds in
         let e = List.fold_left (fun a k -> e_get a (e_var k)) (e_var x) ks in
         let def = p_forall ks (is_obj te e) in
         {
           d_lfun = lfun ; d_types = 0 ; d_params = [x] ;
           d_cluster = Definitions.matrix te ;
           d_definition = Predicate(Def,def) ;
         }
      ) [t]

end

(* -------------------------------------------------------------------------- *)
(* --- Null-Values                                                        --- *)
(* -------------------------------------------------------------------------- *)

let null = Context.create "Lang.null"
module NULL = STRUCTURAL
    (struct
      let prefix = "Null"
      let natural = true
      let is_int _i = p_equal e_zero
      let is_float _f = p_equal e_zero_real
      let is_pointer p = Context.get null p
    end)

let is_null = NULL.is_obj

module TYPE = STRUCTURAL
    (struct
      let prefix = "Is"
      let natural = false
      let is_int = Cint.range
      let is_float = Cfloat.range
      let is_pointer _ = p_true
    end)

let has_ctype = TYPE.is_typ

let has_ltype ltype e =
  match Logic_utils.unroll_type ~unroll_typedef:false ltype with
  | Ctype typ -> has_ctype typ e
  | Ltype _ | Lvar _ | Linteger | Lreal | Larrow _ -> p_true

let is_object obj = function
  | Loc _ -> p_true
  | Val e -> TYPE.is_obj obj e

let cdomain obj =
  if is_constrained_obj obj then Some(TYPE.is_obj obj) else None

let ldomain ltype =
  match Logic_utils.unroll_type ~unroll_typedef:false ltype with
  | Ctype typ -> cdomain (Ctypes.object_of typ)
  | Ltype _ | Lvar _ | Linteger | Lreal | Larrow _ -> None

(* -------------------------------------------------------------------------- *)
(* --- Volatile                                                           --- *)
(* -------------------------------------------------------------------------- *)

let volatile ?warn () =
  Wp_parameters.Volatile.get () ||
  ( Extlib.may
      (fun w -> Warning.emit ~severe:false
          ~effect:"ignore volatile attribute" "%s" w)
      warn ; false )

(* -------------------------------------------------------------------------- *)
(* --- ACSL Equality                                                      --- *)
(* -------------------------------------------------------------------------- *)

let s_eq = ref (fun _ _ _ -> assert false) (* recursion for equal_object *)

let rec reduce_eqcomp = function
  | [a;b] when Lang.F.equal a b -> F.e_true
  | _::ws -> reduce_eqcomp ws
  | [] -> raise Not_found

module EQARRAY = Model.Generator(Matrix.NATURAL)
    (struct
      open Matrix
      type key = matrix
      type data = Lang.lfun
      let name = "Cvalues.EqArray"
      let compile (te,ds) =
        let lfun = Lang.generated_f ~sort:Logic.Sprop "EqArray%s_%s"
            (Matrix.id ds) (Matrix.natural_id te)
        in
        let cluster = Definitions.matrix te in
        let denv = Matrix.denv ds in
        let tau = Matrix.tau te ds in
        let xa = Lang.freshvar ~basename:"T" tau in
        let xb = Lang.freshvar ~basename:"T" tau in
        let ta = e_var xa in
        let tb = e_var xb in
        let ta_xs = List.fold_left e_get ta denv.index_val in
        let tb_xs = List.fold_left e_get tb denv.index_val in
        let property = p_hyps (denv.index_range) (!s_eq te ta_xs tb_xs) in
        let definition = p_forall denv.index_var property in
        (* Definition of the symbol *)
        Definitions.define_symbol {
          d_lfun = lfun ; d_types = 0 ;
          d_params = denv.size_var @ [xa ; xb ] ;
          d_definition = Predicate(Def,definition) ;
          d_cluster = cluster ;
        } ;
        Lang.F.set_builtin lfun reduce_eqcomp ;
        (* Finally return symbol *)
        lfun
    end)

let rec equal_object obj a b =
  match obj with
  | C_int _ | C_float _ | C_pointer _ -> p_equal a b
  | C_array t ->
      equal_array (Matrix.of_array t) a b
  | C_comp c ->
      equal_comp c a b

and equal_typ typ a b = equal_object (Ctypes.object_of typ) a b

and equal_comp c a b =
  Definitions.call_pred
    (Lang.generated_p ("Eq" ^ Lang.comp_id c))
    (fun lfun ->
       let basename = if c.cstruct then "S" else "U" in
       let xa = Lang.freshvar ~basename (Lang.tau_of_comp c) in
       let xb = Lang.freshvar ~basename (Lang.tau_of_comp c) in
       let ra = e_var xa in
       let rb = e_var xb in
       let def = p_all
           (fun f ->
              let fd = Cfield f in
              equal_typ f.ftype
                (e_getfield ra fd) (e_getfield rb fd))
           c.cfields
       in
       Lang.F.set_builtin lfun reduce_eqcomp ;
       {
         d_lfun = lfun ; d_types = 0 ; d_params = [xa;xb] ;
         d_cluster = Definitions.compinfo c ;
         d_definition = Predicate(Def,def) ;
       }
    ) [a;b]

and equal_array m a b =
  match m with
  | _obj , [None] -> p_equal a b
  | _ -> p_call (EQARRAY.get m) (Matrix.size m @ [a;b])

let () = s_eq := equal_object

(* -------------------------------------------------------------------------- *)
(* --- Lifting Values                                                     --- *)
(* -------------------------------------------------------------------------- *)

let map_value f = function
  | Val t -> Val t
  | Loc l -> Loc (f l)

let map_sloc f = function
  | Sloc l -> Sloc (f l)
  | Sarray(l,obj,n) -> Sarray(f l,obj,n)
  | Srange(l,obj,a,b) -> Srange(f l,obj,a,b)
  | Sdescr(xs,l,p) -> Sdescr(xs,f l,p)

let map_logic f = function
  | Vexp t -> Vexp t
  | Vloc l -> Vloc (f l)
  | Vset s -> Vset s
  | Lset ls -> Lset (List.map (map_sloc f) ls)

let plain lt e =
  if Logic_typing.is_set_type lt then
    let te = Logic_typing.type_of_set_elem lt in
    Vset [Vset.Set(tau_of_ltype te,e)]
  else
    Vexp e

(* -------------------------------------------------------------------------- *)
(* --- Int-As-Booleans                                                    --- *)
(* -------------------------------------------------------------------------- *)

let bool_eq a b = e_if (e_eq a b) e_one e_zero
let bool_lt a b = e_if (e_lt a b) e_one e_zero
let bool_neq a b = e_if (e_eq a b) e_zero e_one
let bool_leq a b = e_if (e_leq a b) e_one e_zero
let bool_and a b = e_and [e_neq a e_zero ; e_neq b e_zero]
let bool_or  a b = e_or  [e_neq a e_zero ; e_neq b e_zero]
let bool_val e = e_if e e_one e_zero
let is_true p = e_if (e_prop p) e_one e_zero
let is_false p = e_if (e_prop p) e_zero e_one

(* -------------------------------------------------------------------------- *)
(* --- Lifting Memory Model to Values                                     --- *)
(* -------------------------------------------------------------------------- *)

type polarity = [ `Positive | `Negative | `NoPolarity ]
let negate = function
  | `Positive -> `Negative
  | `Negative -> `Positive
  | `NoPolarity -> `NoPolarity

module Logic(M : Sigs.Model) =
struct

  type logic = M.loc Sigs.logic
  type segment = c_object * M.loc Sigs.sloc
  type region = M.loc Sigs.region

  (* -------------------------------------------------------------------------- *)
  (* --- Projections                                                        --- *)
  (* -------------------------------------------------------------------------- *)

  let value = function
    | Vexp e -> e
    | Vloc l -> M.pointer_val l
    | Vset s -> Vset.concretize s
    | Lset _ -> Warning.error "T-Set of values not yet implemented"

  let loc = function
    | Vloc l -> l
    | Vexp e -> M.pointer_loc e
    | Vset _ -> Warning.error "Set of pointers not yet implemented"
    | Lset _ -> Warning.error "T-Set of regions not yet implemented"

  let rdescr = function
    | Sloc l -> [],l,p_true
    | Sdescr(xs,l,p) -> xs,l,p
    | Sarray(l,obj,n) ->
        let x = Lang.freshvar ~basename:"k" Logic.Int in
        let k = e_var x in
        [x],M.shift l obj k,arange k n
    | Srange(l,obj,a,b) ->
        let x = Lang.freshvar ~basename:"k" Logic.Int in
        let k = e_var x in
        [x],M.shift l obj k,Vset.in_range k a b

  let vset_of_sloc sloc =
    List.map
      (function
        | Sloc p -> Vset.Singleton (M.pointer_val p)
        | u ->
            let xs,l,p = rdescr u in
            Vset.Descr( xs , M.pointer_val l , p )
      ) sloc

  let sloc_of_vset phi vset =
    List.map
      (function
        | Vset.Singleton e -> phi (Sloc (M.pointer_loc e))
        | w ->
            let xs,t,p = Vset.descr w in
            phi (Sdescr(xs,M.pointer_loc t,p))
      ) vset

  let vset = function
    | Vexp v -> Vset.singleton v
    | Vloc l -> Vset.singleton (M.pointer_val l)
    | Vset s -> s
    | Lset sloc -> vset_of_sloc sloc

  let sloc_map phi = function
    | Vexp e -> [phi (Sloc (M.pointer_loc e))]
    | Vloc l -> [phi (Sloc l)]
    | Lset locs -> List.map phi locs
    | Vset vset -> sloc_of_vset phi vset

  let region obj logic = sloc_map (fun s -> obj , s) logic
  let sloc logic = sloc_map (fun s -> s) logic

  (* -------------------------------------------------------------------------- *)
  (* --- Morphisms                                                          --- *)
  (* -------------------------------------------------------------------------- *)

  let is_single = function (Vexp _ | Vloc _) -> true | (Lset _ | Vset _) -> false

  let map_lift f1 f2 a =
    match a with
    | Vexp e -> Vexp (f1 e)
    | Vloc l -> Vexp (f1 (M.pointer_val l))
    | _ -> Vset(f2 (vset a))

  let apply_lift f1 f2 a b =
    if is_single a && is_single b then
      Vexp (f1 (value a) (value b))
    else
      Vset (f2 (vset a) (vset b))

  let map f = map_lift f (Vset.map f)
  let map_opp = map_lift e_opp Vset.map_opp

  let apply f = apply_lift f (Vset.lift f)
  let apply_add = apply_lift e_add Vset.lift_add
  let apply_sub = apply_lift e_sub Vset.lift_sub

  let map_loc f lv =
    if is_single lv then Vloc (f (loc lv))
    else Lset
        (List.map
           (function
             | Sloc l -> Sloc (f l)
             | s -> let xs,l,p = rdescr s in Sdescr(xs,f l,p)
           ) (sloc lv))

  let map_l2t f lv =
    if is_single lv then Vexp (f (loc lv))
    else Vset
        (List.map
           (function
             | Sloc l -> Vset.Singleton (f l)
             | s -> let xs,l,p = rdescr s in Vset.Descr(xs,f l,p)
           ) (sloc lv))

  let map_t2l f sv =
    if is_single sv then Vloc (f (value sv))
    else Lset
        (List.map
           (function
             | Vset.Singleton e -> Sloc (f e)
             | s -> let xs,l,p = Vset.descr s in Sdescr(xs,f l,p)
           ) (vset sv))

  (* -------------------------------------------------------------------------- *)
  (* --- Locations                                                          --- *)
  (* -------------------------------------------------------------------------- *)

  let field lv f = map_loc (fun l -> M.field l f) lv

  let restrict kset = function
    | None -> kset
    | Some s ->
        if Kernel.SafeArrays.get () then
          match kset with
          | Vset.Singleton _ | Vset.Set _ -> kset
          | Vset.Range(a,b) ->
              let cap l = function None -> Some l | u -> u in
              Vset.Range(cap e_zero a,cap (e_int (s-1)) b)
          | Vset.Descr(xs,k,p) ->
              let a = e_zero in
              let b = e_int s in
              Vset.Descr(xs,k,p_conj [p_leq a k;p_lt k b;p])
        else kset

  let is_ainf = function
    | Some e -> e == e_zero
    | None -> false

  let is_asup n = function
    | Some e -> e == e_int (n-1)
    | None -> false

  let srange loc obj size a b =
    match size with
    | None -> Srange(loc,obj,a,b)
    | Some n ->
        if is_ainf a && is_asup n b then
          Sarray(loc,obj,n)
        else
          Srange(loc,obj,a,b)

  let shift_set sloc obj (size : int option) kset =
    match sloc , size , kset with
    | Sloc l , Some n , Vset.Range(None,None) when Kernel.SafeArrays.get () ->
        Sarray(l,obj,n)
    | _ ->
        match sloc , restrict kset size with
        | Sloc l , Vset.Singleton k -> Sloc(M.shift l obj k)
        | Sloc l , Vset.Range(a,b) -> srange l obj size a b
        | Srange(l,obj0,a0,b0) , Vset.Singleton k
          when Ctypes.equal obj0 obj ->
            let a = Vset.bound_add a0 (Some k) in
            let b = Vset.bound_add b0 (Some k) in
            srange l obj0 size a b
        | Srange(l,obj0,a0,b0) , Vset.Range(a1,b1)
          when Ctypes.equal obj0 obj ->
            let a = Vset.bound_add a0 a1 in
            let b = Vset.bound_add b0 b1 in
            srange l obj0 size a b
        | _ ->
            let xs,l,p = rdescr sloc in
            let ys,k,q = Vset.descr kset in
            Sdescr( xs @ ys , M.shift l obj k , p_and p q )

  let shift lv obj ?size kv =
    if is_single kv then
      let k = value kv in map_loc (fun l -> M.shift l obj k) lv
    else
      let ks = vset kv in
      Lset(List.fold_left
             (fun s sloc ->
                List.fold_left
                  (fun s kset ->
                     shift_set sloc obj size kset :: s
                  ) s ks
             ) [] (sloc lv))

  (* -------------------------------------------------------------------------- *)
  (* --- Load in Memory                                                     --- *)
  (* -------------------------------------------------------------------------- *)

  type loader = {
    mutable sloc : M.loc sloc list ;
    mutable vset : Vset.vset list ;
  }

  let flush prefer_loc a = match a with
    | { vset=[] } -> Lset (List.rev a.sloc)
    | { sloc=[] } -> Vset (List.rev a.vset)
    | _ ->
        if prefer_loc then
          Lset (a.sloc @ sloc_of_vset (fun r -> r) a.vset)
        else
          Vset (vset_of_sloc a.sloc @ a.vset)

  let loadsloc a sigma obj = function
    | Sloc l ->
        begin
          match M.load sigma obj l with
          | Val t -> a.vset <- Vset.Singleton t :: a.vset
          | Loc l -> a.sloc <- Sloc l :: a.sloc
        end
    | (Sarray _ | Srange _ | Sdescr _) as s ->
        let xs , l , p = rdescr s in
        begin
          match M.load sigma obj l with
          | Val t -> a.vset <- Vset.Descr(xs,t,p) :: a.vset
          | Loc l -> a.sloc <- Sdescr(xs,l,p) :: a.sloc
        end

  let load sigma obj lv =
    if is_single lv then
      let data = M.load sigma obj (loc lv) in
      Lang.assume (is_object obj data) ;
      match data with
      | Val t -> Vexp t
      | Loc l -> Vloc l
    else
      let a = { vset=[] ; sloc=[] } in
      List.iter (loadsloc a sigma obj) (sloc_map (fun r -> r) lv) ;
      flush (Ctypes.is_pointer obj) a

  let union t vs =
    let a = { vset=[] ; sloc=[] } in
    List.iter
      (function
        | Vexp e -> a.vset <- Vset.Singleton e::a.vset
        | Vloc l -> a.sloc <- Sloc l :: a.sloc
        | Vset s -> a.vset <- List.rev_append s a.vset
        | Lset s -> a.sloc <- List.rev_append s a.sloc
      ) vs ;
    flush (Logic_typing.is_pointer_type t) a

  let inter t vs =
    match List.map (fun v -> Vset.concretize (vset v)) vs with
    | [] ->
        if Logic_typing.is_pointer_type t
        then Lset [] else Vset []
    | v::vs ->
        let s = List.fold_left Vset.inter v vs in
        let t = Lang.tau_of_ltype t in
        Vset [Vset.Set(t,s)]

  (* -------------------------------------------------------------------------- *)
  (* --- Sloc to Rloc                                                       --- *)
  (* -------------------------------------------------------------------------- *)

  let rloc obj = function
    | Sloc l -> Rloc(obj,l)
    | Sarray(l,t,n) -> Rrange(l,t,ainf,asup n)
    | Srange(l,t,a,b) -> Rrange(l,t,a,b)
    | Sdescr _ -> raise Exit

  (* -------------------------------------------------------------------------- *)
  (* --- Separated                                                          --- *)
  (* -------------------------------------------------------------------------- *)

  let separated_region w (r1 : region) (r2 : region) =
    List.fold_left
      (fun w (o1,s1) ->
         List.fold_left
           (fun w (o2,s2) ->
              let cond =
                try M.separated (rloc o1 s1) (rloc o2 s2)
                with Exit ->
                  let xs,l1,p1 = rdescr s1 in
                  let ys,l2,p2 = rdescr s2 in
                  let se1 = Rloc(o1,l1) in
                  let se2 = Rloc(o2,l2) in
                  p_forall (xs@ys) (p_hyps [p1;p2] (M.separated se1 se2))
              in cond::w
           ) w r2
      ) w r1

  let rec separated_from w (r1 : region) = function
    | r2::rs -> separated_from (separated_region w r1 r2) r1 rs
    | [] -> w

  let rec separated_regions w = function
    | r::rs -> separated_regions (separated_from w r rs) rs
    | [] -> w

  let separated (regions : region list) =
    (* forall i<j, (tau_i,R_i)#(tau_j,R_j) *)
    (* forall i<j, forall p in R_j, forall q in R_j, p#q *)
    p_conj (separated_regions [] regions)

  (* -------------------------------------------------------------------------- *)
  (* --- Included                                                           --- *)
  (* -------------------------------------------------------------------------- *)

  let included (obj1,s1) (obj2,s2) =
    try M.included (rloc obj1 s1) (rloc obj2 s2)
    with Exit ->
      let xs,l1,p1 = rdescr s1 in
      let ys,l2,p2 = rdescr s2 in
      let se1 = Rloc(obj1,l1) in
      let se2 = Rloc(obj2,l2) in
      p_forall xs (p_imply p1 (p_exists ys (p_and p2 (M.included se1 se2))))

  (* -------------------------------------------------------------------------- *)
  (* --- Valid                                                              --- *)
  (* -------------------------------------------------------------------------- *)

  let on_sloc phi (obj,sloc) = match sloc with
    | Sloc l -> phi (Rloc(obj,l))
    | Sarray(l,t,n) -> phi (Rrange(l,t,ainf,asup n))
    | Srange(l,t,a,b) -> phi (Rrange(l,t,a,b))
    | Sdescr(xs,l,p) -> p_forall xs (p_imply p (phi (Rloc(obj,l))))

  let valid sigma acs sloc = on_sloc (M.valid sigma acs) sloc
  let invalid sigma sloc = on_sloc (M.invalid sigma) sloc

  (* -------------------------------------------------------------------------- *)
  (* --- Subset                                                             --- *)
  (* -------------------------------------------------------------------------- *)

  let subset ta la tb lb =
    match la , lb with
    | Vexp x , Vexp y -> F.p_equal x y
    | Vexp e , Vset b -> Vset.member e b
    | Vset a , Vexp e -> Vset.subset a [Vset.Singleton e]
    | Vset a , Vset b -> Vset.subset a b
    | Vloc _ , _ | _ , Vloc _
    | Lset _ , _ | _ , Lset _ ->
        let ta = Ctypes.object_of_logic_pointed ta in
        let tb = Ctypes.object_of_logic_pointed tb in
        let ra = List.map (fun s -> ta,s) (sloc la) in
        let rb = List.map (fun s -> tb,s) (sloc lb) in
        p_all (fun s -> p_any (included s) rb) ra

end
