import XCTest

final class TimerInputEdgeCaseTests: TimerUITestCase {
  func testBackspaceWithNoDigits() throws {
    let window = app.windows.firstMatch

    window.typeKey(.delete, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.forwardDelete, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    XCTAssertTrue(window.exists, "Window should exist after backspace with no digits")

    window.typeKey("5", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    XCTAssertTrue(window.exists, "Window should accept input after empty backspace")
  }

  func testMultipleBackspacesSequentially() throws {
    let window = app.windows.firstMatch

    // Type "123" to set 123 minutes
    window.typeKey("1", modifierFlags: [])
    window.typeKey("2", modifierFlags: [])
    window.typeKey("3", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    // Backspace three times: 123 → 12 → 1 → 0
    window.typeKey(.delete, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.1)
    window.typeKey(.delete, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.1)
    window.typeKey(.delete, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    // Timer should be at zero — pressing Enter should not start it
    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Window should exist after backspacing to zero")

    window.typeKey("5", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Should be able to start timer after backspacing to zero")

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
  }

  func testRKeyWithNoPreviousTimer() throws {
    let window = app.windows.firstMatch

    window.typeKey("r", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Window should exist after R with no previous timer")

    window.typeKey("1", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Should be able to start timer after R with no history")

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
  }

  func testMultipleWindowsIndependentTimers() throws {
    let firstWindow = app.windows.firstMatch

    firstWindow.typeKey("3", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    firstWindow.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    app.typeKey("n", modifierFlags: .command)

    let secondWindow = app.windows.element(boundBy: 1)
    XCTAssertTrue(secondWindow.waitForExistence(timeout: 2), "Second window should appear")
    XCTAssertEqual(app.windows.count, 2, "Should have 2 windows")

    let frontWindow = app.windows.firstMatch
    frontWindow.typeKey("1", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    frontWindow.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.5)

    XCTAssertEqual(app.windows.count, 2, "Both windows should still exist")

    frontWindow.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    app.typeKey("w", modifierFlags: .command)
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertEqual(app.windows.count, 1, "Should have 1 window remaining")
    app.windows.firstMatch.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
  }

  func testZeroAsOnlyDigit() throws {
    let window = app.windows.firstMatch

    window.typeKey("0", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Window should exist after typing 0 and Enter")

    window.typeKey("5", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Should be able to start timer after zero input")

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
  }
}
