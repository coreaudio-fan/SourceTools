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

	@Test func alignedParameterListsReflowWithoutJoining() async throws {
		let parameters = ReflowParameters(limitWidth: 120, tabWidth: 4)
		let input = [
			"\t///\tMake a bunch of nodes and arcs in one pass",
			"\t///",
			"\t///\t- Parameters:",
			"\t///\t\t- nodes:\ta node is created and associated with each NodeData in this array",
			"\t///\t\t- arcs:\t\tan arc is created using the data in each tuple in this array, the indexes refer to the indexes of the array passed as the with nodes: argument.",
		]

		#expect(Reflow.reflowedLines(of: input, parameters: parameters) == [
			"\t///\tMake a bunch of nodes and arcs in one pass",
			"\t///",
			"\t///\t- Parameters:",
			"\t///\t\t- nodes:\ta node is created and associated with each NodeData in this array",
			"\t///\t\t- arcs:\t\tan arc is created using the data in each tuple in this array, the indexes refer to the indexes",
			"\t///\t\t\t\t\tof the array passed as the with nodes: argument.",
		])
	}

	@Test func absorbedOverflowRejoinsItsColumnatedLine() async throws {
		let parameters = ReflowParameters(limitWidth: 120, tabWidth: 4)
		let input = [
			"\t///\tMake a bunch of nodes and arcs in one pass in a really long comment that goes on and on and on",
			"\t///\tfor well over 120 columns and still doesn't stop",
			"\t///",
			"\t///\t- Parameters:",
			"\t///\t\t- nodes:\ta node is created and associated with each NodeData in this array",
			"\t///\t\t\t\t\tbut this text needs to be reflowed with the line above it so that this whole unit is less than the 120 column wrap point.",
			"\t///\t\t- arcs:\t\tan arc is created using the data in each tuple in this array, the indexes refer to the indexes of the array passed as the with nodes: argument.",
		]

		#expect(Reflow.reflowedLines(of: input, parameters: parameters) == [
			"\t///\tMake a bunch of nodes and arcs in one pass in a really long comment that goes on and on and on for well over 120",
			"\t///\tcolumns and still doesn't stop",
			"\t///",
			"\t///\t- Parameters:",
			"\t///\t\t- nodes:\ta node is created and associated with each NodeData in this array but this text needs to be",
			"\t///\t\t\t\t\treflowed with the line above it so that this whole unit is less than the 120 column wrap point.",
			"\t///\t\t- arcs:\t\tan arc is created using the data in each tuple in this array, the indexes refer to the indexes",
			"\t///\t\t\t\t\tof the array passed as the with nodes: argument.",
		])
	}

	@Test func depthChangeSplitsProseUnits() async throws {
		let parameters = ReflowParameters(limitWidth: 40, tabWidth: 4)
		let input = ["// aa bb cc dd", "//\tdeep one"]

		#expect(Reflow.reflowedLines(of: input, parameters: parameters) == input)
	}

	@Test func columnatedLinesNeverJoinTheirNeighbors() async throws {
		let parameters = ReflowParameters(limitWidth: 60, tabWidth: 4)
		let input = ["# plain prose here", "# label:\tvalue words", "# more plain prose"]

		#expect(Reflow.reflowedLines(of: input, parameters: parameters) == input)
	}

	@Test func overflowIsAbsorbedOnlyAtTheExactHangingColumn() async throws {
		let parameters = ReflowParameters(limitWidth: 60, tabWidth: 4)
		let absorbed = ["# label:\tone two", "#\t\t\tthree four"]
		let offColumn = ["# label:\tone two", "#\t\tthree four"]

		#expect(Reflow.reflowedLines(of: absorbed, parameters: parameters) == ["# label:\tone two three four"])
		#expect(Reflow.reflowedLines(of: offColumn, parameters: parameters) == offColumn)
	}

	@Test func columnatedLineEndingInATabPassesThrough() async throws {
		let parameters = ReflowParameters(limitWidth: 40, tabWidth: 4)
		let input = ["\t// label:\t"]

		#expect(Reflow.reflowedLines(of: input, parameters: parameters) == input)
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
			([
				"\t///\t- Parameters:",
				"\t///\t\t- nodes:\ta node is created and associated with each NodeData in this array",
				"\t///\t\t- arcs:\t\tan arc is created using the data in each tuple in this array, the indexes refer to the indexes of the array passed as the with nodes: argument.",
			], ReflowParameters(limitWidth: 120, tabWidth: 4)),
			([
				"\t///\tMake a bunch of nodes and arcs in one pass in a really long comment that goes on and on and on",
				"\t///\tfor well over 120 columns and still doesn't stop",
				"\t///",
				"\t///\t\t- nodes:\ta node is created and associated with each NodeData in this array",
				"\t///\t\t\t\t\tbut this text needs to be reflowed with the line above it so that this whole unit is less than the 120 column wrap point.",
			], ReflowParameters(limitWidth: 120, tabWidth: 4)),
		]
		for reflowCase in cases {
			let once = Reflow.reflowedLines(of: reflowCase.input, parameters: reflowCase.parameters)
			let twice = Reflow.reflowedLines(of: once, parameters: reflowCase.parameters)

			#expect(twice == once)
		}
	}

}
