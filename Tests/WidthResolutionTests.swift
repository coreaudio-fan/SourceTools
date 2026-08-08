import SourceToolsCore
import Testing

struct WidthResolutionTests {

	@Test func usableXcodeWidthPassesThrough() async throws {
		#expect(WidthResolution.resolvedWidth(xcodeReformatWidth: 120) == 120)
		#expect(WidthResolution.resolvedWidth(xcodeReformatWidth: 1) == 1)
	}

	@Test func missingKeyFallsBackToTheDefault() async throws {
		#expect(WidthResolution.resolvedWidth(xcodeReformatWidth: nil) == WidthResolution.fallbackWidth)
	}

	@Test func invalidStoredWidthFallsBackToTheDefault() async throws {
		#expect(WidthResolution.resolvedWidth(xcodeReformatWidth: 0) == WidthResolution.fallbackWidth)
		#expect(WidthResolution.resolvedWidth(xcodeReformatWidth: -40) == WidthResolution.fallbackWidth)
	}

	@Test func resolvedWidthIsAlwaysPositive() async throws {
		for storedWidth in [nil, -1, 0, 1, 80, 120] {
			#expect(WidthResolution.resolvedWidth(xcodeReformatWidth: storedWidth) >= 1)
		}
	}

}
