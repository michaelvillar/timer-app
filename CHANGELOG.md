# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Unit test target (`TimerTests`) with 39 tests covering `TimerLogic`
- UI test target (`TimerUITests`) with 38 XCUITest tests covering keyboard input, mouse interaction, arrow dragging, context menu, sound selection, dock badge, timer completion, and multiple windows
- Shared Xcode scheme with test action; `TimerUITests.xcscheme` for running UI tests separately
- `make test` and `make uitest` targets for running tests locally
- `make lint`, `make analyze`, and `make format` targets
- CI test step in `swift.yml` workflow
- Sound choice persisted to UserDefaults across launches
- Dark mode support: 5 asset catalog color sets with light/dark variants for timer time, minutes, seconds, arrow focused, and arrow unfocused colors
- VoiceOver accessibility: `MVClockView` reports timer state ("Ready", "5 minutes 30 seconds remaining", "Paused at 3 minutes"), `MVClockArrowView` acts as a slider with duration value

### Changed

- Raised deployment target to macOS 14 (Sonoma)
- Replaced deprecated `NSUserNotification` / `NSUserNotificationCenter` with `UNUserNotificationCenter`
- Used `async`/`await` for notification authorization in `AppDelegate`, logging errors instead of silently ignoring
- Replaced `NSTextView` with `NSTextField` in `MVLabel` (lightweight label rendering)
- Cached `NSGradient` as static constant in `MVMainView.draw()` (was allocated every frame)
- Cached `NSBezierPath` for clock face hit testing in `MVClockView` (was allocated every `hitTest` call)
- Cached `NSImage` resources as static constants in `MVClockProgressView` and `MVClockFaceView`
- Cached `DateFormatter` in `MVClockView.updateTimeLabel()` (was allocated every second)
- Scoped `MVClockView` focus notifications to own window via `viewDidMoveToWindow()` (was `object: nil`, reacting to all windows)
- Removed unnecessary window focus notification observers from `MVMainView` (gradient is focus-independent)
- Replaced hard-coded `sRGB` colors with `NSColor(resource:)` in `MVClockView` and `MVClockArrowView`
- Replaced `NSColor(named:)` with `NSColor(resource:)` and `NSImage(named:)` with `NSImage(resource:)` for compile-time safety
- Modernized Xcode project settings: `objectVersion` 46→56, `compatibilityVersion` Xcode 3.2→14.0, `developmentRegion` English→en
- Updated C/C++ language standards: `gnu99`→`gnu11`, `gnu++0x`→`gnu++14`
- Removed deprecated build settings: `ALWAYS_SEARCH_USER_PATHS`, `GCC_DYNAMIC_NO_PIC`, `ENABLE_STRICT_OBJC_MSGSEND`
- Set `CURRENT_PROJECT_VERSION = 1` (was unset, `CFBundleVersion` resolved to empty)
- Added explicit `SWIFT_OPTIMIZATION_LEVEL = -O` for Release builds
- Extracted pure logic from `MVClockView` and `MVTimerController` into new `TimerLogic` enum for unit testability
- Extracted `MVClockProgressView`, `MVClockArrowView`, and `MVClockFaceView` into separate files from `MVClockView.swift`
- Replaced `@NSApplicationMain` with `@main` in `AppDelegate`
- Replaced `NSString(format:)` with native Swift string interpolation in `TimerLogic`
- Replaced target/selector `Timer.scheduledTimer` with closure-based variant using `[weak self]`
- Replaced `perform(_:with:)` / `NSNumber` boxing with typed closure callbacks
- Replaced target/action pattern for timer completion with `onTimerComplete` closure
- Converted all 11 selector-based `NotificationCenter` observers to closure-based `addObserver(forName:)` with token cleanup
- Converted `MVUserDefaultsKeys` and `Keycode` from `struct` to caseless `enum`
- Downgraded `MVClockArrowView` and `MVClockView` from `NSControl` to `NSView` (no longer use target/action)
- Eliminated all force unwraps across `MVWindow`, `MVMainView`, `MVTimerController`, `AppDelegate`, and `MVClockView`
- Reduced `@objc` annotations from 13 to 3 (only XIB/menu action targets remain)
- Tightened access control across all view classes
- Added `final` to all non-subclassed classes for compiler optimizations
- Replaced `import Cocoa` with `import AppKit` in all view/controller files
- Replaced `NSAffineTransform` Obj-C bridge with pure `CGAffineTransform` in `MVClockProgressView`
- Replaced `representedObject` / `as? Int` casts with type-safe `NSMenuItem.tag` for sound selection
- Normalized indentation to 2-space in `MVTimerController` and `MVMainView`
- Added SwiftLint opt-in rules: `force_unwrapping`, `explicit_self`, `private_over_fileprivate`, `discouraged_optional_boolean`, `static_over_final_class`, `first_where`, `discouraged_optional_collection`, `prefer_zero_over_explicit_init`, `unneeded_break_in_switch`
- Updated CI workflow (`swift.yml`) to trigger on `main` branch instead of `master`
- Updated README deployment target from macOS 10.11 to macOS 14 (Sonoma)
- `make build` now allows incremental builds (no longer forces clean)
- `make` now opens `Timer.app` directly instead of the Release folder
- Renamed `makefile` to `Makefile` (conventional capitalization)

### Removed

