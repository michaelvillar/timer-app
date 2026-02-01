import Cocoa

final class MVClockFaceView: NSView {
  private var cachedImage: NSImage?

  func update(highlighted: Bool = false) {
    // Load the appropriate image for the clock face
    let resource: ImageResource

    if highlighted {
      resource = .clockHighlighted
    } else {
      let windowHasFocus = self.window?.isKeyWindow ?? false
      resource = windowHasFocus ? .clock : .clockUnfocus
    }

    cachedImage = NSImage(resource: resource)

    self.needsDisplay = true
  }

  override func draw(_ dirtyRect: NSRect) {
    if let image = cachedImage {
      image.draw(in: self.bounds)
    }
  }

  override func hitTest(_ aPoint: NSPoint) -> NSView? {
    nil
  }
}
