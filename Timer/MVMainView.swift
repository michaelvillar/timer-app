import Cocoa

extension NSView {
    var isDarkMode: Bool {
        if #available(OSX 10.14, *) {
            if effectiveAppearance.name == .darkAqua {
                return true
            }
        }
        return false
    }
}

class MVMainView: NSView {

  weak var controller : MVTimerController?
  private let appDelegate: AppDelegate  = NSApplication.shared.delegate as! AppDelegate
  private var contextMenu: NSMenu?
  public  var menuItem : NSMenuItem?
  override var menu: NSMenu?{
    get{return self.contextMenu}
    set{}
  }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    self.contextMenu = NSMenu(title: "Menu")
    menuItem = NSMenuItem(title:"Show in Dock", action:#selector(self.toggleShowInDock), keyEquivalent:"")
    self.contextMenu?.addItem(menuItem!)

    let nc = NotificationCenter.default
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindow.didBecomeKeyNotification, object: nil)
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindow.didResignKeyNotification, object: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc func toggleShowInDock() {
    if menuItem?.state == .on {
      appDelegate.removeBadgeFromDock()
    } else {
      appDelegate.addBadgeToDock(controller: self.controller!)
    }
  }

  deinit {
    let nc = NotificationCenter.default
    nc.removeObserver(self)
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    
    if #available(OSX 10.13, *) {
        NSColor(named: "background-color")?.setFill()
    } else {
        NSColor(srgbRed: 0.949, green: 0.945, blue: 0.949, alpha: 1.0).setFill()
        if isDarkMode {
            NSColor(srgbRed: 0.145, green: 0.145, blue: 0.145, alpha: 1.0).setFill()
        }
    }
       
    dirtyRect.fill()
  }

  @objc func windowFocusChanged(_ notification: Notification) {
    self.needsDisplay = true
  }

}
