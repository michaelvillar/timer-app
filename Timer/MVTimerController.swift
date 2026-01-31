import AVFoundation
import Cocoa
import UserNotifications

class MVTimerController: NSWindowController {
  private var mainView: MVMainView!
  private var clockView: MVClockView!

  private var audioPlayer: AVAudioPlayer? // player must be kept in memory
  private var soundURL = Bundle.main.url(forResource: "alert-sound", withExtension: "caf")

  convenience init() {
    let mainView = MVMainView(frame: NSRect.zero)

    let window = MVWindow(mainView: mainView)

    self.init(window: window)

    self.mainView = mainView
    self.mainView.controller = self
    self.clockView = MVClockView()
    self.clockView.target = self
    self.clockView.action = #selector(handleClockTimer)
    self.mainView.addSubview(clockView)

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

    if closeToWindow != nil {
      var point = closeToWindow!.frame.origin
      point.x += CGFloat(Int(arc4random_uniform(UInt32(80))) - 40)
      point.y += CGFloat(Int(arc4random_uniform(UInt32(80))) - 40)
      self.window?.setFrameOrigin(point)
    }
  }

  deinit {
    self.clockView.target = nil
    self.clockView.stop()
  }

  func showInDock(_ state: Bool) {
    self.clockView.inDock = state
    self.mainView.menuItem?.state = state ? .on : .off
  }

  func windowVisibilityChanged(_ visible: Bool) {
    clockView.windowIsVisible = visible
  }

  func playAlarmSound() {
    if soundURL != nil {
        audioPlayer = try? AVAudioPlayer(contentsOf: soundURL!)
        //audioPlayer?.volume = self.volume
        audioPlayer?.play()
    }
  }

  @objc func handleClockTimer(_ clockView: MVClockView) {
    let content = UNMutableNotificationContent()
    content.title = "It's time! 🕘"

    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request)

    NSApplication.shared.requestUserAttention(.criticalRequest)

    playAlarmSound()
  }

  override func keyUp(with theEvent: NSEvent) {
    self.clockView.keyUp(with: theEvent)
  }

  override func keyDown(with event: NSEvent) {
  }

  func pickSound(_ index: Int, preview: Bool = true) {
    UserDefaults.standard.set(index, forKey: MVUserDefaultsKeys.soundIndex)
    applySoundIndex(index, preview: preview)
  }

  private func applySoundIndex(_ index: Int, preview: Bool = false) {
    if let sound = TimerLogic.soundFilename(forIndex: index) {
        self.soundURL = Bundle.main.url(forResource: sound, withExtension: "caf")

        if preview {
            playAlarmSound()
        }
    } else {
        self.soundURL = nil
    }
  }
}
