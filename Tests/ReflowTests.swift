import SourceToolsCore
import Testing

struct ReflowTests {

	@Test func tabIndentedCommentWrapsWithItsTabSeparatorPreserved() async throws {
		let parameters = ReflowParameters(limitWidth: 40, tabWidth: 4)
		let input = ["\t//\tAlpha beta gamma delta epsilon zeta"]

		#expect(Reflow.reflowedLines(of: input, parameters: parameters) == [
			"\t//\tAlpha beta gamma delta epsilon",
			"\t//\tzeta",
		])
	}

	@Test func commentAtTheFullCommentWidthLimitWrapsAtOneHundredTwenty() async throws {
		let parameters = ReflowParameters(limitWidth: 120, tabWidth: 4)
		let word = "abcdefghij"
		let input = ["\t//\t" + Array(repeating: word, count: 12).joined(separator: " ")]

		#expect(Reflow.reflowedLines(of: input, parameters: parameters) == [
			"\t//\t" + Array(repeating: word, count: 10).joined(separator: " "),
			"\t//\t" + Array(repeating: word, count: 2).joined(separator: " "),
		])
	}

	@Test func shortLinesJoinBeforeRewrapping() async throws {
		let parameters = ReflowParameters(limitWidth: 20, tabWidth: 4)
		let input = ["hello world", "this is", "a test"]

		#expect(Reflow.reflowedLines(of: input, parameters: parameters) == ["hello world this is", "a test"])
	}

	@Test func oversizedWordOverflowsOnItsOwnLine() async throws {
		let parameters = ReflowParameters(limitWidth: 10, tabWidth: 4)
		let input = ["short verylongwordexceedslimit ok"]

		#expect(Reflow.reflowedLines(of: input, parameters: parameters) == [
			"short",
			"verylongwordexceedslimit",
			"ok",
		])
	}

	@Test func blankLinesSeparateParagraphsAndSurviveVerbatim() async throws {
		let parameters = ReflowParameters(limitWidth: 12, tabWidth: 4)
		let input = ["# aa bb cc dd ee ff", "", "# gg hh"]

		#expect(Reflow.reflowedLines(of: input, parameters: parameters) == [
			"# aa bb cc",
			"# dd ee ff",
			"",
			"# gg hh",
		])
	}

	@Test func documentationCommentParagraphJoinsUnderItsLeader() async throws {
		let parameters = ReflowParameters(limitWidth: 40, tabWidth: 4)
		let input = ["\t///\tSummary line one", "\t///\tand two"]

		#expect(Reflow.reflowedLines(of: input, parameters: parameters) == ["\t///\tSummary line one and two"])
	}

	@Test func leaderOnlyLineSeparatesCommentParagraphs() async throws {
		let parameters = ReflowParameters(limitWidth: 20, tabWidth: 4)
		let input = ["\t// first paragraph", "\t//", "\t// second paragraph"]

		#expect(Reflow.reflowedLines(of: input, parameters: parameters) == [
			"\t// first",
			"\t// paragraph",
			"\t//",
			"\t// second",
			"\t// paragraph",
		])
	}

	@Test func mixedLeaderParagraphPassesThroughUnchanged() async throws {
		let parameters = ReflowParameters(limitWidth: 10, tabWidth: 4)
		let input = ["code line that is long", "// comment line that is long"]

		#expect(Reflow.reflowedLines(of: input, parameters: parameters) == input)
	}

	@Test func blockCommentDelimitersProtectTheirParagraph() async throws {
		let parameters = ReflowParameters(limitWidth: 10, tabWidth: 4)
		let input = ["/** Summary sentence here", " * more words follow", " */"]

		#expect(Reflow.reflowedLines(of: input, parameters: parameters) == input)
	}

	@Test func interiorStarLinesReflowWhenSelectedAlone() async throws {
		let parameters = ReflowParameters(limitWidth: 20, tabWidth: 4)
		let input = [" * one two", " * three"]

		#expect(Reflow.reflowedLines(of: input, parameters: parameters) == [" * one two three"])
	}

	@Test func whitespaceOnlySelectionPassesThroughUnchanged() async throws {
		let parameters = ReflowParameters(limitWidth: 10, tabWidth: 4)
		let input = ["", "\t", "  "]

		#expect(Reflow.reflowedLines(of: input, parameters: parameters) == input)
	}

	@Test func emptyInputYieldsEmptyOutput() async throws {
		let parameters = ReflowParameters(limitWidth: 10, tabWidth: 4)

		#expect(Reflow.reflowedLines(of: [], parameters: parameters) == [])
	}

	@Test func eachParagraphKeepsItsOwnFirstLineIndentation() async throws {
		let parameters = ReflowParameters(limitWidth: 20, tabWidth: 4)
		let input = ["\tindented paragraph one", "", "    spaced paragraph two"]

		#expect(Reflow.reflowedLines(of: input, parameters: parameters) == [
			"\tindented",
			"\tparagraph one",
			"",
			"    spaced paragraph",
			"    two",
		])
	}

	@Test func parametersClampToAMinimumOfOne() async throws {
		let parameters = ReflowParameters(limitWidth: 0, tabWidth: -3)

		#expect(parameters.limitWidth == 1)
		#expect(parameters.tabWidth == 1)
	}

	@Test func reflowingIsIdempotent() async throws {
		let cases: [(input: [String], parameters: ReflowParameters)] = [
			(["\t//\tAlpha beta gamma delta epsilon zeta"], ReflowParameters(limitWidth: 40, tabWidth: 4)),
			(["hello world", "this is", "a test"], ReflowParameters(limitWidth: 20, tabWidth: 4)),
			(["short verylongwordexceedslimit ok"], ReflowParameters(limitWidth: 10, tabWidth: 4)),
			(["# aa bb cc dd ee ff", "", "# gg hh"], ReflowParameters(limitWidth: 12, tabWidth: 4)),
			(["\t// first paragraph", "\t//", "\t// second paragraph"], ReflowParameters(limitWidth: 20, tabWidth: 4)),
			(["/** Summary sentence here", " * more words follow", " */"], ReflowParameters(limitWidth: 10, tabWidth: 4)),
			(["\tindented paragraph one", "", "    spaced paragraph two"], ReflowParameters(limitWidth: 20, tabWidth: 4)),
		]
		for reflowCase in cases {
			let once = Reflow.reflowedLines(of: reflowCase.input, parameters: reflowCase.parameters)
			let twice = Reflow.reflowedLines(of: once, parameters: reflowCase.parameters)

			#expect(twice == once)
		}
	}

}
