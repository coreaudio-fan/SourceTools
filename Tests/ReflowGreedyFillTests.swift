import SourceToolsCore
import Testing

struct ReflowGreedyFillTests {

	private func filledStrings(of text: Substring, prefixWidth: Int, limitWidth: Int) -> [[String]] {
		let groups = Reflow.filledWordGroups(
			of: Reflow.words(of: text),
			prefixWidth: prefixWidth,
			limitWidth: limitWidth)
		return groups.map { group in group.map { word in String(word) } }
	}

	@Test func wordsSplitOnSpacesAndTabsAndCollapseRuns() async throws {
		#expect(Reflow.words(of: "a  b\tc \t d") == ["a", "b", "c", "d"])
	}

	@Test func nonBreakingSpaceStaysInsideItsWord() async throws {
		#expect(Reflow.words(of: "a\u{00A0}b c") == ["a\u{00A0}b", "c"])
	}

	@Test func wordEndingExactlyAtTheLimitFits() async throws {
		#expect(filledStrings(of: "hello world", prefixWidth: 0, limitWidth: 11) == [["hello", "world"]])
	}

	@Test func wordOnePastTheLimitStartsANewGroup() async throws {
		#expect(filledStrings(of: "hello world", prefixWidth: 0, limitWidth: 10) == [["hello"], ["world"]])
	}

	@Test func oversizedWordOverflowsAloneWithoutBeingBroken() async throws {
		#expect(filledStrings(of: "verylongword", prefixWidth: 0, limitWidth: 5) == [["verylongword"]])
	}

	@Test func limitNotExceedingPrefixYieldsOneWordPerGroup() async throws {
		#expect(filledStrings(of: "a b c", prefixWidth: 10, limitWidth: 8) == [["a"], ["b"], ["c"]])
	}

	@Test func prefixWidthCountsAgainstTheLimit() async throws {
		#expect(filledStrings(of: "aa bb", prefixWidth: 4, limitWidth: 9) == [["aa", "bb"]])
		#expect(filledStrings(of: "aa bb", prefixWidth: 5, limitWidth: 9) == [["aa"], ["bb"]])
	}

	@Test func emptyWordListYieldsNoGroups() async throws {
		#expect(filledStrings(of: "", prefixWidth: 0, limitWidth: 10) == [])
	}

}
