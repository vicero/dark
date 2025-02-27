include Prelude

open ProgramTypes.Expr

@ppx.deriving(show({with_path: false})) type rec t = ProgramTypes.Expr.t

@ppx.deriving(show({with_path: false}))
type rec fluidPatOrExpr =
  | Expr(t)
  | Pat(fluidPattern)

let newB = () => ProgramTypes.Expr.EBlank(gid())

let toID = (expr: t): ID.t =>
  switch expr {
  | EInteger(id, _)
  | EString(id, _)
  | EBool(id, _)
  | ENull(id)
  | EFloat(id, _, _)
  | EVariable(id, _)
  | EFieldAccess(id, _, _)
  | EFnCall(id, _, _, _)
  | ELambda(id, _, _)
  | EBlank(id)
  | ELet(id, _, _, _)
  | EIf(id, _, _, _)
  | EPartial(id, _, _)
  | ERightPartial(id, _, _)
  | ELeftPartial(id, _, _)
  | EList(id, _)
  | ERecord(id, _)
  | EPipe(id, _)
  | EPipeTarget(id)
  | EBinOp(id, _, _, _, _)
  | EConstructor(id, _, _)
  | EFeatureFlag(id, _, _, _, _)
  | EMatch(id, _, _) => id
  }

let rec findExprOrPat = (target: ID.t, within: fluidPatOrExpr): option<fluidPatOrExpr> => {
  let (id, patOrExprs) = switch within {
  | Expr(expr) =>
    switch expr {
    | EInteger(id, _)
    | EBool(id, _)
    | EString(id, _)
    | EFloat(id, _, _)
    | ENull(id)
    | EBlank(id)
    | EVariable(id, _)
    | EPipeTarget(id) => (id, list{})
    | ELet(id, _, e1, e2) | EBinOp(id, _, e1, e2, _) => (id, list{Expr(e1), Expr(e2)})
    | EIf(id, e1, e2, e3) | EFeatureFlag(id, _, e1, e2, e3) => (
        id,
        list{Expr(e1), Expr(e2), Expr(e3)},
      )
    | ELambda(id, _, e1)
    | EFieldAccess(id, e1, _)
    | EPartial(id, _, e1)
    | ERightPartial(id, _, e1)
    | ELeftPartial(id, _, e1) => (id, list{Expr(e1)})
    | EFnCall(id, _, exprs, _)
    | EList(id, exprs)
    | EPipe(id, exprs)
    | EConstructor(id, _, exprs) => (id, List.map(exprs, ~f=e1 => Expr(e1)))
    | ERecord(id, nameAndExprs) => (id, List.map(nameAndExprs, ~f=((_, e1)) => Expr(e1)))
    | EMatch(id, e1, pairs) => (
        id,
        list{
          Expr(e1),
          ...pairs |> List.map(~f=((p1, e1)) => list{Pat(p1), Expr(e1)}) |> List.flatten,
        },
      )
    }
  | Pat(pat) =>
    switch pat {
    | FPVariable(_, pid, _)
    | FPInteger(_, pid, _)
    | FPBool(_, pid, _)
    | FPNull(_, pid)
    | FPBlank(_, pid)
    | FPFloat(_, pid, _, _)
    | FPString({matchID: _, patternID: pid, str: _}) => (pid, list{})
    | FPConstructor(_, pid, _, pats) => (pid, List.map(pats, ~f=p1 => Pat(p1)))
    }
  }

  if id == target {
    Some(within)
  } else {
    patOrExprs |> List.findMap(~f=pOrE => findExprOrPat(target, pOrE))
  }
}

