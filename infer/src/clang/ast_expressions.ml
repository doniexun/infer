(*
 * Copyright (c) 2013 - present Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *)

open! Utils

open CFrontend_utils

(** This module creates extra ast constructs that are needed for the translation *)

let dummy_source_range () =
  let dummy_source_loc = {
    Clang_ast_t.sl_file = None;
    sl_line = None;
    sl_column = None;
  } in
  (dummy_source_loc, dummy_source_loc)

let dummy_stmt_info () = {
  Clang_ast_t.si_pointer = Ast_utils.get_fresh_pointer ();
  si_source_range = dummy_source_range ();
}

(* given a stmt_info return the same stmt_info with a fresh pointer *)
let fresh_stmt_info stmt_info =
  { stmt_info with Clang_ast_t.si_pointer = Ast_utils.get_fresh_pointer () }

let fresh_decl_info decl_info =
  { decl_info with Clang_ast_t.di_pointer = Ast_utils.get_fresh_pointer () }

let empty_decl_info = {
  Clang_ast_t.di_pointer = Ast_utils.get_invalid_pointer ();
  di_parent_pointer = None;
  di_previous_decl = `None;
  di_source_range = dummy_source_range ();
  di_owning_module = None;
  di_is_hidden = false;
  di_is_implicit = false;
  di_is_used = true;
  di_is_this_declaration_referenced = true;
  di_is_invalid_decl = false;
  di_attributes = [];
  di_full_comment = None;
}

let empty_var_decl_info = {
  Clang_ast_t.vdi_storage_class = None;
  vdi_tls_kind =`Tls_none;
  vdi_is_global = false;
  vdi_is_static_local = false;
  vdi_is_module_private = false;
  vdi_is_nrvo_variable = false;
  vdi_is_const_expr = false;
  vdi_init_expr = None;
  vdi_parm_index_in_function = None;
}

let stmt_info_with_fresh_pointer stmt_info = {
  Clang_ast_t.si_pointer = Ast_utils.get_fresh_pointer ();
  si_source_range = stmt_info.Clang_ast_t.si_source_range;
}

let new_constant_type_ptr () =
  let pointer = Ast_utils.get_fresh_pointer () in
  `Prebuilt pointer

(* Whenever new type are added manually to the translation here, *)
(* they should be added to the map in cTypes_decl too!! *)
let create_int_type =
  new_constant_type_ptr ()

let create_void_type =
  new_constant_type_ptr ()

let create_void_star_type =
  new_constant_type_ptr ()

let create_id_type =
  new_constant_type_ptr ()

let create_nsarray_star_type =
  new_constant_type_ptr ()

let create_char_type =
  new_constant_type_ptr ()

let create_char_star_type =
  new_constant_type_ptr ()

let create_BOOL_type =
  new_constant_type_ptr ()

let create_unsigned_long_type =
  new_constant_type_ptr ()

let create_void_unsigned_long_type =
  new_constant_type_ptr ()

let create_void_void_type =
  new_constant_type_ptr ()

let create_class_type class_info = `ClassType class_info

let create_struct_type struct_name = `StructType struct_name

let create_pointer_type typ = `PointerOf typ

let create_reference_type typ = `ReferenceOf typ

let create_integer_literal n =
  let stmt_info = dummy_stmt_info () in
  let expr_info = {
    Clang_ast_t.ei_type_ptr = create_int_type;
    ei_value_kind = `RValue;
    ei_object_kind = `Ordinary;
  } in
  let integer_literal_info = {
    Clang_ast_t.ili_is_signed = true;
    ili_bitwidth = 32;
    ili_value = n;
  } in
  Clang_ast_t.IntegerLiteral (stmt_info, [], expr_info, integer_literal_info)

let create_cstyle_cast_expr stmt_info stmts tp =
  let expr_info = {
    Clang_ast_t.ei_type_ptr = create_void_star_type;
    ei_value_kind = `RValue;
    ei_object_kind = `Ordinary;
  } in
  let cast_expr = {
    Clang_ast_t.cei_cast_kind = `NullToPointer;
    cei_base_path = [];
  } in
  Clang_ast_t.CStyleCastExpr (stmt_info, stmts, expr_info, cast_expr, tp)

