import SourceToolsCore
import Testing

struct SelectionMappingTests {

	private func selection(_ startLine: Int, _ startColumn: Int, _ endLine: Int, _ endColumn: Int) -> TextSelection {
		TextSelection(
			start: TextPosition(lineIndex: startLine, columnIndex: startColumn),
			end: TextPosition(lineIndex: endLine, columnIndex: endColumn))
	}

	@Test func insertionPointContributesNothing() async throws {
		#expect(SelectionMapping.lineRanges(of: [selection(5, 3, 5, 3)], lineCount: 10) == [])
	}

	@Test func sameLineSelectionTouchesThatLine() async throws {
		#expect(SelectionMapping.lineRanges(of: [selection(2, 1, 2, 5)], lineCount: 10) == [2...2])
	}

	@Test func endAtColumnZeroExcludesItsLine() async throws {
		#expect(SelectionMapping.lineRanges(of: [selection(1, 0, 3, 0)], lineCount: 10) == [1...2])
	}

	@Test func endPastColumnZeroIncludesItsLine() async throws {
		#expect(SelectionMapping.lineRanges(of: [selection(1, 0, 3, 4)], lineCount: 10) == [1...3])
	}

	@Test func rangeIsClampedToTheLineCount() async throws {
		#expect(SelectionMapping.lineRanges(of: [selection(0, 0, 12, 5)], lineCount: 10) == [0...9])
	}

	@Test func selectionEntirelyPastTheEndContributesNothing() async throws {
		#expect(SelectionMapping.lineRanges(of: [selection(12, 0, 15, 0)], lineCount: 10) == [])
	}

	@Test func overlappingSelectionsMergeIntoOneRange() async throws {
		let selections = [selection(0, 0, 5, 0), selection(3, 0, 8, 0)]

		#expect(SelectionMapping.lineRanges(of: selections, lineCount: 10) == [0...7])
	}

	@Test func adjacentSelectionsStaySeparate() async throws {
		let selections = [selection(0, 0, 2, 5), selection(3, 0, 5, 5)]

		#expect(SelectionMapping.lineRanges(of: selections, lineCount: 10) == [3...5, 0...2])
	}

	@Test func rangesAreReturnedInDescendingOrder() async throws {
		let selections = [selection(0, 0, 0, 3), selection(4, 0, 4, 3), selection(8, 0, 8, 3)]

		#expect(SelectionMapping.lineRanges(of: selections, lineCount: 10) == [8...8, 4...4, 0...0])
	}

	@Test func replacementYieldsAWholeLineSelectionOverTheNewText() async throws {
		let replacements = [LineReplacement(lineRange: 5...8, replacementLineCount: 2)]

		#expect(SelectionMapping.updatedSelections(for: replacements) == [selection(5, 0, 7, 0)])
	}

	@Test func laterSelectionsShiftByTheGrowthOfEarlierReplacements() async throws {
		let replacements = [
			LineReplacement(lineRange: 10...12, replacementLineCount: 5),
			LineReplacement(lineRange: 2...4, replacementLineCount: 1),
		]

		#expect(SelectionMapping.updatedSelections(for: replacements) == [
			selection(2, 0, 3, 0),
			selection(8, 0, 13, 0),
		])
	}

}
