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
  weak var controller: MVTimerController?
  private var contextMenu: NSMenu?
  public  var menuItem: NSMenuItem?

  // swiftlint:disable unused_setter_value
  override var menu: NSMenu? {
    get { self.contextMenu }
    set {}
  }
  // swiftlint:enable unused_setter_value

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    self.contextMenu = NSMenu(title: "Menu")
    menuItem = NSMenuItem(
      title: "Show timer badge in dock",
      action: #selector(self.toggleShowInDock),
      keyEquivalent: ""
    )
    self.contextMenu?.addItem(menuItem!)

    let notificationCenter = NotificationCenter.default

    notificationCenter.addObserver(
      self,
      selector: #selector(windowFocusChanged),
      name: NSWindow.didBecomeKeyNotification,
      object: nil
    )

    notificationCenter.addObserver(
      self,
      selector: #selector(windowFocusChanged),
      name: NSWindow.didResignKeyNotification,
      object: nil
    )
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc func toggleShowInDock() {
    // swiftlint:disable force_cast
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    // swiftlint:enable force_cast

    if menuItem?.state == .on {
      appDelegate.removeBadgeFromDock()
    } else {
      appDelegate.addBadgeToDock(controller: self.controller!)
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    let windowHasFocus = self.window?.isKeyWindow ?? false

    var topColor = NSColor(srgbRed: 242 / 255, green: 241 / 255, blue: 242 / 255, alpha: 1.000)
    var bottomColor = NSColor(srgbRed: 214 / 255, green: 212 / 255, blue: 214 / 255, alpha: 1.000)

    if !windowHasFocus {
      topColor = NSColor(srgbRed: 246 / 255, green: 246 / 255, blue: 246 / 255, alpha: 1.000)
      bottomColor = topColor
    }

    if isDarkMode {
        topColor = NSColor(srgbRed: 39 / 255, green: 39 / 255, blue: 39 / 255, alpha: 1.000)
        bottomColor = NSColor(srgbRed: 18 / 255, green: 18 / 255, blue: 18 / 255, alpha: 1.000)
    }

    if #available(OSX 10.13, *) {
        topColor = NSColor(named: "background-top-color")!
        bottomColor = NSColor(named: "background-bottom-color")!
    }

    let gradient = NSGradient(colors: [topColor, bottomColor])
    let radius: CGFloat = 4.53
    let path = NSBezierPath(roundedRect: self.bounds, xRadius: radius, yRadius: radius)

    gradient?.draw(in: path, angle: -90)
  }

  @objc func windowFocusChanged(_ notification: Notification) {
    self.needsDisplay = true
  }
}
