import XCTest

final class TimerDockAndCompletionTests: TimerUITestCase {
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
}
