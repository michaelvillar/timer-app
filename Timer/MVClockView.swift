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
  public  var inDock: Bool = false {
    didSet {
      if !inDock {
        self.removeBadge()
      }
      self.updateBadge()
    }
  }
  public var windowIsVisible: Bool = false {
    didSet {
      if windowIsVisible {
        self.startClockTimer()
        self.updateAllViews() // Update the UI with any changes that may have happened while it was hidden
      } else { // window is no longer visible
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
    self.init(frame: NSRect(x: 0, y: 0, width: 150, height: 150))

    progressView = MVClockProgressView()
    self.center(progressView)
    self.addSubview(progressView)

    arrowView = MVClockArrowView(center: CGPoint(x: 75, y: 75))
    arrowView.target = self
    arrowView.action = #selector(handleArrowControl)
    arrowView.actionMouseUp = #selector(handleArrowControlMouseUp)
    self.layoutSubviews()
    self.addSubview(arrowView)

    clockFaceView = MVClockFaceView(frame: NSRect(x: 16, y: 15, width: 118, height: 118))
    self.addSubview(clockFaceView)

    pauseIconImageView = NSImageView(frame: NSRect(x: 70, y: 99, width: 10, height: 12))
    pauseIconImageView.image = NSImage(named: "icon-pause")
    pauseIconImageView.alphaValue = 0.0
    self.addSubview(pauseIconImageView)

    timerTimeLabel = MVLabel(frame: NSRect(x: 0, y: 94, width: 150, height: 20))
    timerTimeLabel.font = NSFont.systemFont(ofSize: timerTimeLabelFontSize, weight: .medium)
    timerTimeLabel.alignment = NSTextAlignment.center
    timerTimeLabel.textColor = NSColor(srgbRed: 0.749, green: 0.1412, blue: 0.0118, alpha: 1.0)
    self.addSubview(timerTimeLabel)

    minutesLabel = MVLabel(frame: NSRect(x: 0, y: 57, width: 150, height: 30))
    minutesLabel.string = ""
    minutesLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 35, weight: .medium)
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

    secondsLabel = MVLabel(frame: NSRect(x: 0, y: 38, width: 150, height: 20))
    secondsLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
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

    let notificationCenter = NotificationCenter.default
    notificationCenter.addObserver(
      self,
      selector: #selector(windowFocusChanged),
      name: NSWindow.didBecomeKeyNotification,
      object: nil
    )

    notificationCenter.addObserver(
      self,
      selector: #selector(windowFocusChanged),
      name: NSWindow.didResignKeyNotification,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)

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

    // swiftlint:disable identifier_name
    let x = self.bounds.width / 2 + cos(angle) * progressView.bounds.width / 2
    let y = self.bounds.height / 2 + sin(angle) * progressView.bounds.height / 2
    // swiftlint:enable identifier_name

    let point = NSPoint(x: x - arrowView.bounds.width / 2, y: y - arrowView.bounds.height / 2)
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
      seconds -= seconds.truncatingRemainder(dividingBy: 10)
    } else {
      seconds -= seconds.truncatingRemainder(dividingBy: 60)
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
    NSAnimationContext.runAnimationGroup({ ctx in
      ctx.duration = 0.2
      ctx.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
      self.pauseIconImageView.animator().alphaValue = showPauseIcon ? 1 : 0
      self.timerTimeLabel.animator().alphaValue = showPauseIcon ? 0 : 1
    }, completionHandler: nil)
  }

  var didDrag: Bool = false

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

    // Period or Decimal
    if key == Keycode.period || key == Keycode.keypadDecimal {
      self.inputSeconds.toggle()
      return
    }

    // Escape
    if key == Keycode.escape {
      self.paused = false
      self.stop()
      self.seconds = 0
      self.updateTimerTime()
      self.inputSeconds = false

      return
    }

    // Backspace
    if key == Keycode.delete || key == Keycode.forwardDelete {
      self.paused = false
      self.stop()

      if self.inputSeconds {
        self.seconds = currentMinutes * 60 + floor(currentSeconds / 10)
      } else {
        self.seconds = floor(currentMinutes / 10) * 60 + currentSeconds
      }

      self.updateTimerTime()

      return
    }

    // "Enter" or "Space" or "Keypad Enter"
    if key == Keycode.returnKey || key == Keycode.space || key == Keycode.keypadEnter {
      self.handleClick()

      return
    }

    // "r" for restarting with the last timer
    if key == Keycode.r && self.timer == nil && self.paused != true, let seconds = self.lastTimerSeconds {
      self.seconds = seconds
      self.handleClick()

      return
    }

    if let number = Int(theEvent.characters ?? "") {
      var newSeconds: CGFloat

      if self.inputSeconds {
        if currentSeconds < 6 || currentMinutes == 0 {
          newSeconds = currentMinutes * 60 + currentSeconds * 10 + CGFloat(number)
        } else {
          newSeconds = self.seconds
        }
      } else {
        newSeconds = currentMinutes * 600 + currentSeconds + CGFloat(number) * 60
      }

      if newSeconds < 999 * 60 {
        self.paused = false
        self.stop()
        self.seconds = newSeconds
        self.updateTimerTime()
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

    if self.seconds < 60 {
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

    if self.seconds < 60 {
      secondsLabel.string = ""
    } else {
      secondsLabel.string = NSString(format: "%i\"", Int(self.seconds.truncatingRemainder(dividingBy: 60))) as String
      secondsLabel.sizeToFit()

      frame = secondsLabel.frame
      frame.origin.x = round((self.bounds.width - (frame.size.width - secondsSuffixWidth)) / 2)
      secondsLabel.frame = frame
    }
  }

  private func updateBadge() {
    if self.inDock {
      if self.timer != nil || self.paused {
        let badgeSeconds = Int(self.seconds.truncatingRemainder(dividingBy: 60))
        let badgeMinutes = Int(self.minutes)
        self.docktile.badgeLabel = NSString(format: "%02d:%02d", badgeMinutes, badgeSeconds) as String
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
    if let ampmRange = (
      timeString.range(of: " AM", options: [.caseInsensitive]) ??
      timeString.range(of: " PM", options: [.caseInsensitive])
    ) {
      timerTimeLabel.setFont(
        NSFont.systemFont(ofSize: timerTimeLabelFontSize - 3, weight: .medium),
        range: NSRange(ampmRange, in: timeString)
      )
    }
  }

  private func start() {
    guard self.seconds > 0  else { return }
    self.lastTimerSeconds = self.seconds

    self.paused = false
    self.stop()

    // Since the UI only allows timers to be set in multiples of 1 second, each tick
    // will fire _near_ an integer seconds-remaining boundary.
    self.timer = Foundation.Timer.scheduledTimer(
      timeInterval: 1, // (second)
      target: self,
      selector: #selector(tick),
      userInfo: nil,
      repeats: true
    )

    // Improves the system's ability to optimize for increased power savings by allowing
    // the timer a small amount of variance in when it can fire (without drifting over time).
    self.timer?.tolerance = 0.03 // (seconds)
  }

  func stop() {
    self.timer?.invalidate()
    self.timer = nil

    if self.inDock && !self.paused {
      self.removeBadge()
    }
  }

  @objc func tick() {
    guard let timerTime = self.timerTime  else { return }

    let secondsRemaining = CGFloat(timerTime.timeIntervalSinceNow)

    // Round the seconds displayed on the clock face
    self.seconds = max(0, round(secondsRemaining))

    if self.seconds <= 0 { // Timer is done!
      self.stop()
      _ = self.target?.perform(self.action, with: self)
    }
  }

  private func startClockTimer() {
    guard currentTimeTimer == nil else { return }

    // Set the current time right away, unless a timer is running
    if self.timer == nil {
      self.timerTime = Date()
    }

    currentTimeTimer = Foundation.Timer.scheduledTimer(
      timeInterval: 1,
      target: self,
      selector: #selector(maintainCurrentTime),
      userInfo: nil,
      repeats: true
    )

    // Improves the system's ability to optimize for increased power savings and responsiveness
    // A general rule, set the tolerance to at least 10% of the interval, for a repeating timer.
    currentTimeTimer?.tolerance = 0.5
  }

  private func stopClockTimer() {
    currentTimeTimer?.invalidate()
    currentTimeTimer = nil
  }

  @objc func maintainCurrentTime() {
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
    let path = NSBezierPath(ovalIn: NSRect(x: 21, y: 21, width: 108, height: 108))
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
    if self.minutes > 60 {
      return progress
    }

    if progress <= scaleActual / 60 {
      return progress * (scaleOriginal / scaleActual)
    } else {
      return (progress * (60 - scaleActual) - scaleActual + scaleOriginal) / 60
    }
  }
}

class MVClockProgressView: NSView {
  var progress: CGFloat = 0.0 {
    didSet {
      self.needsDisplay = true
    }
  }

  convenience init() {
    self.init(frame: NSRect(x: 0, y: 0, width: 116, height: 116))

    let notificationCenter = NotificationCenter.default

    notificationCenter.addObserver(
      self,
      selector: #selector(windowFocusChanged),
      name: NSWindow.didBecomeKeyNotification,
      object: nil
    )

    notificationCenter.addObserver(
      self,
      selector: #selector(windowFocusChanged),
      name: NSWindow.didResignKeyNotification,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func draw(_ dirtyRect: NSRect) {
    NSColor(srgbRed: 0.7255, green: 0.7255, blue: 0.7255, alpha: 0.15).setFill()
    NSBezierPath(ovalIn: self.bounds).fill()

    drawArc(progress)
  }

  private func drawArc(_ progress: CGFloat) {
    let center = NSPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
    let windowHasFocus = self.window?.isKeyWindow ?? false

    let path = NSBezierPath()
    path.move(to: NSPoint(x: self.bounds.width / 2, y: self.bounds.height))
    path.appendArc(
      withCenter: NSPoint(x: self.bounds.width / 2, y: self.bounds.height / 2),
      radius: self.bounds.width / 2,
      startAngle: 90,
      endAngle: 90 - (progress > 1 ? 1 : progress) * 360,
      clockwise: true
    )
    path.line(to: center)
    path.addClip()

    let ctx = NSGraphicsContext.current
    ctx?.saveGraphicsState()

    var transform = AffineTransform.identity
    transform.translate(x: center.x, y: center.y)
    transform.rotate(byDegrees: -progress * 360)
    transform.translate(x: -center.x, y: -center.y)
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
  private var center = CGPoint.zero

  convenience init(center: CGPoint) {
    self.init(frame: NSRect(x: 0, y: 0, width: 25, height: 25))
    self.center = center

    let notificationCenter = NotificationCenter.default

    notificationCenter.addObserver(
      self,
      selector: #selector(windowFocusChanged),
      name: NSWindow.didBecomeKeyNotification,
      object: nil
    )

    notificationCenter.addObserver(
      self,
      selector: #selector(windowFocusChanged),
      name: NSWindow.didResignKeyNotification,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func draw(_ dirtyRect: NSRect) {
    NSColor.clear.setFill()
    self.bounds.fill()

    let path = NSBezierPath()
    path.move(to: CGPoint(x: 0, y: 0))
    path.line(to: CGPoint(x: self.bounds.width / 2, y: self.bounds.height * 0.8))
    path.line(to: CGPoint(x: self.bounds.width, y: 0))

    let center = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
    let angle = -progress * .pi * 2
    var transform = AffineTransform.identity
    transform.translate(x: center.x, y: center.y)
    transform.rotate(byRadians: angle)
    transform.translate(x: -center.x, y: -center.y)

    path.transform(using: transform)

    let windowHasFocus = self.window?.isKeyWindow ?? false
    if windowHasFocus {
      let ratio: CGFloat = 0.5
      NSColor(
        srgbRed: 0.1734 + ratio * (0.2235 - 0.1734),
        green: 0.5284 + ratio * (0.5686 - 0.5284),
        blue: 0.9448 + ratio * (0.9882 - 0.9448),
        alpha: 1.0
      ).setFill()
    } else {
      NSColor(srgbRed: 0.5529, green: 0.6275, blue: 0.7216, alpha: 1.0).setFill()
    }
    path.fill()
  }

  override func mouseDown(with theEvent: NSEvent) {
    var isDragging = false
    var isTracking = true
    var event: NSEvent = theEvent

    while isTracking {
      switch event.type {
      case .leftMouseUp:
        isTracking = false
        self.handleUp(event)
        break

      case .leftMouseDragged:
        if isDragging {
          self.handleDragged(event)
        } else {
          isDragging = true
        }
        break

      default:
        break
      }

      if isTracking {
        let anEvent = self.window?.nextEvent(matching: [.leftMouseUp, .leftMouseDragged])
        event = anEvent!
      }
    }
  }

  func handleDragged(_ theEvent: NSEvent) {
    var location = self.convert(theEvent.locationInWindow, from: nil)
    location = self.convert(location, to: self.superview)

    // swiftlint:disable identifier_name
    let dx = (location.x - center.x) / center.x
    let dy = (location.y - center.y) / center.y
    // swiftlint:enable identifier_name

    var angle = atan(dy / dx)

    if dx < 0 {
      angle -= .pi
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
  private var _image: NSImage?

  func update(highlighted: Bool = false) {
    // Load the appropriate image for the clock face
    let imageName: String

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
    nil
  }
}
