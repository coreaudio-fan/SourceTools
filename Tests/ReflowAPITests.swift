//	These tests exercise SourceToolsCore exactly as another module sees it, through a plain import.
//
//	Never add @testable to this file. It would make every internal declaration visible and silently
//	destroy the one thing this suite exists to check: that the published API is reachable from
//	outside the framework.
//
//	Access control is enforced at compile time, so a regression breaks the build here rather than
//	failing a test. The #expect calls keep each test honest at runtime, but the fact that this file
//	compiles at all is the real assertion.
import SourceToolsCore
import Testing

struct ReflowAPITests {

	private func requireSendable(_ value: some Sendable) -> some Sendable {
		value
	}

	@Test func clientCanConstructEveryPublishedValueType() async throws {
		let parameters = ReflowParameters(limitWidth: 80, tabWidth: 4)
		let leader = CommentLeader(token: "//", separator: "\t")
		let position = TextPosition(lineIndex: 0, columnIndex: 0)
		let selection = TextSelection(start: position, end: position)
		let replacement = LineReplacement(lineRange: 0...1, replacementLineCount: 1)

		#expect(parameters.limitWidth == 80)
		#expect(leader.token == "//")
		#expect(selection.start == selection.end)
		#expect(replacement.replacementLineCount == 1)
	}

	@Test func publishedValueTypesAreSendable() async throws {
		let sendables: [any Sendable] = [
			requireSendable(ReflowParameters(limitWidth: 80, tabWidth: 4)),
			requireSendable(CommentLeader(token: "//", separator: " ")),
			requireSendable(TextPosition(lineIndex: 0, columnIndex: 0)),
			requireSendable(TextSelection(
				start: TextPosition(lineIndex: 0, columnIndex: 0),
				end: TextPosition(lineIndex: 0, columnIndex: 0))),
			requireSendable(LineReplacement(lineRange: 0...0, replacementLineCount: 1)),
		]

		#expect(sendables.count == 5)
	}

	@Test func clientCanReachEveryReflowOperation() async throws {
		let parameters = ReflowParameters(limitWidth: 20, tabWidth: 4)
		let indentation = Reflow.leadingWhitespace(of: "\ttext")
		let width = Reflow.renderedWidth(of: "\tab", tabWidth: 4)
		let leaderMatch = Reflow.commentLeader(of: "// text")
		let wordList = Reflow.words(of: "a b")
		let groups = Reflow.filledWordGroups(of: wordList, prefixWidth: 0, limitWidth: 20)
		let lines = Reflow.reflowedLines(of: ["hello world"], parameters: parameters)

		#expect(indentation == "\t")
		#expect(width == 6)
		#expect(leaderMatch != nil)
		#expect(groups == [["a", "b"]])
		#expect(lines == ["hello world"])
	}

	@Test func clientCanMapSelectionsBothWays() async throws {
		let selection = TextSelection(
			start: TextPosition(lineIndex: 0, columnIndex: 0),
			end: TextPosition(lineIndex: 1, columnIndex: 0))
		let ranges = SelectionMapping.lineRanges(of: [selection], lineCount: 5)
		let updated = SelectionMapping.updatedSelections(for: [
			LineReplacement(lineRange: 0...0, replacementLineCount: 2),
		])

		#expect(ranges == [0...0])
		#expect(updated.count == 1)
	}

	@Test func clientCanResolveWidthsPurelyAndAtTheEdge() async throws {
		let fallbackResolved = WidthResolution.resolvedWidth(xcodeReformatWidth: nil)
		let xcodeWidth = XcodeDefaults.reformatWidth()

		#expect(fallbackResolved == WidthResolution.fallbackWidth)
		#expect((xcodeWidth == nil) || (xcodeWidth ?? 0 >= 1))
	}

}
