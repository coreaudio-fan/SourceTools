# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working in this repository.

## Purpose

SourceTools is a macOS app hosting **SourceTools for Xcode**, an Xcode Source Editor Extension that adds an Editor-menu command reflowing the selected lines of text at a column width, preserving indentation and comment leaders. See `~/.claude/CLAUDE.md` for the global style guide.

## Build and Test

```sh
# Build (Debug)
xcodebuild -project SourceTools.xcodeproj -scheme App -configuration Debug build

# Build (Release)
xcodebuild -project SourceTools.xcodeproj -scheme App -configuration Release build

# Run the tests
xcodebuild -project SourceTools.xcodeproj -scheme App -configuration Debug test
```

`App` is the only **shared** scheme — tracked at `SourceTools.xcodeproj/xcshareddata/xcschemes/App.xcscheme`, so it exists in a fresh clone and in CI. It builds the app (which transitively builds every other target through dependencies), runs it, and its test action runs the `Tests` bundle, so the one scheme covers build, test, run, analyze, profile, and archive.

`xcodebuild -list` also shows `Extension` and `Framework` schemes. Those are synthesized per-user by Xcode for scheme-worthy target types not covered by a shared scheme; they are untracked and no documented command uses them. Use `-scheme App` for every action.

## Architecture

Four targets. Target names are generic, matching the `Config/` filename stems and the source directories rather than the products they build — the same convention Utilities (`Framework`/`Tests`) and HelloWorld (`Tool`) use:

| Target | Product | Builds from | Notes |
|---|---|---|---|
| `App` | `SourceTools.app` | `App/` | SwiftUI enablement window; embeds the framework and the appex |
| `Extension` | `SourceTools for Xcode.appex` | `Extension/` | The source editor extension — the XcodeKit edge and nothing more |
| `Framework` | `SourceToolsCore.framework` | `Framework/` | The pure reflow engine, plus two documented impure width readers |
| `Tests` | `SourceTools Tests.xctest` | `Tests/` | swift-testing; links the framework library-style (no `TEST_HOST`) |

The engine is pure — lines in, lines out — and every editor-facing decision (selection decision table, terminator handling policy, width resolution) is expressed in `SourceToolsCore` value types so it is testable without XcodeKit. `Extension/ReflowSelectionCommand.swift` only bridges: selections in, spliced lines and updated selections out, all synchronously on whichever thread Xcode chose, which is what keeps strict concurrency happy without annotations.

### Embedding and runpaths

`SourceToolsCore.framework` is embedded **once**, in `SourceTools.app/Contents/Frameworks`. The appex sits in `Contents/PlugIns` and reaches the framework through `@executable_path/../../../../Frameworks` — the runpath Apple's own app-extension template ships. The appex deliberately contains no framework copy of its own.

`XcodeKit.framework` lives at `$(DEVELOPER_DIR)/Library/Frameworks`, **not** in the macOS SDK. The `com.apple.product-type.xcode-extension` product type injects the linker search path, the `_XCExtensionMain` entry point, and the `-lXcodeExtension` glue by itself; the Swift *compile* step is the one consumer that needs the explicit `FRAMEWORK_SEARCH_PATHS = $(DEVELOPER_FRAMEWORKS_DIR)` in `Extension-Common.xcconfig`.

