import SourceToolsCore
import SwiftUI

///	The settings window: wrap-column mode, custom width, a diagnostic of the resolved width, and the
///	first-run steps for enabling the extension.
struct SettingsView: View {

	@AppStorage(SharedSettings.widthModeKey, store: SettingsStore.defaults)
	private var widthModeRawValue = WidthMode.xcodeSetting.rawValue

	@AppStorage(SharedSettings.customWidthKey, store: SettingsStore.defaults)
	private var customWidth = WidthResolution.fallbackWidth

	///	Recomputed on every body evaluation, so changing either setting refreshes the diagnostic.
	private var resolution: (width: Int, provenance: WidthProvenance) {
		WidthResolver.currentResolution()
	}

	private var provenanceDescription: String {
		switch resolution.provenance {
		case .custom: "the custom width configured here"
		case .xcodeSetting: "Xcode's \"Reformat code at column\" setting"
		case .fallback: "the built-in fallback"
		}
	}

	var body: some View {
		Form {
			Section("Wrap column") {
				Picker("Width", selection: $widthModeRawValue) {
					Text("Use Xcode's \"Reformat code at column\" setting")
						.tag(WidthMode.xcodeSetting.rawValue)
					Text("Custom")
						.tag(WidthMode.custom.rawValue)
				}
				.pickerStyle(.radioGroup)
				.labelsHidden()
				HStack {
					TextField("Custom width", value: $customWidth, format: .number)
						.frame(width: 64)
					Stepper("Custom width", value: $customWidth, in: 40...300)
						.labelsHidden()
				}
				.disabled(widthModeRawValue != WidthMode.custom.rawValue)
			}

			Section("Resolved right now") {
				LabeledContent("Wrap column", value: "\(resolution.width)")
				LabeledContent("Comes from", value: provenanceDescription)
			}

			Section("Enable the extension") {
				Text("Open System Settings > General > Login Items & Extensions > Xcode Source Editor and enable SourceTools for Xcode.")
				Text("Relaunch Xcode. The command appears under Editor > SourceTools for Xcode > Reflow Selection, where Key Bindings can give it a shortcut.")
			}
		}
		.formStyle(.grouped)
		.frame(width: 480)
	}

}
