open Tc

type t = ProgramTypes.Pattern.t

// CLEANUP: Added temporarily. Fluid stuff was in libshared and so couldn't rely on
// types. But now we're moving things around and we can. this is here to let it all
// typecheck and then we'll move this.
let gid = () => Js_math.random_int(0, 2147483647) |> string_of_int |> ID.fromString

let toID = (p: t): ID.t =>
  switch p {
  | FPVariable(_, id, _)
  | FPConstructor(_, id, _, _)
  | FPInteger(_, id, _)
  | FPBool(_, id, _)
  | FPString({patternID: id, _})
  | FPFloat(_, id, _, _)
  | FPNull(_, id)
  | FPBlank(_, id) => id
  }

let rec ids = (p: t): list<ID.t> =>
  switch p {
  | FPConstructor(_, id, _, list) =>
    list |> List.map(~f=ids) |> List.flatten |> (l => list{id, ...l})
  | FPVariable(_)
  | FPInteger(_)
  | FPBool(_)
  | FPString(_)
  | FPFloat(_)
  | FPNull(_)
  | FPBlank(_) => list{toID(p)}
  }

let toMatchID = (p: t): ID.t =>
  switch p {
  | FPVariable(mid, _, _)
  | FPConstructor(mid, _, _, _)
  | FPInteger(mid, _, _)
  | FPBool(mid, _, _)
  | FPString({matchID: mid, _})
  | FPFloat(mid, _, _, _)
  | FPNull(mid, _)
  | FPBlank(mid, _) => mid
  }

let rec clone = (matchID: ID.t, p: t): t =>
  switch p {
  | FPVariable(_, _, name) => FPVariable(matchID, gid(), name)
  | FPConstructor(_, _, name, patterns) =>
    FPConstructor(matchID, gid(), name, List.map(~f=p => clone(matchID, p), patterns))
  | FPInteger(_, _, i) => FPInteger(matchID, gid(), i)
  | FPBool(_, _, b) => FPBool(matchID, gid(), b)
  | FPString({str, _}) => FPString({matchID: matchID, patternID: gid(), str: str})
  | FPBlank(_, _) => FPBlank(matchID, gid())
  | FPNull(_, _) => FPNull(matchID, gid())
  | FPFloat(_, _, whole, fraction) => FPFloat(matchID, gid(), whole, fraction)
  }

let rec variableNames = (p: t): list<string> =>
  switch p {
  | FPVariable(_, _, name) => list{name}
  | FPConstructor(_, _, _, patterns) => patterns |> List.map(~f=variableNames) |> List.flatten
  | FPInteger(_) | FPBool(_) | FPString(_) | FPBlank(_) | FPNull(_) | FPFloat(_) => list{}
  }

let hasVariableNamed = (varName: string, p: t): bool =>
  List.member(~value=varName, variableNames(p))

let rec findPattern = (patID: ID.t, within: t): option<t> =>
  switch within {
  | FPVariable(_, pid, _)
  | FPInteger(_, pid, _)
  | FPBool(_, pid, _)
  | FPNull(_, pid)
  | FPBlank(_, pid)
  | FPFloat(_, pid, _, _)
  | FPString({matchID: _, patternID: pid, str: _}) =>
    if patID == pid {
      Some(within)
    } else {
      None
    }
  | FPConstructor(_, pid, _, pats) =>
    if patID == pid {
      Some(within)
    } else {
      List.findMap(pats, ~f=p => findPattern(patID, p))
    }
  }

let rec preTraversal = (~f: t => t, pattern: t): t => {
  let r = preTraversal(~f)
  let pattern = f(pattern)
  switch pattern {
  | FPVariable(_)
  | FPInteger(_)
  | FPBool(_)
  | FPString(_)
  | FPBlank(_)
  | FPNull(_)
  | FPFloat(_) => pattern
  | FPConstructor(matchID, patternID, name, patterns) =>
    FPConstructor(matchID, patternID, name, List.map(patterns, ~f=p => r(p)))
  }
}

let rec postTraversal = (~f: t => t, pattern: t): t => {
  let r = postTraversal(~f)
  let result = switch pattern {
  | FPVariable(_)
  | FPInteger(_)
  | FPBool(_)
  | FPString(_)
  | FPBlank(_)
  | FPNull(_)
  | FPFloat(_) => pattern
  | FPConstructor(matchID, patternID, name, patterns) =>
    FPConstructor(matchID, patternID, name, List.map(patterns, ~f=p => r(p)))
  }

  f(result)
}