let rec find = (target: ID.t, expr: t): option<t> => {
  let fe = find(target)
  if toID(expr) == target {
    Some(expr)
  } else {
    switch expr {
    | EInteger(_)
    | EBlank(_)
    | EString(_)
    | EVariable(_)
    | EBool(_)
    | ENull(_)
    | EPipeTarget(_)
    | EFloat(_) =>
      None
    | ELet(_, _, rhs, next) => fe(rhs) |> Option.orElseLazy(() => fe(next))
    | EIf(_, cond, ifexpr, elseexpr) =>
      fe(cond) |> Option.orElseLazy(() => fe(ifexpr)) |> Option.orElseLazy(() => fe(elseexpr))
    | EBinOp(_, _, lexpr, rexpr, _) => fe(lexpr) |> Option.orElseLazy(() => fe(rexpr))
    | EFieldAccess(_, expr, _) | ELambda(_, _, expr) => fe(expr)
    | ERecord(_, fields) => fields |> List.map(~f=Tuple2.second) |> List.findMap(~f=fe)
    | EMatch(_, expr, pairs) =>
      fe(expr) |> Option.orElseLazy(() =>
        pairs |> List.map(~f=Tuple2.second) |> List.findMap(~f=fe)
      )
    | EFnCall(_, _, exprs, _)
    | EList(_, exprs)
    | EConstructor(_, _, exprs)
    | EPipe(_, exprs) =>
      List.findMap(~f=fe, exprs)
    | EPartial(_, _, oldExpr)
    | ERightPartial(_, _, oldExpr)
    | ELeftPartial(_, _, oldExpr) =>
      fe(oldExpr)
    | EFeatureFlag(_, _, cond, casea, caseb) =>
      fe(cond) |> Option.orElseLazy(() => fe(casea)) |> Option.orElseLazy(() => fe(caseb))
    }
  }
}

let children = (expr: t): list<t> =>
  switch expr {
  // None
  | EInteger(_)
  | EString(_)
  | EBool(_)
  | EFloat(_)
  | ENull(_)
  | EBlank(_)
  | EPipeTarget(_)
  | EVariable(_) => list{}
  // One
  | EPartial(_, _, expr)
  | ERightPartial(_, _, expr)
  | ELeftPartial(_, _, expr)
  | ELambda(_, _, expr)
  | EFieldAccess(_, expr, _) => list{expr}
  // Two
  | EBinOp(_, _, c0, c1, _) | ELet(_, _, c0, c1) => list{c0, c1}
  // Three
  | EFeatureFlag(_, _, c0, c1, c2) | EIf(_, c0, c1, c2) => list{c0, c1, c2}
  // List
  | EFnCall(_, _, exprs, _)
  | EList(_, exprs)
  | EConstructor(_, _, exprs)
  | EPipe(_, exprs) => exprs
  // Special
  | ERecord(_, pairs) => pairs |> List.map(~f=Tuple2.second)
  | EMatch(_, matchExpr, cases) =>
    let casePointers = cases |> List.map(~f=Tuple2.second)
    list{matchExpr, ...casePointers}
  }

let findParent = (target: ID.t, expr: t): option<t> => {
  let rec findParent' = (~parent: option<t>, target: ID.t, expr: t): option<t> =>
    if toID(expr) == target {
      parent
    } else {
      let f = findParent'(~parent=Some(expr), target)
      List.findMap(~f, children(expr))
    }

  findParent'(~parent=None, target, expr)
}

let isBlank = (expr: t) =>
  switch expr {
  | EBlank(_) => true
  | _ => false
  }

let isEmpty = (expr: t): bool =>
  switch expr {
  | EBlank(_) => true
  | ERecord(_, list{}) => true
  | ERecord(_, l) => l |> List.filter(~f=((k, v)) => k == "" && !isBlank(v)) |> List.isEmpty
  | EList(_, l) => l |> List.filter(~f=\"<<"(not, isBlank)) |> List.isEmpty
  | _ => false
  }

let hasEmptyWithId = (id: ID.t, expr: t): bool =>
  switch find(id, expr) {
  | Some(e) => isEmpty(e)
  | _ => false
  }

