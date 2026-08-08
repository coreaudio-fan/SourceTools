///	The comment marker shared by the lines of a paragraph, split into the marker itself and the whitespace
///	separating it from the text.
public struct CommentLeader: Sendable, Equatable {

	///	The marker characters, such as `//` or `#`.
	public let token: String

	///	The whitespace run between the token and the text; reproduced verbatim on every output line.
	public let separator: String

	///	Creates a leader from its marker and the whitespace that follows it.
	public init(token: String, separator: String) {
		self.token = token
		self.separator = separator
	}

}

extension Reflow {

	///	The comment markers the reflow recognizes, longest first so `///` wins over `//`.
	private static let commentLeaderTokens = ["///", "//", "#", "--", ";", "*"]

	///	Detects a comment leader at the start of `remainder`, the portion of a line after its indentation.
	///
	///	A token counts as a leader only when it is followed by a space, a tab, or the end of the line. This rejects
	///	constructs such as `#!/bin/sh`, `*pointer`, and `//////` divider lines, whose marker-like prefixes are not
	///	comment leaders.
	///
	///	- Returns: the leader and the text after it, or nil when `remainder` carries no recognized leader.
	public static func commentLeader(of remainder: Substring) -> (leader: CommentLeader, text: Substring)? {
		commentLeaderTokens.lazy.compactMap { token in leaderMatch(of: remainder, token: token) }.first
	}

	///	The leader and following text when `remainder` starts with `token` as a delimited comment marker, else nil.
	private static func leaderMatch(of remainder: Substring, token: String) -> (leader: CommentLeader, text: Substring)? {
		guard remainder.hasPrefix(token) else {
			return nil
		}
		let afterToken = remainder.dropFirst(token.count)
		let separator = leadingWhitespace(of: afterToken)
		let isDelimited = afterToken.isEmpty || !(separator.isEmpty)
		return isDelimited
			? (CommentLeader(token: token, separator: String(separator)), afterToken.dropFirst(separator.count))
			: nil
	}

}
