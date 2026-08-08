import SourceToolsCore
import Testing

struct ReflowMeasurementTests {

	@Test func tabAtLineStartAdvancesOneTabStop() async throws {
		#expect(Reflow.renderedWidth(of: "\t", tabWidth: 4) == 4)
		#expect(Reflow.renderedWidth(of: "\tA", tabWidth: 4) == 5)
	}

	@Test func tabAfterPartialColumnAdvancesToNextMultiple() async throws {
		#expect(Reflow.renderedWidth(of: "AB\t", tabWidth: 4) == 4)
		#expect(Reflow.renderedWidth(of: "ABCD\t", tabWidth: 4) == 8)
	}

	@Test func consecutiveTabsEachAdvanceOneTabStop() async throws {
		#expect(Reflow.renderedWidth(of: "\t\t", tabWidth: 4) == 8)
		#expect(Reflow.renderedWidth(of: "\t//\t", tabWidth: 4) == 8)
	}

	@Test func tabWidthOtherThanFourIsRespected() async throws {
		#expect(Reflow.renderedWidth(of: "\tA", tabWidth: 8) == 9)
		#expect(Reflow.renderedWidth(of: "AB\t", tabWidth: 8) == 8)
	}

	@Test func emptyTextHasZeroWidth() async throws {
		#expect(Reflow.renderedWidth(of: "", tabWidth: 4) == 0)
	}

	@Test func leadingWhitespaceStopsAtFirstOtherCharacter() async throws {
		#expect(Reflow.leadingWhitespace(of: " \t x") == " \t ")
		#expect(Reflow.leadingWhitespace(of: "x  ") == "")
	}

	@Test func leadingWhitespaceOfWhitespaceOnlyLineIsTheWholeLine() async throws {
		#expect(Reflow.leadingWhitespace(of: "  \t") == "  \t")
		#expect(Reflow.leadingWhitespace(of: "") == "")
	}

}
