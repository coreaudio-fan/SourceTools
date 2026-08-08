# ``SourceToolsCore``

The pure reflow engine behind SourceTools for Xcode.

## Overview

`SourceToolsCore` reflows lines of text at a rendered column width, preserving indentation and comment
leaders. The engine is pure — lines in, lines out — with its two effectful edges (`XcodeDefaults`,
`WidthResolver`) confined to width resolution. `SelectionMapping` mirrors the editor's selection model so
that every decision the Xcode extension makes is testable without XcodeKit.
