import Cocoa

class MVClockView: NSControl {

    private var clickGesture: NSClickGestureRecognizer!
    private var imageView: NSImageView!
    private var pauseIconImageView: NSImageView!
    private var progressView: MVClockProgressView!
    private var arrowView: MVClockArrowView!
    private var timerTimeLabel: NSTextView!
    private var minutesLabel: NSTextView!
    private var minutesLabelSuffixWidth: CGFloat = 0.0
    private var minutesLabelSecondsSuffixWidth: CGFloat = 0.0
    private var secondsLabel: NSTextView!
    private var secondsSuffixWidth: CGFloat = 0.0
    private var timerTime: NSDate? {
        didSet {
            updateTimeLabel()
        }
    }
    private var timer: NSTimer?
    private var paused: Bool = false {
        didSet {
            layoutPauseViews()
        }
    }

    var seconds: CGFloat = 0.0 {
        didSet {
            minutes = floor(seconds / 60)
            progress = invertProgressToScale(seconds / 60.0 / 60.0)
        }
    }
    var minutes: CGFloat = 0.0 {
        didSet {
            updateLabels()
        }
    }
    var progress: CGFloat = 0.0 {
        didSet {
            layoutSubviews()
            progressView.progress = progress
            arrowView.progress = progress
        }
    }

