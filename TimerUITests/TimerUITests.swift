import XCTest

final class TimerWindowTests: TimerUITestCase {
  // MARK: - Window & Launch

  func testWindowExists() throws {
    let window = app.windows.firstMatch
    XCTAssertTrue(window.exists, "Main window should exist")
    XCTAssertTrue(window.isHittable, "Main window should be hittable")
  }

  func testWindowDragging() throws {
    let window = app.windows.firstMatch
    let windowCenter = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let destination = windowCenter.withOffset(CGVector(dx: 100, dy: 100))

    windowCenter.press(forDuration: 0.1, thenDragTo: destination)
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Window should still exist after dragging")
  }

  func testCloseSecondaryWindow() throws {
    app.typeKey("n", modifierFlags: .command)

    let secondWindow = app.windows.element(boundBy: 1)
    XCTAssertTrue(secondWindow.waitForExistence(timeout: 2), "Second window should appear")

    let windowCount = app.windows.count
    XCTAssertGreaterThanOrEqual(windowCount, 2, "Should have at least 2 windows")

    app.typeKey("w", modifierFlags: .command)
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertEqual(app.windows.count, windowCount - 1, "Should have one fewer window after Cmd+W")
  }

  func testCloseLastWindowAppStaysRunning() throws {
    XCTAssertEqual(app.windows.count, 1, "Should start with one window")

    app.typeKey("w", modifierFlags: .command)
    Thread.sleep(forTimeInterval: 0.5)

    XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground,
                  "App should still be running after closing last window")

    app.typeKey("n", modifierFlags: .command)

    let window = app.windows.firstMatch
    XCTAssertTrue(window.waitForExistence(timeout: 2), "Should be able to create new window after closing last one")
  }
}
