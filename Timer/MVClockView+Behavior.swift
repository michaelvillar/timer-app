import AppKit

// MARK: - Event Handling

extension MVClockView {
  override func mouseDown(with event: NSEvent) {
    self.didDrag = false
    self.updateClockFaceView(highlighted: true)
    self.nextResponder?.mouseDown(with: event)
  }

  override func mouseDragged(with _: NSEvent) {
    if !self.didDrag {
      self.didDrag = true
      self.updateClockFaceView()
    }
  }

  override func mouseUp(with event: NSEvent) {
    let point = self.convert(event.locationInWindow, from: nil)
    if self.hitTest(point) == self, !self.didDrag {
      self.handleClick()
    }
    self.updateClockFaceView()
  }

  override func keyUp(with event: NSEvent) {
    switch event.charactersIgnoringModifiers {
    case ".":
      self.inputSeconds.toggle()

    case "\u{1B}": // escape
      self.resetTimer()

    case "\u{7F}", "\u{F728}": // delete, forward delete
      self.handleBackspace()

    case "\r", " ", "\u{03}": // return, space, keypad enter
      self.handleClick()

    case "r":
      if self.timerTask == nil, !self.paused, let seconds = self.lastTimerSeconds {
        self.seconds = seconds
        self.handleClick()
      }

    default:
      self.handleDigitInput(event)
    }
  }

  private func resetTimer() {
    self.paused = false
    self.stop()
    self.seconds = 0
    self.updateTimerTime()
    self.inputSeconds = false
  }

  private func handleBackspace() {
    let currentSeconds = self.seconds.truncatingRemainder(dividingBy: 60)
    let currentMinutes = floor(self.seconds / 60)
    self.paused = false
    self.stop()
    self.seconds = TimerLogic.processBackspace(
      currentSeconds: currentSeconds,
      currentMinutes: currentMinutes,
      inputSeconds: self.inputSeconds
    )
    self.updateTimerTime()
  }

  private func handleDigitInput(_ event: NSEvent) {
    guard let characters = event.characters, let number = Int(characters) else { return }

    let currentSeconds = self.seconds.truncatingRemainder(dividingBy: 60)
    let currentMinutes = floor(self.seconds / 60)
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

// MARK: - Timer

extension MVClockView {
  func start() {
    guard self.seconds > 0 else { return }
    self.lastTimerSeconds = self.seconds

    self.paused = false
    self.stop()

    self.timerTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1), tolerance: .milliseconds(30))
        self?.tick()
      }
    }
  }

  func stop() {
    self.timerTask?.cancel()
    self.timerTask = nil

    if self.inDock, !self.paused {
      self.removeBadge()
    }
  }

  private func tick() {
    guard let timerTime = self.timerTime else { return }

    let secondsRemaining = CGFloat(timerTime.timeIntervalSinceNow)

    self.seconds = max(0, round(secondsRemaining))

    if self.seconds <= 0 {
      self.stop()
      self.postAccessibilityValueChanged()
      self.onTimerComplete?()
    }
  }

  func startClockTimer() {
    guard self.currentTimeTask == nil else { return }

    if self.timerTask == nil {
      self.timerTime = Date()
    }

    self.currentTimeTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1), tolerance: .milliseconds(500))
        self?.maintainCurrentTime()
      }
    }
  }

  func stopClockTimer() {
    self.currentTimeTask?.cancel()
    self.currentTimeTask = nil
  }

  private func maintainCurrentTime() {
    guard self.timerTask == nil else { return }

    let time = Date()
    if Calendar.current.component(.second, from: time) == 0 {
      self.timerTime = time
    }
  }
}

// MARK: - Accessibility

extension MVClockView {
  override func isAccessibilityElement() -> Bool { true }
  override func accessibilityRole() -> NSAccessibility.Role? { .group }
  override func accessibilityLabel() -> String? { "Timer" }
  override func accessibilityValue() -> Any? { self.accessibilityTimerDescription }

  private var accessibilityTimerDescription: String {
    let mins = Int(self.minutes)
    let secs = Int(self.seconds.truncatingRemainder(dividingBy: 60))

    if self.seconds <= 0, self.timerTask == nil {
      return "Ready"
    }

    let timeDescription = TimerLogic.accessibilityTimeDescription(minutes: mins, seconds: secs)

    if self.paused {
      return "Paused at \(timeDescription)"
    }
    if self.timerTask != nil {
      return "\(timeDescription) remaining"
    }
    return timeDescription
  }

  func postAccessibilityValueChanged() {
    NSAccessibility.post(element: self, notification: .valueChanged)
  }
}
