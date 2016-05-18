import Cocoa

class MVClockView: NSControl {
  
  private var clickGesture: NSClickGestureRecognizer!
  private var imageView: NSImageView!
  private var pauseIconImageView: NSImageView!
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
  private var paused: Bool = false {
    didSet {
      self.layoutPauseViews()
    }
  }
  
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
    
    pauseIconImageView = NSImageView(frame: NSMakeRect(70, 99, 10, 12))
    pauseIconImageView.image = NSImage(named: "icon-pause")
    pauseIconImageView.alphaValue = 0.0
    self.addSubview(pauseIconImageView)
    
    timerTimeLabel = MVLabel(frame: NSMakeRect(0, 94, 150, 20))
    if #available(OSX 10.11, *) {
      timerTimeLabel.font = NSFont.systemFontOfSize(15, weight: NSFontWeightMedium)
    } else {
      timerTimeLabel.font = NSFont(name: "HelveticaNeue-Medium", size: 15)
    }
    timerTimeLabel.alignment = NSTextAlignment.Center
    timerTimeLabel.textColor = NSColor(SRGBRed: 0.749, green: 0.1412, blue: 0.0118, alpha: 1.0)
    self.addSubview(timerTimeLabel)
    
    minutesLabel = MVLabel(frame: NSMakeRect(0, 57, 150, 30))
    minutesLabel.string = ""
    if #available(OSX 10.11, *) {
      minutesLabel.font = NSFont.systemFontOfSize(35, weight: NSFontWeightMedium)
    } else {
      minutesLabel.font = NSFont(name: "HelveticaNeue-Medium", size: 35)
    }
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
    if #available(OSX 10.11, *) {
      secondsLabel.font = NSFont.systemFontOfSize(15, weight: NSFontWeightMedium)
    } else {
      secondsLabel.font = NSFont(name: "HelveticaNeue-Medium", size: 15)
    }
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
    
    arrowView.target = nil
  }
  
  func windowFocusChanged(notification: NSNotification) {
    self.updateClockImageView()
  }
  
  private func updateClockImageView(highlighted highlighted: Bool = false) {
    let windowHasFocus = self.window?.keyWindow ?? false
    var image = windowHasFocus ? "clock" : "clock-unfocus"
    if highlighted {
      image = "clock-highlighted"
    }
    imageView.image = NSImage(named: image)
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
    
    self.stop()
    
    self.paused = false
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
      self.paused = true
      self.stop()
    }
  }
  
  private func layoutPauseViews() {
    let showPauseIcon = paused && self.timer != nil
    NSAnimationContext.runAnimationGroup({ (ctx) in
      ctx.duration = 0.2
      ctx.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
      self.pauseIconImageView.animator().alphaValue = showPauseIcon ? 1 : 0
      self.timerTimeLabel.animator().alphaValue = showPauseIcon ? 0 : 1
    }, completionHandler: nil)
  }
  
  override func mouseDown(theEvent: NSEvent) {
    self.updateClockImageView(highlighted: true)
    if let event = self.window?.nextEventMatchingMask(Int(NSEventMask.LeftMouseUpMask.rawValue) | Int(NSEventMask.LeftMouseDraggedMask.rawValue)) {
      if event.type == NSEventType.LeftMouseUp {
        let point = self.convertPoint(event.locationInWindow, fromView: nil)
        if self.hitTest(point) == self {
          self.handleClick()
        }
      }
    }
    self.updateClockImageView()
    
    super.mouseDown(theEvent)
  }
  
  override func keyUp(theEvent: NSEvent) {
    let char = theEvent.characters
    if let number = Int(char ?? "") {
      let newSeconds = floor(self.seconds / 60) * 600 + (self.seconds % 60) + CGFloat(number) * 60
      if (newSeconds < 999*60) {
        self.paused = false
        self.stop()
        self.seconds = newSeconds
        self.updateTimerTime()
      }
    } else if theEvent.keyCode == 53 {
      // Escape
      self.paused = false
      self.stop()
      self.seconds = 0
      self.updateTimerTime()
    } else if theEvent.keyCode == 51 {
      // Backspace
      self.paused = false
      self.stop()
      if self.seconds <= 60 * 10 {
        self.seconds = 0
      } else {
        self.seconds = floor(floor(self.seconds / 60) / 10) * 60 + (self.seconds % 60)
      }
      self.updateTimerTime()
    } else if theEvent.keyCode == 36 || theEvent.keyCode == 49 {
      // Enter or Space
      self.handleClick();
    }
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
    self.paused = false
    self.stop()
    self.timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
  }
  
  func stop() {
    self.timer?.invalidate()
    self.timer = nil
  }
  
  func tick() {
    if (self.timerTime == nil) {
      return;
    }
    self.seconds = fmax(0, ceil(CGFloat(self.timerTime!.timeIntervalSinceNow ?? 0)))
    if self.seconds <= 0 {
      self.stop()
      self.target?.performSelector(self.action, withObject: self)
    }
  }
  
  override func hitTest(aPoint: NSPoint) -> NSView? {
    let view = super.hitTest(aPoint)
    if view == arrowView {
      return view
    }
    let path = NSBezierPath(ovalInRect: NSMakeRect(21, 21, 108, 108))
    if path.containsPoint(aPoint) && self.seconds > 0 {
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
      let ratio: CGFloat = 0.5
      NSColor(SRGBRed: 0.1734 + ratio * (0.2235 - 0.1734), green: 0.5284 + ratio * (0.5686 - 0.5284), blue: 0.9448 + ratio * (0.9882 - 0.9448), alpha: 1.0).setFill()
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