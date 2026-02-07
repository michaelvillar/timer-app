import AppKit

final class MVLabel: NSTextField {
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    self.isEditable = false
    self.isSelectable = false
    self.isBezeled = false
    self.drawsBackground = false
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Convenience to match the NSTextView `string` API used throughout the codebase.
  var string: String {
    get { self.stringValue }
    set { self.stringValue = newValue }
  }

  /// Sets the font for a specific range of the displayed text.
  func setFont(_ font: NSFont, range: NSRange) {
    let attributed = NSMutableAttributedString(attributedString: self.attributedStringValue)
    attributed.addAttribute(.font, value: font, range: range)
    self.attributedStringValue = attributed
  }

  override func hitTest(_: NSPoint) -> NSView? {
    nil
  }
}
