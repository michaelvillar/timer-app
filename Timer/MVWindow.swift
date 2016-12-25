import Cocoa

class MVWindow: NSWindow {
  
  var mainView: NSView!
  
  private var initialLocation: CGPoint!
  
  convenience init(mainView: NSView) {
    let styleMask: NSWindowStyleMask = [.closable, .titled]
    let size: CGFloat = 150.0
    let titleBarHeight = MVWindow.frameRect(forContentRect: NSMakeRect(0, 0, size, size), styleMask: styleMask).size.height - size
    
    let windowFrame = NSMakeRect(NSScreen.main()!.frame.width / 2 - size / 2,
                           NSScreen.main()!.frame.height/2 - size / 2,
                           size, size - titleBarHeight)
    
    self.init(contentRect: windowFrame,
              styleMask: styleMask,
              backing: NSBackingStoreType.buffered,
              defer: true)
    
    self.mainView = mainView
    self.mainView.frame = NSMakeRect(0, 0, size, size)
    
    self.titleVisibility = NSWindowTitleVisibility.hidden
    self.titlebarAppearsTransparent = true
    
    let titleBarController = MVTitlebarAccessoryViewController()
    titleBarController.view.frame = NSMakeRect(0, 0, size, windowFrame.size.height)
    self.addTitlebarAccessoryViewController(titleBarController)
    
    self.layoutSubviews()
  }
  
  func layoutSubviews() {
    // Display main view
    if let themeFrame = self.contentView?.superview as NSView! {
      if let firstSubview = themeFrame.subviews[1] as NSView! {
        if let subSubView = firstSubview.subviews[0] as NSView! {
          firstSubview.addSubview(self.mainView,
                                  positioned: NSWindowOrderingMode.below,
                                  relativeTo: subSubView)
        }
      }
    }
    
    // Hide controls
    let close = self.standardWindowButton(NSWindowButton.closeButton)!
    var closeFrame = close.frame
    closeFrame.origin.y -= 2
    close.frame = closeFrame
    
    let minimize = self.standardWindowButton(NSWindowButton.miniaturizeButton)
    minimize?.isHidden = true
    
    let zoom = self.standardWindowButton(NSWindowButton.zoomButton)
    zoom?.isHidden = true
  }
  
}