let rec preTraversal = (~f: t => t, expr: t): t => {
  let r = preTraversal(~f)
  let expr = f(expr)
  switch expr {
  | EInteger(_)
  | EBlank(_)
  | EString(_)
  | EVariable(_)
  | EBool(_)
  | ENull(_)
  | EPipeTarget(_)
  | EFloat(_) => expr
  | ELet(id, name, rhs, next) => ELet(id, name, r(rhs), r(next))
  | EIf(id, cond, ifexpr, elseexpr) => EIf(id, r(cond), r(ifexpr), r(elseexpr))
  | EBinOp(id, op, lexpr, rexpr, ster) => EBinOp(id, op, r(lexpr), r(rexpr), ster)
  | EFieldAccess(id, expr, fieldname) => EFieldAccess(id, r(expr), fieldname)
  | EFnCall(id, name, exprs, ster) => EFnCall(id, name, List.map(~f=r, exprs), ster)
  | ELambda(id, names, expr) => ELambda(id, names, r(expr))
  | EList(id, exprs) => EList(id, List.map(~f=r, exprs))
  | EMatch(id, mexpr, pairs) =>
    EMatch(id, r(mexpr), List.map(~f=((name, expr)) => (name, r(expr)), pairs))
  | ERecord(id, fields) => ERecord(id, List.map(~f=((name, expr)) => (name, r(expr)), fields))
  | EPipe(id, exprs) => EPipe(id, List.map(~f=r, exprs))
  | EConstructor(id, name, exprs) => EConstructor(id, name, List.map(~f=r, exprs))
  | EPartial(id, str, oldExpr) => EPartial(id, str, r(oldExpr))
  | ERightPartial(id, str, oldExpr) => ERightPartial(id, str, r(oldExpr))
  | ELeftPartial(id, str, oldExpr) => ELeftPartial(id, str, r(oldExpr))
  | EFeatureFlag(id, msg, cond, casea, caseb) => EFeatureFlag(id, msg, r(cond), r(casea), r(caseb))
  }
}

let rec postTraversal = (~f: t => t, expr: t): t => {
  let r = postTraversal(~f)
  let result = switch expr {
  | EInteger(_)
  | EBlank(_)
  | EString(_)
  | EVariable(_)
  | EBool(_)
  | ENull(_)
  | EPipeTarget(_)
  | EFloat(_) => expr
  | ELet(id, name, rhs, next) => ELet(id, name, r(rhs), r(next))
  | EIf(id, cond, ifexpr, elseexpr) => EIf(id, r(cond), r(ifexpr), r(elseexpr))
  | EBinOp(id, op, lexpr, rexpr, ster) => EBinOp(id, op, r(lexpr), r(rexpr), ster)
  | EFieldAccess(id, expr, fieldname) => EFieldAccess(id, r(expr), fieldname)
  | EFnCall(id, name, exprs, ster) => EFnCall(id, name, List.map(~f=r, exprs), ster)
  | ELambda(id, names, expr) => ELambda(id, names, r(expr))
  | EList(id, exprs) => EList(id, List.map(~f=r, exprs))
  | EMatch(id, mexpr, pairs) =>
    EMatch(id, r(mexpr), List.map(~f=((name, expr)) => (name, r(expr)), pairs))
  | ERecord(id, fields) => ERecord(id, List.map(~f=((name, expr)) => (name, r(expr)), fields))
  | EPipe(id, exprs) => EPipe(id, List.map(~f=r, exprs))
  | EConstructor(id, name, exprs) => EConstructor(id, name, List.map(~f=r, exprs))
  | EPartial(id, str, oldExpr) => EPartial(id, str, r(oldExpr))
  | ERightPartial(id, str, oldExpr) => ERightPartial(id, str, r(oldExpr))
  | ELeftPartial(id, str, oldExpr) => ELeftPartial(id, str, r(oldExpr))
  | EFeatureFlag(id, msg, cond, casea, caseb) => EFeatureFlag(id, msg, r(cond), r(casea), r(caseb))
  }

  f(result)
}

