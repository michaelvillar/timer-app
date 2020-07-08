import Cocoa

class MVTitlebarAccessoryViewController: NSTitlebarAccessoryViewController {
  override func loadView() {
    self.view = NSView(frame: NSRect.zero)
  }
}
