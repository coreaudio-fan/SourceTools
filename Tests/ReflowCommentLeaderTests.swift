import SourceToolsCore
import Testing

struct ReflowCommentLeaderTests {

	@Test func everyTokenIsDetectedWhenFollowedBySpace() async throws {
		for marker in ["///", "//", "#", "--", ";", "*"] {
			let match = try #require(Reflow.commentLeader(of: Substring(marker + " text")))

			#expect(match.leader == CommentLeader(token: marker, separator: " "))
			#expect(match.text == "text")
		}
	}

	@Test func tabAfterTokenIsCapturedAsTheSeparator() async throws {
		let match = try #require(Reflow.commentLeader(of: "//\ttext"))

		#expect(match.leader == CommentLeader(token: "//", separator: "\t"))
		#expect(match.text == "text")
	}

	@Test func tokenAtEndOfLineIsALeaderWithEmptySeparator() async throws {
		let match = try #require(Reflow.commentLeader(of: "//"))

		#expect(match.leader == CommentLeader(token: "//", separator: ""))
		#expect(match.text == "")
	}

	@Test func tripleSlashWinsOverDoubleSlash() async throws {
		let match = try #require(Reflow.commentLeader(of: "/// doc"))

		#expect(match.leader.token == "///")
		#expect(match.text == "doc")
	}

	@Test func shebangIsNotALeader() async throws {
		#expect(Reflow.commentLeader(of: "#!/bin/sh") == nil)
	}

	@Test func markerGluedToTextIsNotALeader() async throws {
		#expect(Reflow.commentLeader(of: "//text") == nil)
		#expect(Reflow.commentLeader(of: "*pointer") == nil)
	}

	@Test func dividerOfRepeatedMarkersIsNotALeader() async throws {
		#expect(Reflow.commentLeader(of: "//////") == nil)
	}

	@Test func dividerAfterALeaderIsOrdinaryText() async throws {
		let match = try #require(Reflow.commentLeader(of: "// ------"))

		#expect(match.leader.token == "//")
		#expect(match.text == "------")
	}

	@Test func separatorWhitespaceIsCapturedVerbatim() async throws {
		let match = try #require(Reflow.commentLeader(of: "// \t after"))

		#expect(match.leader.separator == " \t ")
		#expect(match.text == "after")
	}

}
