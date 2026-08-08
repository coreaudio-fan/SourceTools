///	Where the wrap column comes from.
public enum WidthMode: String, Sendable {

	///	Follow Xcode's "Reformat code at column" setting.
	case xcodeSetting = "xcode"

	///	Use the width configured in the SourceTools app.
	case custom = "custom"

}

///	The source a resolved wrap column came from.
public enum WidthProvenance: Sendable, Equatable {

	///	The custom width configured in the SourceTools app.
	case custom

	///	Xcode's "Reformat code at column" setting.
	case xcodeSetting

	///	The built-in fallback width.
	case fallback

}

///	Pure resolution of the wrap column from its optional sources.
public enum WidthResolution {

	///	The wrap column used when the custom width does not apply and Xcode's setting cannot be read.
	///
	///	Intended to be the default value Xcode's "Reformat code at column" field displays, so the resolved width
	///	matches what Xcode itself would reformat at even when the preference was never persisted. Provisionally
	///	120 pending the defaults-key discovery experiment recorded in CLAUDE.md.
	public static let fallbackWidth = 120

	///	Resolves the wrap column and reports where it came from.
	///
	///	The custom width wins when the mode selects it and the value is at least 1; an unset or invalid custom
	///	width falls through to Xcode's setting, and an unreadable or invalid Xcode value falls through to the
	///	fallback. The result is therefore always at least 1.
	public static func resolvedWidth(
		mode: WidthMode,
		customWidth: Int?,
		xcodeReformatWidth: Int?) -> (width: Int, provenance: WidthProvenance) {
		let validCustomWidth = (mode == .custom) ? customWidth.flatMap(validatedWidth) : nil
		let validXcodeWidth = xcodeReformatWidth.flatMap(validatedWidth)
		let resolved: (width: Int, provenance: WidthProvenance) = switch (validCustomWidth, validXcodeWidth) {
		case (let width?, _): (width, .custom)
		case (nil, let width?): (width, .xcodeSetting)
		case (nil, nil): (fallbackWidth, .fallback)
		}
		return resolved
	}

	///	The width itself when usable as a wrap column, or nil for zero and negative values.
	private static func validatedWidth(_ width: Int) -> Int? {
		width >= 1 ? width : nil
	}

}
