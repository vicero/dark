module Tests.BinarySerialization

open Expecto

open Prelude
open Tablecloth
open TestUtils.TestUtils

module File = LibBackend.File
module Config = LibBackend.Config
module PT = LibExecution.ProgramTypes
module BinarySerialization = LibBinarySerialization.BinarySerialization

/// The test values below are used to check the exact output of test file. So we need
/// the test inputs to be consistent, which is why we never use `gid ()` below, or
/// FSharpToExpr functions.
let testExpr =
  let e = PT.EInteger(34545UL, 5)
  PT.ELet(
    295510954UL,
    "x1",
    PT.EInteger(929452387UL, 5L),
    PT.ELet(
      620028536UL,
      "x2",
      PT.EInteger(452247642UL, 6L),
      PT.ELet(
        68205955UL,
        "bool",
        PT.EBool(43581311UL, true),
        PT.ELet(
          755798860UL,
          "bool",
          PT.EBool(97054530UL, false),
          PT.ELet(
            244891515UL,
            "str",
            PT.EString(446488682UL, "a string"),
            PT.ELet(
              537517627UL,
              "char",
              PT.ECharacter(1031176330UL, "a"),
              PT.ELet(
                399526184UL,
                "float",
                PT.EFloat(770715427UL, Negative, "6", "5"),
                PT.ELet(
                  975263310UL,
                  "n",
                  PT.ENull 923644248UL,
                  PT.ELet(
                    468988830UL,
                    "b",
                    PT.EBlank 133368677UL,
                    PT.ELet(
                      43886336UL,
                      "i",
                      PT.EIf(
                        46231874UL,
                        PT.EFnCall(
                          898531080UL,
                          PT.FQFnName.Stdlib
                            { module_ = "Bool"; function_ = "isError"; version = 0 },
                          [ PT.EInteger(160106123UL, 6L) ],
                          PT.Rail
                        ),
                        PT.EIf(
                          729246077UL,
                          PT.EBinOp(
                            94793109UL,
                            { module_ = None; function_ = "!=" },
                            PT.EInteger(264400705UL, 5L),
                            PT.EInteger(335743639UL, 6L),
                            PT.NoRail
                          ),
                          PT.EBinOp(
                            775118986UL,
                            { module_ = None; function_ = "+" },
                            PT.EInteger(803876589UL, 5L),
                            PT.EInteger(219131014UL, 2L),
                            PT.NoRail
                          ),
                          PT.ELambda(
                            947647446UL,
                            [ (180359194UL, "y") ],
                            PT.EBinOp(
                              140609068UL,
                              { module_ = None; function_ = "+" },
                              PT.EInteger(450951790UL, 2L),
                              PT.EVariable(402203255UL, "y"),
                              PT.NoRail
                            )
                          )
                        ),
                        PT.EBinOp(
                          265463935UL,
                          { module_ = None; function_ = "+" },
                          PT.EBinOp(
                            312092282UL,
                            { module_ = None; function_ = "+" },
                            PT.EFieldAccess(
                              974664608UL,
                              PT.EVariable(1002893266UL, "x"),
                              "y"
                            ),
                            PT.EFnCall(
                              173079901UL,
                              PT.FQFnName.Stdlib
                                { module_ = "Int"; function_ = "add"; version = 0 },
                              [ PT.EInteger(250221144UL, 6L)
                                PT.EInteger(298149318UL, 2L) ],
                              PT.NoRail
                            ),
                            PT.NoRail
                          ),
                          PT.EList(
                            539797095UL,
                            [ PT.EInteger(267797631UL, 5L)
                              PT.EInteger(352138743UL, 6L)
                              PT.EInteger(430871955UL, 7L) ]
                          ),
                          PT.NoRail
                        )
                      ),
                      PT.ELet(
                        831830073UL,
                        "r",
                        PT.ERecord(
                          109539183UL,
                          [ ("field",
                             PT.EPipe(
                               786862131UL,
                               PT.EInteger(555880460UL, 5L),
                               PT.EBinOp(
                                 1021880969UL,
                                 { module_ = None; function_ = "+" },
                                 PT.EPipeTarget 936577032UL,
                                 PT.EInteger(962393769UL, 2L),
                                 PT.NoRail
                               ),
                               []
                             ))
                            ("constructor",
                             PT.EConstructor(
                               567764301UL,
                               "Ok",
                               [ PT.EConstructor(
                                   646107057UL,
                                   "Error",
                                   [ PT.EConstructor(
                                       689802831UL,
                                       "Just",
                                       [ PT.EConstructor(957916875UL, "Nothing", []) ]
                                     ) ]
                                 ) ]
                             )) ]
                        ),
                        PT.ELet(
                          745304029UL,
                          "m",
                          PT.EMatch(
                            889712088UL,
                            PT.EFnCall(
                              203239466UL,
                              PT.FQFnName.Stdlib
                                { module_ = "Mod"
                                  function_ = "function"
                                  version = 2 },
                              [],
                              PT.NoRail
                            ),
                            [ (PT.PConstructor(
                                1015986188UL,
                                "Ok",
                                [ PT.PVariable(334386852UL, "x") ]
                               ),
                               PT.EVariable(863810169UL, "v"))
                              (PT.PInteger(928253813UL, 5L),
                               PT.EInteger(342670561UL, 6L))
                              (PT.PBool(435227293UL, true),
                               PT.EInteger(232748650UL, 7L))
                              (PT.PCharacter(387662539UL, "c"),
                               PT.ECharacter(657848009UL, "c"))
                              (PT.PString(491115870UL, "string"),
                               PT.EString(820329949UL, "string"))
                              (PT.PNull 701616052UL, PT.ENull 731162955UL)
                              (PT.PVariable(722099983UL, "var"),
                               PT.EBinOp(
                                 275666765UL,
                                 { module_ = None; function_ = "+" },
                                 PT.EInteger(739193732UL, 6L),
                                 PT.EVariable(880556562UL, "var"),
                                 PT.NoRail
                               ))
                              (PT.PFloat(409097457UL, Positive, "5", "6"),
                               PT.EFloat(131187958UL, Positive, "5", "6"))
                              (PT.PBlank 858594159UL, PT.EInteger(135348705UL, 6L)) ]
                          ),
                          PT.ELet(
                            927055617UL,
                            "f",
                            PT.EFeatureFlag(
                              882488977UL,
                              "test",
                              PT.EBool(349352147UL, true),
                              PT.EInteger(578528886UL, 5L),
                              PT.EInteger(562930224UL, 6L)
                            ),
                            PT.EList(
                              23423423UL,
                              [ PT.EPartial(2949606UL, "some 🤬 string", e)
                                PT.ERightPartial(9239755UL, "some 😭 string", e)
                                PT.ELeftPartial(
                                  234885UL,
                                  "some 👨‍👩‍👧‍👦 string",
                                  e
                                ) ]
                            )
                          )
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )


let testPos : PT.Position = { x = 6; y = 6 }

let testHandlerIDs : PT.Handler.ids =
  { moduleID = 129952UL; nameID = 33052UL; modifierID = 10038562UL }

let testHttpHandler : PT.Handler.T =
  let spec = PT.Handler.HTTP("/path", "GET", testHandlerIDs)
  { spec = spec; tlid = 92987663UL; ast = testExpr; pos = testPos }

let testWorker : PT.Handler.T =
  let spec = PT.Handler.Worker("name", testHandlerIDs)
  { spec = spec; tlid = 19930486UL; ast = testExpr; pos = testPos }

let testOldWorker : PT.Handler.T =
  let spec = PT.Handler.OldWorker("MODULE", "name", testHandlerIDs)
  { spec = spec; tlid = 10438664321UL; ast = testExpr; pos = testPos }

let testRepl : PT.Handler.T =
  let spec = PT.Handler.REPL("name", testHandlerIDs)
  { spec = spec; tlid = 10395769302UL; ast = testExpr; pos = testPos }

let testCron1 : PT.Handler.T =
  let spec = PT.Handler.Cron("name", None, testHandlerIDs)
  { spec = spec; tlid = 294906673UL; ast = testExpr; pos = testPos }

let testCron2 : PT.Handler.T =
  let spec = PT.Handler.Cron("name", Some PT.Handler.Every12Hours, testHandlerIDs)
  { spec = spec; tlid = 199385766UL; ast = testExpr; pos = testPos }

let testUnknownHandler : PT.Handler.T =
  let spec = PT.Handler.UnknownHandler("name", "", testHandlerIDs)
  { spec = spec; tlid = 13633UL; ast = testExpr; pos = testPos }


let testHandlers : List<PT.Handler.T> =
  [ testHttpHandler
    testWorker
    testCron1
    testCron2
    testRepl
    testUnknownHandler
    testOldWorker ]

let testType =
  PT.TRecord [ ("nested",
                PT.TList(
                  PT.TDict(
                    PT.TDB(
                      PT.THttpResponse(
                        PT.TOption(
                          PT.TDbList(
                            PT.TResult(PT.TInt, PT.TFn([ PT.TFloat ], PT.TNull))
                          )
                        )
                      )
                    )
                  )
                ))
               ("int", PT.TInt)
               ("int", PT.TFloat)
               ("float", PT.TFloat)
               ("bool", PT.TBool)
               ("null", PT.TNull)
               ("str", PT.TStr)
               ("incomplete", PT.TIncomplete)
               ("error", PT.TError)
               ("date", PT.TDate)
               ("char", PT.TChar)
               ("password", PT.TPassword)
               ("uuid", PT.TUuid)
               ("errorRail", PT.TErrorRail)
               ("bytes", PT.TBytes)
               ("variable ", PT.TVariable "v") ]


let testDB : List<PT.DB.T> =
  [ { tlid = 0UL
      pos = testPos
      nameID = 2399545UL
      name = "User"
      version = 0
      cols =
        [ { name = None; typ = None; nameID = 2949054UL; typeID = 5929202UL }
          { name = None; typ = Some PT.TInt; nameID = 20109857UL; typeID = 299063UL }
          { name = Some "name"
            typ = None
            nameID = 28234232UL
            typeID = 029985336UL }
          { name = Some "value"
            typ = Some testType
            nameID = 923982352UL
            typeID = 289429232UL } ] } ]

let testFunctions : List<PT.UserFunction.T> =
  [ { tlid = 0UL
      name = "myFunc"
      nameID = 1828332UL
      parameters =
        [ { name = "myparam1"
            nameID = 23824935UL
            typ = None
            typeID = 38284244UL
            description = "param1" }
          { name = "myparam2"
            nameID = 92837232UL
            typ = Some testType
            typeID = 239232UL
            description = "param1" } ]
      returnType = testType
      returnTypeID = 23923423UL
      description = "function description"
      infix = false
      body = testExpr } ]

let testUserTypes : List<PT.UserType.T> =
  [ { tlid = 0UL
      name = "User"
      nameID = 92930232UL
      version = 0
      definition =
        PT.UserType.Record [ { name = "prop1"
                               typ = None
                               nameID = 923942342UL
                               typeID = 3452342UL }
                             { name = "prop1"
                               typ = Some testType
                               nameID = 0698978UL
                               typeID = 93494534UL } ] } ]


let testToplevels : List<PT.Toplevel.T> =
  [ List.map PT.Toplevel.TLHandler testHandlers
    List.map PT.Toplevel.TLDB testDB
    List.map PT.Toplevel.TLFunction testFunctions
    List.map PT.Toplevel.TLType testUserTypes ]
  |> List.concat

let toplevelRoundtripTest =
  testMany
    "serializeToplevels"
    (fun tl ->
      let tlid = PT.Toplevel.toTLID tl
      tl
      |> BinarySerialization.serializeToplevel
      |> BinarySerialization.deserializeToplevel tlid
      |> (=) tl)
    (List.map (fun x -> x, true) testToplevels)

let testOplist : PT.Oplist =
  let id = 923832423UL
  let tlid = 94934534UL
  [ PT.SetHandler(testHttpHandler.tlid, testPos, testHttpHandler)
    PT.CreateDB(tlid, testPos, "name")
    PT.AddDBCol(tlid, id, id)
    PT.SetDBColName(tlid, id, "name")
    PT.SetDBColType(tlid, id, "int")
    PT.DeleteTL tlid
    PT.MoveTL(tlid, testPos)
    PT.SetFunction(testFunctions[0])
    PT.ChangeDBColName(tlid, id, "name")
    PT.ChangeDBColType(tlid, id, "int")
    PT.UndoTL tlid
    PT.RedoTL tlid
    PT.SetExpr(tlid, id, testExpr)
    PT.TLSavepoint tlid
    PT.DeleteFunction tlid
    PT.DeleteDBCol(tlid, id)
    PT.RenameDBname(tlid, "newname")
    PT.CreateDBWithBlankOr(tlid, testPos, id, "User")
    PT.SetType(testUserTypes[0])
    PT.DeleteType tlid ]

let oplistRoundtripTest =
  test "roundtrip oplists" {
    let actual =
      testOplist
      |> BinarySerialization.serializeOplist 0UL
      |> BinarySerialization.deserializeOplist 0UL
    Expect.equal actual testOplist ""
  }

/// Generates timestamped test files for binary serialization. These files are used
/// to prove that the binary serialization format is compatible.  When we change the
/// format, we should still be able to read the old files in addition to the new ones
/// (though they will not necessarily have the same output). If we make changes to
/// the binary serialization format (or to the test cases), we generate the files
/// and commit them.
let generateBinarySerializationTestFiles () : unit =
  let binaryData = testOplist |> BinarySerialization.serializeOplist 0UL
  let jsonData = testOplist |> BinarySerialization.Test.serializeOplistToJson 0UL

  let sha1 =
    System.Security.Cryptography.SHA1.HashData(System.ReadOnlySpan binaryData)
    |> SimpleBase.Base16.LowerCase.Encode

  File.writefileBytes Config.Serialization $"oplist-format-{sha1}.bin" binaryData
  File.writefileBytes Config.Serialization "oplist-format-latest.bin" binaryData

  File.writefile Config.Serialization $"oplist-format-{sha1}.json" jsonData
  File.writefile Config.Serialization "oplist-format-latest.json" jsonData

let testTestFiles =
  test "check test files are correct" {
    // We can just check the oplists as expressions and toplevels are contained inside

    // Check that the generated JSON matches what we have saved. This ensures the
    // format have not diverged.
    let expectedJsonContents =
      File.readfile Config.Serialization "oplist-format-latest.json"
    let actualJson = testOplist |> BinarySerialization.Test.serializeOplistToJson 0UL
    // There are times where the json would be the same but the binary would be different
    Expect.equal actualJson expectedJsonContents "check generates the same json"

    // Check that the generated binary data matches what we have saved. This ensures
    // the format has not changed.
    let actualBinary = testOplist |> BinarySerialization.serializeOplist 0UL
    let expectedBinaryBytes =
      File.readfileBytes Config.Serialization "oplist-format-latest.bin"
    Expect.equal actualBinary expectedBinaryBytes "check can read the saved file"

    // Check that all .bin files can be parsed and give us the expected answer (this
    // might not be true as we get more formats, so this may need to be adapted)
    File.lsdir Config.Serialization "./"
    |> List.filter (String.endsWith ".bin")
    |> List.iter (fun filename ->
      let actual =
        File.readfileBytes Config.Serialization filename
        |> BinarySerialization.deserializeOplist 0UL
      Expect.equal actual testOplist "should all equal latest format")
  }


let tests =
  testList
    "BinarySerialization"
    [ toplevelRoundtripTest; oplistRoundtripTest; testTestFiles ]
