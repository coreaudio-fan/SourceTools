import AppKit
import SwiftUI

///	The window shown at launch: how to enable the extension, and a button that opens System Settings as
///	close as possible to the Xcode Source Editor extensions page.
struct EnablementView: View {

	///	Candidate System Settings destinations, most specific first. The pane URLs are undocumented, so
	///	the button walks this list and stops at the first URL the system accepts — a future macOS pane
	///	rename degrades to a nearby page rather than a dead button. Observed on macOS 26.6.1
	///	(2026-08-08): the first candidate lands directly on the Xcode Source Editor extensions page;
	///	discovery record in CLAUDE.md.
	private static let systemSettingsCandidates = [
		"x-apple.systempreferences:com.apple.ExtensionsPreferences?extensionPointIdentifier=com.apple.dt.Xcode.extension.source-editor",
		"x-apple.systempreferences:com.apple.ExtensionsPreferences",
		"x-apple.systempreferences:com.apple.LoginItems-Settings.extension",
	]

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text("Enable the Xcode extension")
				.font(.title2)
				.bold()
			//	Multiline text in a content-sized window keeps its single-line ideal width unless told to
			//	trade width for height, so each wrapping line carries fixedSize(horizontal:vertical:).
			Text("1. Open System Settings > General > Login Items & Extensions > Xcode Source Editor and enable SourceTools for Xcode.")
				.fixedSize(horizontal: false, vertical: true)
			Text("2. Relaunch Xcode. The command appears under Editor > SourceTools for Xcode > Reflow Selection, where Xcode's Key Bindings can give it a shortcut.")
				.fixedSize(horizontal: false, vertical: true)
			Text("The wrap column always follows Xcode's \"Reformat code at column\" setting.")
				.foregroundStyle(.secondary)
				.fixedSize(horizontal: false, vertical: true)
			Button("Open System Settings…") {
				Self.openSystemSettings()
			}
			.keyboardShortcut(.defaultAction)
			.frame(maxWidth: .infinity, alignment: .center)
		}
		.padding(20)
		.frame(width: 480)
	}

	///	Walks the candidate destinations and stops at the first one the system accepts.
	private static func openSystemSettings() {
		let candidateURLs = systemSettingsCandidates.compactMap { candidate in URL(string: candidate) }
		_ = candidateURLs.first { url in NSWorkspace.shared.open(url) }
	}

}
