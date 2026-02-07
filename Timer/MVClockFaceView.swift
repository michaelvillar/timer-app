import AppKit

final class MVClockFaceView: NSView {
  private static let clockImage = NSImage(resource: .clock)
  private static let clockUnfocusImage = NSImage(resource: .clockUnfocus)
  private static let clockHighlightedImage = NSImage(resource: .clockHighlighted)

  private var currentImage: NSImage?

  func update(highlighted: Bool = false) {
    if highlighted {
      self.currentImage = Self.clockHighlightedImage
    } else {
      let windowHasFocus = self.window?.isKeyWindow ?? false
      self.currentImage = windowHasFocus ? Self.clockImage : Self.clockUnfocusImage
    }

    self.needsDisplay = true
  }

  override func draw(_ dirtyRect: NSRect) {
    if let image = self.currentImage {
      image.draw(in: self.bounds)
    }
  }

  override func hitTest(_ aPoint: NSPoint) -> NSView? {
    nil
  }
}
