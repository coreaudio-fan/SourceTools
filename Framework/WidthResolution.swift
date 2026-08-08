///	Pure resolution of the wrap column from Xcode's setting.
public enum WidthResolution {

	///	The wrap column used when Xcode's setting cannot be read: the default value a pristine
	///	"Reformat code at column" field displays, so the resolved width matches what Xcode itself would
	///	reformat at on a machine where the key was never written. The key discovery and this value are
	///	recorded in CLAUDE.md.
	public static let fallbackWidth = 80

	///	The wrap column: `xcodeReformatWidth` when it is a usable column of at least 1, otherwise the
	///	fallback. The result is therefore always at least 1.
	public static func resolvedWidth(xcodeReformatWidth: Int?) -> Int {
		let validWidth = xcodeReformatWidth.flatMap { width in width >= 1 ? width : nil }
		return validWidth ?? fallbackWidth
	}

}
