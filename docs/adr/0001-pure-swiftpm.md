# ADR 0001: Pure SwiftPM, no Xcode project

- **Status:** Accepted
- **Date:** 2026-10-27

## Context

Summwatch needs a UI-agnostic core library, a macOS menu bar app, and a mock-server tool. Contributors should be able to build and test with the least possible setup, and the full Xcode install is large. Committed `.xcodeproj` files cause frequent merge conflicts in open-source projects.

## Decision

Use a single `Package.swift` containing:
- `SummwatchCore` (library)
- `SummwatchApp` (executable)
- `SummwatchMock` (executable)
- test targets using **Swift Testing**

A script (`scripts/bundle.sh`, milestone M4) assembles `Summwatch.app`: binary, `Info.plist` with `LSUIElement`, `.icns`, and resources. It then code-signs the bundle (ad-hoc until a Developer ID is available).

## Consequences

**Benefits**
- Builds with only the Command Line Tools, and `swift build` / `swift test` work the same locally and in CI.
- No project-file merge conflicts. Contributors can still open `Package.swift` in Xcode for debugging.

**Costs**
- No asset catalogs, so we ship a plain `.icns`.
- `Info.plist` and entitlements are maintained by hand.
- SwiftUI previews are less convenient.
- Notarization is scripted (`notarytool`) instead of going through Xcode's Archive.

**Notes**
- XCTest isn't included with the Command Line Tools, but Swift Testing is, so tests use Swift Testing.
- If an Xcode app target is ever needed, only the app layer moves; the core package stays as it is.
