open Prelude
open Tester
open Analysis
module B = BlankOr

let run = () => {
  describe("requestAnalysis", () =>
    test("on tlid not found", () => {
      let m = {...Defaults.defaultModel, deletedUserFunctions: TLIDDict.empty}

      expect(requestAnalysis(m, TLID.fromString("123"), "abc")) |> toEqual(Cmd.none)
    })
  )
  ()
}
