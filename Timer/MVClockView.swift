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
  private var inputSeconds: Bool = false
  private var timerTime: Date? {
    didSet {
      self.updateTimeLabel()
    }
  }
  private var timer: Foundation.Timer?
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
    
    arrowView = MVClockArrowView(center: CGPoint(x: 75, y: 75))
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
      timerTimeLabel.font = NSFont.systemFont(ofSize: 15, weight: NSFontWeightMedium)
    } else {
      timerTimeLabel.font = NSFont(name: "HelveticaNeue-Medium", size: 15)
    }
    timerTimeLabel.alignment = NSTextAlignment.center
    timerTimeLabel.textColor = NSColor(srgbRed: 0.749, green: 0.1412, blue: 0.0118, alpha: 1.0)
    self.addSubview(timerTimeLabel)
    
    minutesLabel = MVLabel(frame: NSMakeRect(0, 57, 150, 30))
    minutesLabel.string = ""
    if #available(OSX 10.11, *) {
      minutesLabel.font = NSFont.systemFont(ofSize: 35, weight: NSFontWeightMedium)
    } else {
      minutesLabel.font = NSFont(name: "HelveticaNeue-Medium", size: 35)
    }
    minutesLabel.alignment = NSTextAlignment.center
    minutesLabel.textColor = NSColor(srgbRed: 0.2353, green: 0.2549, blue: 0.2706, alpha: 1.0)
    self.addSubview(minutesLabel)
    
    let minutesLabelSuffix = "'"
    let minutesLabelSize = minutesLabelSuffix.size(withAttributes: [
      NSFontAttributeName: minutesLabel.font!
    ])
    minutesLabelSuffixWidth = minutesLabelSize.width
    
    let minutesLabelSecondsSuffix = "\""
    let minutesLabelSecondsSize = minutesLabelSecondsSuffix.size(withAttributes: [
      NSFontAttributeName: minutesLabel.font!
    ])
    minutesLabelSecondsSuffixWidth = minutesLabelSecondsSize.width

    secondsLabel = MVLabel(frame: NSMakeRect(0, 38, 150, 20))
    if #available(OSX 10.11, *) {
      secondsLabel.font = NSFont.systemFont(ofSize: 15, weight: NSFontWeightMedium)
    } else {
      secondsLabel.font = NSFont(name: "HelveticaNeue-Medium", size: 15)
    }
    secondsLabel.alignment = NSTextAlignment.center
    secondsLabel.textColor = NSColor(srgbRed: 0.6353, green: 0.6667, blue: 0.6863, alpha: 1.0)
    self.addSubview(secondsLabel)
    
    let secondsLabelSuffix = "'"
    let secondsLabelSize = secondsLabelSuffix.size(withAttributes: [
      NSFontAttributeName: secondsLabel.font!
    ])
    secondsSuffixWidth = secondsLabelSize.width
    
    self.updateLabels()
    self.updateTimeLabel()
    self.updateClockImageView()
    
    let nc = NotificationCenter.default
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSNotification.Name.NSWindowDidBecomeKey, object: nil)
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSNotification.Name.NSWindowDidResignKey, object: nil)
  }
  
  deinit {
    let nc = NotificationCenter.default
    nc.removeObserver(self)
    
    arrowView.target = nil
  }
  
  func windowFocusChanged(_ notification: Notification) {
    self.updateClockImageView()
  }
  
  private func updateClockImageView(highlighted: Bool = false) {
    let windowHasFocus = self.window?.isKeyWindow ?? false
    var image = windowHasFocus ? "clock" : "clock-unfocus"
    if highlighted {
      image = "clock-highlighted"
    }
    imageView.image = NSImage(named: image)
  }
  
  private func center(_ view: NSView) {
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
  
  func handleArrowControl(_ object: NSNumber) {
    var progressValue = CGFloat(object.floatValue)
    progressValue = convertProgressToScale(progressValue)
    var seconds: CGFloat = round(progressValue * 60.0 * 60.0)
    if seconds <= 300 {
      seconds = seconds - seconds.truncatingRemainder(dividingBy: 10)
    } else {
      seconds = seconds - seconds.truncatingRemainder(dividingBy: 60)
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
  
  override func mouseDown(with theEvent: NSEvent) {
    self.updateClockImageView(highlighted: true)
    if let event = self.window?.nextEvent(matching: [.leftMouseUp, .leftMouseDragged]) {
      if event.type == NSEventType.leftMouseUp {
        let point = self.convert(event.locationInWindow, from: nil)
        if self.hitTest(point) == self {
          self.handleClick()
        }
      }
    }
    self.updateClockImageView()
    
    super.mouseDown(with: theEvent)
  }
  
  override func keyUp(with theEvent: NSEvent) {
    let key = theEvent.keyCode
    let currentSeconds = self.seconds.truncatingRemainder(dividingBy: 60)
    let currentMinutes = floor(self.seconds / 60)
    if let number = Int(theEvent.characters ?? "") {
      var newSeconds:CGFloat
      if self.inputSeconds {
        if currentSeconds < 10 {
          newSeconds = currentMinutes * 60 + currentSeconds * 10 + CGFloat(number)
        } else {
          newSeconds = self.seconds
        }
      } else {
        newSeconds = currentMinutes * 600 + currentSeconds + CGFloat(number) * 60
      }
      if (newSeconds < 999*60) {
        self.paused = false
        self.stop()
        self.seconds = newSeconds
        self.updateTimerTime()
      }
    } else if key == 47 || key == 65 {
      // Period or Decimal
      self.inputSeconds = !self.inputSeconds
    } else if key == 53 {
      // Escape
      self.paused = false
      self.stop()
      self.seconds = 0
      self.updateTimerTime()
      self.inputSeconds = false
    } else if key == 51 {
      // Backspace
      self.paused = false
      self.stop()
      if self.inputSeconds {
        self.seconds = currentMinutes * 60 + floor(currentSeconds / 10)
      } else {
        self.seconds = floor(currentMinutes / 10) * 60 + currentSeconds
      }
      self.updateTimerTime()
    } else if key == 36 || key == 49 {
      // Enter or Space
      self.handleClick();
    }
  }
  
  private func updateTimerTime() {
    self.timerTime = Date(timeIntervalSinceNow: Double(self.seconds))
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
      secondsLabel.string = NSString(format: "%i\"", Int(self.seconds.truncatingRemainder(dividingBy: 60))) as String
      secondsLabel.sizeToFit()
      
      frame = secondsLabel.frame
      frame.origin.x = round((self.bounds.width - (frame.size.width - secondsSuffixWidth)) / 2)
      secondsLabel.frame = frame
    }
  }
  
  private func updateTimeLabel() {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    timerTimeLabel.string = formatter.string(from: self.timerTime ?? Date())
  }
  
  private func start() {
    if self.seconds <= 0 {
      return
    }
    self.paused = false
    self.stop()
    self.timer = Foundation.Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
  }
  
  func stop() {
    self.timer?.invalidate()
    self.timer = nil
  }
  
  func tick() {
    if (self.timerTime == nil) {
      return;
    }
    self.seconds = fmax(0, ceil(CGFloat(self.timerTime!.timeIntervalSinceNow)))
    if self.seconds <= 0 {
      self.stop()
      _ = self.target?.perform(self.action, with: self)
    }
  }
  
  override func hitTest(_ aPoint: NSPoint) -> NSView? {
    let view = super.hitTest(aPoint)
    if view == arrowView {
      return view
    }
    let path = NSBezierPath(ovalIn: NSMakeRect(21, 21, 108, 108))
    if path.contains(aPoint) && self.seconds > 0 {
      return self
    }
    return nil
  }
  
  private let scaleOriginal: CGFloat = 6
  private let scaleActual: CGFloat = 3
  
  private func convertProgressToScale(_ progress: CGFloat) -> CGFloat {
    if self.minutes <= 60 {
      if progress <= scaleOriginal / 60 {
        return progress / (scaleOriginal / scaleActual)
      } else {
        return (progress * 60 - scaleOriginal + scaleActual) / (60 - scaleActual)
      }
    }
    return progress
  }
  
  private func invertProgressToScale(_ progress: CGFloat) -> CGFloat {
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
    
    let nc = NotificationCenter.default
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSNotification.Name.NSWindowDidBecomeKey, object: nil)
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSNotification.Name.NSWindowDidResignKey, object: nil)
  }
  
  deinit {
    let nc = NotificationCenter.default
    nc.removeObserver(self)
  }
  
  override func draw(_ dirtyRect: NSRect) {
    NSColor(srgbRed: 0.7255, green: 0.7255, blue: 0.7255, alpha: 0.15).setFill()
    NSBezierPath(ovalIn: self.bounds).fill()
    
    drawArc(progress)
  }
  
  private func drawArc(_ progress: CGFloat) {
    let cp = NSMakePoint(self.bounds.width / 2, self.bounds.height / 2)
    let windowHasFocus = self.window?.isKeyWindow ?? false

    let path = NSBezierPath()
    path.move(to: NSMakePoint(self.bounds.width / 2, self.bounds.height))
    path.appendArc(withCenter: NSMakePoint(self.bounds.width / 2, self.bounds.height / 2),
                                           radius: self.bounds.width / 2,
                                           startAngle: 90,
                                           endAngle: 90 - (progress > 1 ? 1 : progress) * 360,
                                           clockwise: true)
    path.line(to: cp)
    path.addClip()
    
    let ctx = NSGraphicsContext.current()
    ctx?.saveGraphicsState()
    
    var transform = AffineTransform.identity
    transform.translate(x: cp.x, y: cp.y)
    transform.rotate(byDegrees: -progress * 360)
    transform.translate(x: -cp.x, y: -cp.y)
    (transform as NSAffineTransform).concat()
    
    let image = NSImage(named: windowHasFocus ? "progress" : "progress-unfocus")
    image?.draw(in: self.bounds)
    
    ctx?.restoreGraphicsState()
  }
  
  func windowFocusChanged(_ notification: Notification) {
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
  private var center: CGPoint = CGPoint.zero
  
  convenience init(center: CGPoint) {
    self.init(frame: NSMakeRect(0, 0, 25, 25))
    self.center = center
    
    let nc = NotificationCenter.default
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSNotification.Name.NSWindowDidBecomeKey, object: nil)
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSNotification.Name.NSWindowDidResignKey, object: nil)
  }
  
  deinit {
    let nc = NotificationCenter.default
    nc.removeObserver(self)
  }
  
  override func draw(_ dirtyRect: NSRect) {
    NSColor.clear.setFill()
    NSRectFill(self.bounds)
    
    let path = NSBezierPath()
    path.move(to: CGPoint(x: 0, y: 0))
    path.line(to: CGPoint(x: self.bounds.width / 2, y: self.bounds.height * 0.8))
    path.line(to: CGPoint(x: self.bounds.width, y: 0))
    
    let cp = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
    let angle = -progress * CGFloat(M_PI) * 2
    var transform = AffineTransform.identity
    transform.translate(x: cp.x, y: cp.y)
    transform.rotate(byRadians: angle)
    transform.translate(x: -cp.x, y: -cp.y)
    
    path.transform(using: transform)
    
    let windowHasFocus = self.window?.isKeyWindow ?? false
    if windowHasFocus {
      let ratio: CGFloat = 0.5
      NSColor(srgbRed: 0.1734 + ratio * (0.2235 - 0.1734), green: 0.5284 + ratio * (0.5686 - 0.5284), blue: 0.9448 + ratio * (0.9882 - 0.9448), alpha: 1.0).setFill()
    } else {
      NSColor(srgbRed: 0.5529, green: 0.6275, blue: 0.7216, alpha: 1.0).setFill()
    }
    path.fill()
  }
  
  override func mouseDown(with theEvent: NSEvent) {
    var isDragging = false
    var isTracking = true
    var event: NSEvent = theEvent
    
    while (isTracking) {
      switch (event.type) {
      case NSEventType.leftMouseUp:
        isTracking = false
        self.handleUp(event)
        break;
        
      case NSEventType.leftMouseDragged:
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
        let anEvent = self.window?.nextEvent(matching: [.leftMouseUp, .leftMouseDragged])
        event = anEvent!
      }
    }
  }
  
  func handleDragged(_ theEvent: NSEvent) {
    var location = self.convert(theEvent.locationInWindow, from: nil)
    location = self.convert(location, to: self.superview)
    let dx = (location.x - center.x) / center.x
    let dy = (location.y - center.y) / center.y
    var angle = atan(dy / dx)
    if (dx < 0) {
      angle = angle - CGFloat(M_PI)
    }
    var progress = (self.progress - self.progress.truncatingRemainder(dividingBy: 1)) + -(angle - CGFloat(M_PI) / 2) / (CGFloat(M_PI) * 2)
    if self.progress - progress > 0.25 {
      progress += 1
    } else if progress - self.progress > 0.75 {
      progress -= 1
    }
    if progress < 0 {
      progress = 0
    }
    let progressNumber = NSNumber(value: Float(progress) as Float)
    _ = self.target?.perform(self.action, with: progressNumber)
  }
  
  func handleUp(_ theEvent: NSEvent) {
    if let selector = self.actionMouseUp {
      _ = self.target?.perform(selector)
    }
  }
  
  func windowFocusChanged(_ notification: Notification) {
    self.needsDisplay = true
  }
  
}

class MVClockImageView: NSImageView {
 
  override func hitTest(_ aPoint: NSPoint) -> NSView? {
    return nil
  }
  
}
