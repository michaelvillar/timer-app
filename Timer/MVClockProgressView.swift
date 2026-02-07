import AppKit

final class MVClockProgressView: NSView {
  private static let ringColor = NSColor(srgbRed: 0.7255, green: 0.7255, blue: 0.7255, alpha: 0.15)
  private static let progressImage = NSImage(resource: .progress)
  private static let progressUnfocusImage = NSImage(resource: .progressUnfocus)

  var progress: CGFloat = 0.0 {
    didSet {
      self.needsDisplay = true
    }
  }
  convenience init() {
    self.init(frame: NSRect(x: 0, y: 0, width: 116, height: 116))
  }

  override func draw(_ dirtyRect: NSRect) {
    Self.ringColor.setFill()
    NSBezierPath(ovalIn: self.bounds).fill()

    self.drawArc(self.progress)
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

    let cgTransform = CGAffineTransform(translationX: center.x, y: center.y)
      .rotated(by: -progress * 2 * .pi)
      .translatedBy(x: -center.x, y: -center.y)
    NSGraphicsContext.current?.cgContext.concatenate(cgTransform)

    let image = windowHasFocus ? Self.progressImage : Self.progressUnfocusImage
    image.draw(in: self.bounds)

    ctx?.restoreGraphicsState()
  }
}
