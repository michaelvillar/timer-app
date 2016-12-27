import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
  
  private var controllers: [MVTimerController] = []
  
  private var staysOnTop = false {
    didSet {
      for controller in controllers {
        controller.window?.level = self.windowLevel(forStaysOnTop: staysOnTop)
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
    
    NSUserNotificationCenter.default.delegate = self
    
    let nc = NotificationCenter.default
    nc.addObserver(self, selector: #selector(handleClose), name: NSNotification.Name.NSWindowWillClose, object: nil)
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
  
  func newDocument(_ sender: AnyObject?) {
    let lastController = self.controllers.last
    let controller = MVTimerController(closeToWindow: lastController?.window)
    controller.window?.level = self.windowLevel(forStaysOnTop: staysOnTop)
    controllers.append(controller)
  }
  
  func handleClose(_ notification: Notification) {
    if controllers.count <= 1 {
      return
    }
    if let window = notification.object as? NSWindow {
      let controller = self.controllerForWindow(window)
      if controller != nil {
        let index = controllers.index(of: controller!)
        if index != nil {
          controllers.remove(at: index!)
        }
      }
    }
  }
  
  func handleUserDefaultsChange(_ notification: Notification) {
    staysOnTop = UserDefaults.standard.bool(forKey: MVUserDefaultsKeys.staysOnTop)
  }
  
  private func windowLevel(forStaysOnTop staysOnTop: Bool) -> Int {
    if staysOnTop {
      return Int(CGWindowLevelForKey(CGWindowLevelKey.floatingWindow))
    } else {
      return Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow))
    }
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