let deprecatedWalk = (~f: t => t, expr: t): t =>
  switch expr {
  | EInteger(_)
  | EBlank(_)
  | EString(_)
  | EVariable(_)
  | EBool(_)
  | ENull(_)
  | EPipeTarget(_)
  | EFloat(_) => expr
  | ELet(id, name, rhs, next) => ELet(id, name, f(rhs), f(next))
  | EIf(id, cond, ifexpr, elseexpr) => EIf(id, f(cond), f(ifexpr), f(elseexpr))
  | EBinOp(id, op, lexpr, rexpr, ster) => EBinOp(id, op, f(lexpr), f(rexpr), ster)
  | EFieldAccess(id, expr, fieldname) => EFieldAccess(id, f(expr), fieldname)
  | EFnCall(id, name, exprs, ster) => EFnCall(id, name, List.map(~f, exprs), ster)
  | ELambda(id, names, expr) => ELambda(id, names, f(expr))
  | EList(id, exprs) => EList(id, List.map(~f, exprs))
  | EMatch(id, mexpr, pairs) =>
    EMatch(id, f(mexpr), List.map(~f=((name, expr)) => (name, f(expr)), pairs))
  | ERecord(id, fields) => ERecord(id, List.map(~f=((name, expr)) => (name, f(expr)), fields))
  | EPipe(id, exprs) => EPipe(id, List.map(~f, exprs))
  | EConstructor(id, name, exprs) => EConstructor(id, name, List.map(~f, exprs))
  | EPartial(id, str, oldExpr) => EPartial(id, str, f(oldExpr))
  | ERightPartial(id, str, oldExpr) => ERightPartial(id, str, f(oldExpr))
  | ELeftPartial(id, str, oldExpr) => ELeftPartial(id, str, f(oldExpr))
  | EFeatureFlag(id, msg, cond, casea, caseb) => EFeatureFlag(id, msg, f(cond), f(casea), f(caseb))
  }

