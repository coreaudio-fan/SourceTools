extension Reflow {

	///	The longest prefix of space and tab characters in `line`.
	public static func leadingWhitespace(of line: Substring) -> Substring {
		line.prefix { character in (character == " ") || (character == "\t") }
	}

	///	The rendered width of `text` with tabs expanded: a tab advances the column to the next multiple of
	///	`tabWidth`, and every other character counts one column.
	public static func renderedWidth(of text: Substring, tabWidth: Int) -> Int {
		text.reduce(0) { width, character in
			character == "\t" ? ((width + tabWidth) - (width % tabWidth)) : (width + 1)
		}
	}

}
