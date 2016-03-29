//
//  MVLabel.swift
//  Timer
//
//  Created by Michael Villar on 3/28/16.
//  Copyright © 2016 Michael Villar. All rights reserved.
//

import Cocoa

class MVLabel: NSTextView {

  override init(frame frameRect: NSRect, textContainer aTextContainer: NSTextContainer!) {
    super.init(frame: frameRect, textContainer: aTextContainer)
    
    self.backgroundColor = NSColor.clearColor()
    self.selectable = false
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func hitTest(aPoint: NSPoint) -> NSView? {
    return nil
  }
  
}