    convenience init() {
        self.init(frame: NSRect(x: 0, y: 0, width: 150, height: 150))

        progressView = MVClockProgressView()
        center(progressView)
        addSubview(progressView)

        arrowView = MVClockArrowView(center: CGPointMake(75, 75))
        arrowView.target = self
        arrowView.action = #selector(handleArrowControl)
        arrowView.actionMouseUp = #selector(handleArrowControlMouseUp)
        layoutSubviews()
        addSubview(arrowView)

        imageView = MVClockImageView(frame: NSRect(x: 16, y: 15, width: 118, height: 118))
        addSubview(imageView)

        pauseIconImageView = NSImageView(frame: NSRect(x: 70, y: 99, width: 10, height: 12))
        pauseIconImageView.image = NSImage(named: "icon-pause")
        pauseIconImageView.alphaValue = 0.0
        addSubview(pauseIconImageView)

        timerTimeLabel = MVLabel(frame: NSRect(x: 0, y: 94, width: 150, height: 20))
        timerTimeLabel.font = NSFont.systemFontOfSize(15, weight: NSFontWeightMedium)
        timerTimeLabel.alignment = .Center
        timerTimeLabel.textColor = NSColor(SRGBRed: 0.749, green: 0.1412, blue: 0.0118, alpha: 1.0)
        addSubview(timerTimeLabel)

        minutesLabel = MVLabel(frame: NSRect(x: 0, y: 57, width: 150, height: 30))
        minutesLabel.string = ""
        minutesLabel.font = NSFont.systemFontOfSize(35, weight: NSFontWeightMedium)
        minutesLabel.alignment = .Center
        minutesLabel.textColor = NSColor(SRGBRed: 0.2353, green: 0.2549, blue: 0.2706, alpha: 1.0)
        addSubview(minutesLabel)

        let minutesLabelSuffix = "'"
        let minutesLabelSize = minutesLabelSuffix.sizeWithAttributes([
            NSFontAttributeName: minutesLabel.font!
            ])
        minutesLabelSuffixWidth = minutesLabelSize.width

        let minutesLabelSecondsSuffix = "\""
        let minutesLabelSecondsSize = minutesLabelSecondsSuffix.sizeWithAttributes([
            NSFontAttributeName: minutesLabel.font!
            ])
        minutesLabelSecondsSuffixWidth = minutesLabelSecondsSize.width

        secondsLabel = MVLabel(frame: NSRect(x: 0, y: 38, width: 150, height: 20))
        secondsLabel.font = NSFont.systemFontOfSize(15, weight: NSFontWeightMedium)
        secondsLabel.alignment = .Center
        secondsLabel.textColor = NSColor(SRGBRed: 0.6353, green: 0.6667, blue: 0.6863, alpha: 1.0)
        addSubview(secondsLabel)

        let secondsLabelSuffix = "'"
        let secondsLabelSize = secondsLabelSuffix.sizeWithAttributes([
            NSFontAttributeName: secondsLabel.font!
            ])
        secondsSuffixWidth = secondsLabelSize.width

        updateLabels()
        updateTimeLabel()
        updateClockImageView()

        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindowDidBecomeKeyNotification, object: nil)
        nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindowDidResignKeyNotification, object: nil)
    }

    deinit {
        let nc = NSNotificationCenter.defaultCenter()
        nc.removeObserver(self)

        arrowView.target = nil
    }

    func windowFocusChanged(notification: NSNotification) {
        updateClockImageView()
    }

    private func updateClockImageView(highlighted highlighted: Bool = false) {
        let windowHasFocus = window?.keyWindow ?? false
        var image = windowHasFocus ? "clock" : "clock-unfocus"
        if highlighted {
            image = "clock-highlighted"
        }
        imageView.image = NSImage(named: image)
    }

    private func center(view: NSView) {
        var frame = view.frame
        frame.origin.x = round((bounds.width - frame.size.width) / 2)
        frame.origin.y = round((bounds.height - frame.size.height) / 2)
        view.frame = frame
    }

    private func layoutSubviews() {
        let angle = -progress * CGFloat(M_PI) * 2 + CGFloat(M_PI) / 2
        let x = bounds.width / 2 + cos(angle) * progressView.bounds.width / 2
        let y = bounds.height / 2 + sin(angle) * progressView.bounds.height / 2
        let point: NSPoint = NSPoint(x: x - arrowView.bounds.width / 2, y: y - arrowView.bounds.height / 2)
        var frame = arrowView.frame
        frame.origin = point
        arrowView.frame = frame
    }

    func handleArrowControl(object: NSNumber) {
        let progressValue = convertProgressToScale(CGFloat(object.floatValue))
        var seconds: CGFloat = round(progressValue * 60.0 * 60.0)

        if seconds <= 300 {
            seconds = seconds - seconds % 10
        } else {
            seconds = seconds - seconds % 60
        }

        self.seconds = seconds
        updateTimerTime()

        stop()

        paused = false
    }

    func handleArrowControlMouseUp() {
        updateTimerTime()
        start()
    }

    func handleClick() {
        if timer == nil && seconds > 0 {
            updateTimerTime()
            start()
        } else {
            paused = true
            stop()
        }
    }

    private func layoutPauseViews() {
        let showPauseIcon = paused && timer != nil
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            self.pauseIconImageView.animator().alphaValue = showPauseIcon ? 1 : 0
            self.timerTimeLabel.animator().alphaValue = showPauseIcon ? 0 : 1
            }, completionHandler: nil)
    }

    override func mouseDown(theEvent: NSEvent) {
        updateClockImageView(highlighted: true)
        if let event = window?.nextEventMatchingMask(Int(NSEventMask.LeftMouseUpMask.rawValue) | Int(NSEventMask.LeftMouseDraggedMask.rawValue)) where event.type == NSEventType.LeftMouseUp {
            let point = convertPoint(event.locationInWindow, fromView: nil)
            if hitTest(point) == self {
                handleClick()
            }
        }
        updateClockImageView()

        super.mouseDown(theEvent)
    }

    private func updateTimerTime() {
        timerTime = NSDate(timeIntervalSinceNow: Double(seconds))
    }

    private func updateLabels() {
        var suffixWidth: CGFloat = 0
        if (seconds < 60) {
            minutesLabel.string = "\(seconds)";
            suffixWidth = minutesLabelSecondsSuffixWidth
        } else {
            minutesLabel.string = "\(minutes)"
            suffixWidth = minutesLabelSuffixWidth
        }
        minutesLabel.sizeToFit()

        var frame = minutesLabel.frame
        frame.origin.x = round((bounds.width - (frame.size.width - suffixWidth)) / 2)
        minutesLabel.frame = frame

        if (seconds < 60) {
            secondsLabel.string = ""
        }
        else {
            secondsLabel.string = "\(Int(seconds % 60))"
            secondsLabel.sizeToFit()

            frame = secondsLabel.frame
            frame.origin.x = round((bounds.width - (frame.size.width - secondsSuffixWidth)) / 2)
            secondsLabel.frame = frame
        }
    }

    private func updateTimeLabel() {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "HH:mm"
        timerTimeLabel.string = formatter.stringFromDate(timerTime ?? NSDate())
    }

    private func start() {
        if seconds <= 0 {
            return
        }
        paused = false
        stop()
        timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func tick() {
        if timerTime == nil {
            return;
        }
        seconds = fmax(0, ceil(CGFloat(timerTime!.timeIntervalSinceNow ?? 0)))

        if seconds <= 0 {
            stop()
            target?.performSelector(action, withObject: self)
        }
    }

    override func hitTest(aPoint: NSPoint) -> NSView? {
        let view = super.hitTest(aPoint)
        if view == arrowView {
            return view
        }
        let path = NSBezierPath(ovalInRect: NSRect(x: 21, y: 21, width: 108, height: 108))
        if path.containsPoint(aPoint) && seconds > 0 {
            return self
        }
        return nil
    }

    private let scaleOriginal: CGFloat = 6
    private let scaleActual: CGFloat = 3

    private func convertProgressToScale(progress: CGFloat) -> CGFloat {
        if minutes <= 60 {
            if progress <= scaleOriginal / 60 {
                return progress / (scaleOriginal / scaleActual)
            } else {
                return (progress * 60 - scaleOriginal + scaleActual) / (60 - scaleActual)
            }
        }
        return progress
    }

    private func invertProgressToScale(progress: CGFloat) -> CGFloat {
        if minutes <= 60 {
            if progress <= scaleActual / 60 {
                return progress * (scaleOriginal / scaleActual)
            } else {
                return (progress * (60 - scaleActual) - scaleActual + scaleOriginal) / 60

            }
        }
        return progress
    }

}