let create_parent_expr stmt_info stmts =
  let expr_info = {
    Clang_ast_t.ei_type_ptr = create_void_star_type;
    ei_value_kind = `RValue;
    ei_object_kind = `Ordinary;
  } in
  Clang_ast_t.ParenExpr (stmt_info, stmts, expr_info)

let create_implicit_cast_expr stmt_info stmts typ cast_kind =
  let expr_info = {
    Clang_ast_t.ei_type_ptr = typ;
    ei_value_kind = `RValue;
    ei_object_kind = `Ordinary;
  } in
  let cast_expr_info = {
    Clang_ast_t.cei_cast_kind = cast_kind;
    cei_base_path = [];
  } in
  Clang_ast_t.ImplicitCastExpr (stmt_info, stmts, expr_info, cast_expr_info)

let create_nil stmt_info =
  let integer_literal = create_integer_literal "0" in
  let cstyle_cast_expr = create_cstyle_cast_expr stmt_info [integer_literal] create_int_type in
  let paren_expr = create_parent_expr stmt_info [cstyle_cast_expr] in
  create_implicit_cast_expr stmt_info [paren_expr] create_id_type `NullToPointer

let dummy_stmt () =
  let pointer = Ast_utils.get_fresh_pointer () in
  let source_range = dummy_source_range () in
  Clang_ast_t.NullStmt({ Clang_ast_t.si_pointer = pointer; si_source_range = source_range } ,[])

let make_stmt_info di = {
  Clang_ast_t.si_pointer = di.Clang_ast_t.di_pointer;
  si_source_range = di.Clang_ast_t.di_source_range;
}

let make_expr_info tp vk objc_kind = {
  Clang_ast_t.ei_type_ptr = tp;
  ei_value_kind = vk;
  ei_object_kind = objc_kind;
}

let make_expr_info_with_objc_kind tp objc_kind =
  make_expr_info tp `LValue objc_kind

let make_decl_ref_exp stmt_info expr_info drei =
  let stmt_info = {
    Clang_ast_t.si_pointer = Ast_utils.get_fresh_pointer ();
    si_source_range = stmt_info.Clang_ast_t.si_source_range
  } in
  Clang_ast_t.DeclRefExpr(stmt_info, [], expr_info, drei)

