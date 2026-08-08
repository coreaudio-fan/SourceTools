///	Parameters governing one reflow operation.
public struct ReflowParameters: Sendable, Equatable {

	///	The rendered-column limit each output line must fit within, measured with tabs expanded.
	public let limitWidth: Int

	///	The rendered width of one tab stop; a tab character advances the column to the next multiple of this width.
	public let tabWidth: Int

	///	Creates parameters, clamping both widths to a minimum of 1.
	public init(limitWidth: Int, tabWidth: Int) {
		self.limitWidth = max(1, limitWidth)
		self.tabWidth = max(1, tabWidth)
	}

}

///	Pure text-reflow operations: lines in, lines out, no I/O and no editor dependencies.
public enum Reflow {

	///	Reflows the given terminator-free lines at the limit width.
	///
	///	Consecutive non-blank lines form a paragraph: their words are joined into one stream and greedily re-wrapped,
	///	and every output line carries the paragraph's first-line indentation verbatim plus the paragraph's common
	///	comment leader. Blank lines and leader-only lines pass through verbatim and separate the paragraphs. A
	///	paragraph whose lines disagree about their comment leader is passed through unchanged, because reflowing it
	///	would fold marker characters into the text.
	public static func reflowedLines(of lines: [String], parameters: ReflowParameters) -> [String] {
		let runs = lineRuns(of: lines.map { analyzedLine(of: $0) })
		return runs.flatMap { run in
			switch run {
			case .separators(let separatorLines): separatorLines.map { $0.original }
			case .paragraph(let paragraphLines): reflowedParagraph(of: paragraphLines, parameters: parameters)
			}
		}
	}

}
