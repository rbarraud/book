(** Book processing. The book's files are in HTMLBook format with some
    custom variations, e.g. we support <link rel="import"> nodes to
    enable inclusion of code blocks in external files. This module
    supports the processing of these files.
*)
open Core.Std
open Async.Std

(******************************************************************************)
(** {2 <link rel="import"> nodes} *)
(******************************************************************************)
type import = {
  data_code_language : Rwo_code_frag.typ;
  href : string;
  part : int option;
  childs : Rwo_html.item list;
}

val parse_import : Rwo_html.item -> import Or_error.t

val import_to_item : import -> Rwo_html.item


(******************************************************************************)
(** {2 <p></p><pre></pre> sections} *)
(******************************************************************************)
(** An item within a <pre> node*)
type code_item = [
| `Output of string
| `Prompt of string
| `Input of string
| `Data of string
]

(** Guaranteed that `Prompt always followed by `Input. *)
type code_block = private code_item list

(** Parsed <pre> node. *)
type pre = {
  data_type : string;
  data_code_language : string option;
  code_block : code_block;
}

(** Parsed <p> node. Only for <p> nodes occurring immediately before a
    <pre> node. O'Reilly used such nodes to encode some information
    about where the code was imported from, index terms, and for the
    captions of the online version. *)
type p = {
  a_href : string; (** href value in main <a> *)
  a_class : string; (** class value in main <a> *)
  em_data : string; (** data of <em> node under main <a> *)
  data1 : string option; (** data node before main <a> *)
  part : int option; (** part number from data node after main <a> *)
  a2 : Rwo_html.item option; (** 2nd <a> node, i.e. 1st after main <a> *)
  a3 : Rwo_html.item option; (** 3rd <a> node, i.e. 2nd after main <a> *)
}

(** A code section is of the form <p></p><pre></pre>. *)
type code_section = {p:p; pre:pre}

val parse_p_before_pre : Rwo_html.item -> p Or_error.t
val code_items_to_code_block : code_item list -> code_block Or_error.t
val parse_pre : Rwo_html.item -> pre Or_error.t

(** Transform code sections according to [f]. Return error if input
    html doesn't conform to the expected schema for code sections. *)
val map_code_sections
  :  Rwo_html.t
  -> f:(code_section -> Rwo_html.item)
  -> Rwo_html.t Or_error.t

val code_section_to_import : code_section -> import Or_error.t

(** [extract_code_from_1e n] extracts code from chapter [n] of the
    HTMLBook sources provided by O'Reilly for edition 1. All <pre>
    nodes are replaced with <link rel="import"> nodes and extracted
    code is written to external files. Raise exception in case of any
    error. *)
val extract_code_from_1e : int -> unit Deferred.t