import SourceToolsCore
import Testing

struct WidthResolutionTests {

	@Test func customModeWithValidWidthWins() async throws {
		let resolved = WidthResolution.resolvedWidth(mode: .custom, customWidth: 100, xcodeReformatWidth: 80)

		#expect(resolved.width == 100)
		#expect(resolved.provenance == .custom)
	}

	@Test func customModeWithoutAWidthFallsThroughToXcode() async throws {
		let resolved = WidthResolution.resolvedWidth(mode: .custom, customWidth: nil, xcodeReformatWidth: 80)

		#expect(resolved.width == 80)
		#expect(resolved.provenance == .xcodeSetting)
	}

	@Test func customModeWithAnInvalidWidthFallsThroughToXcode() async throws {
		let resolved = WidthResolution.resolvedWidth(mode: .custom, customWidth: 0, xcodeReformatWidth: 80)

		#expect(resolved.width == 80)
		#expect(resolved.provenance == .xcodeSetting)
	}

	@Test func xcodeModeIgnoresTheCustomWidth() async throws {
		let resolved = WidthResolution.resolvedWidth(mode: .xcodeSetting, customWidth: 100, xcodeReformatWidth: 80)

		#expect(resolved.width == 80)
		#expect(resolved.provenance == .xcodeSetting)
	}

	@Test func unreadableXcodeWidthFallsThroughToTheFallback() async throws {
		let resolved = WidthResolution.resolvedWidth(mode: .xcodeSetting, customWidth: nil, xcodeReformatWidth: nil)

		#expect(resolved.width == WidthResolution.fallbackWidth)
		#expect(resolved.provenance == .fallback)
	}

	@Test func invalidXcodeWidthFallsThroughToTheFallback() async throws {
		let resolved = WidthResolution.resolvedWidth(mode: .xcodeSetting, customWidth: nil, xcodeReformatWidth: 0)

		#expect(resolved.width == WidthResolution.fallbackWidth)
		#expect(resolved.provenance == .fallback)
	}

	@Test func everyCombinationResolvesToAPositiveWidth() async throws {
		for mode in [WidthMode.xcodeSetting, WidthMode.custom] {
			for customWidth in [nil, 0, 100] {
				for xcodeWidth in [nil, 0, 80] {
					let resolved = WidthResolution.resolvedWidth(
						mode: mode,
						customWidth: customWidth,
						xcodeReformatWidth: xcodeWidth)

					#expect(resolved.width >= 1)
				}
			}
		}
	}

}
