//
//  MVMainView.swift
//  Timer
//
//  Created by Michael Villar on 3/27/16.
//  Copyright © 2016 Michael Villar. All rights reserved.
//

import Cocoa

class MVMainView: NSView {
  
  override func drawRect(dirtyRect: NSRect) {
    super.drawRect(dirtyRect)
    
    let topColor = NSColor(SRGBRed: 0.949, green: 0.9451, blue: 0.949, alpha: 1.0)
    let bottomColor = NSColor(SRGBRed: 0.8392, green: 0.8314, blue: 0.8392, alpha: 1.0)
    let gradient = NSGradient(colors: [topColor, bottomColor])
    let radius: CGFloat = 4.53
    let path = NSBezierPath(roundedRect: self.bounds, xRadius: radius, yRadius: radius)
    gradient?.drawInBezierPath(path, angle: -90)
  }
  
}
