//
//  MVWindow.swift
//  Timer
//
//  Created by Michael Villar on 3/27/16.
//  Copyright © 2016 Michael Villar. All rights reserved.
//

import Cocoa

class MVWindow: NSWindow {
  
  var mainView: NSView!
  
  private var initialLocation: CGPoint!
  
  convenience init(mainView: NSView) {
    let styleMask: Int = NSClosableWindowMask | NSTitledWindowMask
    let size: CGFloat = 150.0
    let titleBarHeight = MVWindow.frameRectForContentRect(NSMakeRect(0, 0, size, size), styleMask: styleMask).size.height - size
    
    let windowFrame = NSMakeRect(NSScreen.mainScreen()!.frame.width / 2 - size / 2,
                           NSScreen.mainScreen()!.frame.height/2 - size / 2,
                           size, size - titleBarHeight)
    
    self.init(contentRect: windowFrame,
              styleMask: styleMask,
              backing: NSBackingStoreType.Buffered,
              defer: true)
    
    self.mainView = mainView
    self.mainView.frame = NSMakeRect(0, 0, size, size)
    
    self.titleVisibility = NSWindowTitleVisibility.Hidden
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
                                  positioned: NSWindowOrderingMode.Below,
                                  relativeTo: subSubView)
        }
      }
    }
    
    // Hide controls
    let close = self.standardWindowButton(NSWindowButton.CloseButton)!
    var closeFrame = close.frame
    closeFrame.origin.y -= 2
    close.frame = closeFrame
    
    let minimize = self.standardWindowButton(NSWindowButton.MiniaturizeButton)
    minimize?.hidden = true
    
    let zoom = self.standardWindowButton(NSWindowButton.ZoomButton)
    zoom?.hidden = true
  }
  
}
