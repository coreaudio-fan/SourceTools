import Foundation
import XcodeKit

///	The extension's principal class. The command list lives in Config/Extension-Info.plist, so nothing is
///	overridden here; XcodeKit documents the in-code `commandDefinitions` property as an override of the
///	Info.plist definitions, not a requirement.
nonisolated final class SourceEditorExtension: NSObject, XCSourceEditorExtension {}