**XcodeKit must additionally be embedded in the appex** (`Contents/Frameworks`, via the Extension target's Embed Frameworks phase with code-sign-on-copy). Nothing supplies it at runtime: XcodeKit's install name is `@rpath/…`, the appex's runpaths are all bundle-relative, and Xcode injects no search path when launching the extension — without the embedded copy the appex dies before `main` with "Library not loaded: @rpath/XcodeKit.framework" (crash report 2026-08-08, `termination.namespace = DYLD`). This is how shipping extensions work: the App Store-distributed Comment Wrapper.appex carries its own `XcodeKit.framework` copy, observed 2026-08-08.

### The wrap column and Xcode's defaults key

The extension defaults its wrap column to Xcode's "Reformat code at column" setting (Settings > Editing). That field is backed by the undocumented defaults key **`DVTTextPageGuideLocation`** in `com.apple.dt.Xcode` — the historical page-guide key, so the reformat column and the page guide location are one setting in this Xcode version. Discovered 2026-08-08 on Xcode 26.6 (17F113) by changing the field and diffing `defaults read com.apple.dt.Xcode`, confirmed in both directions (93 on change, 120 on restore). Every earlier hunt for a key containing "reformat" was empty because the label and the storage key parted ways somewhere in Xcode's history.

Reading another application's preference domain from a sandboxed process requires the `com.apple.security.temporary-exception.shared-preference.read-only` entitlement, carried by the **appex only** — the app reads nothing from Xcode's domain. It is a documented Apple mechanism appropriate for personal distribution; the Mac App Store rejects temporary-exception entitlements, so App Store distribution would require dropping the Xcode-tracking behavior.

Resolution (`WidthResolution.resolvedWidth(xcodeReformatWidth:)`): the Xcode key via `CFPreferencesCopyAppValue` when it holds a usable column of at least 1, otherwise the hardcoded fallback 80 — the user-reported value of a pristine field. The fallback could not be observed directly because the key on the development machine was overridden long ago; it only fires on machines where the key has never been written. There is deliberately no user-configurable width: the first iteration had a settings window, width modes, and an app group to share them, all removed once the Xcode read was proven (2026-08-08).

Indentation needs none of this: `XCSourceTextBuffer` hands the extension `tabWidth`, `indentationWidth`, and `usesTabsForIndentation` per invocation, and the reflow preserves each paragraph's existing leading whitespace verbatim, so only `tabWidth` (for measuring) is consumed.

### The System Settings button

The enablement window's button opens System Settings via the undocumented `x-apple.systempreferences:` URL scheme. `App/EnablementView.swift` walks an ordered candidate list and stops at the first URL the system accepts, so a future pane rename degrades to a nearby page rather than a dead button. Observed on macOS 26.6.1 (2026-08-08): the most specific candidate,
`x-apple.systempreferences:com.apple.ExtensionsPreferences?extensionPointIdentifier=com.apple.dt.Xcode.extension.source-editor`, lands directly on the Xcode Source Editor extensions page.

### Languages

The targets are configured to host **C, C++, Objective-C, and Swift**, not Swift alone. The sources are currently Swift-only, but the build settings are deliberately broader: `GCC_C_LANGUAGE_STANDARD = gnu23`, `CLANG_CXX_LANGUAGE_STANDARD = gnu++23`, the full Objective-C and C++ warning and static-analyzer allowlists, and a Headers build phase on the `Framework` target.

Do not read the current file list as the project's language scope, and do not prune C, C++, or Objective-C settings as dead weight. Apple frequently reuses a build setting that is ostensibly for one language to control another, and frequently does not document that it does.

Platform scope is a separate axis and *is* narrow: `SUPPORTED_PLATFORMS = macosx` on every target, because an Xcode extension and its host app cannot meaningfully target anything else. That narrowing says nothing about the language settings above.

### Adding files

`App/`, `Extension/`, `Framework/`, `Tests/`, and `Config/` are `PBXFileSystemSynchronizedRootGroup`s (`objectVersion = 77`). Files are picked up by folder membership — **drop a file into the directory and it joins the target with no `project.pbxproj` edit**. This is also why XCODE-1 (navigator mirrors the filesystem) holds by construction. `Config` belongs to no target: it anchors the xcconfig references and carries the signing/packaging inputs, so nothing in it joins a build phase and no synchronized-group exception set is needed.

The one explicit `PBXBuildFile` is `Documentation.docc` in the Framework's Sources phase, which is normal for DocC catalogs.

### Build settings (`Config/`)

All build settings live in `.xcconfig` files; every `buildSettings` dict in `project.pbxproj` is empty, wired via `baseConfigurationReferenceAnchor` + `baseConfigurationReferenceRelativePath`. When changing a setting, edit the `.xcconfig` — anything set in Xcode's Build Settings UI gets written back as an inline pbxproj override that silently shadows the file. The files reproduce the organization of Xcode's Build Settings UI; see HelloWorld's CLAUDE.md for the exact formatting rules.

| File | Scope |
|---|---|
| `Project-{Common,Debug,Release}.xcconfig` | Byte-identical copies of Utilities' — language standards, warning and analyzer allowlists, Swift language mode and concurrency, signing, and the optimization/testability split |
| `App-*.xcconfig` | App target: platform, packaging, runpath, entitlements, hardened runtime, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` |
| `Extension-*.xcconfig` | Appex target: platform, packaging (`INFOPLIST_FILE` merge), XcodeKit search path, runpaths, entitlements |
| `Framework-*.xcconfig` | Framework target: platform, packaging, dylib identity, module verifier, `APPLICATION_EXTENSION_API_ONLY` |
| `Tests-*.xcconfig` | Test bundle: platform and packaging; no `TEST_HOST`, no `BUNDLE_LOADER` |
| `App.entitlements` / `Extension.entitlements` | App: sandbox only. Extension: sandbox plus the read-only preference exception for `com.apple.dt.Xcode` |
| `Extension-Info.plist` | The `NSExtension` dict only (principal class, one command definition); merged into the generated Info.plist |

Deliberate divergences from the Utilities baseline, each on purpose:

- `RUN_DOCUMENTATION_COMPILER = NO` on App, Extension, and Tests. Documentation enforcement stays on the Framework, the one published API surface; docc also fails outright on the catalog-less appex target ("No valid content was found in this file", first build, 2026-08-08).
- No `BUILD_LIBRARY_FOR_DISTRIBUTION` on the framework. Utilities keeps it because other repos consume it as a subproject; SourceToolsCore has exactly one consumer in this repo, and library evolution would cost build time for nothing.
- `APPLICATION_EXTENSION_API_ONLY = YES` on the framework, because the appex links it and the xcode-extension product type requires extension-safe API.
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` in `App-Common.xcconfig` only, mirroring Apple's app template; the project baseline stays `nonisolated` because `XCSourceEditorCommand.perform` arrives on an arbitrary thread and the engine must not be actor-bound.
- `ENABLE_HARDENED_RUNTIME = YES` on both the App and the Extension. During bring-up, hardened runtime was briefly misdiagnosed as the cause of the appex's launch crash; the real cause was the missing embedded XcodeKit (see Embedding and runpaths above), and the working App Store specimen Comment Wrapper runs its appex hardened, so hardened runtime stays.

## Testing

The suite uses **swift-testing** — `import Testing`, `struct` suites, `@Test` functions, `#expect`/`try #require`. 63 tests in 7 suites as of this writing. All tests use a plain `import SourceToolsCore`; **`@testable` is banned**, so access-control regressions fail the build rather than a test. `Tests/ReflowAPITests.swift` covers the published surface from a client's perspective and documents the rationale in its header. Expected outputs in `Tests/ReflowTests.swift` were derived by hand from the greedy-fill invariant; the idempotence test re-reflows every case.

## Enabling and debugging the extension

1. Build and launch `SourceTools.app` once so macOS registers the appex (`pluginkit -m | grep -i sourcetools` to confirm).
2. System Settings > General > Login Items & Extensions > Xcode Source Editor: enable **SourceTools for Xcode**.
3. Relaunch Xcode. The command appears at **Editor > SourceTools for Xcode > Reflow Selection**; Xcode's Key Bindings can give it a shortcut.

An empty selection (caret only) is a no-op by design. To debug the appex, run the `App` scheme, then Debug > Attach to Process once Xcode's extension host spawns it — or add a per-user scheme for the Extension target that asks which app to launch; none is shared on purpose.

### Troubleshooting a missing Editor-menu entry

Hard-won findings from 2026-08-08, in the order to check them:

- `pluginkit -m -v -i coreaudio-fan.SourceTools.Extension` shows the election state: `+` in use, `-` ignored, `!` **debugger use only**, `=` superseded (legend: `man pluginkit`). Running the Extension scheme leaves a `!` debugger election behind that masks normal use; reset it with `pluginkit -e use -i coreaudio-fan.SourceTools.Extension`.
- Install the app in `/Applications`, not DerivedData; replacing the bundle invalidates the System Settings approval, which must be re-toggled.
- A crash report named `SourceTools for Xcode-*.ips` in `~/Library/Logs/DiagnosticReports` with `DYLD, Library missing` means the appex lost its embedded `XcodeKit.framework` (see Embedding and runpaths above) — check the Extension target's Embed Frameworks phase.
- The extension submenu materializes at the bottom of the Editor menu only while a source editor has focus.
- A launch crash also poisons later attempts: the failed extension may not be relaunched until its registration is replaced or the machine restarts, so after fixing a crash, reinstall, re-register, and reset the election before judging the fix.
