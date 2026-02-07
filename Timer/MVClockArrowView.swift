import AppKit

final class MVClockArrowView: NSView {
  private static let focusedColor = NSColor(resource: .arrowFocused)
  private static let unfocusedColor = NSColor(resource: .arrowUnfocused)

  var progress: CGFloat = 0.0 {
    didSet {
      self.needsDisplay = true
    }
  }
  override var mouseDownCanMoveWindow: Bool { false }

  var onProgressChanged: ((CGFloat) -> Void)?
  var onMouseUp: (() -> Void)?
  private var center = CGPoint.zero

  convenience init(center: CGPoint) {
    self.init(frame: NSRect(x: 0, y: 0, width: 25, height: 25))
    self.center = center
  }

  override func draw(_: NSRect) {
    NSColor.clear.setFill()
    self.bounds.fill()

    let path = NSBezierPath()
    path.move(to: .zero)
    path.line(to: CGPoint(x: self.bounds.width / 2, y: self.bounds.height * 0.8))
    path.line(to: CGPoint(x: self.bounds.width, y: 0))

    let center = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
    let angle = -self.progress * .pi * 2
    var transform = AffineTransform.identity
    transform.translate(x: center.x, y: center.y)
    transform.rotate(byRadians: angle)
    transform.translate(x: -center.x, y: -center.y)

    path.transform(using: transform)

    let color = (self.window?.isKeyWindow ?? false) ? Self.focusedColor : Self.unfocusedColor
    color.setFill()
    path.fill()
  }

  override func mouseDown(with event: NSEvent) {
    var isDragging = false
    var isTracking = true
    var trackingEvent: NSEvent = event

    while isTracking {
      switch trackingEvent.type {
      case .leftMouseUp:
        isTracking = false
        self.handleUp()

      case .leftMouseDragged:
        if isDragging {
          self.handleDragged(trackingEvent)
        } else {
          isDragging = true
        }

      default:
        break
      }

      if isTracking {
        guard let nextEvent = self.window?.nextEvent(matching: [.leftMouseUp, .leftMouseDragged]) else {
          break
        }
        trackingEvent = nextEvent
      }
    }
  }

  private func handleDragged(_ event: NSEvent) {
    var location = self.convert(event.locationInWindow, from: nil)
    location = self.convert(location, to: self.superview)

    // swiftlint:disable identifier_name
    let dx = (location.x - self.center.x) / self.center.x
    let dy = (location.y - self.center.y) / self.center.y
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

    self.onProgressChanged?(progress)
  }

  private func handleUp() {
    self.onMouseUp?()
  }

  // MARK: - Accessibility

  override func isAccessibilityElement() -> Bool { true }
  override func accessibilityRole() -> NSAccessibility.Role? { .slider }
  override func accessibilityLabel() -> String? { "Timer duration" }

  override func accessibilityValue() -> Any? {
    let totalSeconds = Int(self.progress * 60 * 60)
    return TimerLogic.accessibilityTimeDescription(minutes: totalSeconds / 60, seconds: totalSeconds % 60)
  }
}
