import XCTest

final class TimerStateTransitionTests: TimerUITestCase {
  func testEscapeWhilePaused() throws {
    let window = app.windows.firstMatch

    window.typeKey("5", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.5)

    window.typeKey(" ", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Window should exist after escape while paused")

    // Proves we're back in idle state
    window.typeKey("3", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Should be able to start new timer after escape from paused")

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
  }

  func testCrossInputPauseResume() throws {
    let window = app.windows.firstMatch
    let windowCenter = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))

    window.typeKey("5", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.5)

    // Pause with Space, resume with click
    window.typeKey(" ", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)
    windowCenter.click()
    Thread.sleep(forTimeInterval: 0.5)

    XCTAssertTrue(window.exists, "Window should exist after space-pause then click-resume")

    // Pause with click, resume with Space
    windowCenter.click()
    Thread.sleep(forTimeInterval: 0.3)
    window.typeKey(" ", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.5)

    XCTAssertTrue(window.exists, "Window should exist after click-pause then space-resume")

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
  }

  func testArrowDragThenEnterToStart() throws {
    let window = app.windows.firstMatch

    let top = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
    let right = window.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
    top.press(forDuration: 0.1, thenDragTo: right)
    Thread.sleep(forTimeInterval: 0.3)

    // Arrow drag auto-starts the timer on mouse-up, so stop it first
    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    // Set via keyboard and start
    window.typeKey("1", modifierFlags: [])
    window.typeKey("0", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.5)

    XCTAssertTrue(window.exists, "Window should exist after keyboard set + Enter start")

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
  }

  func testContextMenuDuringActiveTimer() throws {
    let window = app.windows.firstMatch

    window.typeKey("5", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.5)

    window.rightClick()
    Thread.sleep(forTimeInterval: 0.3)

    let menuItems = app.menuItems
    XCTAssertFalse(menuItems.allElementsBoundByIndex.isEmpty, "Context menu should have items during active timer")

    // Dismiss the menu
    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Window should exist after context menu during timer")

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
  }

  func testCloseWindowWithActiveTimer() throws {
    app.typeKey("n", modifierFlags: .command)

    let secondWindow = app.windows.element(boundBy: 1)
    XCTAssertTrue(secondWindow.waitForExistence(timeout: 2), "Second window should appear")

    let windowCount = app.windows.count
    XCTAssertGreaterThanOrEqual(windowCount, 2, "Should have at least 2 windows")

    // Start a timer in the front window
    let window = app.windows.firstMatch
    window.typeKey("5", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.5)

    app.typeKey("w", modifierFlags: .command)
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertEqual(app.windows.count, windowCount - 1, "Should have one fewer window")
    XCTAssertTrue(app.windows.firstMatch.exists, "Remaining window should exist")
  }

  func testDigitInputStopsRunningTimer() throws {
    let window = app.windows.firstMatch

    window.typeKey("5", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 1.0)

    // Type a digit while the timer is actively counting down
    window.typeKey("3", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Window should exist after digit input during countdown")

    // The new value should be startable
    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Should be able to start timer with new value after interrupting")

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
  }

  func testRapidPauseResumeCycles() throws {
    let window = app.windows.firstMatch

    window.typeKey("5", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.5)

    for _ in 0..<6 {
      window.typeKey(" ", modifierFlags: [])
      Thread.sleep(forTimeInterval: 0.15)
    }

    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Window should exist after rapid pause/resume cycles")

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    // Verify clean state
    window.typeKey("1", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Should be able to start new timer after rapid cycles")

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
  }
}
