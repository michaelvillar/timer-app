import Cocoa

class MVLabel: NSTextView {
  override init(frame frameRect: NSRect, textContainer aTextContainer: NSTextContainer?) {
    super.init(frame: frameRect, textContainer: aTextContainer)

    self.commonInit()
  }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    self.commonInit()
  }

  private func commonInit() {
    self.backgroundColor = NSColor.clear
    self.isSelectable = false
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func hitTest(_ aPoint: NSPoint) -> NSView? {
    nil
  }
}
