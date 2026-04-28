# copyWorld

macOS first-version clipboard history app.

## First-Version Plan

### Goal

Ship a local-only menu bar clipboard tool for macOS that behaves like a lightweight clipboard history feature.

### MVP Scope

- Monitor text changes in the macOS clipboard
- Save the latest 30 text entries locally
- Show history from a menu bar window
- Search previous copied text
- Copy an old entry back into the system clipboard
- Delete one item or clear all history

### Out of Scope for V1

- Images, files, and rich text
- Global shortcuts
- Cloud sync
- App signing and notarization

### Delivery Steps

1. Set up a native macOS app shell with SwiftUI menu bar UI.
2. Add clipboard polling through `NSPasteboard`.
3. Persist clipboard history with `UserDefaults`.
4. Build history browsing, search, copy-back, delete, and clear actions.
5. Keep a standard Xcode app project for normal development and retain local scripts as a fallback path.

## Tech Stack

- `Swift`
- `SwiftUI`
- `AppKit`
- `UserDefaults`
- `Xcode` macOS app target
- `Swift Package Manager` for package metadata and tests
- `swiftc` fallback scripts for local bundle staging

## Build And Package

The repository now includes a standard macOS app project at [copyWorld.xcodeproj](copyWorld/copyWorld.xcodeproj).

Build a release `.app` into `dist/`:

```bash
./scripts/build_app.sh
```

Build a distributable `.dmg` into `dist/`:

```bash
./scripts/build_dmg.sh
```

The generated files are:

- `dist/copyWorld.app`
- `dist/copyWorld.dmg`

## Local Run

Preferred development flow:

```bash
open copyWorld.xcodeproj
```

In Xcode, select the `copyWorld` scheme and use `Run` or `Product > Build`.

You can also build from the command line once Xcode first-launch setup is complete:

```bash
xcodebuild -project copyWorld.xcodeproj -scheme copyWorld -configuration Debug build
```

Run the packaged app directly:

```bash
./scripts/run_app.sh
```
