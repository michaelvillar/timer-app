# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Unit test target (`TimerTests`) with 39 tests covering `TimerLogic`
- Shared Xcode scheme with test action
- `make test` target for running tests locally
- CI test step in `swift.yml` workflow
- Sound choice is now persisted to UserDefaults across launches

### Changed

- Extracted pure logic from `MVClockView` and `MVTimerController` into new `TimerLogic` enum
- `MVClockView` and `MVTimerController` now delegate to `TimerLogic` for progress scale conversion, display formatting, keyboard input processing, and sound filename mapping
- SwiftLint now also lints `TimerTests` directory
- Raised deployment target to macOS 14 (Sonoma)
- Replaced deprecated `NSUserNotification` / `NSUserNotificationCenter` with `UNUserNotificationCenter`

### Fixed

- Resolved all SwiftLint warnings: replaced `arc4random_uniform` with `Int.random(in:)`, fixed comment spacing, removed superfluous disable command, moved analyzer-only rules to correct config section, removed defunct `anyobject_protocol` rule
- Updated `MACOSX_DEPLOYMENT_TARGET` from 10.11 to 10.13 (Xcode no longer supports targets below 10.13)
- Fixed `handleOcclusionChange` to use `window.occlusionState.contains(.visible)` instead of `window.isVisible`, which only checked if the window was ordered in rather than actually visible on screen
- Removed redundant `#available(OSX 10.13, *)` check now that the deployment target is 10.13
- Removed dead code in `MVMainView.draw()` — hardcoded colors were overwritten by named colors
- Cached `DateFormatter` in `MVClockView.updateTimeLabel()` to avoid allocation every second
- Replaced force unwrap of `nextEvent` in `MVClockArrowView.mouseDown` with safe unwrap
- Removed unused `initialLocation` property in `MVWindow`
- Secondary timer windows no longer overwrite the primary window's saved position
