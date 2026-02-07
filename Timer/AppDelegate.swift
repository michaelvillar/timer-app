import AppKit
import UserNotifications

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
  private var controllers: [MVTimerController] = []
  private var currentlyInDock: MVTimerController?
  private var notificationTasks: [Task<Void, Never>] = []

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
    Task {
      do {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
      } catch {
        NSLog("Notification authorization failed: %@", error.localizedDescription)
      }
    }

    self.notificationTasks.append(
      Task { [weak self] in
        for await notification in NotificationCenter.default.notifications(named: NSWindow.willCloseNotification) {
          self?.handleClose(notification)
        }
      }
    )

    self.notificationTasks.append(
      Task { [weak self] in
        for await _ in NotificationCenter.default.notifications(named: UserDefaults.didChangeNotification) {
          self?.handleUserDefaultsChange()
        }
      }
    )

    self.notificationTasks.append(
      Task { [weak self] in
        for await notification in NotificationCenter.default.notifications(
          named: NSWindow.didChangeOcclusionStateNotification
        ) {
          self?.handleOcclusionChange(notification)
        }
      }
    )

    self.staysOnTop = UserDefaults.standard.bool(forKey: MVUserDefaultsKeys.staysOnTop)
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    for window in NSApplication.shared.windows {
      window.makeKeyAndOrderFront(self)
    }
    return true
  }

  nonisolated func userNotificationCenter(
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
    MainActor.assumeIsolated {
      self.notificationTasks.forEach { $0.cancel() }
    }
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
