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

///	One independently reflowing piece of a paragraph.
///
///	A plain unit is a prose flow: one or more lines sharing a text-start column, joined and refilled under
///	the first line's verbatim prefix. A columnated unit is a single line whose interior tabs declare
///	alignment: its head (everything through its last interior tab) is kept verbatim, and only the text
///	after the head — plus any absorbed overflow lines — flows, hanging at the head's end column.
enum ReflowUnit {

	case plain(prefix: String, textStartColumn: Int, words: [Substring])
	case columnated(headLine: String, hangingColumn: Int, continuationPrefix: String, words: [Substring])

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

	///	Reflows one paragraph as independently wrapped units.
	///
	///	A paragraph whose lines disagree about their leader token is returned unchanged, because reflowing
	///	it would fold marker characters into the word stream; this is also what keeps block-comment
	///	delimiter lines protective of their block.
	static func reflowedParagraph(of lines: [AnalyzedLine], parameters: ReflowParameters) -> [String] {
		let uniqueTokens = Set(lines.map { $0.leader?.token })
		guard uniqueTokens.count == 1 else {
			return lines.map { $0.original }
		}
		let units = reflowUnits(of: lines, tabWidth: parameters.tabWidth)
		return units.flatMap { unit in renderedUnit(unit, parameters: parameters) }
	}

	///	Segments a leader-consistent paragraph into reflow units.
	///
	///	The structure is read entirely from tabs: a line with an interior tab is columnated and always
	///	stands alone; a plain line continues the plain unit above it at the same text-start column, is
	///	absorbed by the columnated unit above it when it starts exactly at that unit's hanging column, and
	///	otherwise begins its own plain unit.
	static func reflowUnits(of lines: [AnalyzedLine], tabWidth: Int) -> [ReflowUnit] {
		lines.reduce(into: [ReflowUnit]()) { units, line in
			let verbatimPrefix = String(line.indentation) + (line.leader.map { $0.token + $0.separator } ?? "")
			let textStartColumn = renderedWidth(of: verbatimPrefix[...], tabWidth: tabWidth)
			if let lastTabIndex = line.text.lastIndex(of: "\t") {
				let flow = line.text[line.text.index(after: lastTabIndex)...]
				let headLine = String(line.original.dropLast(flow.count))
				let hangingColumn = renderedWidth(of: headLine[...], tabWidth: tabWidth)
				let basePrefix = String(line.indentation) + (line.leader.map { $0.token } ?? "")
				let basePrefixWidth = renderedWidth(of: basePrefix[...], tabWidth: tabWidth)
				units.append(.columnated(
					headLine: headLine,
					hangingColumn: hangingColumn,
					continuationPrefix: basePrefix + tabPadding(from: basePrefixWidth, to: hangingColumn, tabWidth: tabWidth),
					words: words(of: flow)))
			} else {
				switch units.last {
					case .plain(let prefix, let column, let unitWords) where column == textStartColumn:
						units[units.count - 1] = .plain(
							prefix: prefix,
							textStartColumn: column,
							words: unitWords + words(of: line.text))

					case .columnated(let headLine, let hangingColumn, let continuationPrefix, let unitWords)
						where hangingColumn == textStartColumn:
						units[units.count - 1] = .columnated(
							headLine: headLine,
							hangingColumn: hangingColumn,
							continuationPrefix: continuationPrefix,
							words: unitWords + words(of: line.text))

					default:
						units.append(.plain(
							prefix: verbatimPrefix,
							textStartColumn: textStartColumn,
							words: words(of: line.text)))
				}
			}
		}
	}

	///	Renders one unit as wrapped output lines.
	static func renderedUnit(_ unit: ReflowUnit, parameters: ReflowParameters) -> [String] {
		let lines: [String]
		switch unit {
			case .plain(let prefix, let textStartColumn, let unitWords):
				let groups = filledWordGroups(
					of: unitWords,
					prefixWidth: textStartColumn,
					limitWidth: parameters.limitWidth)
				lines = groups.map { group in prefix + group.joined(separator: " ") }

			case .columnated(let headLine, let hangingColumn, let continuationPrefix, let unitWords):
				let groups = filledWordGroups(
					of: unitWords,
					prefixWidth: hangingColumn,
					limitWidth: parameters.limitWidth)
				let firstLine = headLine + (groups.first.map { group in group.joined(separator: " ") } ?? "")
				let continuationLines = groups.dropFirst().map { group in
					continuationPrefix + group.joined(separator: " ")
				}
				lines = [firstLine] + continuationLines
		}
		return lines
	}

	///	Tabs sufficient to advance the column from `startColumn` to `targetColumn`.
	///
	///	The caller guarantees `targetColumn` is a later tab stop, which every hanging column is by
	///	construction: it is the column immediately after a tab character, and tabs land only on stops.
	private static func tabPadding(from startColumn: Int, to targetColumn: Int, tabWidth: Int) -> String {
		let firstStopColumn = (startColumn + tabWidth) - (startColumn % tabWidth)
		let followingTabCount = (targetColumn - firstStopColumn) / tabWidth
		return String(repeating: "\t", count: 1 + followingTabCount)
	}

}
