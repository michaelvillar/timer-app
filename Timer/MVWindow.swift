import Cocoa

class MVWindow: NSWindow {
  
  var mainView: NSView!
  
  private var initialLocation: CGPoint!
  
  convenience init(mainView: NSView) {
    let styleMask: NSWindow.StyleMask = [.closable, .titled]
    let size: CGFloat = 150.0
    let titleBarHeight = MVWindow.frameRect(forContentRect: NSMakeRect(0, 0, size, size), styleMask: styleMask).size.height - size
    
    let windowFrame = NSMakeRect(NSScreen.main!.frame.width / 2 - size / 2,
                           NSScreen.main!.frame.height/2 - size / 2,
                           size, size - titleBarHeight)
    
    self.init(contentRect: windowFrame,
              styleMask: styleMask,
              backing: .buffered,
              defer: true)
    
    self.mainView = mainView
    self.mainView.frame = NSMakeRect(0, 0, size, size)
    
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    
    // Create a transparent titlebar accessory to overlay the window (to capture drag events)
    let titleBarController = MVTitlebarAccessoryViewController()
    titleBarController.view.frame = NSMakeRect(0, 0, size, windowFrame.size.height)
    self.addTitlebarAccessoryViewController(titleBarController)
    
    // Hide some of the default window buttons
    self.standardWindowButton(.miniaturizeButton)?.isHidden = true
    self.standardWindowButton(.zoomButton)?.isHidden = true
    
    // Adjust the close button
    let closeButton = self.standardWindowButton(.closeButton)!
    var closeFrame = closeButton.frame
    closeFrame.origin.y -= 2
    closeButton.frame = closeFrame
    
    // Add the main clock view as a sibling underneath the close button
    closeButton.superview?.addSubview(self.mainView, positioned: .below, relativeTo: closeButton)
  }
  
}
