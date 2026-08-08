import Foundation
import SourceToolsCore

///	The app-group defaults suite the settings window writes and the extension reads.
enum SettingsStore {

	///	The shared suite, or the standard defaults when the app-group container is unavailable — which only
	///	happens on entitlement misconfiguration, and keeps the window functional rather than trapping.
	static let defaults = UserDefaults(suiteName: SharedSettings.suiteName) ?? .standard

}
