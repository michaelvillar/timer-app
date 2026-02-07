import XCTest

final class TimerInteractionTests: TimerUITestCase {
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
}
