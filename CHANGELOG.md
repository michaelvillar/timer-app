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
- Added 7 final UI tests: active timer interruption (`testDigitInputStopsRunningTimer`), timer completion then restart (`testTimerCompletionThenRestartWithRKey`), background timer execution (`testTimerContinuesWhileAppHidden`), rapid pause/resume stress test (`testRapidPauseResumeCycles`), multi-window dock badge handoff (`testDockBadgeSwitchesBetweenWindows`), sequential backspace (`testMultipleBackspacesSequentially`), and natural completion with badge (`testTimerCompletionWithDockBadgeActive`) — 54 total UI tests
- Removed 16 redundant UI tests where one test was a strict subset or near-duplicate of another (54 → 38 UI tests, no code path coverage lost)
- Improved UI test quality: replaced silent `if exists` guards with `XCTAssertTrue` assertions in `testSoundMenuSelection`, replaced `Thread.sleep` with `waitForExistence(timeout:)` for window appearance waits, consolidated 14 MARK sections into 9

### Changed

- Added comment documenting empty `keyDown` override that suppresses system beep
- Made `windowLevel()` private in `AppDelegate`
- Made `menuItem` property `private(set)` in `MVMainView`
- Replaced force unwraps on named colors with `guard let` in `MVMainView.draw()`
- Added `final` to all non-subclassed classes for compiler optimizations
- Downgraded `MVClockArrowView` and `MVClockView` from `NSControl` to `NSView` (no longer use target/action)
- Eliminated force unwraps in `MVWindow` (`NSScreen.main!`, `standardWindowButton(.closeButton)!`) using nil-coalescing and `if let`
- Eliminated remaining force unwrap in `MVMainView` init (`menuItem!` → `if let`)
- Renamed `_image` to `cachedImage` in `MVClockFaceView` for idiomatic Swift naming
- Tightened access control: made `MVWindow.mainView`, `MVClockView.handleClick`/`didDrag`/`seconds`/`minutes`/`progress`, and `MVClockArrowView.handleDragged`/`handleUp` private
- Replaced `NSString(format:)` with native Swift string interpolation and `String(format:)` in `TimerLogic`
- Eliminated force unwraps in `MVTimerController` and `AppDelegate` using `if let` and optional chaining
- Converted `MVUserDefaultsKeys` and `Keycode` from `struct` to caseless `enum` to prevent accidental instantiation
- Replaced `@NSApplicationMain` with `@main` in `AppDelegate`
- Shortened fully-qualified type references (`NSTextAlignment.center` → `.center`, `NSRect.zero` → `.zero`, etc.)
- Renamed `theEvent` parameters to `event` for consistency across `MVClockView` and `MVTimerController`
- Removed unnecessary `completionHandler: nil` argument and replaced `setNeedsDisplay(bounds)` with `needsDisplay = true`
- Replaced target/selector `Timer.scheduledTimer` with closure-based variant using `[weak self]` in `MVClockView`
- Made `tick()` and `maintainCurrentTime()` private (no longer need `@objc`)
- Tightened access control: removed unnecessary `public` on `MVClockView.inDock`, `MVClockView.windowIsVisible`, `MVMainView.menuItem`
- Extracted `MVClockProgressView`, `MVClockArrowView`, and `MVClockFaceView` into separate files from `MVClockView.swift`
- Replaced `perform(_:with:)` / `NSNumber` boxing in `MVClockArrowView` with typed closure callbacks (`onProgressChanged`, `onMouseUp`)
- Replaced target/action pattern for timer completion between `MVClockView` and `MVTimerController` with `onTimerComplete` closure
- Converted all 11 selector-based `NotificationCenter` observers across 5 files to closure-based `addObserver(forName:)` with token cleanup
- Eliminated force cast (`as!`) and force unwraps in `MVMainView` using `guard let` and optional chaining
- Reduced `@objc` annotations from 13 to 3 (only XIB/menu action targets remain)
- Extracted pure logic from `MVClockView` and `MVTimerController` into new `TimerLogic` enum
- `MVClockView` and `MVTimerController` now delegate to `TimerLogic` for progress scale conversion, display formatting, keyboard input processing, and sound filename mapping
- SwiftLint now also lints `TimerTests` directory
- Removed unnecessary `mainView` stored property from `MVWindow`
- Raised deployment target to macOS 14 (Sonoma)
- Replaced deprecated `NSUserNotification` / `NSUserNotificationCenter` with `UNUserNotificationCenter`
- Extracted static font constants (`minutesFont`, `secondsFont`) in `MVClockView`, eliminating 3 force unwraps on `.font!`
- Converted suffix width properties from `var` to `let` computed from static fonts in `MVClockView`
- Converted 7 IUO subview properties in `MVClockView` to `private let` with inline initialization
- Converted `clockView` IUO in `MVTimerController` to `private let` with inline initialization
- Replaced `mainView` IUO in `MVTimerController` with `weak var dockMenuItem: NSMenuItem?`
- Fixed trailing closure syntax in `NSAnimationContext.runAnimationGroup` call in `MVClockView`
- Simplified `self.paused != true` to `!self.paused` in `MVClockView`
- Made `playAlarmSound()` private in `MVTimerController`
- Replaced `NSColor(named:)` with `NSColor(resource:)` in `MVMainView.draw()` for compile-time safety
- Replaced all 6 `NSImage(named:)` calls with `NSImage(resource:)` in `MVClockView`, `MVClockFaceView`, `MVClockProgressView`
- Consolidated window-focus notification observers from `MVClockArrowView` and `MVClockProgressView` into parent `MVClockView`
- Added `force_unwrapping` opt-in SwiftLint rule to prevent regressions
- Normalized 4-space indentation to 2-space in `MVTimerController` and `MVMainView`
- Fixed double-space before `else` in 3 guard statements in `MVClockView`
- Replaced `representedObject` / `as? Int` casts with type-safe `NSMenuItem.tag` for sound selection in `MVMainView`
- Made `contextMenu` a non-optional `let` constant in `MVMainView`
- Replaced `NSAffineTransform` Obj-C bridge with pure `CGAffineTransform` in `MVClockProgressView`
- Converted `windowLevel()` function to computed property in `AppDelegate`
- `make build` now allows incremental builds (no longer forces clean)

