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
    }
  }
  var progress: CGFloat = 0.0 {
    didSet {
      self.layoutSubviews()
      self.progressView.progress = progress
      self.arrowView.progress = progress
    }
  }
  
  convenience init() {
    self.init(frame: NSMakeRect(0, 0, 150, 150))
    
    progressView = MVClockProgressView()
    self.center(progressView)
    self.addSubview(progressView)
    
    arrowView = MVClockArrowView(center: CGPointMake(75, 75))
    arrowView.target = self
    arrowView.action = #selector(handleArrowControl)
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
  
  func handleArrowControl(object: NSNumber) {
    let progressValue = CGFloat(object.floatValue)
    self.minutes = progressValue * 60.0
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

class MVClockArrowView: NSControl {
  
  var progress: CGFloat = 0.0 {
    didSet {
      self.needsDisplay = true
    }
  }
  private var center: CGPoint = CGPointZero
  
  convenience init(center: CGPoint) {
    self.init(frame: NSMakeRect(0, 0, 25, 25))
    self.center = center
  }
  
  override func drawRect(dirtyRect: NSRect) {
    NSColor.clearColor().setFill()
    NSRectFill(self.bounds)
    
    let path = NSBezierPath()
    path.moveToPoint(CGPointMake(0, 0))
    path.lineToPoint(CGPointMake(self.bounds.width / 2, self.bounds.height * 0.8))
    path.lineToPoint(CGPointMake(self.bounds.width, 0))
    
    let cp = CGPointMake(self.bounds.width / 2, self.bounds.height / 2)
    let angle = -progress * CGFloat(M_PI) * 2
    let transform = NSAffineTransform()
    transform.translateXBy(cp.x, yBy: cp.y)
    transform.rotateByRadians(angle)
    transform.translateXBy(-cp.x, yBy: -cp.y)
    
    path.transformUsingAffineTransform(transform)
    
    NSColor(SRGBRed: 0.2235, green: 0.5686, blue: 0.9882, alpha: 1.0).setFill()
    path.fill()
  }
  
  override func mouseDown(theEvent: NSEvent) {
    var isDragging = false
    var isTracking = true
    var event: NSEvent = theEvent
    
    while (isTracking) {
      switch (event.type) {
      case NSEventType.LeftMouseUp:
        isTracking = false
        self.handleUp(event)
        break;
        
      case NSEventType.LeftMouseDragged:
        if (isDragging) {
          self.handleDragged(event)
        }
        else {
          isDragging = true
        }
        break;
      default:
        break;
      }
      
      if (isTracking) {
        let anEvent = self.window?.nextEventMatchingMask(Int(NSEventMask.LeftMouseUpMask.rawValue) | Int(NSEventMask.LeftMouseDraggedMask.rawValue))
        event = anEvent!
      }
    }
  }
  
  func handleDragged(theEvent: NSEvent) {
    var location = self.convertPoint(theEvent.locationInWindow, fromView: nil)
    location = self.convertPoint(location, toView: self.superview)
    let dx = (location.x - center.x) / center.x
    let dy = (location.y - center.y) / center.y
    var angle = atan(dy / dx)
    if (dx < 0) {
      angle = angle - CGFloat(M_PI)
    }
    let progress = -(angle - CGFloat(M_PI) / 2) / (CGFloat(M_PI) * 2)
    let progressNumber = NSNumber(float: Float(progress))
    self.target?.performSelector(self.action, withObject: progressNumber)
  }
  
  func handleUp(theEvent: NSEvent) {
  }
  
}