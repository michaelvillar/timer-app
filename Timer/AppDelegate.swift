import Cocoa
import AVFoundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
  
  var window: MVWindow!
  var mainView: MVMainView!
  var clockView: MVClockView!

  func applicationDidFinishLaunching(aNotification: NSNotification) {
    self.mainView = MVMainView(frame: NSZeroRect)
    
    self.clockView = MVClockView()
    self.clockView.target = self
    self.clockView.action = #selector(handleClockTimer)
    self.mainView.addSubview(clockView)
    
    window = MVWindow(mainView: mainView)
    window.makeKeyAndOrderFront(self)
    window.releasedWhenClosed = false
    
    NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
  }
  
  func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    self.window.makeKeyAndOrderFront(self)
    return true
  }

  func handleClockTimer(clockView: MVClockView) {
    let notification = NSUserNotification()
    notification.title = "It's time! 🕘"
    
    NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
    
    NSApplication.sharedApplication().requestUserAttention(NSRequestUserAttentionType.CriticalRequest)
    
    let soundURL = NSBundle.mainBundle().URLForResource("alert-sound", withExtension: "caf")
    var soundID: SystemSoundID = 0
    AudioServicesCreateSystemSoundID(soundURL!, &soundID)
    AudioServicesPlaySystemSound(soundID)
  }
  
  func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
    return true
  }

}

