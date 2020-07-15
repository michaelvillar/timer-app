import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
  private var controllers: [MVTimerController] = []
  private var currentlyInDock: MVTimerController?

  private var staysOnTop = false {
    didSet {
      for window in NSApplication.shared.windows {
        window.level = self.windowLevel()
      }
    }
  }

  override init() {
    super.init()
    self.registerDefaults()
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let controller = MVTimerController()
    controllers.append(controller)
    self.addBadgeToDock(controller: controller)

    NSUserNotificationCenter.default.delegate = self

    let notificationCenter = NotificationCenter.default

    notificationCenter.addObserver(
      self,
      selector: #selector(handleClose),
      name: NSWindow.willCloseNotification,
      object: nil
    )

    notificationCenter.addObserver(
      self,
      selector: #selector(handleUserDefaultsChange),
      name: UserDefaults.didChangeNotification,
      object: nil
    )

    notificationCenter.addObserver(
      self,
      selector: #selector(handleOcclusionChange),
      name: NSWindow.didChangeOcclusionStateNotification,
      object: nil
    )

    staysOnTop = UserDefaults.standard.bool(forKey: MVUserDefaultsKeys.staysOnTop)
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    for window in NSApplication.shared.windows {
      window.makeKeyAndOrderFront(self)
    }
    return true
  }

  func userNotificationCenter(
    _ center: NSUserNotificationCenter,
    shouldPresent notification: NSUserNotification) -> Bool {
    true
  }

  func addBadgeToDock(controller: MVTimerController) {
    if currentlyInDock != controller {
      self.removeBadgeFromDock()
    }
    currentlyInDock = controller
    controller.showInDock(true)
  }

  func removeBadgeFromDock() {
    if currentlyInDock != nil {
      currentlyInDock!.showInDock(false)
    }
  }

  @objc func newDocument(_ sender: AnyObject?) {
    let controller = MVTimerController(closeToWindow: NSApplication.shared.keyWindow)
    controller.window?.level = self.windowLevel()
    controllers.append(controller)
  }

  @objc func handleClose(_ notification: Notification) {
    if let window = notification.object as? NSWindow,
      let controller = window.windowController as? MVTimerController,
      controller != currentlyInDock,
      let index = controllers.firstIndex(of: controller) {
          controllers.remove(at: index)
    }
  }

  @objc func handleOcclusionChange(_ notification: Notification) {
    if let window = notification.object as? NSWindow,
      let controller = window.windowController as? MVTimerController {
      controller.windowVisibilityChanged(window.isVisible)
    }
  }

  @objc func handleUserDefaultsChange(_ notification: Notification) {
    staysOnTop = UserDefaults.standard.bool(forKey: MVUserDefaultsKeys.staysOnTop)
  }

  func windowLevel() -> NSWindow.Level {
    staysOnTop ? .floating : .normal
  }

  private func registerDefaults() {
    UserDefaults.standard.register(defaults: [MVUserDefaultsKeys.staysOnTop: false])
  }
}
