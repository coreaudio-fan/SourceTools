extension Reflow {

	///	Splits `text` into words at space and tab characters only.
	///
	///	Other Unicode whitespace, such as a non-breaking space, deliberately stays inside its word — a non-breaking
	///	space exists precisely to forbid a line break at its position.
	public static func words(of text: Substring) -> [Substring] {
		text.split { character in (character == " ") || (character == "\t") }
	}

	///	Greedily packs `wordList` into groups of at most `limitWidth` rendered columns, of which `prefixWidth`
	///	columns are already spent on every line.
	///
	///	Each emitted group is maximal: adding its successor word would exceed the limit. A word that alone exceeds
	///	the remaining budget is emitted alone and overflows rather than being broken or dropped, and when
	///	`limitWidth` does not exceed `prefixWidth` this degrades to one word per group. No group is ever empty.
	public static func filledWordGroups(of wordList: [Substring], prefixWidth: Int, limitWidth: Int) -> [[Substring]] {
		let filled = wordList.reduce(into: (groups: [[Substring]](), lastWidth: 0)) { state, word in
			let wordWidth = word.count
			let extendsLastGroup = !(state.groups.isEmpty) && ((state.lastWidth + 1 + wordWidth) <= limitWidth)
			if extendsLastGroup {
				state.groups[state.groups.count - 1].append(word)
				state.lastWidth += (1 + wordWidth)
			} else {
				state.groups.append([word])
				state.lastWidth = prefixWidth + wordWidth
			}
		}
		return filled.groups
	}

}
