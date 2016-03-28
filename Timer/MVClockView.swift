//
//  MVClockView.swift
//  Timer
//
//  Created by Michael Villar on 3/27/16.
//  Copyright © 2016 Michael Villar. All rights reserved.
//

import Cocoa

class MVClockView: NSView {
  
  private var imageView: NSImageView!
  private var progressView: MVClockProgressView!
  private var arrowView: MVClockArrowView!
  
  var minutes: CGFloat = 0.0 {
    didSet {
      self.progress = minutes / 60.0
      self.progressView.progress = progress
    }
  }
  var progress: CGFloat = 0.0 {
    didSet {
      self.layoutSubviews()
    }
  }
  
  convenience init() {
    self.init(frame: NSMakeRect(0, 0, 150, 150))
    
    progressView = MVClockProgressView()
    self.center(progressView)
    self.addSubview(progressView)
    
    arrowView = MVClockArrowView()
    self.layoutSubviews()
    self.addSubview(arrowView)
    
    imageView = NSImageView(frame: NSMakeRect(16, 15, 118, 118))
    imageView.image = NSImage(named: "clock")
    self.addSubview(imageView)
  }
  
  private func center(view: NSView) {
    var frame = view.frame
    frame.origin.x = (self.bounds.width - frame.size.width) / 2
    frame.origin.y = (self.bounds.height - frame.size.height) / 2
    view.frame = frame
  }
  
  private func layoutSubviews() {
    let angle = -progress * CGFloat(M_PI) * 2 + CGFloat(M_PI) / 2
    let x = self.bounds.width / 2 + cos(angle) * progressView.bounds.width / 2
    let y = self.bounds.height / 2 + sin(angle) * progressView.bounds.height / 2
    let point: NSPoint = NSMakePoint(x - arrowView.bounds.width / 2, y - arrowView.bounds.height / 2)
    var frame = arrowView.frame
    frame.origin = point
    arrowView.frame = frame
  }
  
}

class MVClockProgressView: NSView {
  
  var progress: CGFloat = 0.0 {
    didSet {
      self.needsDisplay = true
    }
  }
  
  convenience init() {
    self.init(frame: NSMakeRect(0, 0, 116, 116))
  }
  
  override func drawRect(dirtyRect: NSRect) {
    NSColor(SRGBRed: 0.2235, green: 0.5686, blue: 0.9882, alpha: 1.0).setFill()
    let path = NSBezierPath()
    path.moveToPoint(NSMakePoint(self.bounds.width / 2, self.bounds.height))
    path.appendBezierPathWithArcWithCenter(NSMakePoint(self.bounds.width / 2, self.bounds.height / 2),
                                           radius: self.bounds.width / 2,
                                           startAngle: 90,
                                           endAngle: 90 - (progress > 1 ? 1 : progress) * 360,
                                           clockwise: true)
    path.lineToPoint(NSMakePoint(self.bounds.width / 2, self.bounds.height / 2))
    path.fill()
  }
  
}

class MVClockArrowView: NSView {
  
  private var startLocation: CGPoint = CGPointZero
  
  convenience init() {
    self.init(frame: NSMakeRect(0, 0, 25, 25))
  }
  
  override func drawRect(dirtyRect: NSRect) {
    NSColor(SRGBRed: 0.2235, green: 0.5686, blue: 0.9882, alpha: 1.0).setFill()
    NSRectFill(self.bounds)
  }
  
  override func mouseDown(theEvent: NSEvent) {
    startLocation = theEvent.locationInWindow
  }
  
  override func mouseDragged(theEvent: NSEvent) {
    let currentLocation = theEvent.locationInWindow
    debugPrint("ok", currentLocation)
  }
  
}