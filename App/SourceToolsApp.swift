import SwiftUI

///	The SourceTools container app: a single window, shown at launch, that walks the user through
///	enabling the Xcode extension it hosts.
@main
struct SourceToolsApp: App {

	var body: some Scene {
		Window("SourceTools", id: "enablement") {
			EnablementView()
		}
		.windowResizability(.contentSize)
	}

}