let filterMap = (~f: t => option<'a>, expr: t): list<'a> => {
  let results = ref(list{})
  let rec myWalk = (e: t): t => {
    switch f(e) {
    | Some(r) =>
      results := list{r, ...results.contents}
      ()
    | None => ()
    }
    deprecatedWalk(~f=myWalk, e)
  }

  ignore(myWalk(expr))
  List.reverse(results.contents)
}

let filter = (~f: t => bool, expr: t): list<t> => filterMap(~f=t =>
    if f(t) {
      Some(t)
    } else {
      None
    }
  , expr)

let decendants = (expr: t): list<ID.t> => {
  let res = ref(list{})
  preTraversal(expr, ~f=e => {
    res := list{toID(e), ...res.contents}
    e
  }) |> ignore
  res.contents
}

let update = (~failIfMissing=true, ~f: t => t, target: ID.t, ast: t): t => {
  let found = ref(false)
  let rec run = e =>
    if target == toID(e) {
      found := true
      f(e)
    } else {
      deprecatedWalk(~f=run, e)
    }

  let finished = run(ast)
  if failIfMissing {
    if !found.contents {
      // prevents the significant performance cost of show
      Recover.asserT(
        ~debug=(ID.toString(target), show(ast)),
        "didn't find the id in the expression to update",
        found.contents,
      )
    }
  }
  finished
}

/* FIXME: [replace] is just [update] with a hack for EPipe.
 * It's very unclear which to use at what point and likely to cause bugs.
 * We should either hide [update] from the public interface of FluidExpression
 * or remove [replace] and put the special-case EPipe logic into the calling code. */
let replace = (~replacement: t, target: ID.t, ast: t): t => {
  // If we're putting a pipe into another pipe, fix it up
  let (target', newExpr') = switch (findParent(target, ast), replacement) {
  | (Some(EPipe(parentID, oldExprs)), EPipe(newID, newExprs)) =>
    let (before, elemAndAfter) = List.splitWhen(~f=nested => toID(nested) == target, oldExprs)

    let after = List.tail(elemAndAfter) |> Option.unwrap(~default=list{})
    (parentID, EPipe(newID, Belt.List.concatMany([before, newExprs, after])))
  | _ => (target, replacement)
  }

  update(target', ast, ~f=_ => newExpr')
}

// Slightly modified version of `AST.uses` (pre-fluid code)
let rec updateVariableUses = (oldVarName: string, ~f: t => t, ast: t): t => {
  let u = updateVariableUses(oldVarName, ~f)
  switch ast {
  | EVariable(_, varName) =>
    if varName == oldVarName {
      f(ast)
    } else {
      ast
    }
  | ELet(id, lhs, rhs, body) =>
    if oldVarName == lhs {
      ELet(id, lhs, u(rhs), body)
    } else {
      ELet(id, lhs, u(rhs), u(body))
    }
  | ELambda(id, vars, lexpr) =>
    if List.map(~f=Tuple2.second, vars) |> List.member(~value=oldVarName) {
      // if variable name is rebound
      ast
    } else {
      ELambda(id, vars, u(lexpr))
    }
  | EMatch(id, cond, pairs) =>
    let pairs = List.map(~f=((pat, expr)) =>
      if FluidPattern.hasVariableNamed(oldVarName, pat) {
        (pat, expr)
      } else {
        (pat, u(expr))
      }
    , pairs)

    EMatch(id, u(cond), pairs)
  | _ => deprecatedWalk(~f=u, ast)
  }
}

let renameVariableUses = (~oldName: string, ~newName: string, ast: t): t => {
  let f = expr =>
    switch expr {
    | EVariable(id, _) => EVariable(id, newName)
    | _ => expr
    }

  updateVariableUses(oldName, ~f, ast)
}

let removeVariableUse = (oldVarName: string, ast: t): t => {
  let f = _ => EBlank(gid())
  updateVariableUses(oldVarName, ~f, ast)
}

let rec clone = (expr: t): t => {
  let c = e => clone(e)
  let cl = es => List.map(~f=c, es)
  switch expr {
  | ELet(_, lhs, rhs, body) => ELet(gid(), lhs, c(rhs), c(body))
  | EIf(_, cond, ifbody, elsebody) => EIf(gid(), c(cond), c(ifbody), c(elsebody))
  | EFnCall(_, name, exprs, r) => EFnCall(gid(), name, cl(exprs), r)
  | EBinOp(_, name, left, right, r) => EBinOp(gid(), name, c(left), c(right), r)
  | ELambda(_, vars, body) => ELambda(gid(), List.map(vars, ~f=((_, var)) => (gid(), var)), c(body))
  | EPipe(_, exprs) => EPipe(gid(), cl(exprs))
  | EFieldAccess(_, obj, field) => EFieldAccess(gid(), c(obj), field)
  | EString(_, v) => EString(gid(), v)
  | EInteger(_, v) => EInteger(gid(), v)
  | EBool(_, v) => EBool(gid(), v)
  | EFloat(_, whole, fraction) => EFloat(gid(), whole, fraction)
  | ENull(_) => ENull(gid())
  | EBlank(_) => EBlank(gid())
  | EVariable(_, name) => EVariable(gid(), name)
  | EList(_, exprs) => EList(gid(), cl(exprs))
  | ERecord(_, pairs) => ERecord(gid(), List.map(~f=((k, v)) => (k, c(v)), pairs))
  | EFeatureFlag(_, name, cond, a, b) => EFeatureFlag(gid(), name, c(cond), c(a), c(b))
  | EMatch(_, matchExpr, cases) =>
    let mid = gid()
    EMatch(mid, c(matchExpr), List.map(~f=((k, v)) => (FluidPattern.clone(mid, k), c(v)), cases))
  | EConstructor(_, name, args) => EConstructor(gid(), name, cl(args))
  | EPartial(_, str, oldExpr) => EPartial(gid(), str, c(oldExpr))
  | ERightPartial(_, str, oldExpr) => ERightPartial(gid(), str, c(oldExpr))
  | ELeftPartial(id, str, oldExpr) => ELeftPartial(id, str, c(oldExpr))
  | EPipeTarget(_) => EPipeTarget(gid())
  }
}

let blanks = filter(~f=isBlank)

let ids = (ast: t): list<ID.t> => filter(ast, ~f=_ => true) |> List.map(~f=toID)

let ancestors = (id: ID.t, expr: t): list<t> => {
  let rec rec_ancestors = (tofind: ID.t, walk: list<t>, exp: t) => {
    let rec_ = (id_, e_, walk_) => rec_ancestors(id_, list{e_, ...walk_})
    let reclist = (id_, e_, walk_, exprs) =>
      exprs |> List.map(~f=rec_(id_, e_, walk_)) |> List.flatten

    if toID(exp) == tofind {
      walk
    } else {
      switch exp {
      | EInteger(_)
      | EString(_)
      | EBool(_)
      | EFloat(_)
      | ENull(_)
      | EBlank(_)
      | EPipeTarget(_) => list{}
      | EVariable(_) => list{}
      | ELet(_, _, rhs, body) => reclist(id, exp, walk, list{rhs, body})
      | EIf(_, cond, ifbody, elsebody) => reclist(id, exp, walk, list{cond, ifbody, elsebody})
      | EFnCall(_, _, exprs, _) => reclist(id, exp, walk, exprs)
      | EBinOp(_, _, lhs, rhs, _) => reclist(id, exp, walk, list{lhs, rhs})
      | ELambda(_, _, lexpr) => rec_(id, exp, walk, lexpr)
      | EPipe(_, exprs) => reclist(id, exp, walk, exprs)
      | EFieldAccess(_, obj, _) => rec_(id, exp, walk, obj)
      | EList(_, exprs) => reclist(id, expr, walk, exprs)
      | ERecord(_, pairs) => pairs |> List.map(~f=Tuple2.second) |> reclist(id, expr, walk)
      | EFeatureFlag(_, _, cond, a, b) => reclist(id, exp, walk, list{cond, a, b})
      | EMatch(_, matchExpr, cases) =>
        reclist(id, exp, walk, list{matchExpr, ...List.map(~f=Tuple2.second, cases)})
      | EConstructor(_, _, args) => reclist(id, exp, walk, args)
      | EPartial(_, _, oldExpr) => rec_(id, exp, walk, oldExpr)
      | ERightPartial(_, _, oldExpr) => rec_(id, exp, walk, oldExpr)
      | ELeftPartial(_, _, oldExpr) => rec_(id, exp, walk, oldExpr)
      }
    }
  }

  rec_ancestors(id, list{}, expr)
}

let rec testEqualIgnoringIds = (a: t, b: t): bool => {
  // helpers for recursive calls
  let eq = testEqualIgnoringIds
  let eq2 = ((e, e'), (f, f')) => eq(e, e') && eq(f, f')
  let eq3 = ((e, e'), (f, f'), (g, g')) => eq(e, e') && (eq(f, f') && eq(g, g'))
  let eqList = (l1, l2) =>
    List.length(l1) == List.length(l2) && List.map2(~f=eq, l1, l2) |> List.all(~f=identity)

  let rec peq = (a: FluidPattern.t, b: FluidPattern.t) => {
    let peqList = (l1, l2) =>
      List.length(l1) == List.length(l2) &&
        Tc.List.map2(~f=peq, l1, l2) |> Tc.List.all(~f=Tc.identity)

    switch (a, b) {
    | (FPVariable(_, _, name), FPVariable(_, _, name')) => name == name'
    | (FPConstructor(_, _, name, patterns), FPConstructor(_, _, name', patterns')) =>
      name == name' && peqList(patterns, patterns')
    | (FPString({str, _}), FPString({str: str', _})) => str == str'
    | (FPInteger(_, _, l), FPInteger(_, _, l')) => l == l'
    | (FPFloat(_, _, w, f), FPFloat(_, _, w', f')) => (w, f) == (w', f')
    | (FPBool(_, _, l), FPBool(_, _, l')) => l == l'
    | (FPNull(_, _), FPNull(_, _)) => true
    | (FPBlank(_, _), FPBlank(_, _)) => true
    | (FPVariable(_), _)
    | (FPConstructor(_), _)
    | (FPString(_), _)
    | (FPInteger(_), _)
    | (FPFloat(_), _)
    | (FPBool(_), _)
    | (FPNull(_), _)
    | (FPBlank(_), _) => false
    }
  }

  switch (a, b) {
  // expressions with no values
  | (ENull(_), ENull(_)) | (EBlank(_), EBlank(_)) | (EPipeTarget(_), EPipeTarget(_)) => true
  // expressions with single string values
  | (EInteger(_, v), EInteger(_, v'))
  | (EString(_, v), EString(_, v'))
  | (EVariable(_, v), EVariable(_, v')) =>
    v == v'
  | (EBool(_, v), EBool(_, v')) => v == v'
  | (EFloat(_, whole, frac), EFloat(_, whole', frac')) => whole == whole' && frac == frac'
  | (ELet(_, lhs, rhs, body), ELet(_, lhs', rhs', body')) =>
    lhs == lhs' && eq2((rhs, rhs'), (body, body'))
  | (EIf(_, con, thn, els), EIf(_, con', thn', els')) => eq3((con, con'), (thn, thn'), (els, els'))
  | (EList(_, l), EList(_, l')) => eqList(l, l')
  | (EFnCall(_, name, args, toRail), EFnCall(_, name', args', toRail')) =>
    name == name' && (eqList(args, args') && toRail == toRail')
  | (EBinOp(_, name, lhs, rhs, toRail), EBinOp(_, name', lhs', rhs', toRail')) =>
    name == name' && (eq2((lhs, lhs'), (rhs, rhs')) && toRail == toRail')
  | (ERecord(_, pairs), ERecord(_, pairs')) =>
    let sort = List.sortBy(~f=((k, _)) => k)
    List.map2(~f=((k, v), (k', v')) => k == k' && eq(v, v'), sort(pairs), sort(pairs')) |> List.all(
      ~f=identity,
    )
  | (EFieldAccess(_, e, f), EFieldAccess(_, e', f')) => eq(e, e') && f == f'
  | (EPipe(_, l), EPipe(_, l')) => eqList(l, l')
  | (EFeatureFlag(_, _, cond, old, knew), EFeatureFlag(_, _, cond', old', knew')) =>
    eq3((cond, cond'), (old, old'), (knew, knew'))
  | (EConstructor(_, s, ts), EConstructor(_, s', ts')) => s == s' && eqList(ts, ts')
  | (ERightPartial(_, str, e), ERightPartial(_, str', e'))
  | (ELeftPartial(_, str, e), ELeftPartial(_, str', e'))
  | (EPartial(_, str, e), EPartial(_, str', e')) =>
    str == str' && eq(e, e')
  | (ELambda(_, vars, e), ELambda(_, vars', e')) =>
    eq(e, e') && List.all(~f=identity, List.map2(vars, vars', ~f=((_, v), (_, v')) => v == v'))
  | (EMatch(_, e, branches), EMatch(_, e', branches')) =>
    eq(e, e') &&
    Tc.List.map2(
      ~f=((p, v), (p', v')) => peq(p, p') && eq(v, v'),
      branches,
      branches',
    ) |> Tc.List.all(~f=Tc.identity)
  | (ENull(_), _)
  | (EBlank(_), _)
  | (EPipeTarget(_), _)
  | (EInteger(_), _)
  | (EString(_), _)
  | (EVariable(_), _)
  | (EBool(_), _)
  | (EFloat(_), _)
  | (ELet(_), _)
  | (EIf(_), _)
  | (EList(_), _)
  | (EFnCall(_), _)
  | (EBinOp(_), _)
  | (ERecord(_), _)
  | (EFieldAccess(_), _)
  | (EPipe(_), _)
  | (EFeatureFlag(_), _)
  | (EConstructor(_), _)
  | (ELeftPartial(_), _)
  | (ERightPartial(_), _)
  | (EPartial(_), _)
  | (ELambda(_), _)
  | (EMatch(_), _) => // exhaustiveness check
    false
  }
}

let toHumanReadable = (expr: t): string => {
  let rec recurse = (~indent: int, expr: t): string => {
    let iStr = String.repeat(~count=indent, " ")
    let r = recurse(~indent)
    let rin = recurse(~indent=indent + 2)
    let newlineList = exprs => exprs |> List.map(~f=rin) |> String.join(~sep="\n")
    let eStr = switch expr {
    | EBlank(_) => "(blank)"
    | EString(_, str) =>
      if String.length(str) > 20 {
        String.slice(~from=0, ~to_=20, str) ++ "..."
      } else {
        str
      } |> Printf.sprintf(`(str "%s")`)
    | EBool(_, true) => "(true)"
    | EBool(_, false) => "(false)"
    | EFloat(_, whole, fractional) => Printf.sprintf(`(%s.%s)`, whole, fractional)
    | EInteger(_, i) => Printf.sprintf(`(%s)`, i)
    | ENull(_) => "(null)"
    | EPipeTarget(_) => "(pt)"
    | EPartial(_, str, e) => Printf.sprintf(`(partial "%s" %s)`, str, r(e))
    | ERightPartial(_, str, e) => Printf.sprintf(`(rpartial "%s" %s)`, str, r(e))
    | ELeftPartial(_, str, e) => Printf.sprintf(`(lpartial "%s" %s)`, str, r(e))
    | EFnCall(_, name, list{}, _) => Printf.sprintf("(fn \"%s\")", name)
    | EFnCall(_, name, exprs, _) => Printf.sprintf("(fn \"%s\"\n%s)", name, newlineList(exprs))
    | EBinOp(_, name, lhs, rhs, _) => Printf.sprintf("(binop \"%s\"\n%s\n%s)", name, r(lhs), r(rhs))
    | EVariable(_, name) => Printf.sprintf(`(%s)`, name)
    | EFieldAccess(_, e, name) => Printf.sprintf("(fieldAccess \"%s\"\n%s)", name, r(e))
    | EMatch(_, cond, matches) =>
      let rec pToTestcase = (p: FluidPattern.t): string => {
        let quoted = str => "\"" ++ (str ++ "\"")
        let listed = elems => "[" ++ (String.join(~sep=";", elems) ++ "]")
        let spaced = elems => String.join(~sep=" ", elems)
        switch p {
        | FPBlank(_) => "pBlank"
        | FPString({str, _}) => spaced(list{"pString", quoted(str)})
        | FPBool(_, _, true) => spaced(list{"pBool true"})
        | FPBool(_, _, false) => spaced(list{"pBool false"})
        | FPFloat(_, _, whole, fractional) => spaced(list{"pFloat'", whole, fractional})
        | FPInteger(_, _, int) => spaced(list{"pInt", int})
        | FPNull(_) => "pNull"
        | FPVariable(_, _, name) => spaced(list{"pVar", quoted(name)})
        | FPConstructor(_, _, name, args) =>
          spaced(list{"pConstructor", quoted(name), listed(List.map(args, ~f=pToTestcase))})
        }
      }

      let matchStrs = List.map(matches, ~f=((p, e)) =>
        "(" ++ (pToTestcase(p) ++ (", " ++ (r(e) ++ ")")))
      )

      Printf.sprintf(`(match\\n%s\\n%s)`, r(cond), String.join(~sep="\n", matchStrs))
    | ERecord(_, list{}) => "(record)"
    | ERecord(_, pairs) =>
      let pairStrs = List.map(pairs, ~f=((k, v)) =>
        Printf.sprintf(`%s("%s" %s)`, iStr, k, String.trim(r(v)))
      )

      Printf.sprintf("(record\n%s)", String.join(~sep="\n", pairStrs))
    | EList(_, list{}) => "(list)"
    | EList(_, exprs) => Printf.sprintf("(list\n%s)", newlineList(exprs))
    | EPipe(_, exprs) => Printf.sprintf("(pipe\n%s)", newlineList(exprs))
    | EConstructor(_, name, exprs) =>
      Printf.sprintf("(constructor \"%s\"\n%s)", name, newlineList(exprs))
    | EIf(_, cond, then', else') =>
      Printf.sprintf("(if %s\n%s\n%s)", r(cond), rin(then'), rin(else'))
    | ELet(_, lhs, rhs, body) => Printf.sprintf("(let %s\n%s\n%s)", lhs, rin(rhs), r(body))
    | ELambda(_, _names, body) => Printf.sprintf("(lambda \n%s)", r(body))
    | EFeatureFlag(_, _, cond, old, new') =>
      Printf.sprintf("(flag %s\n%s\n%s)", rin(cond), rin(old), rin(new'))
    }

    iStr ++ eStr
  }

  recurse(~indent=0, expr)
}
