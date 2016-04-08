import Cocoa

class MVMainView: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindowDidBecomeKeyNotification, object: nil)
        nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindowDidResignKeyNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        let windowHasFocus = self.window?.keyWindow ?? false
        var topColor = NSColor(SRGBRed: 0.949, green: 0.9451, blue: 0.949, alpha: 1.0)
        var bottomColor = NSColor(SRGBRed: 0.8392, green: 0.8314, blue: 0.8392, alpha: 1.0)
        if !windowHasFocus {
            topColor = NSColor(SRGBRed: 0.9647, green: 0.9647, blue: 0.9647, alpha: 1.0)
            bottomColor = NSColor(SRGBRed: 0.9647, green: 0.9647, blue: 0.9647, alpha: 1.0)
        }

        let gradient = NSGradient(colors: [topColor, bottomColor])
        let radius: CGFloat = 4.53
        let path = NSBezierPath(roundedRect: self.bounds, xRadius: radius, yRadius: radius)
        gradient?.drawInBezierPath(path, angle: -90)
    }
    
    func windowFocusChanged(notification: NSNotification) {
        self.needsDisplay = true
    }
    
}
