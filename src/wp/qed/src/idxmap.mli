(**************************************************************************)
(*                                                                        *)
(*  This file is part of WP plug-in of Frama-C.                           *)
(*                                                                        *)
(*  Copyright (C) 2007-2012                                               *)
(*    CEA (Commissariat a l'�nergie atomique et aux �nergies              *)
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

(** Map with indexed keys *)

module type S =
sig
  type key
  type 'a t
  val empty : 'a t
  val add : key -> 'a -> 'a t -> 'a t
  val mem : key -> 'a t -> bool
  val find : key -> 'a t -> 'a
  val remove : key -> 'a t -> 'a t
  val iter : (key -> 'a -> unit) -> 'a t -> unit
  val map : (key -> 'a -> 'b) -> 'a t -> 'b t
  val fold : (key -> 'a -> 'b -> 'b) -> 'a t -> 'b -> 'b
  val union : (key -> 'a -> 'a -> 'a) -> 'a t -> 'a t -> 'a t
  val inter : (key -> 'a -> 'a -> 'a) -> 'a t -> 'a t -> 'a t
  val merge : (key -> 'a option -> 'b option -> 'c option) -> 'a t -> 'b t -> 'c t 
end

module type IndexedKey =
sig
  type t
  val id : t -> int (** unique per t *)
end

module Make( K : IndexedKey ) : S with type key = K.t