let make_obj_c_message_expr_info_instance sel = {
  Clang_ast_t.omei_selector = sel;
  omei_receiver_kind = `Instance;
  omei_is_definition_found = false;
  omei_decl_pointer = None; (* TODO look into it *)
}

let make_obj_c_message_expr_info_class selector tp pointer = {
  Clang_ast_t.omei_selector = selector;
  omei_receiver_kind = `Class (create_class_type (tp, `OBJC));
  omei_is_definition_found = false;
  omei_decl_pointer = pointer
}

let make_decl_ref k decl_ptr name is_hidden tp_opt = {
  Clang_ast_t.dr_kind = k;
  dr_decl_pointer = decl_ptr;
  dr_name = Some name;
  dr_is_hidden = is_hidden ;
  dr_type_ptr = tp_opt
}

let make_decl_ref_tp k decl_ptr name is_hidden tp =
  make_decl_ref k decl_ptr name is_hidden (Some tp)

let make_decl_ref_no_tp k decl_ptr name is_hidden =
  make_decl_ref k decl_ptr name is_hidden None

let make_decl_ref_invalid k name is_hidden tp =
  make_decl_ref k (Ast_utils.get_invalid_pointer ()) name is_hidden (Some tp)

let make_decl_ref_expr_info decl_ref = {
  Clang_ast_t.drti_decl_ref = Some decl_ref;
  drti_found_decl_ref = None;
}

let make_objc_ivar_decl decl_info tp ivar_name =
  let field_decl_info = {
    Clang_ast_t.fldi_is_mutable = true;
    fldi_is_module_private = true;
    fldi_init_expr = None;
    fldi_bit_width_expr = None;
  } in
  let obj_c_ivar_decl_info = {
    Clang_ast_t.ovdi_is_synthesize = true; (* NOTE: We set true here because we use this definition to synthesize the getter/setter*)
    ovdi_access_control = `Private;
  } in
  Clang_ast_t.ObjCIvarDecl(decl_info, ivar_name, tp, field_decl_info, obj_c_ivar_decl_info)

let make_expr_info tp = {
  Clang_ast_t.ei_type_ptr = tp;
  ei_value_kind = `LValue;
  ei_object_kind = `ObjCProperty
}

let make_general_expr_info tp vk ok = {
  Clang_ast_t.ei_type_ptr = tp;
  ei_value_kind = vk;
  ei_object_kind = ok
}

let make_ObjCBoolLiteralExpr stmt_info value =
  let ei = make_expr_info create_BOOL_type in
  Clang_ast_t.ObjCBoolLiteralExpr((fresh_stmt_info stmt_info),[], ei, value)

let make_message_expr param_tp selector decl_ref_exp stmt_info add_cast =
  let stmt_info = stmt_info_with_fresh_pointer stmt_info in
  let parameters =
    if add_cast then
      let cast_expr = create_implicit_cast_expr stmt_info [decl_ref_exp] param_tp `LValueToRValue in
      [cast_expr]
    else [decl_ref_exp] in
  let obj_c_message_expr_info = make_obj_c_message_expr_info_instance selector in
  let expr_info = make_expr_info_with_objc_kind param_tp `ObjCProperty in
  Clang_ast_t.ObjCMessageExpr (stmt_info, parameters, expr_info, obj_c_message_expr_info)

let make_binary_stmt stmt1 stmt2 stmt_info expr_info boi =
  let stmt_info = stmt_info_with_fresh_pointer stmt_info in
  Clang_ast_t.BinaryOperator(stmt_info, [stmt1; stmt2], expr_info, boi)

let make_next_object_exp stmt_info item items =
  let var_decl_ref, var_type =
    match item with
    | Clang_ast_t.DeclStmt (_, _, [Clang_ast_t.VarDecl(di, name_info, var_type, _)]) ->
        let decl_ptr = di.Clang_ast_t.di_pointer in
        let decl_ref = make_decl_ref_tp `Var decl_ptr name_info false var_type in
        let stmt_info_var = {
          Clang_ast_t.si_pointer = di.Clang_ast_t.di_pointer;
          si_source_range = di.Clang_ast_t.di_source_range
        } in
        let expr_info = make_expr_info_with_objc_kind var_type `ObjCProperty in
        let decl_ref_expr_info = make_decl_ref_expr_info decl_ref in
        Clang_ast_t.DeclRefExpr (stmt_info_var, [], expr_info, decl_ref_expr_info),
        var_type
    | _ -> assert false in
  let message_call = make_message_expr create_id_type
      CFrontend_config.next_object items stmt_info false in
  let boi = { Clang_ast_t.boi_kind = `Assign } in
  let expr_info = make_expr_info_with_objc_kind var_type `ObjCProperty in
  let assignment = make_binary_stmt var_decl_ref message_call stmt_info expr_info boi in
  let boi' = { Clang_ast_t.boi_kind = `NE } in
  let cast = create_implicit_cast_expr stmt_info [var_decl_ref] var_type `LValueToRValue in
  let nil_exp = create_nil stmt_info in
  let loop_cond = make_binary_stmt cast nil_exp stmt_info expr_info boi' in
  assignment, loop_cond

(* 1. dispatch_once(v,block_def) is transformed as: block_def() *)
(* 2. dispatch_once(v,block_var) is transformed as n$1 = *&block_var; n$2=n$1() *)
let translate_dispatch_function stmt_info stmt_list n =
  let open Clang_ast_t in
  match stmt_list with
  | _:: args_stmts ->
      let expr_info_call = make_general_expr_info create_void_star_type `XValue `Ordinary in
      let arg_stmt = try IList.nth args_stmts n with Failure _ -> assert false in
      CallExpr (stmt_info, [arg_stmt], expr_info_call)
  | _ -> assert false

(* Create declaration statement: tp vname = iexp *)
let make_DeclStmt stmt_info di tp vname old_vdi iexp =
  let init_expr_opt, init_expr_l = match iexp with
    | Some iexp' ->
        let ie = create_implicit_cast_expr stmt_info [iexp'] tp `IntegralCast in
        Some ie, [ie]
    | None -> None, [] in
  let var_decl_info = { old_vdi with Clang_ast_t.vdi_init_expr = init_expr_opt } in
  let di = fresh_decl_info di in
  let var_decl = Clang_ast_t.VarDecl (di, vname, tp, var_decl_info) in
  Clang_ast_t.DeclStmt (stmt_info, init_expr_l, [var_decl])

let build_OpaqueValueExpr si source_expr ei =
  let opaque_value_expr_info = { Clang_ast_t.ovei_source_expr = Some source_expr } in
  Clang_ast_t.OpaqueValueExpr (si, [], ei, opaque_value_expr_info)

let pseudo_object_tp () = create_class_type (CFrontend_config.pseudo_object_type, `OBJC)

(* Create expression PseudoObjectExpr for 'o.m' *)
let build_PseudoObjectExpr tp_m o_cast_decl_ref_exp mname =
  match o_cast_decl_ref_exp with
  | Clang_ast_t.ImplicitCastExpr (si, _, ei, _) ->
      let ove = build_OpaqueValueExpr si o_cast_decl_ref_exp ei in
      let ei_opre = make_expr_info (pseudo_object_tp ()) in
      let count_name = Ast_utils.make_name_decl CFrontend_config.count in
      let pointer = si.Clang_ast_t.si_pointer in
      let obj_c_property_ref_expr_info = {
        Clang_ast_t.oprei_kind =
          `PropertyRef (make_decl_ref_no_tp `ObjCProperty pointer count_name false);
        oprei_is_super_receiver = false;
        oprei_is_messaging_getter = true;
        oprei_is_messaging_setter = false;
      } in
      let opre = Clang_ast_t.ObjCPropertyRefExpr (si, [ove], ei_opre, obj_c_property_ref_expr_info) in
      let ome = make_message_expr tp_m mname o_cast_decl_ref_exp si false in
      let poe_ei = make_general_expr_info tp_m `LValue `Ordinary in
      Clang_ast_t.PseudoObjectExpr (si, [opre; ove; ome], poe_ei)
  | _ -> assert false

let create_call stmt_info decl_pointer function_name tp parameters =
  let expr_info_call = {
    Clang_ast_t.ei_type_ptr = create_void_star_type;
    ei_value_kind = `XValue;
    ei_object_kind = `Ordinary
  } in
  let expr_info_dre = make_expr_info_with_objc_kind tp `Ordinary in
  let decl_ref = make_decl_ref_tp `Function decl_pointer function_name false tp in
  let decl_ref_info = make_decl_ref_expr_info decl_ref in
  let decl_ref_exp = Clang_ast_t.DeclRefExpr (stmt_info, [], expr_info_dre, decl_ref_info) in
  let cast = create_implicit_cast_expr (fresh_stmt_info stmt_info) [decl_ref_exp] tp `FunctionToPointerDecay in
  Clang_ast_t.CallExpr (stmt_info, cast:: parameters, expr_info_call)

(* For a of type NSArray* Translate
   [a enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL * stop) {
      body_block
     };
   ];

   as follows:

    NSArray *objects = a;
    void (^enumerateObjectsUsingBlock)(id, NSUInteger, BOOL* ) =
      ^(id object, NSUInteger idx, BOOL* stop) {
         body_block
     };
     BOOL *stop = malloc(sizeof(BOOL));
     *stop = NO;

     for (NSUInteger idx=0; idx<objects.count; idx++) {
         id object= objects[idx];
         enumerateObjectsUsingBlock(object, idx, stop);
         if ( *stop ==YES) break;
     }
     free(stop);
*)
let translate_block_enumerate block_name stmt_info stmt_list ei =

  let rec get_name_pointers lp =
    match lp with
    | [] -> []
    | Clang_ast_t.ParmVarDecl (di, name, tp, _) :: lp' ->
        (name.Clang_ast_t.ni_name, di.Clang_ast_t.di_pointer, tp):: get_name_pointers lp'
    | _ -> assert false in

  let build_idx_decl pidx =
    match pidx with
    | Clang_ast_t.ParmVarDecl (di_idx, name_idx, tp_idx, vdi) ->
        let zero = create_integer_literal "0" in
        (* tp_idx idx = 0; *)
        let idx_decl_stmt = make_DeclStmt (fresh_stmt_info stmt_info) di_idx tp_idx
            name_idx vdi (Some zero) in
        let idx_ei = make_expr_info tp_idx in
        let pointer = di_idx.Clang_ast_t.di_pointer in
        let idx_decl_ref = make_decl_ref_tp `Var pointer name_idx false tp_idx in
        let idx_drei = make_decl_ref_expr_info idx_decl_ref in
        let idx_decl_ref_exp = make_decl_ref_exp stmt_info idx_ei idx_drei in
        let idx_cast = create_implicit_cast_expr (fresh_stmt_info stmt_info) [idx_decl_ref_exp]
            tp_idx `LValueToRValue in
        idx_decl_stmt, idx_decl_ref_exp, idx_cast, tp_idx
    | _ -> assert false in

  let cast_expr decl_ref tp =
    let ei = make_expr_info tp in
    let drei = make_decl_ref_expr_info decl_ref in
    let decl_ref_exp = make_decl_ref_exp (fresh_stmt_info stmt_info) ei drei in
    create_implicit_cast_expr (fresh_stmt_info stmt_info) [decl_ref_exp] tp `LValueToRValue in

  (* build statement BOOL *stop = malloc(sizeof(BOOL)); *)
  let build_stop pstop =
    match pstop with
    | Clang_ast_t.ParmVarDecl (di, name, tp, vdi) ->
        let tp_fun = create_void_unsigned_long_type in
        let type_opt = Some create_BOOL_type in
        let parameter = Clang_ast_t.UnaryExprOrTypeTraitExpr
            ((fresh_stmt_info stmt_info), [],
             make_general_expr_info create_unsigned_long_type `RValue `Ordinary,
             { Clang_ast_t.uttei_kind = `SizeOf; Clang_ast_t.uttei_type_ptr = type_opt}) in
        let pointer = di.Clang_ast_t.di_pointer in
        let stmt_info = fresh_stmt_info stmt_info in
        let malloc_name = Ast_utils.make_name_decl CFrontend_config.malloc in
        let malloc = create_call stmt_info pointer malloc_name tp_fun [parameter] in
        let init_exp = create_implicit_cast_expr (fresh_stmt_info stmt_info) [malloc] tp `BitCast in
        make_DeclStmt (fresh_stmt_info stmt_info) di tp name vdi (Some init_exp)
    | _ -> assert false in

  (* BOOL *stop =NO; *)
  let stop_equal_no pstop =
    match pstop with
    | Clang_ast_t.ParmVarDecl (di, name, tp, _) ->
        let decl_ref = make_decl_ref_tp `Var di.Clang_ast_t.di_pointer name false tp in
        let cast = cast_expr decl_ref tp in
        let postfix_deref = { Clang_ast_t.uoi_kind = `Deref; uoi_is_postfix = true } in
        let lhs = Clang_ast_t.UnaryOperator (fresh_stmt_info stmt_info, [cast], ei, postfix_deref) in
        let bool_NO = make_ObjCBoolLiteralExpr stmt_info 0 in
        let assign = { Clang_ast_t.boi_kind = `Assign } in
        Clang_ast_t.BinaryOperator (fresh_stmt_info stmt_info, [lhs; bool_NO], ei, assign)
    | _ -> assert false in

  (* build statement free(stop); *)
  let free_stop pstop =
    match pstop with
    | Clang_ast_t.ParmVarDecl (di, name, tp, _) ->
        let tp_fun = create_void_void_type in
        let decl_ref = make_decl_ref_tp `Var di.Clang_ast_t.di_pointer name false tp in
        let cast = cast_expr decl_ref tp in
        let free_name = Ast_utils.make_name_decl CFrontend_config.free in
        let parameter =
          create_implicit_cast_expr (fresh_stmt_info stmt_info) [cast] create_void_star_type `BitCast in
        let pointer = di.Clang_ast_t.di_pointer in
        create_call (fresh_stmt_info stmt_info) pointer free_name tp_fun [parameter]
    | _ -> assert false in

  (* idx<a.count *)
  let bin_op pidx array_decl_ref_exp =
    let _, _, idx_cast, idx_tp = build_idx_decl pidx in
    let rhs = build_PseudoObjectExpr idx_tp array_decl_ref_exp CFrontend_config.count in
    let lt = { Clang_ast_t.boi_kind = `LT } in
    let exp_info = make_expr_info create_int_type in
    Clang_ast_t.BinaryOperator (fresh_stmt_info stmt_info, [idx_cast; rhs], exp_info, lt) in

  (*  idx++ *)
  let un_op idx_decl_ref_expr tp_idx =
    let idx_ei = make_expr_info tp_idx in
    let postinc = { Clang_ast_t.uoi_kind = `PostInc; uoi_is_postfix = true } in
    Clang_ast_t.UnaryOperator (fresh_stmt_info stmt_info, [idx_decl_ref_expr], idx_ei, postinc) in

  let get_ei_from_cast cast =
    match cast with
    | Clang_ast_t.ImplicitCastExpr (_, _, ei, _) -> ei
    | _ -> assert false in

  (* id object = objects[idx]; *)
  let build_object_DeclStmt pobj decl_ref_expr_array decl_ref_expr_idx =
    let open Clang_ast_t in
    match pobj with
    | ParmVarDecl(di_obj, name_obj, tp_obj, _) ->
        let poe_ei = make_general_expr_info tp_obj `RValue `Ordinary in
        let ei_array = get_ei_from_cast decl_ref_expr_array in
        let ove_array = build_OpaqueValueExpr (fresh_stmt_info stmt_info) decl_ref_expr_array ei_array in
        let ei_idx = get_ei_from_cast decl_ref_expr_idx in
        let ove_idx = build_OpaqueValueExpr (fresh_stmt_info stmt_info) decl_ref_expr_idx ei_idx in
        let objc_sre = ObjCSubscriptRefExpr (fresh_stmt_info stmt_info, [ove_array; ove_idx],
                                             make_expr_info (pseudo_object_tp ()),
                                             { osrei_kind =`ArraySubscript; osrei_getter = None; osrei_setter = None; }) in
        let obj_c_message_expr_info = make_obj_c_message_expr_info_instance CFrontend_config.object_at_indexed_subscript_m in
        let ome = ObjCMessageExpr (fresh_stmt_info stmt_info, [ove_array; ove_idx], poe_ei, obj_c_message_expr_info) in
        let pseudo_obj_expr = PseudoObjectExpr (fresh_stmt_info stmt_info, [objc_sre; ove_array; ove_idx; ome], poe_ei) in
        let vdi = { empty_var_decl_info with vdi_init_expr = Some (pseudo_obj_expr) } in
        let var_decl = VarDecl (di_obj, name_obj, tp_obj, vdi) in
        DeclStmt (fresh_stmt_info stmt_info, [pseudo_obj_expr], [var_decl])
    | _ -> assert false in

  (* NSArray *objects = a *)
  let objects_array_DeclStmt init =
    let di = { empty_decl_info with Clang_ast_t.di_pointer = Ast_utils.get_fresh_pointer () } in
    let tp = create_pointer_type (create_class_type (CFrontend_config.nsarray_cl, `OBJC)) in
    (* init should be ImplicitCastExpr of array a *)
    let vdi = { empty_var_decl_info with Clang_ast_t.vdi_init_expr = Some (init) } in
    let objects_name = Ast_utils.make_name_decl CFrontend_config.objects in
    let var_decl = Clang_ast_t.VarDecl (di, objects_name, tp, vdi) in
    Clang_ast_t.DeclStmt (fresh_stmt_info stmt_info, [init], [var_decl]), [(CFrontend_config.objects, di.Clang_ast_t.di_pointer, tp)] in

  let make_object_cast_decl_ref_expr objects =
    match objects with
    | Clang_ast_t.DeclStmt (si, _, [Clang_ast_t.VarDecl (_, name, tp, _)]) ->
        let decl_ref = make_decl_ref_tp `Var si.Clang_ast_t.si_pointer name false tp in
        cast_expr decl_ref tp
    | _ -> assert false in

  let build_cast_decl_ref_expr_from_parm p =
    match p with
    | Clang_ast_t.ParmVarDecl (di, name, tp, _) ->
        let decl_ref = make_decl_ref_tp `Var di.Clang_ast_t.di_pointer name false tp in
        cast_expr decl_ref tp
    | _ -> assert false in

  let qual_block_name = Ast_utils.make_name_decl block_name in

  let make_block_decl be =
    match be with
    | Clang_ast_t.BlockExpr (bsi, _, bei, _) ->
        let di = { empty_decl_info with Clang_ast_t.di_pointer = Ast_utils.get_fresh_pointer () } in
        let vdi = { empty_var_decl_info with Clang_ast_t.vdi_init_expr = Some (be) } in
        let tp = bei.Clang_ast_t.ei_type_ptr in
        let var_decl = Clang_ast_t.VarDecl (di, qual_block_name, tp, vdi) in
        Clang_ast_t.DeclStmt (bsi, [be], [var_decl]), [(block_name, di.Clang_ast_t.di_pointer, bei.Clang_ast_t.ei_type_ptr)]
    | _ -> assert false in

  let make_block_call block_tp object_cast idx_cast stop_cast =
    let decl_ref = make_decl_ref_invalid `Var qual_block_name false block_tp in
    let fun_cast = cast_expr decl_ref block_tp in
    let ei_call = make_expr_info create_void_star_type in
    Clang_ast_t.CallExpr (fresh_stmt_info stmt_info, [fun_cast; object_cast; idx_cast; stop_cast], ei_call) in

  (* build statement "if (stop) break;" *)
  let build_if_stop stop_cast =
    let bool_tp = create_BOOL_type in
    let ei = make_expr_info bool_tp in
    let unary_op = Clang_ast_t.UnaryOperator (fresh_stmt_info stmt_info, [stop_cast], ei, { Clang_ast_t.uoi_kind = `Deref; uoi_is_postfix = true }) in
    let cond = create_implicit_cast_expr (fresh_stmt_info stmt_info) [unary_op] bool_tp `LValueToRValue in
    let break_stmt = Clang_ast_t.BreakStmt (fresh_stmt_info stmt_info, []) in
    Clang_ast_t.IfStmt (fresh_stmt_info stmt_info, [dummy_stmt (); cond; break_stmt; dummy_stmt ()]) in

  let translate params array_cast_decl_ref_exp block_decl block_tp =
    match params with
    | [pobj; pidx; pstop] ->
        let objects_decl, op = objects_array_DeclStmt array_cast_decl_ref_exp in
        let decl_stop = build_stop pstop in
        let assign_stop = stop_equal_no pstop in
        let objects = make_object_cast_decl_ref_expr objects_decl in
        let idx_decl_stmt, idx_decl_ref_exp, idx_cast, tp_idx = build_idx_decl pidx in
        let guard = bin_op pidx objects in
        let incr = un_op idx_decl_ref_exp tp_idx in
        let obj_assignment = build_object_DeclStmt pobj objects idx_cast in
        let object_cast = build_cast_decl_ref_expr_from_parm pobj in
        let stop_cast = build_cast_decl_ref_expr_from_parm pstop in
        let call_block = make_block_call block_tp object_cast idx_cast stop_cast in
        let if_stop = build_if_stop stop_cast in
        let free_stop = free_stop pstop in
        [ objects_decl; block_decl; decl_stop; assign_stop;
          Clang_ast_t.ForStmt (stmt_info, [idx_decl_stmt; dummy_stmt (); guard; incr;
                                           Clang_ast_t.CompoundStmt(stmt_info, [obj_assignment; call_block; if_stop])]); free_stop], op
    | _ -> assert false in
  let open Clang_ast_t in
  match stmt_list with
  | [s; BlockExpr (_, _, bei, BlockDecl (_, bdi)) as be] ->
      let block_decl, bv = make_block_decl be in
      let vars_to_register = get_name_pointers bdi.bdi_parameters in
      let translated_stmt, op = translate bdi.bdi_parameters s block_decl bei.ei_type_ptr in
      CompoundStmt (stmt_info, translated_stmt), vars_to_register @ op @ bv
  | _ -> (* When it is not the method we expect with only one parameter, we don't translate *)
      Printing.log_out "WARNING: Block Enumeration called at %s not translated." (Clang_ast_j.string_of_stmt_info stmt_info);
      CompoundStmt (stmt_info, stmt_list), []

(* We translate the logical negation of an integer with a conditional*)
(* !x <=> x?0:1 *)
let trans_negation_with_conditional stmt_info expr_info stmt_list =
  let stmt_list_cond = stmt_list @ [create_integer_literal "0"] @ [create_integer_literal "1"] in
  Clang_ast_t.ConditionalOperator (stmt_info, stmt_list_cond, expr_info)

let create_assume_not_null_call decl_info var_name var_type =
  let stmt_info = stmt_info_with_fresh_pointer (make_stmt_info decl_info) in
  let boi = { Clang_ast_t.boi_kind = `NE } in
  let decl_ptr = decl_info.Clang_ast_t.di_pointer in
  let decl_ref = make_decl_ref_tp `Var decl_ptr var_name false var_type in
  let stmt_info_var = dummy_stmt_info () in
  let decl_ref_info = make_decl_ref_expr_info decl_ref in
  let var_decl_ref = Clang_ast_t.DeclRefExpr (stmt_info_var, [], (make_expr_info var_type), decl_ref_info) in
  let var_decl_ptr = Ast_utils.get_invalid_pointer () in
  let expr_info = {
    Clang_ast_t.ei_type_ptr = var_type;
    ei_value_kind = `RValue;
    ei_object_kind = `Ordinary
  } in
  let cast_info_call = { Clang_ast_t.cei_cast_kind = `LValueToRValue; cei_base_path = [] } in
  let decl_ref_exp_cast = Clang_ast_t.ImplicitCastExpr (stmt_info, [var_decl_ref], expr_info, cast_info_call) in
  let null_expr = create_integer_literal "0" in
  let bin_op_expr_info = make_general_expr_info create_BOOL_type `RValue `Ordinary in
  let bin_op = make_binary_stmt decl_ref_exp_cast null_expr stmt_info bin_op_expr_info boi in
  let parameters = [bin_op] in
  let procname = Procname.to_string ModelBuiltins.__infer_assume in
  let qual_procname = Ast_utils.make_name_decl procname in
  create_call stmt_info var_decl_ptr qual_procname create_void_star_type parameters
