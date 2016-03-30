//
//  MVClockView.swift
//  Timer
//
//  Created by Michael Villar on 3/27/16.
//  Copyright © 2016 Michael Villar. All rights reserved.
//

import Cocoa

class MVClockView: NSControl {
  
  private var clickGesture: NSClickGestureRecognizer!
  private var imageView: NSImageView!
  private var progressView: MVClockProgressView!
  private var arrowView: MVClockArrowView!
  private var timerTimeLabel: NSTextView!
  private var minutesLabel: NSTextView!
  private var minutesLabelSuffixWidth: CGFloat = 0.0
  private var minutesLabelSecondsSuffixWidth: CGFloat = 0.0
  private var secondsLabel: NSTextView!
  private var secondsSuffixWidth: CGFloat = 0.0
  private var timerTime: NSDate? {
    didSet {
      self.updateTimeLabel()
    }
  }
  private var timer: NSTimer?
  
  var seconds: CGFloat = 0.0 {
    didSet {
      self.minutes = floor(seconds / 60)
      self.progress = invertProgressToScale(seconds / 60.0 / 60.0)
    }
  }
  var minutes: CGFloat = 0.0 {
    didSet {
      self.updateLabels()
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
    arrowView.actionMouseUp = #selector(handleArrowControlMouseUp)
    self.layoutSubviews()
    self.addSubview(arrowView)
    
    imageView = MVClockImageView(frame: NSMakeRect(16, 15, 118, 118))
    self.addSubview(imageView)
    
    timerTimeLabel = MVLabel(frame: NSMakeRect(0, 94, 150, 20))
    timerTimeLabel.font = NSFont.systemFontOfSize(15, weight: NSFontWeightMedium)
    timerTimeLabel.alignment = NSTextAlignment.Center
    timerTimeLabel.textColor = NSColor(SRGBRed: 0.749, green: 0.1412, blue: 0.0118, alpha: 1.0)
    self.addSubview(timerTimeLabel)
    
    minutesLabel = MVLabel(frame: NSMakeRect(0, 57, 150, 30))
    minutesLabel.string = ""
    minutesLabel.font = NSFont.systemFontOfSize(35, weight: NSFontWeightMedium)
    minutesLabel.alignment = NSTextAlignment.Center
    minutesLabel.textColor = NSColor(SRGBRed: 0.2353, green: 0.2549, blue: 0.2706, alpha: 1.0)
    self.addSubview(minutesLabel)
    
    let minutesLabelSuffix = "'"
    let minutesLabelSize = minutesLabelSuffix.sizeWithAttributes([
      NSFontAttributeName: minutesLabel.font!
    ])
    minutesLabelSuffixWidth = minutesLabelSize.width
    
    let minutesLabelSecondsSuffix = "\""
    let minutesLabelSecondsSize = minutesLabelSecondsSuffix.sizeWithAttributes([
      NSFontAttributeName: minutesLabel.font!
    ])
    minutesLabelSecondsSuffixWidth = minutesLabelSecondsSize.width

    secondsLabel = MVLabel(frame: NSMakeRect(0, 38, 150, 20))
    secondsLabel.font = NSFont.systemFontOfSize(15, weight: NSFontWeightMedium)
    secondsLabel.alignment = NSTextAlignment.Center
    secondsLabel.textColor = NSColor(SRGBRed: 0.6353, green: 0.6667, blue: 0.6863, alpha: 1.0)
    self.addSubview(secondsLabel)
    
    let secondsLabelSuffix = "'"
    let secondsLabelSize = secondsLabelSuffix.sizeWithAttributes([
      NSFontAttributeName: secondsLabel.font!
    ])
    secondsSuffixWidth = secondsLabelSize.width
    
    self.updateLabels()
    self.updateTimeLabel()
    self.updateClockImageView()
    
    let nc = NSNotificationCenter.defaultCenter()
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindowDidBecomeKeyNotification, object: nil)
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindowDidResignKeyNotification, object: nil)
  }
  
  deinit {
    let nc = NSNotificationCenter.defaultCenter()
    nc.removeObserver(self)
  }
  
  func windowFocusChanged(notification: NSNotification) {
    self.updateClockImageView()
  }
  
  private func updateClockImageView() {
    let windowHasFocus = self.window?.keyWindow ?? false
    imageView.image = NSImage(named: windowHasFocus ? "clock" : "clock-unfocus")
  }
  
  private func center(view: NSView) {
    var frame = view.frame
    frame.origin.x = round((self.bounds.width - frame.size.width) / 2)
    frame.origin.y = round((self.bounds.height - frame.size.height) / 2)
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
    var progressValue = CGFloat(object.floatValue)
    progressValue = convertProgressToScale(progressValue)
    var seconds: CGFloat = round(progressValue * 60.0 * 60.0)
    if seconds <= 300 {
      seconds = seconds - seconds % 10
    } else {
      seconds = seconds - seconds % 60
    }
    self.seconds = seconds
    self.updateTimerTime()
    
    self.timer?.invalidate()
    self.timer = nil
  }
  
  func handleArrowControlMouseUp() {
    self.updateTimerTime()
    self.start()
  }
  
  func handleClick() {
    if self.timer == nil && self.seconds > 0 {
      self.updateTimerTime()
      self.start()
    } else {
      self.timer?.invalidate()
      self.timer = nil
    }
  }
  
  override func mouseDown(theEvent: NSEvent) {
    if let event = self.window?.nextEventMatchingMask(Int(NSEventMask.LeftMouseUpMask.rawValue) | Int(NSEventMask.LeftMouseDraggedMask.rawValue)) {
      if event.type == NSEventType.LeftMouseUp {
        let point = self.convertPoint(event.locationInWindow, fromView: nil)
        if self.hitTest(point) == self {
          self.handleClick()
        }
      }
    }
    
    super.mouseDown(theEvent)
  }
  
  private func updateTimerTime() {
    self.timerTime = NSDate(timeIntervalSinceNow: Double(self.seconds))
  }
  
  private func updateLabels() {
    var suffixWidth: CGFloat = 0
    if (self.seconds < 60) {
      minutesLabel.string = NSString(format: "%i\"", Int(self.seconds)) as String
      suffixWidth = minutesLabelSecondsSuffixWidth
    } else {
      minutesLabel.string = NSString(format: "%i'", Int(self.minutes)) as String
      suffixWidth = minutesLabelSuffixWidth
    }
    minutesLabel.sizeToFit()
    
    var frame = minutesLabel.frame
    frame.origin.x = round((self.bounds.width - (frame.size.width - suffixWidth)) / 2)
    minutesLabel.frame = frame
    
    if (self.seconds < 60) {
      secondsLabel.string = ""
    }
    else {
      secondsLabel.string = NSString(format: "%i\"", Int(self.seconds % 60)) as String
      secondsLabel.sizeToFit()
      
      frame = secondsLabel.frame
      frame.origin.x = round((self.bounds.width - (frame.size.width - secondsSuffixWidth)) / 2)
      secondsLabel.frame = frame
    }
  }
  
  private func updateTimeLabel() {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "HH:mm"
    timerTimeLabel.string = formatter.stringFromDate(self.timerTime ?? NSDate())
  }
  
  private func start() {
    if self.seconds <= 0 {
      return
    }
    self.timer?.invalidate()
    self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
  }
  
  func tick() {
    self.seconds = self.seconds - 1
    if self.seconds <= 0 {
      self.timer?.invalidate()
      self.timer = nil
      self.target?.performSelector(self.action, withObject: self)
    }
  }
  
  override func hitTest(aPoint: NSPoint) -> NSView? {
    let view = super.hitTest(aPoint)
    if view == arrowView {
      return view
    }
    if NSPointInRect(aPoint, self.bounds) {
      return self
    }
    return nil
  }
  
  private let scaleOriginal: CGFloat = 6
  private let scaleActual: CGFloat = 3
  
  private func convertProgressToScale(progress: CGFloat) -> CGFloat {
    if self.minutes <= 60 {
      if progress <= scaleOriginal / 60 {
        return progress / (scaleOriginal / scaleActual)
      } else {
        return (progress * 60 - scaleOriginal + scaleActual) / (60 - scaleActual)
      }
    }
    return progress
  }
  
  private func invertProgressToScale(progress: CGFloat) -> CGFloat {
    if self.minutes <= 60 {
      if progress <= scaleActual / 60 {
        return progress * (scaleOriginal / scaleActual)
      } else {
        return (progress * (60 - scaleActual) - scaleActual + scaleOriginal) / 60
        
      }
    }
    return progress
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
    
    let nc = NSNotificationCenter.defaultCenter()
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindowDidBecomeKeyNotification, object: nil)
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindowDidResignKeyNotification, object: nil)
  }
  
  deinit {
    let nc = NSNotificationCenter.defaultCenter()
    nc.removeObserver(self)
  }
  
  override func drawRect(dirtyRect: NSRect) {
    NSColor(SRGBRed: 0.7255, green: 0.7255, blue: 0.7255, alpha: 0.15).setFill()
    NSBezierPath(ovalInRect: self.bounds).fill()
    
    drawArc(progress)
  }
  
  private func drawArc(progress: CGFloat) {
    let cp = NSMakePoint(self.bounds.width / 2, self.bounds.height / 2)
    let windowHasFocus = self.window?.keyWindow ?? false

    let path = NSBezierPath()
    path.moveToPoint(NSMakePoint(self.bounds.width / 2, self.bounds.height))
    path.appendBezierPathWithArcWithCenter(NSMakePoint(self.bounds.width / 2, self.bounds.height / 2),
                                           radius: self.bounds.width / 2,
                                           startAngle: 90,
                                           endAngle: 90 - (progress > 1 ? 1 : progress) * 360,
                                           clockwise: true)
    path.lineToPoint(cp)
    path.addClip()
    
    let ctx = NSGraphicsContext.currentContext()
    ctx?.saveGraphicsState()
    
    let transform = NSAffineTransform()
    transform.translateXBy(cp.x, yBy: cp.y)
    transform.rotateByDegrees(-progress * 360)
    transform.translateXBy(-cp.x, yBy: -cp.y)
    transform.concat()
    
    let image = NSImage(named: windowHasFocus ? "progress" : "progress-unfocus")
    image?.drawInRect(self.bounds)
    
    ctx?.restoreGraphicsState()
  }
  
  func windowFocusChanged(notification: NSNotification) {
    self.needsDisplay = true
  }
  
}

