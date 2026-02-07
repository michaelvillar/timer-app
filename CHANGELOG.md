# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [2.1.0] - 2026-02-07

### Added

- URL scheme support — e.g. `open "timer://5"`, `open "timer://2:30?window=2"` (#51)
- Launch argument support — e.g. `open -a Timer --args 5 --window 2` (#51)
- AppleScript support with scripting definition — e.g. `tell app "Timer" to start timer "5"` (#105)
- CLI wrapper script (`timer-cli`) with `make install-cli` target (#51)
- Commands: start, stop, reset, pause, new — all with optional window targeting
- Time input formats: `5` (5 min), `2.5` (2m30s fractional), `2:30` (2m30s colon)
- Scroll wheel input for setting timer duration (#140)
- Open/closed hand cursor feedback on arrow control (#139)

### Fixed

- Label colors now use Apple Lead (#191919) instead of pure black for better contrast

## [2.0.0] - 2026-02-07

### Added

- 43 unit tests and 38 UI tests
- Xcode schemes for running tests; `make test` and `make uitest` targets
- `make lint`, `make analyze`, and `make format` targets
- CI test step in build workflow
- Sound choice persists across launches
- Dark mode color support
- VoiceOver accessibility for timer state and arrow control

### Changed

- Upgraded to Swift 6
- Raised deployment target to macOS 14 (Sonoma)
- Replaced deprecated `NSUserNotification` with `UNUserNotificationCenter`
- Adopted `async`/`await` throughout (timers, notifications, authorization)
- Improved keyboard input to use character-based matching (better international keyboard support)
- Reduced per-frame allocations by caching gradients, images, paths, and formatters
- Extracted reusable logic into `TimerLogic` for testability
- Split large files to stay within default SwiftLint thresholds
- Modernized Xcode project settings and build configuration
- Expanded SwiftLint opt-in rules from 6 to 73
- General code cleanup: tightened access control, removed force unwraps, reduced Obj-C surface

### Removed

- `Keycodes.swift` (replaced by character-based key matching)
- ~500 lines of unused XIB menus and dead code
- Deprecated `Info.plist` keys

### Fixed

- Window occlusion detection now checks actual visibility, not just window ordering
- Secondary timer windows no longer overwrite the primary window's saved position

### CI

- Updated all GitHub Actions to current versions
- Replaced deprecated SwiftLint and release actions

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

[Unreleased]: https://github.com/michaelvillar/timer-app/compare/2.1.0...HEAD
[2.1.0]: https://github.com/michaelvillar/timer-app/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/michaelvillar/timer-app/compare/1.6.0...2.0.0
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
