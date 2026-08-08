import Foundation

///	Resolves the wrap column from the shared settings and Xcode's preferences at the moment of use.
///
///	Like `XcodeDefaults`, this is an impure edge: it gathers the current values from the app-group defaults
///	suite and from Xcode's domain, then delegates the decision to the pure `WidthResolution` chain.
public enum WidthResolver {

	///	The wrap column a reflow would use right now, and where it came from.
	public static func currentResolution() -> (width: Int, provenance: WidthProvenance) {
		let sharedDefaults = UserDefaults(suiteName: SharedSettings.suiteName)
		let storedMode = sharedDefaults?.string(forKey: SharedSettings.widthModeKey)
		let mode = storedMode.flatMap { raw in WidthMode(rawValue: raw) } ?? .xcodeSetting
		let customWidth = sharedDefaults?.integer(forKey: SharedSettings.customWidthKey)
		return WidthResolution.resolvedWidth(
			mode: mode,
			customWidth: customWidth,
			xcodeReformatWidth: XcodeDefaults.reformatWidth())
	}

}