class MVClockArrowView: NSControl {
  
  var progress: CGFloat = 0.0 {
    didSet {
      self.needsDisplay = true
    }
  }
  var actionMouseUp: Selector?
  private var center: CGPoint = CGPointZero
  
  convenience init(center: CGPoint) {
    self.init(frame: NSMakeRect(0, 0, 25, 25))
    self.center = center
    
    let nc = NSNotificationCenter.defaultCenter()
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindowDidBecomeKeyNotification, object: nil)
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindowDidResignKeyNotification, object: nil)
  }
  
  deinit {
    let nc = NSNotificationCenter.defaultCenter()
    nc.removeObserver(self)
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
    
    let windowHasFocus = self.window?.keyWindow ?? false
    if windowHasFocus {
      NSColor(SRGBRed: 0.2235, green: 0.5686, blue: 0.9882, alpha: 1.0).setFill()
    } else {
      NSColor(SRGBRed: 0.5529, green: 0.6275, blue: 0.7216, alpha: 1.0).setFill()
    }
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
    var progress = (self.progress - self.progress % 1) + -(angle - CGFloat(M_PI) / 2) / (CGFloat(M_PI) * 2)
    if self.progress - progress > 0.25 {
      progress += 1
    } else if progress - self.progress > 0.75 {
      progress -= 1
    }
    if progress < 0 {
      progress = 0
    }
    let progressNumber = NSNumber(float: Float(progress))
    self.target?.performSelector(self.action, withObject: progressNumber)
  }
  
  func handleUp(theEvent: NSEvent) {
    if let selector = self.actionMouseUp {
      self.target?.performSelector(selector)
    }
  }
  
  func windowFocusChanged(notification: NSNotification) {
    self.needsDisplay = true
  }
  
}

class MVClockImageView: NSImageView {
 
  override func hitTest(aPoint: NSPoint) -> NSView? {
    return nil
  }
  
}