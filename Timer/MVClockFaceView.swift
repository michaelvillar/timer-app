import AppKit

final class MVClockFaceView: NSView {
  private static let clockImage = NSImage(resource: .clock)
  private static let clockUnfocusImage = NSImage(resource: .clockUnfocus)
  private static let clockHighlightedImage = NSImage(resource: .clockHighlighted)

  private enum State {
    case normal, focused, highlighted
  }

  private var state = State.normal

  func update(highlighted: Bool = false) {
    if highlighted {
      self.state = .highlighted
    } else {
      self.state = (self.window?.isKeyWindow ?? false) ? .focused : .normal
    }
    self.needsDisplay = true
  }

  override func draw(_: NSRect) {
    let image: NSImage
    switch self.state {
    case .highlighted: image = Self.clockHighlightedImage
    case .focused: image = Self.clockImage
    case .normal: image = Self.clockUnfocusImage
    }
    image.draw(in: self.bounds)
  }

  override func hitTest(_: NSPoint) -> NSView? {
    nil
  }
}
