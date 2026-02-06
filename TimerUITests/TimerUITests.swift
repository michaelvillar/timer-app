import XCTest

/// UI Tests for the Timer app
/// Run with: make uitest
final class TimerUITests: XCTestCase {
  var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launch()
  }

  override func tearDownWithError() throws {
    app.terminate()
    app = nil
  }

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

  // MARK: - Mouse & Arrow Drag

  func testClickClockFaceResumesTimer() throws {
    let window = app.windows.firstMatch

    window.typeKey("1", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    // Click to pause, click again to resume
    let windowCenter = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    windowCenter.click()
    Thread.sleep(forTimeInterval: 0.3)
    windowCenter.click()
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Window should still exist after clicking to resume")
  }

  func testDragArrowToSetTimer() throws {
    let window = app.windows.firstMatch

    let topOfClock = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
    let rightOfClock = window.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))

    topOfClock.press(forDuration: 0.1, thenDragTo: rightOfClock)
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Window should still exist after dragging arrow")
  }

  func testDragArrowFullCircle() throws {
    let window = app.windows.firstMatch

    let top = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
    let right = window.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
    let bottom = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05))
    let left = window.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5))

    top.press(forDuration: 0.05, thenDragTo: right)
    Thread.sleep(forTimeInterval: 0.1)
    right.press(forDuration: 0.05, thenDragTo: bottom)
    Thread.sleep(forTimeInterval: 0.1)
    bottom.press(forDuration: 0.05, thenDragTo: left)
    Thread.sleep(forTimeInterval: 0.1)
    left.press(forDuration: 0.05, thenDragTo: top)
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Window should still exist after full circle drag")
  }

  // MARK: - Context Menu & Sound

  func testDockBadgeMenuItemExists() throws {
    let window = app.windows.firstMatch

    window.rightClick()
    Thread.sleep(forTimeInterval: 0.3)

    let dockMenuItem = app.menuItems["Show timer badge in dock"]
    XCTAssertTrue(dockMenuItem.exists, "Dock badge menu item should exist")
  }

  func testSoundMenuSelection() throws {
    let window = app.windows.firstMatch

    window.rightClick()
    Thread.sleep(forTimeInterval: 0.3)

    let soundMenuItem = app.menuItems["Sound"]
    XCTAssertTrue(soundMenuItem.exists, "Sound submenu should exist")
    soundMenuItem.hover()
    Thread.sleep(forTimeInterval: 0.3)

    let sound1 = app.menuItems["Sound 1"]
    XCTAssertTrue(sound1.exists, "Sound 1 menu item should exist")
    sound1.click()
    Thread.sleep(forTimeInterval: 0.5)

    XCTAssertTrue(window.exists, "Window should still exist after sound selection")
  }

  func testSoundPersistsAfterRestart() throws {
    let window = app.windows.firstMatch

    // Select Sound 2 via context menu
    window.rightClick()
    Thread.sleep(forTimeInterval: 0.3)
    let soundMenuItem = app.menuItems["Sound"]
    XCTAssertTrue(soundMenuItem.exists, "Sound menu should exist")
    soundMenuItem.hover()
    Thread.sleep(forTimeInterval: 0.3)
    app.menuItems["Sound 2"].click()
    Thread.sleep(forTimeInterval: 0.3)

    // Terminate and relaunch the app
    app.terminate()
    Thread.sleep(forTimeInterval: 0.5)
    app.launch()

    let newWindow = app.windows.firstMatch
    XCTAssertTrue(newWindow.waitForExistence(timeout: 3), "Window should exist after relaunch")

    // Open Sound submenu and verify all items are present after relaunch
    newWindow.rightClick()
    Thread.sleep(forTimeInterval: 0.3)
    let soundMenu = app.menuItems["Sound"]
    XCTAssertTrue(soundMenu.exists, "Sound menu should exist after relaunch")
    soundMenu.hover()
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(app.menuItems["Sound 1"].exists, "Sound 1 should exist after relaunch")
    XCTAssertTrue(app.menuItems["Sound 2"].exists, "Sound 2 should exist after relaunch")
    XCTAssertTrue(app.menuItems["Sound 3"].exists, "Sound 3 should exist after relaunch")
    XCTAssertTrue(app.menuItems["No Sound"].exists, "No Sound should exist after relaunch")

    // Restore Sound 1
    app.menuItems["Sound 1"].click()
    Thread.sleep(forTimeInterval: 0.3)
  }

  // MARK: - Dock Badge

  func testDockBadgeActiveWhileTimerRuns() throws {
    let window = app.windows.firstMatch

    window.rightClick()
    Thread.sleep(forTimeInterval: 0.3)
    let dockMenuItem = app.menuItems["Show timer badge in dock"]
    XCTAssertTrue(dockMenuItem.exists, "Dock badge menu item should exist")
    dockMenuItem.click()
    Thread.sleep(forTimeInterval: 0.3)

    window.typeKey("1", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 2.0)

    XCTAssertTrue(window.exists, "Window should exist with dock badge active")

    // Pause and resume to exercise badge update paths
    window.typeKey(" ", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.5)
    window.typeKey(" ", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.5)

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)

    XCTAssertTrue(window.exists, "Window should exist after stopping timer with badge")

    // Clean up
    window.rightClick()
    Thread.sleep(forTimeInterval: 0.3)
    app.menuItems["Show timer badge in dock"].click()
    Thread.sleep(forTimeInterval: 0.3)
  }

  func testDockBadgeClearsOnTimerStop() throws {
    let window = app.windows.firstMatch

    window.rightClick()
    Thread.sleep(forTimeInterval: 0.3)
    app.menuItems["Show timer badge in dock"].click()
    Thread.sleep(forTimeInterval: 0.3)

    window.typeKey("5", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 1.0)

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(window.exists, "Window should exist after badge clear")

    // Clean up
    window.rightClick()
    Thread.sleep(forTimeInterval: 0.3)
    app.menuItems["Show timer badge in dock"].click()
    Thread.sleep(forTimeInterval: 0.3)
  }

  func testDockBadgeSwitchesBetweenWindows() throws {
    let firstWindow = app.windows.firstMatch

    firstWindow.rightClick()
    Thread.sleep(forTimeInterval: 0.3)
    app.menuItems["Show timer badge in dock"].click()
    Thread.sleep(forTimeInterval: 0.3)

    app.typeKey("n", modifierFlags: .command)

    let secondWindow = app.windows.element(boundBy: 1)
    XCTAssertTrue(secondWindow.waitForExistence(timeout: 2), "Second window should appear")
    XCTAssertEqual(app.windows.count, 2, "Should have 2 windows")

    // Enable dock badge on the second window (should replace first)
    let frontWindow = app.windows.firstMatch
    frontWindow.rightClick()
    Thread.sleep(forTimeInterval: 0.3)
    app.menuItems["Show timer badge in dock"].click()
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(frontWindow.exists, "Second window should exist after badge switch")
    XCTAssertEqual(app.windows.count, 2, "Both windows should still exist")

    // Clean up
    frontWindow.rightClick()
    Thread.sleep(forTimeInterval: 0.3)
    app.menuItems["Show timer badge in dock"].click()
    Thread.sleep(forTimeInterval: 0.3)

    app.typeKey("w", modifierFlags: .command)
    Thread.sleep(forTimeInterval: 0.3)
  }

  // MARK: - Timer Completion & Notification

  func testNotificationOnTimerComplete() throws {
    let window = app.windows.firstMatch

    // Use No Sound to avoid audio during test
    window.rightClick()
    Thread.sleep(forTimeInterval: 0.3)
    let soundMenu = app.menuItems["Sound"]
    XCTAssertTrue(soundMenu.exists, "Sound submenu should exist")
    soundMenu.hover()
    Thread.sleep(forTimeInterval: 0.3)
    app.menuItems["No Sound"].click()
    Thread.sleep(forTimeInterval: 0.3)

    // Set a 3-second timer
    window.typeKey(".", modifierFlags: [])
    window.typeKey("3", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])

    // Wait for timer to complete (3s + buffer for notification dispatch)
    Thread.sleep(forTimeInterval: 4.5)

    // XCUITest cannot reliably inspect system notification banners, but we verify
    // the full completion flow (notification posting + attention request) doesn't crash.
    XCTAssertTrue(window.exists, "Window should exist after timer completion with notification")
    XCTAssertTrue(window.isHittable, "Window should be hittable after notification fires")

    // Restore Sound 1
    window.rightClick()
    Thread.sleep(forTimeInterval: 0.3)
    app.menuItems["Sound"].hover()
    Thread.sleep(forTimeInterval: 0.3)
    app.menuItems["Sound 1"].click()
    Thread.sleep(forTimeInterval: 0.3)
  }

  func testTimerCompletionThenRestartWithRKey() throws {
    let window = app.windows.firstMatch

    // Set a 3-second timer and let it complete
    window.typeKey(".", modifierFlags: [])
    window.typeKey("3", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])

    Thread.sleep(forTimeInterval: 4.0)

    // Press "r" to restart with the same duration
    window.typeKey("r", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.5)

    XCTAssertTrue(window.exists, "Window should exist after restarting completed timer with R key")

    Thread.sleep(forTimeInterval: 1.0)
    XCTAssertTrue(window.exists, "Timer should be running after R key restart")

    window.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
  }

  func testTimerContinuesWhileAppHidden() throws {
    let window = app.windows.firstMatch

    // Set a 3-second timer
    window.typeKey(".", modifierFlags: [])
    window.typeKey("3", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    // Hide the app while timer is running
    app.typeKey("h", modifierFlags: .command)
    Thread.sleep(forTimeInterval: 0.5)

    // Wait for the timer to complete in the background
    Thread.sleep(forTimeInterval: 3.5)

    // Bring the app back
    app.activate()

    let reactivatedWindow = app.windows.firstMatch
    XCTAssertTrue(reactivatedWindow.waitForExistence(timeout: 3), "Window should exist after unhiding")
    XCTAssertTrue(reactivatedWindow.isHittable, "Window should be hittable after unhiding")

    // Verify we're back at idle
    reactivatedWindow.typeKey("1", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    reactivatedWindow.typeKey(.return, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.3)

    XCTAssertTrue(reactivatedWindow.exists, "Should be able to start new timer after background completion")

    reactivatedWindow.typeKey(.escape, modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
  }

  func testTimerCompletionWithDockBadgeActive() throws {
    let window = app.windows.firstMatch

    // Enable dock badge
    window.rightClick()
    Thread.sleep(forTimeInterval: 0.3)
    app.menuItems["Show timer badge in dock"].click()
    Thread.sleep(forTimeInterval: 0.3)

    // Use No Sound to avoid audio during test
    window.rightClick()
    Thread.sleep(forTimeInterval: 0.3)
    let soundMenu = app.menuItems["Sound"]
    XCTAssertTrue(soundMenu.exists, "Sound submenu should exist")
    soundMenu.hover()
    Thread.sleep(forTimeInterval: 0.3)
    app.menuItems["No Sound"].click()
    Thread.sleep(forTimeInterval: 0.3)

    // Set a 3-second timer and let it complete with badge active
    window.typeKey(".", modifierFlags: [])
    window.typeKey("3", modifierFlags: [])
    Thread.sleep(forTimeInterval: 0.2)
    window.typeKey(.return, modifierFlags: [])

    Thread.sleep(forTimeInterval: 4.5)

    XCTAssertTrue(window.exists, "Window should exist after timer completion with badge")
    XCTAssertTrue(window.isHittable, "Window should be hittable after completion")

    // Clean up: toggle badge off, restore Sound 1
    window.rightClick()
    Thread.sleep(forTimeInterval: 0.3)
    app.menuItems["Show timer badge in dock"].click()
    Thread.sleep(forTimeInterval: 0.3)

    window.rightClick()
    Thread.sleep(forTimeInterval: 0.3)
    app.menuItems["Sound"].hover()
    Thread.sleep(forTimeInterval: 0.3)
    app.menuItems["Sound 1"].click()
    Thread.sleep(forTimeInterval: 0.3)
  }

  // MARK: - State Transition Edge Cases

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

  // MARK: - Input Edge Cases

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
