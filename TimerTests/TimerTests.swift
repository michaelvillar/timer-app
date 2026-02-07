@testable import Timer
import XCTest

final class TimerLogicTests: XCTestCase {
  // MARK: - convertProgressToScale

  func testConvertProgressToScalePassthroughAbove60Minutes() {
    let result = TimerLogic.convertProgressToScale(0.5, minutes: 61)
    XCTAssertEqual(result, 0.5)
  }

  func testConvertProgressToScalePassthroughAt90Minutes() {
    let result = TimerLogic.convertProgressToScale(0.75, minutes: 90)
    XCTAssertEqual(result, 0.75)
  }

  func testConvertProgressToScaleLowRange() {
    // progress = 0.05 which is <= 6/60 = 0.1
    let result = TimerLogic.convertProgressToScale(0.05, minutes: 30)
    XCTAssertEqual(result, 0.05 / 2.0, accuracy: 1e-10)
  }

  func testConvertProgressToScaleHighRange() {
    // progress = 0.5, minutes = 30 -> high range formula
    let result = TimerLogic.convertProgressToScale(0.5, minutes: 30)
    let expected = (0.5 * 60 - 6 + 3) / (60 - 3)
    XCTAssertEqual(result, expected, accuracy: 1e-10)
  }

  func testConvertProgressToScaleZero() {
    let result = TimerLogic.convertProgressToScale(0, minutes: 30)
    XCTAssertEqual(result, 0)
  }

  func testConvertProgressToScaleAtBoundary() {
    // progress = 6/60 = 0.1 exactly (boundary)
    let result = TimerLogic.convertProgressToScale(0.1, minutes: 30)
    XCTAssertEqual(result, 0.1 / 2.0, accuracy: 1e-10)
  }

  // MARK: - invertProgressToScale

  func testInvertProgressToScalePassthroughAbove60Minutes() {
    let result = TimerLogic.invertProgressToScale(0.5, minutes: 61)
    XCTAssertEqual(result, 0.5)
  }

  func testInvertProgressToScaleLowRange() {
    // progress = 0.025 which is <= 3/60 = 0.05
    let result = TimerLogic.invertProgressToScale(0.025, minutes: 30)
    XCTAssertEqual(result, 0.025 * 2.0, accuracy: 1e-10)
  }

  func testInvertProgressToScaleHighRange() {
    // progress = 0.5, minutes = 30
    let result = TimerLogic.invertProgressToScale(0.5, minutes: 30)
    let expected = (0.5 * (60 - 3) - 3 + 6) / 60
    XCTAssertEqual(result, expected, accuracy: 1e-10)
  }

  func testConvertAndInvertAreInverses() {
    // For a given progress in low range, convert then invert should round-trip
    let original: CGFloat = 0.04
    let converted = TimerLogic.convertProgressToScale(original, minutes: 30)
    let inverted = TimerLogic.invertProgressToScale(converted, minutes: 30)
    XCTAssertEqual(inverted, original, accuracy: 1e-10)
  }

  func testConvertAndInvertAreInversesHighRange() {
    let original: CGFloat = 0.7
    let converted = TimerLogic.convertProgressToScale(original, minutes: 30)
    let inverted = TimerLogic.invertProgressToScale(converted, minutes: 30)
    XCTAssertEqual(inverted, original, accuracy: 1e-10)
  }

  // MARK: - minutesDisplayString

  func testMinutesDisplayStringUnderOneMinute() {
    XCTAssertEqual(TimerLogic.minutesDisplayString(seconds: 45), "45\"")
  }

  func testMinutesDisplayStringZeroSeconds() {
    XCTAssertEqual(TimerLogic.minutesDisplayString(seconds: 0), "0\"")
  }

  func testMinutesDisplayStringExactlyOneMinute() {
    XCTAssertEqual(TimerLogic.minutesDisplayString(seconds: 60), "1'")
  }

  func testMinutesDisplayStringMultipleMinutes() {
    XCTAssertEqual(TimerLogic.minutesDisplayString(seconds: 150), "2'")
  }

  func testMinutesDisplayStringLargeValue() {
    XCTAssertEqual(TimerLogic.minutesDisplayString(seconds: 3_600), "60'")
  }

  // MARK: - secondsDisplayString

  func testSecondsDisplayStringUnderOneMinute() {
    XCTAssertEqual(TimerLogic.secondsDisplayString(seconds: 45), "")
  }

  func testSecondsDisplayStringExactMinute() {
    XCTAssertEqual(TimerLogic.secondsDisplayString(seconds: 120), "0\"")
  }

  func testSecondsDisplayStringWithRemainder() {
    XCTAssertEqual(TimerLogic.secondsDisplayString(seconds: 90), "30\"")
  }

  func testSecondsDisplayStringAt61() {
    XCTAssertEqual(TimerLogic.secondsDisplayString(seconds: 61), "1\"")
  }

  // MARK: - badgeString

  func testBadgeStringZero() {
    XCTAssertEqual(TimerLogic.badgeString(minutes: 0, seconds: 0), "00:00")
  }

  func testBadgeStringSingleDigits() {
    XCTAssertEqual(TimerLogic.badgeString(minutes: 5, seconds: 3), "05:03")
  }

  func testBadgeStringDoubleDigits() {
    XCTAssertEqual(TimerLogic.badgeString(minutes: 12, seconds: 45), "12:45")
  }

  // MARK: - processDigitInput (minutes mode)

  func testDigitInputMinutesMode() {
    let result = TimerLogic.processDigitInput(
      digit: 5, currentSeconds: 0, currentMinutes: 0, totalSeconds: 0, inputSeconds: false
    )
    XCTAssertTrue(result.accepted)
    XCTAssertEqual(result.seconds, 300) // 5 * 60
  }

