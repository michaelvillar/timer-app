import AppKit
import UserNotifications

@main
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
  private var controllers: [MVTimerController] = []
  private var currentlyInDock: MVTimerController?
  private var notificationObservers: [NSObjectProtocol] = []

  private var staysOnTop = false {
    didSet {
      for window in NSApplication.shared.windows {
        window.level = self.windowLevel
      }
    }
  }

  override init() {
    super.init()
    self.registerDefaults()
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let controller = MVTimerController()
    self.controllers.append(controller)
    self.addBadgeToDock(controller: controller)

    UNUserNotificationCenter.current().delegate = self
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

    let notificationCenter = NotificationCenter.default

    self.notificationObservers.append(
      notificationCenter.addObserver(
        forName: NSWindow.willCloseNotification, object: nil, queue: nil
      ) { [weak self] notification in self?.handleClose(notification) }
    )

    self.notificationObservers.append(
      notificationCenter.addObserver(
        forName: UserDefaults.didChangeNotification, object: nil, queue: nil
      ) { [weak self] _ in self?.handleUserDefaultsChange() }
    )

    self.notificationObservers.append(
      notificationCenter.addObserver(
        forName: NSWindow.didChangeOcclusionStateNotification, object: nil, queue: nil
      ) { [weak self] notification in self?.handleOcclusionChange(notification) }
    )

    self.staysOnTop = UserDefaults.standard.bool(forKey: MVUserDefaultsKeys.staysOnTop)
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    for window in NSApplication.shared.windows {
      window.makeKeyAndOrderFront(self)
    }
    return true
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.banner, .sound])
  }

  func addBadgeToDock(controller: MVTimerController) {
    if self.currentlyInDock != controller {
      self.removeBadgeFromDock()
    }
    self.currentlyInDock = controller
    controller.showInDock(true)
  }

  func removeBadgeFromDock() {
    self.currentlyInDock?.showInDock(false)
  }

  @objc func newDocument(_ sender: AnyObject?) {
    let controller = MVTimerController(closeToWindow: NSApplication.shared.keyWindow)
    controller.window?.level = self.windowLevel
    self.controllers.append(controller)
  }

  private func handleClose(_ notification: Notification) {
    if let window = notification.object as? NSWindow,
      let controller = window.windowController as? MVTimerController,
      controller != self.currentlyInDock,
      let index = self.controllers.firstIndex(of: controller) {
      self.controllers.remove(at: index)
    }
  }

  private func handleOcclusionChange(_ notification: Notification) {
    if let window = notification.object as? NSWindow,
      let controller = window.windowController as? MVTimerController {
      controller.windowVisibilityChanged(window.occlusionState.contains(.visible))
    }
  }

  private func handleUserDefaultsChange() {
    self.staysOnTop = UserDefaults.standard.bool(forKey: MVUserDefaultsKeys.staysOnTop)
  }

  deinit {
    self.notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
  }

  private var windowLevel: NSWindow.Level {
    self.staysOnTop ? .floating : .normal
  }

  private func registerDefaults() {
    UserDefaults.standard.register(defaults: [
      MVUserDefaultsKeys.staysOnTop: false,
      MVUserDefaultsKeys.soundIndex: 0
    ])
  }
}
