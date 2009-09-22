(**************************************************************************)
(*                                                                        *)
(*  This file is part of Frama-C.                                         *)
(*                                                                        *)
(*  Copyright (C) 2007-2009                                               *)
(*    CEA (Commissariat � l'�nergie Atomique)                             *)
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


module F :
  sig
    type t
    val of_float : float -> t
    exception Nan_or_infinite
  end

module Float_abstract :
  sig
    type t 
    type integer = Abstract_interp.Int.t
    exception Nan_or_infinite
    exception Bottom
    val inject : F.t -> F.t -> t
    val top : t
    val add_float : t -> t -> t
    val sub_float : t -> t -> t
    val mult_float : t -> t -> t
    val div_float : t -> t -> t
    val contains_zero : t -> bool 
    val compare : t -> t -> int
    val pretty : Format.formatter -> t -> unit
    val hash : 'a * 'b -> int
    val zero : t
    val rounding_inject : F.t -> F.t -> t
    val is_included : t -> t -> bool
    val join : t -> t -> t
    val meet : t -> t -> t

    val contains_a_zero : t -> bool
    val is_zero : t -> bool
    val is_singleton : t -> bool
    val neg_float : t -> t
    val sqrt_float : t -> t
    val minus_one_one : t
    val cos_float : t -> t
    val widen : t -> t -> t
    val equal_float_ieee : t -> t -> bool * bool
    val maybe_le_ieee_float : t -> t -> bool
    val maybe_lt_ieee_float : t -> t -> bool
    val diff : t -> t -> t
    val filter_le : t -> t -> t
    val filter_ge : t -> t -> t
    val filter_lt : t -> t -> t
    val filter_gt : t -> t -> t
  end


module O :
  sig
    type elt = Abstract_interp.Int.t
    type t (*=
        Abstract_interp.Make_Lattice_Mod(Abstract_interp.Int)(N)(Float_abstract).O.t*)
    val empty : t
    val is_empty : t -> bool
    val mem : elt -> t -> bool
    val add : elt -> t -> t
    val singleton : elt -> t
    val remove : elt -> t -> t
    val union : t -> t -> t
    val inter : t -> t -> t
    val diff : t -> t -> t
    val compare : t -> t -> int
    val equal : t -> t -> bool
    val subset : t -> t -> bool
    val iter : (elt -> unit) -> t -> unit
    val fold : (elt -> 'a -> 'a) -> t -> 'a -> 'a
    val for_all : (elt -> bool) -> t -> bool
    val exists : (elt -> bool) -> t -> bool
    val filter : (elt -> bool) -> t -> t
    val partition : (elt -> bool) -> t -> t * t
    val cardinal : t -> int
    val elements : t -> elt list
    val min_elt : t -> elt
    val max_elt : t -> elt
    val choose : t -> elt
    val split : elt -> t -> t * bool * t
  end
type tt =
 (* Abstract_interp.Make_Lattice_Mod(Abstract_interp.Int)(N)(Float_abstract).tt =*)
    Set of O.t
  | Float of Float_abstract.t
  | Top of Abstract_interp.Int.t option * Abstract_interp.Int.t option *
      Abstract_interp.Int.t * Abstract_interp.Int.t
module Widen_Hints :
  sig
    module V :
      sig
        type t = Abstract_interp.Int.t
        val pretty : Format.formatter -> t -> unit
        val compare : t -> t -> int
        val hash : t -> int
	module Datatype : Project.Datatype.S with type t = t
        val gt : t -> t -> bool
        val le : t -> t -> bool
        val ge : t -> t -> bool
        val lt : t -> t -> bool
        val eq : t -> t -> bool
        val add : t -> t -> t
        val sub : t -> t -> t
        val mul : t -> t -> t
        val native_div : t -> t -> t
        val rem : t -> t -> t
        val pos_div : t -> t -> t
        val c_div : t -> t -> t
        val c_rem : t -> t -> t
        val cast : size:t -> signed:bool -> value:t -> t
        val abs : t -> t
        val zero : t
        val one : t
        val two : t
        val four : t
        val minus_one : t
        val is_zero : t -> bool
        val is_one : t -> bool
        val equal : t -> t -> bool
        val pgcd : t -> t -> t
        val ppcm : t -> t -> t
        val min : t -> t -> t
        val max : t -> t -> t
        val length : t -> t -> t
        val of_int : int -> t
        val of_float : float -> t
        val of_int64 : Int64.t -> t
        val to_int : t -> int
        val to_float : t -> float
        val neg : t -> t
        val succ : t -> t
        val pred : t -> t
        val round_up_to_r : min:t -> r:t -> modu:t -> t
        val round_down_to_r : max:t -> r:t -> modu:t -> t
        val pos_rem : t -> t -> t
        val shift_left : t -> t -> t
        val shift_right : t -> t -> t
        val fold : (t -> 'a -> 'a) -> inf:t -> sup:t -> step:t -> 'a -> 'a
        val logand : t -> t -> t
        val logor : t -> t -> t
        val logxor : t -> t -> t
        val lognot : t -> t
        val power_two : int -> t
        val two_power : t -> t
        val extract_bits :
          with_alarms:CilE.warn_mode -> start:t -> stop:t -> t -> t
      end
    type elt = V.t
    type t (*=
        Abstract_interp.Make_Lattice_Mod(Abstract_interp.Int)(N)(Float_abstract).Widen_Hints.t *)
    val empty : t
    val is_empty : t -> bool
    val mem : elt -> t -> bool
    val add : elt -> t -> t
    val singleton : elt -> t
    val remove : elt -> t -> t
    val union : t -> t -> t
    val inter : t -> t -> t
    val diff : t -> t -> t
    val compare : t -> t -> int
    val equal : t -> t -> bool
    val subset : t -> t -> bool
    val iter : (elt -> unit) -> t -> unit
    val fold : (elt -> 'a -> 'a) -> t -> 'a -> 'a
    val for_all : (elt -> bool) -> t -> bool
    val exists : (elt -> bool) -> t -> bool
    val filter : (elt -> bool) -> t -> t
    val partition : (elt -> bool) -> t -> t * t
    val cardinal : t -> int
    val elements : t -> elt list
    val min_elt : t -> elt
    val max_elt : t -> elt
    val choose : t -> elt
    val split : elt -> t -> t * bool * t
    val nearest_elt_le : elt -> t -> elt
    val nearest_elt_ge : elt -> t -> elt
    val default_widen_hints : t
  end
exception Error_Top
exception Error_Bottom
type t = tt
type widen_hint = Widen_Hints.t
val join : t -> t -> t
val link : t -> t -> t
val meet : t -> t -> t
val narrow : t -> t -> t
val bottom : t
val top : t
val is_included : t -> t -> bool
val is_included_exn : t -> t -> unit
val intersects : t -> t -> bool
val pretty : Format.formatter -> t -> unit
val widen : widen_hint -> t -> t -> t
module Datatype : Project.Datatype.S with type t = t
val hash : t -> int
val equal : t -> t -> bool
val fold_enum : split_non_enumerable:int -> (t -> 'a -> 'a) -> t -> 'a -> 'a
val diff : t -> t -> t
val diff_if_one : t -> t -> t
val add : t -> t -> t
val neg : t -> t
val sub : t -> t -> t

val min_int : t -> Abstract_interp.Int.t option
(** A [None] result means the argument is unbounded. *)
val max_int : t -> Abstract_interp.Int.t option
(** A [None] result means the argument is unbounded. *)

val min_and_max :
  t -> Abstract_interp.Int.t option * Abstract_interp.Int.t option
val bitwise_and : size:int -> t -> t -> t
val bitwise_or : size:int -> t -> t -> t

val inject_range :
  Abstract_interp.Int.t option -> Abstract_interp.Int.t option -> t
  (** [None] means unbounded. The interval is inclusive. *)

val all_positives : Abstract_interp.Int.t option -> bool
val all_negatives : Abstract_interp.Int.t option -> bool
val cardinal_zero_or_one : t -> bool
val is_singleton_int : t -> bool
val inject_singleton : Abstract_interp.Int.t -> t
val zero : t
val one : t
val compare_min_float : t -> t -> int
val compare_max_float : t -> t -> int
val is_zero : t -> bool
val is_one : t -> bool
val inject_float : Float_abstract.t -> t
val top_float : t
val project_float : t -> Float_abstract.t
    (** @raise F.Nan_or_infinite when the float is Nan or infinite. *)

val in_interval :
  Abstract_interp.Int.t ->
  Abstract_interp.Int.t option ->
  Abstract_interp.Int.t option ->
  Abstract_interp.Int.t -> Abstract_interp.Int.t -> bool
val contains_zero : t -> bool
exception Not_Singleton_Int
val project_int : t -> Abstract_interp.Int.t
    (** @raise Not_Singleton_Int when the cardinal of the argument is not 1. *)
val cardinal_less_than : t -> int -> int
(** [cardinal_less_than t n] returns the cardinal of [t] is this cardinal
    is at most [n].
    @raise Abstract_interp.Not_less_than is the cardinal of [t]
    is more than [n] *)

val splitting_cardinal_less_than: split_non_enumerable:int -> t -> int -> int

val inject_top :
  Abstract_interp.Int.t option ->
  Abstract_interp.Int.t option ->
  Abstract_interp.Int.t -> Abstract_interp.Int.t -> t
(** [inject_top min max r m] returns the smallest lattice element that
    contains all integers equal to [r] modulo [m] between [min] and
    [max]. [None] means unbounded. *)

val fold : (Abstract_interp.Int.t -> 'a -> 'a) -> t -> 'a -> 'a
exception Apply_Set_Exn of exn
val apply_set :
  string ->
  (Abstract_interp.Int.t -> Abstract_interp.Int.t -> Abstract_interp.Int.t) ->
  t -> t -> t
val apply_set_unary :
  'a -> (Abstract_interp.Int.t -> Abstract_interp.Int.t) -> t -> t
val singleton_zero : t
(** The lattice element that contains only the integer zero. *)
val singleton_one : t
(** The lattice element that contains only the integer one. *)
val zero_or_one : t
(** The lattice element that contains only the integers zero and one. *)
val contains_non_zero : t -> bool
val subdiv_float_interval : t -> t * t
val scale : Abstract_interp.Int.t -> t -> t
val scale_div : pos:bool -> Abstract_interp.Int.t -> t -> t
val negative : t
val div : t -> t -> t
val scale_rem : pos:bool -> Abstract_interp.Int.t -> t -> t
val c_rem : t -> t -> t
val mul : t -> t -> t
val shift_left : size:Abstract_interp.Int.t -> t -> t -> t
val shift_right : size:Abstract_interp.Int.t -> t -> t -> t
val interp_boolean : contains_zero:bool -> contains_non_zero:bool -> t


val filter_set : (int -> bool) -> Abstract_interp.Int.t -> O.t -> t
(** return the smallest lattice element that contains the elements of [s]
   that are in relation [f] ([<=],[>=],...) to [bound] *)

val extract_bits :
  with_alarms:CilE.warn_mode ->
  start:Abstract_interp.Int.t -> stop:Abstract_interp.Int.t -> t -> t
val create_all_values : 
  modu:Abstract_interp.Int.t -> signed:bool -> size:int -> t
val all_values : size:Abstract_interp.Int.t -> t -> bool
val filter_le_int : Abstract_interp.Int.t option -> t -> t
val filter_ge_int : Abstract_interp.Int.t option -> t -> t
val filter_lt_int : Abstract_interp.Int.t option -> t -> t
val filter_gt_int : Abstract_interp.Int.t option -> t -> t
val filter_le : t -> t -> t
val filter_ge : t -> t -> t
val filter_lt : t -> t -> t
val filter_gt : t -> t -> t
val filter_le_float : t -> t -> t
val filter_ge_float : t -> t -> t
val filter_lt_float : t -> t -> t
val filter_gt_float : t -> t -> t
val compare_C :
  (Abstract_interp.Int.t option ->
   Abstract_interp.Int.t option ->
   Abstract_interp.Int.t option -> Abstract_interp.Int.t option -> 'a) ->
  t -> t -> 'a
val max_max :
  Abstract_interp.Int.t option ->
  Abstract_interp.Int.t option -> Abstract_interp.Int.t option
val scale_int64base : Int_Base.tt -> t -> t
val cast_float_to_int : Float_abstract.t -> t
val of_int : int -> t
val of_int64 : int64 -> t
val cast_int_to_float : t -> t
val cast : size:Abstract_interp.Int.t -> signed:bool -> value:t -> t
val tag : t -> int
val pretty_debug : Format.formatter -> t -> unit
val name : string
