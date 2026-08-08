import Foundation
import SourceToolsCore
import XcodeKit

///	Reflows the lines touched by the current selections at the resolved wrap column.
///
///	All work happens synchronously on whichever thread Xcode chose — XcodeKit guarantees nothing about it —
///	so no XcodeKit object ever crosses an isolation boundary. No cancellation handler is installed: the
///	reflow is bounded and fast, and XcodeKit discards the mutations of a canceled invocation regardless.
nonisolated final class ReflowSelectionCommand: NSObject, XCSourceEditorCommand {

	func perform(
		with invocation: XCSourceEditorCommandInvocation,
		completionHandler: @escaping ((any Error)?) -> Void) {
		let buffer = invocation.buffer
		let selections = buffer.selections.compactMap { boxedRange in
			(boxedRange as? XCSourceTextRange).map { range in textSelection(of: range) }
		}
		let lineRanges = SelectionMapping.lineRanges(of: selections, lineCount: buffer.lines.count)
		//	An empty result means every selection is an insertion point: a successful no-op that leaves the
		//	buffer and the selections untouched, per the requirement that no selection processes no lines.
		if !lineRanges.isEmpty {
			let parameters = ReflowParameters(
				limitWidth: WidthResolver.currentResolution().width,
				tabWidth: buffer.tabWidth)
			let replacements = lineRanges.map { lineRange in
				replacedLines(in: lineRange, of: buffer, parameters: parameters)
			}
			updateSelections(of: buffer, to: SelectionMapping.updatedSelections(for: replacements))
		}
		completionHandler(nil)
	}

	///	The engine's mirror of one editor selection range.
	private func textSelection(of range: XCSourceTextRange) -> TextSelection {
		TextSelection(
			start: TextPosition(lineIndex: range.start.line, columnIndex: range.start.column),
			end: TextPosition(lineIndex: range.end.line, columnIndex: range.end.column))
	}

	///	One line split into its text and its terminator; XcodeKit documents that buffer lines include their
	///	line endings, and the engine works on terminator-free lines.
	private func splitTerminator(of line: String) -> (body: String, terminator: String) {
		let terminator = line.hasSuffix("\r\n") ? "\r\n" : (line.hasSuffix("\n") ? "\n" : "")
		return (String(line.dropLast(terminator.count)), terminator)
	}

	///	Reflows one line range in place and reports the splice.
	private func replacedLines(
		in lineRange: ClosedRange<Int>,
		of buffer: XCSourceTextBuffer,
		parameters: ReflowParameters) -> LineReplacement {
		let originalLines = lineRange.map { lineIndex in (buffer.lines[lineIndex] as? String) ?? "" }
		let splitLines = originalLines.map { line in splitTerminator(of: line) }
		let reflowedBodies = Reflow.reflowedLines(of: splitLines.map { $0.body }, parameters: parameters)
		//	Every replacement line takes the range's first terminator, except the last, which takes the last
		//	original line's terminator — possibly empty at the end of the buffer.
		let bodyTerminator = splitLines.first.map { $0.terminator } ?? "\n"
		let lastTerminator = splitLines.last.map { $0.terminator } ?? "\n"
		let replacementLines = reflowedBodies.enumerated().map { entry in
			let isLastLine = entry.offset == (reflowedBodies.count - 1)
			return entry.element + (isLastLine ? lastTerminator : bodyTerminator)
		}
		buffer.lines.replaceObjects(
			in: NSRange(location: lineRange.lowerBound, length: lineRange.count),
			withObjectsFrom: replacementLines)
		return LineReplacement(lineRange: lineRange, replacementLineCount: replacementLines.count)
	}

	///	Points the buffer's selections at the freshly reflowed regions. XcodeKit publishes `selections` as a
	///	readonly mutable array, so its contents are replaced rather than the property reassigned.
	private func updateSelections(of buffer: XCSourceTextBuffer, to selections: [TextSelection]) {
		let ranges = selections.map { selection in
			XCSourceTextRange(
				start: XCSourceTextPosition(line: selection.start.lineIndex, column: selection.start.columnIndex),
				end: XCSourceTextPosition(line: selection.end.lineIndex, column: selection.end.columnIndex))
		}
		buffer.selections.removeAllObjects()
		buffer.selections.addObjects(from: ranges)
	}

}