  func testDigitInputMinutesModeAppend() {
    // Starting at 5 minutes (300s), type "3" -> 53 minutes
    let result = TimerLogic.processDigitInput(
      digit: 3, currentSeconds: 0, currentMinutes: 5, totalSeconds: 300, inputSeconds: false
    )
    XCTAssertTrue(result.accepted)
    XCTAssertEqual(result.seconds, 5 * 600 + 3 * 60) // 3180
  }

  func testDigitInputMinutesModeRejectsOver999() {
    // 999 minutes = 59940 seconds; typing another digit would exceed limit
    let result = TimerLogic.processDigitInput(
      digit: 1, currentSeconds: 0, currentMinutes: 999, totalSeconds: 59_940, inputSeconds: false
    )
    XCTAssertFalse(result.accepted)
    XCTAssertEqual(result.seconds, 59_940)
  }

  // MARK: - processDigitInput (seconds mode)

  func testDigitInputSecondsMode() {
    let result = TimerLogic.processDigitInput(
      digit: 3, currentSeconds: 0, currentMinutes: 5, totalSeconds: 300, inputSeconds: true
    )
    XCTAssertTrue(result.accepted)
    XCTAssertEqual(result.seconds, 303) // 5*60 + 0*10 + 3
  }

  func testDigitInputSecondsModeAppend() {
    // 5 minutes 3 seconds, type "2" -> 5 minutes 32 seconds
    let result = TimerLogic.processDigitInput(
      digit: 2, currentSeconds: 3, currentMinutes: 5, totalSeconds: 303, inputSeconds: true
    )
    XCTAssertTrue(result.accepted)
    XCTAssertEqual(result.seconds, 332) // 5*60 + 3*10 + 2
  }

  func testDigitInputSecondsModeBlockedWhenFull() {
    // currentSeconds >= 6 and currentMinutes > 0 -> blocked
    let result = TimerLogic.processDigitInput(
      digit: 1, currentSeconds: 30, currentMinutes: 5, totalSeconds: 330, inputSeconds: true
    )
    XCTAssertTrue(result.accepted) // accepted but unchanged
    XCTAssertEqual(result.seconds, 330)
  }

  func testDigitInputSecondsModeZeroMinutesAllowsLargeSeconds() {
    // With 0 minutes, any seconds value can be appended
    let result = TimerLogic.processDigitInput(
      digit: 5, currentSeconds: 9, currentMinutes: 0, totalSeconds: 9, inputSeconds: true
    )
    XCTAssertTrue(result.accepted)
    XCTAssertEqual(result.seconds, 95) // 0*60 + 9*10 + 5
  }

  // MARK: - processBackspace

  func testBackspaceMinutesMode() {
    // 53 minutes 0 seconds -> removes last digit of minutes -> 5 minutes
    let result = TimerLogic.processBackspace(currentSeconds: 0, currentMinutes: 53, inputSeconds: false)
    XCTAssertEqual(result, 5 * 60) // floor(53/10)*60 + 0
  }

  func testBackspaceSecondsMode() {
    // 5 minutes 32 seconds -> removes last digit of seconds -> 5 minutes 3 seconds
    let result = TimerLogic.processBackspace(currentSeconds: 32, currentMinutes: 5, inputSeconds: true)
    XCTAssertEqual(result, 303) // 5*60 + floor(32/10)
  }

  func testBackspaceMinutesModeFromZero() {
    let result = TimerLogic.processBackspace(currentSeconds: 0, currentMinutes: 0, inputSeconds: false)
    XCTAssertEqual(result, 0)
  }

  func testBackspaceSecondsModeFromSingleDigit() {
    // 5 minutes 3 seconds -> removes last digit -> 5 minutes 0 seconds
    let result = TimerLogic.processBackspace(currentSeconds: 3, currentMinutes: 5, inputSeconds: true)
    XCTAssertEqual(result, 300)
  }

  // MARK: - soundFilename

  func testSoundFilenameNone() {
    XCTAssertNil(TimerLogic.soundFilename(forIndex: -1))
  }

  func testSoundFilenameDefault() {
    XCTAssertEqual(TimerLogic.soundFilename(forIndex: 0), "alert-sound")
  }

  func testSoundFilenameSecond() {
    XCTAssertEqual(TimerLogic.soundFilename(forIndex: 1), "alert-sound-2")
  }

  func testSoundFilenameThird() {
    XCTAssertEqual(TimerLogic.soundFilename(forIndex: 2), "alert-sound-3")
  }

  func testSoundFilenameUnknownIndex() {
    XCTAssertEqual(TimerLogic.soundFilename(forIndex: 99), "alert-sound")
  }

  // MARK: - accessibilityTimeDescription

  func testAccessibilityTimeDescriptionMinutesAndSeconds() {
    XCTAssertEqual(TimerLogic.accessibilityTimeDescription(minutes: 5, seconds: 30), "5 minutes 30 seconds")
  }

  func testAccessibilityTimeDescriptionMinutesOnly() {
    XCTAssertEqual(TimerLogic.accessibilityTimeDescription(minutes: 3, seconds: 0), "3 minutes")
  }

  func testAccessibilityTimeDescriptionSecondsOnly() {
    XCTAssertEqual(TimerLogic.accessibilityTimeDescription(minutes: 0, seconds: 45), "45 seconds")
  }

  func testAccessibilityTimeDescriptionZero() {
    XCTAssertEqual(TimerLogic.accessibilityTimeDescription(minutes: 0, seconds: 0), "0 seconds")
  }
}
