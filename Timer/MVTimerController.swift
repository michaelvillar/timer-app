import Cocoa
import AVFoundation

class MVTimerController: NSWindowController {

    private var mainView: MVMainView!
    private var clockView: MVClockView!

    convenience init() {
        let mainView = MVMainView(frame: NSZeroRect)

        let window = MVWindow(mainView: mainView)
        window.releasedWhenClosed = false

        self.init(window: window)

        self.mainView = mainView
        self.clockView = MVClockView()
        self.clockView.target = self
        self.clockView.action = #selector(handleClockTimer)
        self.mainView.addSubview(clockView)

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
    
    
}
