import XCTest

class TimerUITestCase: XCTestCase { // swiftlint:disable:this final_test_case
  var app: XCUIApplication! // swiftlint:disable:this implicitly_unwrapped_optional

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launch()
  }

  override func tearDownWithError() throws {
    app.terminate()
    app = nil
  }
}
