import Foundation

///	Reads of Xcode's preference domain.
///
///	This is the framework's one deliberately impure type: its function performs I/O against another
///	application's defaults, per the functional-first rule that effects live at named edges. Reading a foreign
///	domain goes through `CFPreferencesCopyAppValue`, which is documented to take an arbitrary application ID —
///	`UserDefaults(suiteName:)` is not usable here, as its documentation forbids passing another app's bundle
///	identifier. Sandboxed callers additionally need the read-only preference exception entitlement for
///	`com.apple.dt.Xcode`; without it every read returns nil and width resolution falls through gracefully.
public enum XcodeDefaults {

	///	Xcode's preference domain.
	private static let xcodeDomain = "com.apple.dt.Xcode"

	///	The defaults key backing Xcode's "Reformat code at column" setting.
	///
	///	The key is undocumented and was absent from the domain until the setting was first changed by hand, so
	///	this name is provisional until the defaults-diff discovery experiment recorded in CLAUDE.md confirms it.
	///	A wrong name is safe: the read returns nil and resolution uses the fallback width.
	private static let reformatWidthKey = "DVTTextReformatWidth"

	///	Xcode's "Reformat code at column" value, or nil when the preference is absent or unreadable.
	public static func reformatWidth() -> Int? {
		CFPreferencesCopyAppValue(reformatWidthKey as CFString, xcodeDomain as CFString) as? Int
	}

}
