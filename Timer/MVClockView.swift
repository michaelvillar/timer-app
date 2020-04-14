import Cocoa

class MVClockView: NSControl {

  private var clockFaceView: MVClockFaceView!
  private var pauseIconImageView: NSImageView!
  private var progressView: MVClockProgressView!
  private var arrowView: MVClockArrowView!
  private var timerTimeLabel: NSTextView!
  private var timerTimeLabelFontSize: CGFloat = 15
  private var minutesLabel: NSTextView!
  private var minutesLabelSuffixWidth: CGFloat = 0.0
  private var minutesLabelSecondsSuffixWidth: CGFloat = 0.0
  private var secondsLabel: NSTextView!
  private var secondsSuffixWidth: CGFloat = 0.0
  private var inputSeconds: Bool = false
  private var lastTimerSeconds: CGFloat?
  private let docktile: NSDockTile = NSApplication.shared.dockTile
  public  var inDock : Bool = false{
    didSet{
      if !inDock {
        self.removeBadge()
      }
      self.updateBadge()
    }
  }
  public var windowIsVisible:Bool = false {
    didSet {
      if windowIsVisible {
        self.startClockTimer()
        self.updateAllViews() // Update the UI with any changes that may have happened while it was hidden
      }
      else { // window is no longer visible
        self.stopClockTimer()
      }
    }
  }
  private var timerTime: Date? {
    didSet {
      if windowIsVisible {
        self.updateTimeLabel()
      }
    }
  }
  private var currentTimeTimer: Timer?
  private var timer: Timer?
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
      if windowIsVisible {
        self.updateLabels()
      }
      self.updateBadge() // Update the dock badge even when the window is hidden
    }
  }
  var progress: CGFloat = 0.0 {
    didSet {
      if windowIsVisible {
        self.layoutSubviews()
      }
    }
  }

  // MARK: -

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

    clockFaceView = MVClockFaceView(frame: NSMakeRect(16, 15, 118, 118))
    self.addSubview(clockFaceView)

    pauseIconImageView = NSImageView(frame: NSMakeRect(70, 99, 10, 12))
    pauseIconImageView.image = NSImage(named: "icon-pause")
    pauseIconImageView.alphaValue = 0.0
    self.addSubview(pauseIconImageView)

    timerTimeLabel = MVLabel(frame: NSMakeRect(0, 94, 150, 20))
    timerTimeLabel.font = timeLabelFont(ofSize: timerTimeLabelFontSize)
    timerTimeLabel.alignment = NSTextAlignment.center
    timerTimeLabel.textColor = NSColor(srgbRed: 0.749, green: 0.1412, blue: 0.0118, alpha: 1.0)
    self.addSubview(timerTimeLabel)

    minutesLabel = MVLabel(frame: NSMakeRect(0, 57, 150, 30))
    minutesLabel.string = ""
    if #available(OSX 10.11, *) {
      minutesLabel.font = NSFont.systemFont(ofSize: 35, weight: .medium)
    } else {
      minutesLabel.font = NSFont(name: "HelveticaNeue-Medium", size: 35)
    }
    minutesLabel.alignment = NSTextAlignment.center
    minutesLabel.textColor = NSColor(srgbRed: 0.2353, green: 0.2549, blue: 0.2706, alpha: 1.0)
    self.addSubview(minutesLabel)

    let minutesLabelSuffix = "'"
    let minutesLabelSize = minutesLabelSuffix.size(withAttributes: [
      NSAttributedString.Key.font: minutesLabel.font!
    ])
    minutesLabelSuffixWidth = minutesLabelSize.width

    let minutesLabelSecondsSuffix = "\""
    let minutesLabelSecondsSize = minutesLabelSecondsSuffix.size(withAttributes: [
      NSAttributedString.Key.font: minutesLabel.font!
    ])
    minutesLabelSecondsSuffixWidth = minutesLabelSecondsSize.width

    secondsLabel = MVLabel(frame: NSMakeRect(0, 38, 150, 20))
    if #available(OSX 10.11, *) {
      secondsLabel.font = NSFont.systemFont(ofSize: 15, weight: .medium)
    } else {
      secondsLabel.font = NSFont(name: "HelveticaNeue-Medium", size: 15)
    }
    secondsLabel.alignment = NSTextAlignment.center
    secondsLabel.textColor = NSColor(srgbRed: 0.6353, green: 0.6667, blue: 0.6863, alpha: 1.0)
    self.addSubview(secondsLabel)

    let secondsLabelSuffix = "'"
    let secondsLabelSize = secondsLabelSuffix.size(withAttributes: [
      NSAttributedString.Key.font: secondsLabel.font!
    ])
    secondsSuffixWidth = secondsLabelSize.width

    self.updateClockFaceView()
    self.updateAllViews()

    let nc = NotificationCenter.default
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindow.didBecomeKeyNotification, object: nil)
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindow.didResignKeyNotification, object: nil)
  }

  deinit {
    let nc = NotificationCenter.default
    nc.removeObserver(self)

    arrowView.target = nil
  }

  @objc func windowFocusChanged(_ notification: Notification) {
    self.updateClockFaceView()
  }

  private func updateClockFaceView(highlighted: Bool = false) {
    clockFaceView.update(highlighted: highlighted)
  }

  private func center(_ view: NSView) {
    var frame = view.frame
    frame.origin.x = round((self.bounds.width - frame.size.width) / 2)
    frame.origin.y = round((self.bounds.height - frame.size.height) / 2)
    view.frame = frame
  }

  private func layoutSubviews() {
    let angle = -progress * .pi * 2 + .pi / 2
    let x = self.bounds.width / 2 + cos(angle) * progressView.bounds.width / 2
    let y = self.bounds.height / 2 + sin(angle) * progressView.bounds.height / 2
    let point: NSPoint = NSMakePoint(x - arrowView.bounds.width / 2, y - arrowView.bounds.height / 2)
    var frame = arrowView.frame
    frame.origin = point
    arrowView.frame = frame

    self.progressView.progress = progress
    self.arrowView.progress = progress
  }

  @objc func handleArrowControl(_ object: NSNumber) {
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

  @objc func handleArrowControlMouseUp() {
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
      ctx.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
      self.pauseIconImageView.animator().alphaValue = showPauseIcon ? 1 : 0
      self.timerTimeLabel.animator().alphaValue = showPauseIcon ? 0 : 1
    }, completionHandler: nil)
  }


  var didDrag:Bool = false

  override func mouseDown(with event: NSEvent) {
    self.didDrag = false
    self.updateClockFaceView(highlighted: true)

    self.nextResponder?.mouseDown(with: event) // Allow window to also track the event (so user can drag window)
  }

  override func mouseDragged(with event: NSEvent) {
    if !self.didDrag {
      self.didDrag = true
      self.updateClockFaceView()
    }
  }

  override func mouseUp(with event: NSEvent) {
    let point = self.convert(event.locationInWindow, from: nil)
    if self.hitTest(point) == self && !self.didDrag {
      self.handleClick()
    }
    self.updateClockFaceView()
  }

  override func keyUp(with theEvent: NSEvent) {
    let key = theEvent.keyCode
    let currentSeconds = self.seconds.truncatingRemainder(dividingBy: 60)
    let currentMinutes = floor(self.seconds / 60)
    if let number = Int(theEvent.characters ?? "") {
      var newSeconds:CGFloat
      if self.inputSeconds {
        if currentSeconds < 6 || currentMinutes == 0 {
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
    } else if (key == Keycode.period || key == Keycode.keypadDecimal) {
      // Period or Decimal
      self.inputSeconds = !self.inputSeconds
    } else if (key == Keycode.escape) {
      // Escape
      self.paused = false
      self.stop()
      self.seconds = 0
      self.updateTimerTime()
      self.inputSeconds = false
    } else if (key == Keycode.delete || key == Keycode.forwardDelete) {
      // Backspace
      self.paused = false
      self.stop()
      if self.inputSeconds {
        self.seconds = currentMinutes * 60 + floor(currentSeconds / 10)
      } else {
        self.seconds = floor(currentMinutes / 10) * 60 + currentSeconds
      }
      self.updateTimerTime()
    } else if (key == Keycode.returnKey || key == Keycode.space || key == Keycode.keypadEnter) {
      // "Enter" or "Space" or "Keypad Enter"
      self.handleClick();
    } else if (key == Keycode.r && self.timer == nil && self.paused != true) {
      // "r" for restarting with the last timer
      if let seconds = self.lastTimerSeconds {
        self.seconds = seconds
        self.handleClick()
      }
        
    }
  }

  private func updateAllViews() {
    self.updateLabels()
    self.updateTimeLabel()
    self.layoutSubviews()
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

  private func updateBadge() {

    if self.inDock {
      if (self.timer != nil || self.paused) {
        let badgeSeconds = Int(self.seconds.truncatingRemainder(dividingBy: 60))
        let badgeMinutes = Int(self.minutes)
        self.docktile.badgeLabel = NSString(format:"%02d:%02d", badgeMinutes, badgeSeconds) as String
      } else {
        self.removeBadge()
      }
    }
  }

  private func removeBadge() {
    self.docktile.badgeLabel = ""
  }

  private func updateTimeLabel() {
    let formatter = DateFormatter()
    formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "jj:mm", options: 0, locale: Locale.current)
    let timeString = formatter.string(from: self.timerTime ?? Date())
    timerTimeLabel.string = timeString

    // If the local time format includes an " AM" or " PM" suffix, show the suffix with a smaller font
    if let ampmRange = timeString.range(of: " AM", options:[.caseInsensitive]) ?? timeString.range(of: " PM", options:[.caseInsensitive]) {
      timerTimeLabel.setFont(timeLabelFont(ofSize: timerTimeLabelFontSize - 3), range: NSRange(ampmRange, in:timeString))
    }
  }

  private func timeLabelFont(ofSize fontSize:CGFloat) -> NSFont {
    if #available(OSX 10.11, *) {
      return NSFont.systemFont(ofSize: fontSize, weight: .medium)
    } else {
      return NSFont.labelFont(ofSize: fontSize)
    }
  }

  private func start() {
    guard self.seconds > 0  else { return }
    self.lastTimerSeconds = self.seconds

    self.paused = false
    self.stop()

    // Ensure that each countdown tick occurs just past the exact seconds boundary (so system delays won't affect the value displayed)
    self.timer = Timer.scheduledTimer(timeInterval: 0.97, target: self, selector: #selector(firstTick), userInfo: nil, repeats: false)
  }

  func stop() {
    self.timer?.invalidate()
    self.timer = nil

    if (self.inDock && !self.paused){
      self.removeBadge()
    }
  }

  @objc func firstTick() {
    self.tick()
    self.timer = Foundation.Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
    self.timer?.tolerance = 0.03 // improve battery life
  }

  @objc func tick() {
    guard let timerTime = self.timerTime  else { return }

    self.seconds = fmax(0, floor(CGFloat(timerTime.timeIntervalSinceNow)))
    if self.seconds <= 0 {
      self.stop()
      _ = self.target?.perform(self.action, with: self)
    }
  }

  private func startClockTimer() {
    guard currentTimeTimer == nil  else { return }

    if self.timer == nil { // Set the current time right away, unless a timer is running
      self.timerTime = Date()
    }
    currentTimeTimer = Foundation.Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(maintainCurrentTime), userInfo: nil, repeats: true)
    currentTimeTimer?.tolerance = 0.5 // improve battery life
  }

  private func stopClockTimer() {
    currentTimeTimer?.invalidate()
    currentTimeTimer = nil
  }

  @objc func maintainCurrentTime(){
    guard self.timer == nil  else { return } // don't set if the main timer is counting down

    let time = Date()
    if Calendar.current.component(.second, from: time) == 0 { // only need to set when minute changes
      self.timerTime = time
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
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindow.didBecomeKeyNotification, object: nil)
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindow.didResignKeyNotification, object: nil)
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

    let ctx = NSGraphicsContext.current
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

  @objc func windowFocusChanged(_ notification: Notification) {
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
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindow.didBecomeKeyNotification, object: nil)
    nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindow.didResignKeyNotification, object: nil)
  }

  deinit {
    let nc = NotificationCenter.default
    nc.removeObserver(self)
  }

  override func draw(_ dirtyRect: NSRect) {
    NSColor.clear.setFill()
    self.bounds.fill()

    let path = NSBezierPath()
    path.move(to: CGPoint(x: 0, y: 0))
    path.line(to: CGPoint(x: self.bounds.width / 2, y: self.bounds.height * 0.8))
    path.line(to: CGPoint(x: self.bounds.width, y: 0))

    let cp = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
    let angle = -progress * .pi * 2
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
      case .leftMouseUp:
        isTracking = false
        self.handleUp(event)
        break;

      case .leftMouseDragged:
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
      angle = angle - .pi
    }
    var progress = (self.progress - self.progress.truncatingRemainder(dividingBy: 1)) + -(angle - .pi / 2) / (.pi * 2)
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

  @objc func windowFocusChanged(_ notification: Notification) {
    self.needsDisplay = true
  }

}

class MVClockFaceView: NSView {

  private var _image:NSImage?

  func update(highlighted: Bool = false) {
    // Load the appropriate image for the clock face
    let imageName:String

    if highlighted {
      imageName = "clock-highlighted"
    } else {
      let windowHasFocus = self.window?.isKeyWindow ?? false
      imageName = windowHasFocus ? "clock" : "clock-unfocus"
    }

    _image = NSImage(named: imageName)

    setNeedsDisplay(self.bounds)
  }

  override func draw(_ dirtyRect: NSRect) {
    if let image = _image {
      image.draw(in: self.bounds)
    }
  }

  override func hitTest(_ aPoint: NSPoint) -> NSView? {
    return nil
  }

}
