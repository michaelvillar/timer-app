import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
  
  private var controllers: [MVTimerController] = []
  private var currentlyInDock : MVTimerController?;
  
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
    
    let nc = NotificationCenter.default
    nc.addObserver(self, selector: #selector(handleClose), name: NSWindow.willCloseNotification, object: nil)
    nc.addObserver(self, selector: #selector(handleUserDefaultsChange), name: UserDefaults.didChangeNotification, object: nil)
    
    staysOnTop = UserDefaults.standard.bool(forKey: MVUserDefaultsKeys.staysOnTop)
  }
  
  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    for window in NSApplication.shared.windows {
      window.makeKeyAndOrderFront(self)
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
    let controller = MVTimerController(closeToWindow: NSApplication.shared.keyWindow)
    controller.window?.level = self.windowLevel()
    controllers.append(controller)
  }
  
  @objc func handleClose(_ notification: Notification) {
    if let window = notification.object as? NSWindow,
      let controller = window.windowController as? MVTimerController,
      let index = controllers.index(of: controller) {
          controllers.remove(at: index)
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

}

