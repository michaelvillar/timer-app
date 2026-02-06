import AppKit
import AVFoundation
import UserNotifications

final class MVTimerController: NSWindowController {
  private weak var dockMenuItem: NSMenuItem?
  private let clockView = MVClockView()

  private var audioPlayer: AVAudioPlayer? // player must be kept in memory
  private var soundURL = Bundle.main.url(forResource: "alert-sound", withExtension: "caf")

  convenience init() {
    let mainView = MVMainView(frame: .zero)

    let window = MVWindow(mainView: mainView)

    self.init(window: window)

    mainView.controller = self
    self.clockView.onTimerComplete = { [weak self] in self?.handleClockTimer() }
    mainView.addSubview(self.clockView)
    self.dockMenuItem = mainView.menuItem

    self.windowFrameAutosaveName = "TimerWindowAutosaveFrame"

    let savedSound = UserDefaults.standard.integer(forKey: MVUserDefaultsKeys.soundIndex)
    self.applySoundIndex(savedSound)

    window.makeKeyAndOrderFront(self)
  }

  convenience init(closeToWindow: NSWindow?) {
    self.init()

    // Secondary windows don't need autosave — clear it so they
    // don't overwrite the primary window's saved position.
    self.windowFrameAutosaveName = ""

    if let closeToWindow {
      var point = closeToWindow.frame.origin
      point.x += CGFloat(Int.random(in: -40...39))
      point.y += CGFloat(Int.random(in: -40...39))
      self.window?.setFrameOrigin(point)
    }
  }

  deinit {
    self.clockView.stop()
  }

  func showInDock(_ state: Bool) {
    self.clockView.inDock = state
    self.dockMenuItem?.state = state ? .on : .off
  }

  func windowVisibilityChanged(_ visible: Bool) {
    self.clockView.windowIsVisible = visible
  }

  private func playAlarmSound() {
    if let soundURL = self.soundURL {
      self.audioPlayer = try? AVAudioPlayer(contentsOf: soundURL)
      self.audioPlayer?.play()
    }
  }

  private func handleClockTimer() {
    let content = UNMutableNotificationContent()
    content.title = "It's time! 🕘"

    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request)

    NSApplication.shared.requestUserAttention(.criticalRequest)

    self.playAlarmSound()
  }

  override func keyUp(with event: NSEvent) {
    self.clockView.keyUp(with: event)
  }

  // Override required to suppress system beep on key press
  override func keyDown(with event: NSEvent) {
  }

  func pickSound(_ index: Int, preview: Bool = true) {
    UserDefaults.standard.set(index, forKey: MVUserDefaultsKeys.soundIndex)
    self.applySoundIndex(index, preview: preview)
  }

  private func applySoundIndex(_ index: Int, preview: Bool = false) {
    if let sound = TimerLogic.soundFilename(forIndex: index) {
      self.soundURL = Bundle.main.url(forResource: sound, withExtension: "caf")

      if preview {
        self.playAlarmSound()
      }
    } else {
      self.soundURL = nil
    }
  }
}
