import Cocoa

final class MVClockView: NSView {
  override var mouseDownCanMoveWindow: Bool { false }

  private static let minutesFont = NSFont.monospacedDigitSystemFont(ofSize: 35, weight: .medium)
  private static let secondsFont = NSFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)

  private let progressView = MVClockProgressView()
  private let arrowView = MVClockArrowView(center: CGPoint(x: 75, y: 75))
  private let clockFaceView = MVClockFaceView(frame: NSRect(x: 16, y: 15, width: 118, height: 118))

  private let pauseIconImageView: NSImageView = {
    let view = NSImageView(frame: NSRect(x: 70, y: 99, width: 10, height: 12))
    view.image = NSImage(resource: .iconPause)
    view.alphaValue = 0.0
    return view
  }()

  private let timerTimeLabel: MVLabel = {
    let label = MVLabel(frame: NSRect(x: 0, y: 94, width: 150, height: 20))
    label.font = NSFont.systemFont(ofSize: 15, weight: .medium)
    label.alignment = .center
    label.textColor = NSColor(srgbRed: 0.749, green: 0.1412, blue: 0.0118, alpha: 1.0)
    return label
  }()

  private let minutesLabel: MVLabel = {
    let label = MVLabel(frame: NSRect(x: 0, y: 57, width: 150, height: 30))
    label.string = ""
    label.font = MVClockView.minutesFont
    label.alignment = .center
    label.textColor = NSColor(srgbRed: 0.2353, green: 0.2549, blue: 0.2706, alpha: 1.0)
    return label
  }()

  private let secondsLabel: MVLabel = {
    let label = MVLabel(frame: NSRect(x: 0, y: 38, width: 150, height: 20))
    label.font = MVClockView.secondsFont
    label.alignment = .center
    label.textColor = NSColor(srgbRed: 0.6353, green: 0.6667, blue: 0.6863, alpha: 1.0)
    return label
  }()

  private let timerTimeLabelFontSize: CGFloat = 15
  private let minutesLabelSuffixWidth = "'".size(withAttributes: [.font: MVClockView.minutesFont]).width
  private let minutesLabelSecondsSuffixWidth = "\"".size(withAttributes: [.font: MVClockView.minutesFont]).width
  private let secondsSuffixWidth = "'".size(withAttributes: [.font: MVClockView.secondsFont]).width
  private lazy var timerTimeLabelFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "jj:mm", options: 0, locale: Locale.current)
    return formatter
  }()
  private var inputSeconds: Bool = false
  private var lastTimerSeconds: CGFloat?
  private let docktile: NSDockTile = NSApplication.shared.dockTile
  var inDock: Bool = false {
    didSet {
      if !inDock {
        self.removeBadge()
      }
      self.updateBadge()
    }
  }
  var windowIsVisible: Bool = false {
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
  var onTimerComplete: (() -> Void)?
  private var notificationObservers: [NSObjectProtocol] = []
  private var currentTimeTimer: Timer?
  private var timer: Timer?
  private var paused: Bool = false {
    didSet {
      self.layoutPauseViews()
    }
  }

  private var seconds: CGFloat = 0.0 {
    didSet {
      self.minutes = floor(seconds / 60)
      self.progress = invertProgressToScale(seconds / 60.0 / 60.0)
    }
  }
  private var minutes: CGFloat = 0.0 {
    didSet {
      if windowIsVisible {
        self.updateLabels()
      }
      self.updateBadge() // Update the dock badge even when the window is hidden
    }
  }
  private var progress: CGFloat = 0.0 {
    didSet {
      if windowIsVisible {
        self.layoutSubviews()
      }
    }
  }

  // MARK: -

  convenience init() {
    self.init(frame: NSRect(x: 0, y: 0, width: 150, height: 150))

    self.center(progressView)
    self.addSubview(progressView)

    self.arrowView.onProgressChanged = { [weak self] progress in self?.handleArrowControl(progress: progress) }
    self.arrowView.onMouseUp = { [weak self] in self?.handleArrowControlMouseUp() }
    self.layoutSubviews()
    self.addSubview(arrowView)

    self.addSubview(clockFaceView)
    self.addSubview(pauseIconImageView)
    self.addSubview(timerTimeLabel)
    self.addSubview(minutesLabel)
    self.addSubview(secondsLabel)

    self.updateClockFaceView()
    self.updateAllViews()

    let notificationCenter = NotificationCenter.default
    notificationObservers.append(
      notificationCenter.addObserver(forName: NSWindow.didBecomeKeyNotification, object: nil, queue: nil) {
        [weak self] _ in
        self?.updateClockFaceView()
        self?.arrowView.needsDisplay = true
        self?.progressView.needsDisplay = true
      }
    )

    notificationObservers.append(
      notificationCenter.addObserver(forName: NSWindow.didResignKeyNotification, object: nil, queue: nil) {
        [weak self] _ in
        self?.updateClockFaceView()
        self?.arrowView.needsDisplay = true
        self?.progressView.needsDisplay = true
      }
    )
  }

  deinit {
    notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
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

  private func handleArrowControl(progress rawProgress: CGFloat) {
    var progressValue = rawProgress
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

  private func handleArrowControlMouseUp() {
    self.updateTimerTime()
    self.start()
  }

  private func handleClick() {
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
    NSAnimationContext.runAnimationGroup { ctx in
      ctx.duration = 0.2
      ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      self.pauseIconImageView.animator().alphaValue = showPauseIcon ? 1 : 0
      self.timerTimeLabel.animator().alphaValue = showPauseIcon ? 0 : 1
    }
  }

  private var didDrag: Bool = false

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

  override func keyUp(with event: NSEvent) {
    let key = event.keyCode
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

      self.seconds = TimerLogic.processBackspace(
        currentSeconds: currentSeconds,
        currentMinutes: currentMinutes,
        inputSeconds: self.inputSeconds
      )

      self.updateTimerTime()

      return
    }

    // "Enter" or "Space" or "Keypad Enter"
    if key == Keycode.returnKey || key == Keycode.space || key == Keycode.keypadEnter {
      self.handleClick()

      return
    }

    // "r" for restarting with the last timer
    if key == Keycode.r && self.timer == nil && !self.paused, let seconds = self.lastTimerSeconds {
      self.seconds = seconds
      self.handleClick()

      return
    }

    if let number = Int(event.characters ?? "") {
      let result = TimerLogic.processDigitInput(
        digit: number,
        currentSeconds: currentSeconds,
        currentMinutes: currentMinutes,
        totalSeconds: self.seconds,
        inputSeconds: self.inputSeconds
      )

      if result.accepted {
        self.paused = false
        self.stop()
        self.seconds = result.seconds
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
    minutesLabel.string = TimerLogic.minutesDisplayString(seconds: self.seconds)
    let suffixWidth: CGFloat = self.seconds < 60 ? minutesLabelSecondsSuffixWidth : minutesLabelSuffixWidth
    minutesLabel.sizeToFit()

    var frame = minutesLabel.frame
    frame.origin.x = round((self.bounds.width - (frame.size.width - suffixWidth)) / 2)
    minutesLabel.frame = frame

    secondsLabel.string = TimerLogic.secondsDisplayString(seconds: self.seconds)
    if self.seconds >= 60 {
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
        self.docktile.badgeLabel = TimerLogic.badgeString(minutes: badgeMinutes, seconds: badgeSeconds)
      } else {
        self.removeBadge()
      }
    }
  }

  private func removeBadge() {
    self.docktile.badgeLabel = ""
  }

  private func updateTimeLabel() {
    let timeString = timerTimeLabelFormatter.string(from: self.timerTime ?? Date())
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
    guard self.seconds > 0 else { return }
    self.lastTimerSeconds = self.seconds

    self.paused = false
    self.stop()

    // Since the UI only allows timers to be set in multiples of 1 second, each tick
    // will fire _near_ an integer seconds-remaining boundary.
    self.timer = Foundation.Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      self?.tick()
    }

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

  private func tick() {
    guard let timerTime = self.timerTime else { return }

    let secondsRemaining = CGFloat(timerTime.timeIntervalSinceNow)

    // Round the seconds displayed on the clock face
    self.seconds = max(0, round(secondsRemaining))

    if self.seconds <= 0 { // Timer is done!
      self.stop()
      self.onTimerComplete?()
    }
  }

  private func startClockTimer() {
    guard currentTimeTimer == nil else { return }

    // Set the current time right away, unless a timer is running
    if self.timer == nil {
      self.timerTime = Date()
    }

    currentTimeTimer = Foundation.Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      self?.maintainCurrentTime()
    }

    // Improves the system's ability to optimize for increased power savings and responsiveness
    // A general rule, set the tolerance to at least 10% of the interval, for a repeating timer.
    currentTimeTimer?.tolerance = 0.5
  }

  private func stopClockTimer() {
    currentTimeTimer?.invalidate()
    currentTimeTimer = nil
  }

  private func maintainCurrentTime() {
    guard self.timer == nil else { return } // don't set if the main timer is counting down

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

  private func convertProgressToScale(_ progress: CGFloat) -> CGFloat {
    TimerLogic.convertProgressToScale(progress, minutes: self.minutes)
  }

  private func invertProgressToScale(_ progress: CGFloat) -> CGFloat {
    TimerLogic.invertProgressToScale(progress, minutes: self.minutes)
  }
}
