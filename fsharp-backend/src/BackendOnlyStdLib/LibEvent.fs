/// StdLib functions for emitting events
///
/// Those events are handled by Workers
module BackendOnlyStdLib.LibEvent

open LibExecution.RuntimeTypes
open Prelude

module EventQueueV2 = LibBackend.EventQueueV2
module Errors = LibExecution.Errors

let fn = FQFnName.stdlibFnName

let incorrectArgs = LibExecution.Errors.incorrectArgs

let varA = TVariable "a"

let fns : List<BuiltInFn> =
  [ { name = fn "" "emit" 0
      parameters =
        [ Param.make "data" varA ""
          Param.make "space" TStr ""
          Param.make "name" TStr "" ]
      returnType = varA
      description =
        "Emit event `name` in `space`, passing along `data` as a parameter"
      fn =
        (function
        | state, [ data; DStr space; DStr name ] ->
          uply {
            let canvasID = state.program.canvasID

            // the "_" exists because handlers in the DB have 3 fields (eg Http, /path, GET),
            // but we don't need a 3rd one for workers
            do! EventQueueV2.enqueue canvasID space name "_" data
            return data
          }
        | _ -> incorrectArgs ())
      sqlSpec = NotQueryable
      previewable = Impure
      deprecated = ReplacedBy(fn "" "emit" 1) }

    { name = fn "" "emit" 1
      parameters = [ Param.make "event" varA ""; Param.make "name" TStr "" ]
      returnType = varA
      description = "Emit a `event` to the `name` worker"
      fn =
        (function
        | state, [ data; DStr name ] ->
          uply {
            let canvasID = state.program.canvasID

            do!
              // the "_" exists because handlers in the DB have 3 fields (eg Http, /path, GET),
              // but we don't need a 3rd one for workers
              EventQueueV2.enqueue canvasID "WORKER" name "_" data

            return data
          }
        | _ -> incorrectArgs ())
      sqlSpec = NotQueryable
      previewable = Impure
      deprecated = NotDeprecated } ]
