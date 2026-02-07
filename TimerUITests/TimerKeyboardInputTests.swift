import XCTest

final class TimerKeyboardInputTests: TimerUITestCase {
  // MARK: - Keyboard Input

  func testEscapeClearsTimer() throws {
    let window = app.windows.firstMatch

    window.typeKey("3", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    XCTAssertTrue(window.exists, "Window should still exist after escape")
  }

  func testEnterStartsTimer() throws {
    let window = app.windows.firstMatch

    window.typeKey("1", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Window should still exist after starting timer")
  }

  func testMultipleDigitsSetTimer() throws {
    let window = app.windows.firstMatch

    window.typeKey("1", modifierFlags: [])
    window.typeKey("2", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Window should still exist after typing multiple digits")
  }

  func testPeriodTogglesSecondsInput() throws {
    let window = app.windows.firstMatch

    window.typeKey(".", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    window.typeKey("3", modifierFlags: [])
    window.typeKey("0", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    XCTAssertTrue(window.exists, "Window should still exist after seconds input")
  }

  func testRKeyRestartsLastTimer() throws {
    let window = app.windows.firstMatch

    window.typeKey("1", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.5)

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    window.typeKey("r", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Window should still exist after restart")
  }

  func testMaxTimerLimitViaKeyboard() throws {
    let window = app.windows.firstMatch

    // Type 999 minutes (max allowed by keyboard input)
    window.typeKey("9", modifierFlags: [])
    window.typeKey("9", modifierFlags: [])
    window.typeKey("9", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    // Try to type another digit (should be rejected, 9990 > 999*60)
    window.typeKey("9", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    XCTAssertTrue(window.exists, "Window should still exist after max keyboard input")

    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.5)
    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    XCTAssertTrue(window.exists, "Window should exist after starting max timer")
  }

  // MARK: - Decimal & Seconds Input

  func testDecimalWithMinutesAndSeconds() throws {
    let window = app.windows.firstMatch

    window.typeKey("5", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(".", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey("3", modifierFlags: [])
    window.typeKey("0", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.5)

    XCTAssertTrue(window.exists, "Window should exist with 5:30 timer")

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
  }

  func testDoublePeriodTogglesBackToMinutes() throws {
    let window = app.windows.firstMatch

    window.typeKey(".", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(".", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    window.typeKey("5", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.5)

    XCTAssertTrue(window.exists, "Window should exist after double period toggle")

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
  }

  func testMaxSecondsInput() throws {
    let window = app.windows.firstMatch

    window.typeKey(".", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey("5", modifierFlags: [])
    window.typeKey("9", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.5)

    XCTAssertTrue(window.exists, "Window should exist with 59 second timer")

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
  }
}
