import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
  
  private var controllers: [MVTimerController] = []
  private var currentlyInDock : MVTimerController?;
  
  private var staysOnTop = false {
    didSet {
      for controller in controllers {
        controller.window?.level = self.windowLevel()
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
    
    let nc = NotificationCenter.default
    nc.addObserver(self, selector: #selector(handleClose), name: NSWindow.willCloseNotification, object: nil)
    nc.addObserver(self, selector: #selector(handleUserDefaultsChange), name: UserDefaults.didChangeNotification, object: nil)
    
    staysOnTop = UserDefaults.standard.bool(forKey: MVUserDefaultsKeys.staysOnTop)
  }
  
  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    for controller in controllers {
      controller.window?.makeKeyAndOrderFront(self)
    }
    return true
  }

  func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
    return true
  }
  
  func addBadgeToDock(controller: MVTimerController){
    if currentlyInDock != nil {
      currentlyInDock!.showInDock(false)
    }
    currentlyInDock = controller
    controller.showInDock(true)
  }
  
  @objc func newDocument(_ sender: AnyObject?) {
    let lastController = self.controllers.last
    let controller = MVTimerController(closeToWindow: lastController?.window)
    controller.window?.level = self.windowLevel()
    controllers.append(controller)
  }
  
  @objc func handleClose(_ notification: Notification) {
    if let window = notification.object as? NSWindow {
      if let controller = self.controllerForWindow(window) {
        if let index = controllers.index(of: controller) {
          controllers.remove(at: index)
        }
      }
    }
  }
  
  @objc func handleUserDefaultsChange(_ notification: Notification) {
    staysOnTop = UserDefaults.standard.bool(forKey: MVUserDefaultsKeys.staysOnTop)
  }
  
  func windowLevel() -> NSWindow.Level {
    return staysOnTop ? .floating : .normal
  }
  
  private func registerDefaults() {
    UserDefaults.standard.register(defaults: [MVUserDefaultsKeys.staysOnTop: false])
  }
  
  private func controllerForWindow(_ window: NSWindow) -> MVTimerController? {
    for controller in controllers {
      if controller.window == window {
        return controller
      }
    }
    return nil
  }

}

