///	A zero-based line and column position, mirroring XcodeKit's `XCSourceTextPosition` so selection arithmetic
///	stays testable without linking XcodeKit.
public struct TextPosition: Sendable, Equatable {

	///	The zero-based line number.
	public let lineIndex: Int

	///	The zero-based column number.
	public let columnIndex: Int

	///	Creates a position from its line and column.
	public init(lineIndex: Int, columnIndex: Int) {
		self.lineIndex = lineIndex
		self.columnIndex = columnIndex
	}

}

///	A selection range, mirroring XcodeKit's `XCSourceTextRange`: half-open, so the start position is included,
///	the end position is excluded, and equal positions describe an insertion point.
public struct TextSelection: Sendable, Equatable {

	///	The position of the first selected character.
	public let start: TextPosition

	///	The position one past the last selected character.
	public let end: TextPosition

	///	Creates a selection from its bounding positions.
	public init(start: TextPosition, end: TextPosition) {
		self.start = start
		self.end = end
	}

}

///	One completed line splice: which lines were replaced and by how many.
public struct LineReplacement: Sendable, Equatable {

	///	The zero-based range of lines that was replaced.
	public let lineRange: ClosedRange<Int>

	///	How many lines replaced the range.
	public let replacementLineCount: Int

	///	Creates a record of one splice.
	public init(lineRange: ClosedRange<Int>, replacementLineCount: Int) {
		self.lineRange = lineRange
		self.replacementLineCount = replacementLineCount
	}

}

///	Pure mapping between editor selections and the line ranges a reflow operates on.
public enum SelectionMapping {

	///	The distinct line ranges the selections touch: overlapping ranges merged, bounds clamped to `lineCount`,
	///	sorted descending so bottom-up splicing keeps the indices of unprocessed ranges valid.
	///
	///	Insertion points contribute nothing — an empty `selections` array or one holding only carets yields an
	///	empty result, which is the caller's no-selection no-op. A selection ending at column 0 of a later line
	///	excludes that line, because the range is half-open and touches no character there. Adjacent but
	///	non-overlapping ranges deliberately stay separate, so two distinct selections never reflow as one
	///	paragraph stream.
	public static func lineRanges(of selections: [TextSelection], lineCount: Int) -> [ClosedRange<Int>] {
		let candidateRanges = selections.compactMap { selection in lineRange(of: selection, lineCount: lineCount) }
		let ascendingRanges = candidateRanges.sorted { $0.lowerBound < $1.lowerBound }
		return Array(merged(ascendingRanges).reversed())
	}

	///	The selections to leave in the buffer after the replacements: one whole-line selection per replacement,
	///	ascending, with line numbers shifted by the growth or shrinkage of the replacements above them.
	public static func updatedSelections(for replacements: [LineReplacement]) -> [TextSelection] {
		let ascending = replacements.sorted { $0.lineRange.lowerBound < $1.lineRange.lowerBound }
		let shifted = ascending.reduce(into: (lineDelta: 0, selections: [TextSelection]())) { state, replacement in
			let shiftedStartIndex = replacement.lineRange.lowerBound + state.lineDelta
			state.selections.append(TextSelection(
				start: TextPosition(lineIndex: shiftedStartIndex, columnIndex: 0),
				end: TextPosition(lineIndex: shiftedStartIndex + replacement.replacementLineCount, columnIndex: 0)))
			state.lineDelta += (replacement.replacementLineCount - replacement.lineRange.count)
		}
		return shifted.selections
	}

	///	The closed line range one selection touches, or nil for an insertion point or a range that clamps away.
	private static func lineRange(of selection: TextSelection, lineCount: Int) -> ClosedRange<Int>? {
		let isInsertionPoint = selection.start == selection.end
		let endsAtLaterColumnZero = (selection.end.lineIndex > selection.start.lineIndex)
			&& (selection.end.columnIndex == 0)
		let lastLineIndex = endsAtLaterColumnZero ? (selection.end.lineIndex - 1) : selection.end.lineIndex
		let clampedLastIndex = min(lastLineIndex, lineCount - 1)
		let isUsable = !isInsertionPoint && (selection.start.lineIndex <= clampedLastIndex)
		return isUsable ? (selection.start.lineIndex...clampedLastIndex) : nil
	}

	///	Merges overlapping members of an ascending range list; adjacent ranges are preserved as distinct.
	private static func merged(_ ascendingRanges: [ClosedRange<Int>]) -> [ClosedRange<Int>] {
		ascendingRanges.reduce(into: [ClosedRange<Int>]()) { mergedRanges, range in
			if let last = mergedRanges.last, range.lowerBound <= last.upperBound {
				mergedRanges[mergedRanges.count - 1] = last.lowerBound...max(last.upperBound, range.upperBound)
			} else {
				mergedRanges.append(range)
			}
		}
	}

}
