import Cocoa
import AVFoundation

class MVTimerController: NSWindowController {

  private var mainView: MVMainView!
  private var clockView: MVClockView!

  convenience init() {
    let mainView = MVMainView(frame: NSZeroRect)

    let window = MVWindow(mainView: mainView)
    //window.isReleasedWhenClosed = false

    self.init(window: window)
    
    self.mainView = mainView
    self.mainView.controller = self
    self.clockView = MVClockView()
    self.clockView.target = self
    self.clockView.action = #selector(handleClockTimer)
    self.mainView.addSubview(clockView)
    
    self.windowFrameAutosaveName = NSWindow.FrameAutosaveName("TimerWindowAutosaveFrame")
    
    window.makeKeyAndOrderFront(self)    
  }
  
  convenience init(closeToWindow: NSWindow?) {
    self.init()
    
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
  
  @objc func handleClockTimer(_ clockView: MVClockView) {
    let notification = NSUserNotification()
    notification.title = "It's time! 🕘"
    
    NSUserNotificationCenter.default.deliver(notification)
    
    NSApplication.shared.requestUserAttention(.criticalRequest)
    
    let soundURL = Bundle.main.url(forResource: "alert-sound", withExtension: "caf")
    var soundID: SystemSoundID = 0
    AudioServicesCreateSystemSoundID(soundURL! as CFURL, &soundID)
    AudioServicesPlaySystemSound(soundID)
  }
  
  override func keyUp(with theEvent: NSEvent) {
    self.clockView.keyUp(with: theEvent)
  }

  override func keyDown(with event: NSEvent) {
  }

}