- Removed unnecessary `break` statements in `MVClockArrowView` switch cases (Swift doesn't fall through by default)
- Simplified optional chain in keyboard input from `Int(event.characters ?? "")` to double-`if let` in `MVClockView`
- Updated deployment target documentation in `CLAUDE.md` from macOS 10.11+ to macOS 14 (Sonoma)
- Fixed over-indentation in `AppDelegate.handleClose` (10 spaces → 6)
- Simplified `pickSound` loop in `MVMainView` with ternary operator
- Re-enabled `unneeded_break_in_switch` SwiftLint rule (redundant breaks cleaned up in Round 8)
- Added `private_over_fileprivate`, `discouraged_optional_boolean`, and `static_over_final_class` SwiftLint opt-in rules
- Fixed `closure_parameter_position` SwiftLint warnings across `AppDelegate`, `MVMainView`, and `MVClockView` by moving closure parameters to the same line as the opening brace
- Extracted inline `NSColor` allocations from `draw()` in `MVClockArrowView` and `MVClockProgressView` into `private static let` constants for performance
- Pre-computed focused arrow color (was interpolated at ratio 0.5 every frame) in `MVClockArrowView`
- Removed unused `event` parameter from `handleUp` in `MVClockArrowView`
- Added `first_where`, `discouraged_optional_collection`, and `prefer_zero_over_explicit_init` SwiftLint opt-in rules
- Replaced `CGPoint(x: 0, y: 0)` with `.zero` in `MVClockArrowView` (caught by new `prefer_zero_over_explicit_init` rule)
- Added `lint`, `analyze`, and `format` targets to Makefile
- Fixed outdated `CLAUDE.md` claim "No unit tests in the project" (now points to `TimerTests/` target)
- Replaced `import Cocoa` with `import AppKit` in 10 view/controller files (narrower import = faster compilation + clearer dependencies)
- Added explicit `self.` prefix to instance members per `explicit_self` analyzer rule in `MVClockArrowView`, `MVClockProgressView`, `MVClockFaceView`
- Added explicit `self.` prefix to instance members in `MVMainView`, `MVTimerController`, `AppDelegate`
- Added explicit `self.` prefix to instance members in `MVClockView` (resolves all `explicit_self` analyzer violations)
- Added `TimerUITests` target with XCUITest framework for automated UI testing
- Added `TimerUITests.xcscheme` for running UI tests separately
- Added `make uitest` target to Makefile for running UI tests
- Added comprehensive UI tests covering: keyboard input (digits, Escape, Enter, Space, R, Backspace, Delete, Period), mouse clicks (clock face pause/resume), arrow dragging, context menu, sound selection, dock badge toggle, timer completion, and multiple windows
- Added 6 medium-difficulty UI tests: keypad decimal edge cases (`testDecimalWithMinutesAndSeconds`, `testDoublePeriodTogglesBackToMinutes`, `testMaxSecondsInput`), max timer limit (`testMaxTimerLimitViaKeyboard`, `testExcessDigitsRejected`), and app reopen from dock (`testAppReopenAfterHide`)
- Added 4 hard-difficulty UI tests: sound preference persistence across restart (`testSoundPersistsAfterRestart`), dock badge active while timer runs (`testDockBadgeActiveWhileTimerRuns`), dock badge clears on timer stop (`testDockBadgeClearsOnTimerStop`), and notification on timer completion (`testNotificationOnTimerComplete`) — 37 total UI tests
- Added 10 edge case UI tests: state transition edge cases (`testEscapeWhilePaused`, `testCrossInputPauseResume`, `testArrowDragThenEnterToStart`, `testContextMenuDuringActiveTimer`, `testCloseWindowWithActiveTimer`, `testCloseLastWindowAppStaysRunning`) and input edge cases (`testBackspaceWithNoDigits`, `testRKeyWithNoPreviousTimer`, `testMultipleWindowsIndependentTimers`, `testZeroAsOnlyDigit`) — 47 total UI tests

### Removed

- Deprecated `CFBundleSignature` key from `Info.plist` (legacy Classic Mac OS creator code, ignored since OS X)
- Empty `CFBundleIconFile` key from `Info.plist` (app uses asset catalog icon)
- Commented-out `audioPlayer?.volume` dead code in `MVTimerController`

- Hidden Edit, Format, View, and Help menus from `MainMenu.xib` (~500 lines of dead XML)
- Hidden Preferences menu item and separator from Timer menu in `MainMenu.xib`
- Unused `NSFontManager` custom object from `MainMenu.xib`

### CI

- Updated `actions/checkout` to `v4` across all workflows
- Replaced deprecated `norio-nomura/action-swiftlint` with direct `brew install swiftlint` on `macos-latest`
- Replaced deprecated `actions/create-release` and `actions/upload-release-asset` with `softprops/action-gh-release@v2`

### Fixed

- Restored `mouseDownCanMoveWindow = false` on `MVClockArrowView` and `MVClockView`, lost when downgrading from `NSControl` to `NSView` — arrow was undraggable because macOS intercepted mouse events for window dragging
- Resolved all SwiftLint warnings: replaced `arc4random_uniform` with `Int.random(in:)`, fixed comment spacing, removed superfluous disable command, moved analyzer-only rules to correct config section, removed defunct `anyobject_protocol` rule
- Updated `MACOSX_DEPLOYMENT_TARGET` from 10.11 to 10.13 (Xcode no longer supports targets below 10.13)
- Fixed `handleOcclusionChange` to use `window.occlusionState.contains(.visible)` instead of `window.isVisible`, which only checked if the window was ordered in rather than actually visible on screen
- Removed redundant `#available(OSX 10.13, *)` check now that the deployment target is 10.13
- Removed dead code in `MVMainView.draw()` — hardcoded colors were overwritten by named colors
- Cached `DateFormatter` in `MVClockView.updateTimeLabel()` to avoid allocation every second
- Replaced force unwrap of `nextEvent` in `MVClockArrowView.mouseDown` with safe unwrap
- Removed unused `initialLocation` property in `MVWindow`
- Fixed unused variable warning in `testWindowDragging` (removed unused `originalFrame`)
- Secondary timer windows no longer overwrite the primary window's saved position
- `make` now opens `Timer.app` directly instead of the Release folder
- Renamed `makefile` to `Makefile` (conventional capitalization)