- Deprecated `CFBundleSignature` key from `Info.plist`
- Empty `CFBundleIconFile` key from `Info.plist`
- Commented-out dead code in `MVTimerController`
- Dead code in `MVMainView.draw()` (hardcoded colors overwritten by named colors)
- Hidden Edit, Format, View, and Help menus from `MainMenu.xib` (~500 lines of dead XML)
- Hidden Preferences menu item and separator from Timer menu in `MainMenu.xib`
- Unused `NSFontManager` custom object from `MainMenu.xib`
- Unused `initialLocation` property in `MVWindow`
- Unnecessary `mainView` stored property from `MVWindow`
- Duplicate `enter` keycode constant (identical to `keypadEnter`, both `0x4C`)

### Fixed

- Fixed `handleOcclusionChange` to use `window.occlusionState.contains(.visible)` instead of `window.isVisible`, which only checked if the window was ordered in rather than actually visible on screen
- Restored `mouseDownCanMoveWindow = false` on `MVClockArrowView` and `MVClockView`, lost when downgrading from `NSControl` to `NSView`
- Secondary timer windows no longer overwrite the primary window's saved position
- Resolved all SwiftLint warnings

### CI

- Updated `actions/checkout` to `v4` across all workflows
- Replaced deprecated `norio-nomura/action-swiftlint` with direct `brew install swiftlint` on `macos-latest`
- Replaced deprecated `actions/create-release` and `actions/upload-release-asset` with `softprops/action-gh-release@v2`

## [1.6.0] - 2021-01-08

### Added

- Sound selection menu: choose between 3 sounds or no sound (#107)

### Changed

- Updated cask install instructions (#106)
- Updated brew cask command format (#98)

## [1.5.5] - 2020-07-16

### Fixed

- Simplified and fixed countdown display skipping seconds (#94)

### Changed

- Added SwiftLint for code style enforcement (#87)

## [1.5.4] - 2020-07-09

### Changed

- Use fixed-width font for less jittery countdown display (#86)

## [1.5.3] - 2020-04-23

### Changed

- Switch to `AVAudioPlayer` for playing the alert sound (#80)

## [1.5.2] - 2020-04-12

### Added

- Press `R` to restart with the last timer after Escape or completion (#75)

### Changed

- Updated text for "Show in Dock" menu option (#74)

## [1.5.1] - 2020-04-11

### Fixed

- Fixed buggy mouse control (#72)

## [1.5.0] - 2020-04-11

### Added

- Dark mode support (#67)
- GitHub Actions for build and release (#62)
- Issue templates and Code of Conduct (#63, #64)
- Keyboard shortcuts documented in README (#65)
- Makefile for build process (#47)

### Changed

- Updated window layout for Mojave compatibility (#50)
- Improved battery life with timer tolerance and reduced display updates (#44)
- Improved countdown precision to ~1/30 second with pre-timer for seconds-boundary alignment (#44)
- Reduced CPU usage by 20x when window is hidden by tracking visibility (#44)
- Window position auto-saved and restored across launches (#39)
- Locale-aware time formatting with small-caps AM/PM (#38)
- Migrated to Swift 4.1 (#37)
- Windows properly deallocated when closed with weak references (#39)

### Fixed

- Fixed crash when reopening dock timer after switching dock assignment (#39)
- Fixed memory leak in mouse event handling (#45)
- Dock badge properly removed when unchecking "Show in Dock" (#42)

## [1.4] - 2018-08-08

### Added

- Keypad Enter support (#35)
- Dock badge with timer countdown (#29)
- Context menu with dock badge toggle (#29)
- Current time label when idle (#27)
- LICENSE file (#18)
- `.gitignore` (#33)

### Changed

- Hidden unused menus (#34)
- Compressed image assets (#32)

### Fixed

- Replaced `CGFloat(M_PI)` with `.pi` (#30)

## [1.3] - 2017-06-01

### Added

- Type seconds from keyboard — e.g., `.150` sets timer to 2:30 (#14)
- Accept second values up to 599 (#14)

### Fixed

- Reduced beeping on key down (#15)

## [1.2] - 2017-02-13

### Added

- Homebrew cask install instructions
- Stay on Top toggle with preference persistence (#9)

### Changed

- Migrated to Swift 3 (#8)

## [1.1.0] - 2016-05-18

### Added

- Keyboard input support
- macOS 10.10 support

### Fixed

- Fixed countdown timing

## [1.0.2] - 2016-03-30

### Changed

- README updates

## [1.0.1] - 2016-03-30

### Fixed

- Fixed crash on launch

[Unreleased]: https://github.com/karbassi/timer-app/compare/1.6.0...HEAD
[1.6.0]: https://github.com/michaelvillar/timer-app/compare/1.5.5...1.6.0
[1.5.5]: https://github.com/michaelvillar/timer-app/compare/1.5.4...1.5.5
[1.5.4]: https://github.com/michaelvillar/timer-app/compare/1.5.3...1.5.4
[1.5.3]: https://github.com/michaelvillar/timer-app/compare/1.5.2...1.5.3
[1.5.2]: https://github.com/michaelvillar/timer-app/compare/1.5.1...1.5.2
[1.5.1]: https://github.com/michaelvillar/timer-app/compare/1.5.0...1.5.1
[1.5.0]: https://github.com/michaelvillar/timer-app/compare/1.4...1.5.0
[1.4]: https://github.com/michaelvillar/timer-app/compare/1.3...1.4
[1.3]: https://github.com/michaelvillar/timer-app/compare/1.2...1.3
[1.2]: https://github.com/michaelvillar/timer-app/compare/1.1.0...1.2
[1.1.0]: https://github.com/michaelvillar/timer-app/compare/1.0.2...1.1.0
[1.0.2]: https://github.com/michaelvillar/timer-app/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/michaelvillar/timer-app/releases/tag/1.0.1
