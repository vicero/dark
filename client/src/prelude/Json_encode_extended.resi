/* This is designed to be used as Json.Encode in Prelude. Don't use it
 * directly unless you have to. */

include module type of Json.Encode

let variant: (string, list<Js.Json.t>) => Js.Json.t

/* CLEANUP : change name of function */
let tcStrSet: Tc.Set.String.t => Js.Json.t

/* CLEANUP : change name of function */
let tcStrDict: ('a => Js.Json.t, Tc.Map.String.t<'a>) => Js.Json.t

let beltStrDict: ('a => Js.Json.t, Belt.Map.String.t<'a>) => Js.Json.t
