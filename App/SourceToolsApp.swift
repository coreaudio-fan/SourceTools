import SwiftUI

///	The SourceTools container app: a single window of settings for the Xcode extension it hosts.
@main
struct SourceToolsApp: App {

	var body: some Scene {
		Window("SourceTools", id: "settings") {
			SettingsView()
		}
		.windowResizability(.contentSize)
	}

}
