import Cocoa

final class MVClockArrowView: NSView {
  // Midpoint (ratio 0.5) between sRGB (0.1734, 0.5284, 0.9448) and (0.2235, 0.5686, 0.9882)
  private static let focusedColor = NSColor(srgbRed: 0.1985, green: 0.5485, blue: 0.9665, alpha: 1.0)
  // Desaturated steel blue for unfocused windows
  private static let unfocusedColor = NSColor(srgbRed: 0.5529, green: 0.6275, blue: 0.7216, alpha: 1.0)

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

  override func draw(_ dirtyRect: NSRect) {
    NSColor.clear.setFill()
    self.bounds.fill()

    let path = NSBezierPath()
    path.move(to: .zero)
    path.line(to: CGPoint(x: self.bounds.width / 2, y: self.bounds.height * 0.8))
    path.line(to: CGPoint(x: self.bounds.width, y: 0))

    let center = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
    let angle = -progress * .pi * 2
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

    self.onProgressChanged?(progress)
  }

  private func handleUp() {
    self.onMouseUp?()
  }
}
