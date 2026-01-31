import Cocoa

class MVMainView: NSView {
  weak var controller: MVTimerController?
  private var contextMenu: NSMenu?
  public  var menuItem: NSMenuItem?
  private var soundMenuItems: [NSMenuItem] = []

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
    let submenu = NSMenu()
    let menuItemSoundChoice = NSMenuItem(
      title: "Sound",
      action: nil,
      keyEquivalent: ""
    )
    let soundOptions = [
        (title: "Sound 1", value: 0),
        (title: "Sound 2", value: 1),
        (title: "Sound 3", value: 2),
        (title: "No Sound", value: -1)
    ]
    for option in soundOptions {
        let soundItem = NSMenuItem(title: option.title, action: #selector(self.pickSound), keyEquivalent: "")
        soundItem.representedObject = option.value
        self.soundMenuItems.append(soundItem)
        submenu.addItem(soundItem)
    }
    let savedSoundIndex = UserDefaults.standard.integer(forKey: MVUserDefaultsKeys.soundIndex)
    for item in self.soundMenuItems {
        item.state = (item.representedObject as? Int) == savedSoundIndex ? .on : .off
    }
    self.contextMenu?.addItem(menuItem!)
    self.contextMenu?.addItem(menuItemSoundChoice)
    self.contextMenu?.setSubmenu(submenu, for: menuItemSoundChoice)

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

  @objc func pickSound(_ sender: NSMenuItem) {
    for item in self.soundMenuItems {
        if item == sender {
            item.state = .on
        } else {
            item.state = .off
        }
    }
    if let soundIdx = sender.representedObject as? Int {
        self.controller!.pickSound(soundIdx)
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    let topColor = NSColor(named: "background-top-color")!
    let bottomColor = NSColor(named: "background-bottom-color")!

    let gradient = NSGradient(colors: [topColor, bottomColor])
    let radius: CGFloat = 4.53
    let path = NSBezierPath(roundedRect: self.bounds, xRadius: radius, yRadius: radius)

    gradient?.draw(in: path, angle: -90)
  }

  @objc func windowFocusChanged(_ notification: Notification) {
    self.needsDisplay = true
  }
}
