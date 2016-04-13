import Cocoa

class MVWindow: NSWindow {

  var mainView: NSView!

  convenience init(mainView: NSView) {
    let styleMask: Int = NSClosableWindowMask | NSTitledWindowMask
    let size: CGFloat = 150.0
    let titleBarHeight = MVWindow.frameRectForContentRect(NSRect(x: 0, y: 0, width: size, height: size), styleMask: styleMask).size.height - size

    let windowFrame = NSRect(x: NSScreen.mainScreen()!.frame.width / 2 - size / 2,
                             y: NSScreen.mainScreen()!.frame.height/2 - size / 2,
                             width: size, height: size - titleBarHeight)

    self.init(contentRect: windowFrame,
              styleMask: styleMask,
              backing: NSBackingStoreType.Buffered,
              defer: true)

    self.mainView = mainView
    self.mainView.frame = NSRect(x: 0, y: 0, width: size, height: size)

    self.titleVisibility = NSWindowTitleVisibility.Hidden
    self.titlebarAppearsTransparent = true

    let titleBarController = MVTitlebarAccessoryViewController()
    titleBarController.view.frame = NSRect(x: 0, y: 0, width: size, height: windowFrame.size.height)
    self.addTitlebarAccessoryViewController(titleBarController)

    self.layoutSubviews()
  }

  func layoutSubviews() {
    // Display main view
    if let themeFrame = contentView?.superview as NSView! {
      if let firstSubview = themeFrame.subviews[1] as NSView! {
        if let subSubView = firstSubview.subviews[0] as NSView! {
          firstSubview.addSubview(mainView, positioned: .Below, relativeTo: subSubView)
        }
      }
    }

    // Hide controls
    let close = standardWindowButton(.CloseButton)!
    var closeFrame = close.frame
    closeFrame.origin.y -= 2
    close.frame = closeFrame

    let minimize = standardWindowButton(.MiniaturizeButton)
    minimize?.hidden = true

    let zoom = standardWindowButton(.ZoomButton)
    zoom?.hidden = true
  }

}
