///	One line of a selection, analyzed into the parts the reflow decisions need.
struct AnalyzedLine {

	///	The line exactly as given, without its terminator.
	let original: String

	///	The line's leading whitespace.
	let indentation: Substring

	///	The comment leader after the indentation, when one is recognized.
	let leader: CommentLeader?

	///	The text after the indentation and any leader.
	let text: Substring

	///	True when the line separates paragraphs: it is entirely whitespace, or carries only a leader.
	let isSeparator: Bool

}

///	A maximal run of consecutive lines that either reflow together as a paragraph or pass through verbatim.
enum LineRun {

	case paragraph([AnalyzedLine])
	case separators([AnalyzedLine])

}

extension Reflow {

	///	Analyzes one terminator-free line into its indentation, leader, text, and separator role.
	static func analyzedLine(of line: String) -> AnalyzedLine {
		let indentation = leadingWhitespace(of: line[...])
		let remainder = line[indentation.endIndex...]
		let leaderMatch = commentLeader(of: remainder)
		let text = leaderMatch.map { $0.text } ?? remainder
		let isSeparator = text.allSatisfy { character in (character == " ") || (character == "\t") }
		return AnalyzedLine(
			original: line,
			indentation: indentation,
			leader: leaderMatch.map { $0.leader },
			text: text,
			isSeparator: isSeparator)
	}

	///	Groups analyzed lines into maximal alternating paragraph and separator runs, preserving order.
	static func lineRuns(of analyzedLines: [AnalyzedLine]) -> [LineRun] {
		analyzedLines.reduce(into: [LineRun]()) { runs, line in
			switch (runs.last, line.isSeparator) {
			case (.separators(let lines), true):
				runs[runs.count - 1] = .separators(lines + [line])

			case (.paragraph(let lines), false):
				runs[runs.count - 1] = .paragraph(lines + [line])

			case (_, true):
				runs.append(.separators([line]))

			case (_, false):
				runs.append(.paragraph([line]))
			}
		}
	}

	///	Reflows one paragraph: its words are re-wrapped under the first line's indentation and the paragraph's
	///	common comment leader. A paragraph whose lines disagree about their leader token is returned unchanged,
	///	because reflowing it would fold marker characters into the word stream.
	static func reflowedParagraph(of lines: [AnalyzedLine], parameters: ReflowParameters) -> [String] {
		let uniqueTokens = Set(lines.map { $0.leader?.token })
		guard let firstLine = lines.first, uniqueTokens.count == 1 else {
			return lines.map { $0.original }
		}
		let leaderText = firstLine.leader.map { $0.token + $0.separator } ?? ""
		let prefix = String(firstLine.indentation) + leaderText
		let prefixWidth = renderedWidth(of: prefix[...], tabWidth: parameters.tabWidth)
		let wordList = lines.flatMap { words(of: $0.text) }
		let groups = filledWordGroups(of: wordList, prefixWidth: prefixWidth, limitWidth: parameters.limitWidth)
		return groups.map { group in prefix + group.joined(separator: " ") }
	}

}