class MVClockProgressView: NSView {

    var progress: CGFloat = 0.0 {
        didSet {
            needsDisplay = true
        }
    }

    convenience init() {
        self.init(frame: NSRect(x: 0, y: 0, width: 116, height: 116))

        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindowDidBecomeKeyNotification, object: nil)
        nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindowDidResignKeyNotification, object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func drawRect(dirtyRect: NSRect) {
        NSColor(SRGBRed: 0.7255, green: 0.7255, blue: 0.7255, alpha: 0.15).setFill()
        NSBezierPath(ovalInRect: bounds).fill()

        drawArc(progress)
    }

    private func drawArc(progress: CGFloat) {
        let cp = NSPoint(x: bounds.width / 2, y: bounds.height / 2)
        let windowHasFocus = window?.keyWindow ?? false

        let path = NSBezierPath()
        path.moveToPoint(NSPoint(x: bounds.width / 2, y: bounds.height))
        path.appendBezierPathWithArcWithCenter(NSPoint(x: bounds.width / 2, y: bounds.height / 2),
                                               radius: bounds.width / 2,
                                               startAngle: 90,
                                               endAngle: 90 - (progress > 1 ? 1 : progress) * 360,
                                               clockwise: true)
        path.lineToPoint(cp)
        path.addClip()

        let ctx = NSGraphicsContext.currentContext()
        ctx?.saveGraphicsState()

        let transform = NSAffineTransform()
        transform.translateXBy(cp.x, yBy: cp.y)
        transform.rotateByDegrees(-progress * 360)
        transform.translateXBy(-cp.x, yBy: -cp.y)
        transform.concat()

        let image = NSImage(named: windowHasFocus ? "progress" : "progress-unfocus")
        image?.drawInRect(bounds)

        ctx?.restoreGraphicsState()
    }

    func windowFocusChanged(notification: NSNotification) {
        needsDisplay = true
    }

}

