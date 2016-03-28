//
//  AppDelegate.swift
//  Timer
//
//  Created by Michael Villar on 3/27/16.
//  Copyright © 2016 Michael Villar. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
  var window: MVWindow!
  var mainView: MVMainView!
  var clockView: MVClockView!

  func applicationDidFinishLaunching(aNotification: NSNotification) {
    self.mainView = MVMainView(frame: NSZeroRect)
    
    self.clockView = MVClockView()
    self.mainView.addSubview(clockView)
    
    window = MVWindow(mainView: mainView)
    window.makeKeyAndOrderFront(self)
    
//    NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: true)
  }
  
  func applicationWillTerminate(aNotification: NSNotification) {
    // Insert code here to tear down your application
  }
  
  func handleTimer(timer: NSTimer) {
    self.clockView.minutes += 0.3
  }
  
  
}

