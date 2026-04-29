# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Open in Xcode (preferred dev flow)
open copyWorld.xcodeproj

# CLI build (Debug)
xcodebuild -project copyWorld.xcodeproj -scheme copyWorld -configuration Debug build

# CLI build (Release) and run
./scripts/build_app.sh
./scripts/run_app.sh

# Build DMG for distribution
./scripts/build_dmg.sh

# Quit running instance
./scripts/quit_app.sh

# Regenerate Xcode project after adding/removing files
ruby scripts/generate_xcodeproj.rb
```

There are no formal tests yet — `Tests/copyWorldTests/` contains a skeleton. The integration test is a standalone script: `swift scripts/test_clipboard_monitor.swift`.

## Architecture

A **menu-bar-only** macOS clipboard history app (no Dock icon, `LSUIElement = true`). Written in Swift + SwiftUI, hosted in an AppKit `NSPopover` inside an `NSStatusItem`. Minimum deployment target: macOS 14.0.

**Entry point**: `CopyWorldApp` (`@main`, SwiftUI `App` lifecycle) — sets `.accessory` activation policy, creates `AppDelegate`, hosts a `Settings` scene for the launch-at-login toggle.

**Singleton coordinator**: `AppState` (`@MainActor`, `ObservableObject`) — owns `ClipboardStorage`, `ClipboardHistoryStore`, `ClipboardMonitor`, and `LaunchAtLoginManager`.

**Core services** (all `@MainActor`):
- `ClipboardMonitor` — polls `NSPasteboard.general` every 800ms via `Task.sleep`. Tracks `changeCount` to detect new content. Captures three content types in priority order: image (`.png`/`.tiff`) > RTF > plain text. Uses SHA256 content hash for dedup. Supports `setCaptureSuspended(true)` while the popover is open so internal copies don't pollute history. When suspension ends, any pending external changes are consumed and discarded. Copy-back writes via `NSPasteboardItem` + `writeObjects`.
- `ClipboardHistoryStore` — `@Published` array of `ClipboardItem` (max 30). Delegates persistence to `ClipboardStorage`. Deduplicates by `contentHash` (SHA256). Exposes `save(item:rtfData:imageData:)`, `remove(itemID:)`, `clear()`.
- `ClipboardStorage` — file-system persistence under `~/Library/Application Support/copyWorld/items/<uuid>/`. Each item directory contains `metadata.json` + optional content files (`content.rtf`, `content.png`, `content.tiff`, `thumbnail.png`). Handles one-time migration from old UserDefaults format (`"clipboard.history.items"` → new file storage). Supports lazy loading: metadata loads eagerly, content loaded on demand.
- `LaunchAtLoginManager` — thin wrapper around `SMAppService.mainApp`. Tracks status: enabled, requiresApproval, notFound, notRegistered.

**UI** (`StatusBarController` + `MenuBarView.swift`):
- `StatusBarController` (`NSObject`, `@MainActor`) — creates `NSStatusItem` with SF Symbol "clipboard" icon, manages `NSPopover` (460×560, `.transient` behavior). Left-click toggles popover; right-click shows Quit context menu. On popover open: suspends capture; on close: resumes capture, clears text selection recursively, stops event monitors.
- `MenuBarView` — SwiftUI view with search `TextField`, `List` of type-aware `ClipboardRow` items (text/RTF icon/image thumbnail), optional `ClipboardPreview` that switches between `TextPreview` (monospaced NSTextView), `RTFPreview` (rich NSTextView), and `ImagePreview` (NSImageView with checkerboard background). Images excluded from text search. Footer with count + login item status. Selection preserved across search filtering.
- `SettingsView` — standalone preferences window with launch-at-login toggle.

**Data model**: `ClipboardItem` — `Codable`, `Identifiable`, `Equatable` struct with `id: UUID`, `type: ClipboardContentType` (`.text`/`.rtf`/`.image`), `text: String` (plain-text fallback), `contentHash: String` (SHA256 for dedup), `createdAt: Date`. Transient fields: `rtfData: Data?`, `image: NSImage?`, `thumbnail: NSImage?` (loaded lazily from disk). `title` is type-aware: first 80 chars for text/RTF, dimensions + format for images.

## Key design decisions

- **Capture suspension model**: When the popover opens, external clipboard polling is paused. Any clipboard change that occurred while suspended is consumed (ignored) on resume. This plus SHA256 hash-based dedup prevents the app's own clipboard writes from appearing as new history entries.
- **All main-actor**: No background queues or async networking. Everything runs synchronously on `@MainActor`, which is safe because clipboard access and file I/O are lightweight on the main thread.
- **File-system persistence**: Replaced UserDefaults with `~/Library/Application Support/copyWorld/items/`. Metadata and content stored separately — metadata loads eagerly (lightweight), content loads on demand for preview. Old UserDefaults data is auto-migrated on first launch and never deleted (safe downgrade).
- **Xcode project is generated**: `scripts/generate_xcodeproj.rb` scans `Sources/` and `Tests/` directories and builds the `.xcodeproj` from scratch using the `xcodeproj` Ruby gem.
- **No sandbox, no hardened runtime**: Sandbox and code signing enforcement are both disabled in the Xcode build settings — this app relies on `NSPasteboard` polling which requires accessibility permissions, not sandbox entitlements.
- **Haptic + visual feedback on actions**: Copy and delete both trigger `NSHapticFeedbackManager.defaultPerformer.perform(.alignment)`. Copy additionally shows a brief button state change (`doc.on.doc` + "Copy" → `checkmark` + "Copied", green tint, disabled for 1.5s) tracked via a `@State copiedItemID` in `MenuBarView` with a `Task.sleep` reset. Follow this pattern when adding new destructive or clipboard-mutating actions.

## Versioning & Release

Version is defined in two places in `copyWorld.xcodeproj/project.pbxproj`:
- `MARKETING_VERSION` — semver display version (e.g. `0.1.0`)
- `CURRENT_PROJECT_VERSION` — integer build number (e.g. `1`)

Release workflow:

```bash
# 1. Bump version in project.pbxproj (MARKETING_VERSION and/or CURRENT_PROJECT_VERSION)
# 2. Build DMG
./scripts/build_dmg.sh

# 3. Tag and push
git tag v<MARKETING_VERSION>
git push origin v<MARKETING_VERSION>

# 4. Create GitHub release with DMG asset
gh release create v<MARKETING_VERSION> \
  --title "v<MARKETING_VERSION> — <简短描述>" \
  --notes-file - \
  dist/copyWorld.dmg <<'EOF'
## copyWorld v<MARKETING_VERSION>

<发行说明>
EOF
```

The app is unsigned — users need to right-click → Open on first launch (or `xattr -cr copyWorld.app`). No notarization, no Sparkle update framework. Each release is a standalone DMG download.
