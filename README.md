# SourceTools

A macOS app hosting **SourceTools for Xcode**, an Xcode Source Editor Extension that reflows the selected lines of text at a column width — vim's `gq` for Xcode.

**Editor > SourceTools for Xcode > Reflow Selection** joins the selected lines into paragraphs (blank lines separate them) and re-wraps the words at the wrap column:

- Indentation is preserved verbatim — tabs stay tabs, measured at the buffer's tab width.
- Comment leaders (`///`, `//`, `#`, `--`, `;`, `*`) are recognized and re-applied to every wrapped line, keeping the leader's own spacing.
- Words are never broken; an oversized word overflows on its own line.
- An empty selection does nothing.

The wrap column always follows Xcode's **"Reformat code at column"** setting, read live at each invocation; when that preference has never been written, the built-in default of 80 — the same column a pristine Xcode would use — applies.

## Enabling

1. Build and launch `SourceTools.app` once. Its window explains the steps and its button opens System Settings directly on the Xcode Source Editor extensions page.
2. Enable **SourceTools for Xcode** there.
3. Relaunch Xcode; the command appears in the Editor menu, and Xcode's Key Bindings can give it a shortcut.

## Building

```sh
xcodebuild -project SourceTools.xcodeproj -scheme App -configuration Debug build
xcodebuild -project SourceTools.xcodeproj -scheme App -configuration Debug test
```

Not Mac App Store distributable: both bundles carry a temporary-exception entitlement to read Xcode's preference domain, which the App Store rejects. Personal and Developer ID distribution are unaffected.
