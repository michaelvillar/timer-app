import AppKit

final class MVMainView: NSView {
  private static let backgroundGradient = NSGradient(colors: [
    NSColor(resource: .backgroundTop),
    NSColor(resource: .backgroundBottom)
  ])

  weak var controller: MVTimerController?
  private let contextMenu = NSMenu(title: "Menu")
  private(set) var menuItem: NSMenuItem?
  private var soundMenuItems: [NSMenuItem] = []

  override var menu: NSMenu? {
    get { self.contextMenu }
    set {}
  }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    self.menuItem = NSMenuItem(
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
      soundItem.tag = option.value
      self.soundMenuItems.append(soundItem)
      submenu.addItem(soundItem)
    }
    let savedSoundIndex = UserDefaults.standard.integer(forKey: MVUserDefaultsKeys.soundIndex)
    for item in self.soundMenuItems {
      item.state = item.tag == savedSoundIndex ? .on : .off
    }
    if let menuItem = self.menuItem {
      self.contextMenu.addItem(menuItem)
    }
    self.contextMenu.addItem(menuItemSoundChoice)
    self.contextMenu.setSubmenu(submenu, for: menuItemSoundChoice)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc func toggleShowInDock() {
    guard let appDelegate = NSApplication.shared.delegate as? AppDelegate,
          let controller = self.controller else { return }

    if self.menuItem?.state == .on {
      appDelegate.removeBadgeFromDock()
    } else {
      appDelegate.addBadgeToDock(controller: controller)
    }
  }

  @objc func pickSound(_ sender: NSMenuItem) {
    for item in self.soundMenuItems {
      item.state = item == sender ? .on : .off
    }
    self.controller?.pickSound(sender.tag)
  }

  override func draw(_ dirtyRect: NSRect) {
    let radius: CGFloat = 4.53
    let path = NSBezierPath(roundedRect: self.bounds, xRadius: radius, yRadius: radius)
    Self.backgroundGradient?.draw(in: path, angle: -90)
  }
}