class MVClockArrowView: NSControl {

    var progress: CGFloat = 0.0 {
        didSet {
            needsDisplay = true
        }
    }
    var actionMouseUp: Selector?
    private var center: CGPoint = CGPointZero

    convenience init(center: CGPoint) {
        self.init(frame: NSRect(x: 0, y: 0, width: 25, height: 25))
        self.center = center

        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindowDidBecomeKeyNotification, object: nil)
        nc.addObserver(self, selector: #selector(windowFocusChanged), name: NSWindowDidResignKeyNotification, object: nil)
    }

    deinit {
        let nc = NSNotificationCenter.defaultCenter()
        nc.removeObserver(self)
    }

    override func drawRect(dirtyRect: NSRect) {
        NSColor.clearColor().setFill()
        NSRectFill(bounds)

        let path = NSBezierPath()
        path.moveToPoint(CGPoint(x: 0, y: 0))
        path.lineToPoint(CGPoint(x: bounds.width / 2, y: bounds.height * 0.8))
        path.lineToPoint(CGPoint(x: bounds.width, y: 0))

        let cp = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let angle = -progress * CGFloat(M_PI) * 2
        let transform = NSAffineTransform()
        transform.translateXBy(cp.x, yBy: cp.y)
        transform.rotateByRadians(angle)
        transform.translateXBy(-cp.x, yBy: -cp.y)

        path.transformUsingAffineTransform(transform)

        let windowHasFocus = window?.keyWindow ?? false
        if windowHasFocus {
            let ratio: CGFloat = 0.5
            NSColor(SRGBRed: 0.1734 + ratio * (0.2235 - 0.1734), green: 0.5284 + ratio * (0.5686 - 0.5284), blue: 0.9448 + ratio * (0.9882 - 0.9448), alpha: 1.0).setFill()
        } else {
            NSColor(SRGBRed: 0.5529, green: 0.6275, blue: 0.7216, alpha: 1.0).setFill()
        }
        path.fill()
    }

    override func mouseDown(theEvent: NSEvent) {
        var isDragging = false
        var isTracking = true
        var event: NSEvent = theEvent

        while (isTracking) {
            switch (event.type) {
            case NSEventType.LeftMouseUp:
                isTracking = false
                handleUp(event)
                break;

            case NSEventType.LeftMouseDragged:
                if (isDragging) {
                    handleDragged(event)
                }
                else {
                    isDragging = true
                }
                break;
            default:
                break;
            }

            if (isTracking) {
                let anEvent = window?.nextEventMatchingMask(Int(NSEventMask.LeftMouseUpMask.rawValue) | Int(NSEventMask.LeftMouseDraggedMask.rawValue))
                event = anEvent!
            }
        }
    }

    func handleDragged(theEvent: NSEvent) {
        var location = convertPoint(theEvent.locationInWindow, fromView: nil)
        location = convertPoint(location, toView: superview)
        let dx = (location.x - center.x) / center.x
        let dy = (location.y - center.y) / center.y
        var angle = atan(dy / dx)
        if (dx < 0) {
            angle = angle - CGFloat(M_PI)
        }
        var progress = (self.progress - self.progress % 1) + -(angle - CGFloat(M_PI) / 2) / (CGFloat(M_PI) * 2)
        if self.progress - progress > 0.25 {
            progress += 1
        } else if progress - self.progress > 0.75 {
            progress -= 1
        }
        if progress < 0 {
            progress = 0
        }
        let progressNumber = NSNumber(float: Float(progress))
        target?.performSelector(action, withObject: progressNumber)
    }
    
    func handleUp(theEvent: NSEvent) {
        if let selector = actionMouseUp {
            target?.performSelector(selector)
        }
    }
    
    func windowFocusChanged(notification: NSNotification) {
        needsDisplay = true
    }
    
}

class MVClockImageView: NSImageView {
    
    override func hitTest(aPoint: NSPoint) -> NSView? {
        return nil
    }
    
}