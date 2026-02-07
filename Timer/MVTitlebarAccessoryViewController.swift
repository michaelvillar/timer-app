import AppKit

final class MVTitlebarAccessoryViewController: NSTitlebarAccessoryViewController {
  override func loadView() {
    self.view = NSView(frame: .zero)
  }
}
