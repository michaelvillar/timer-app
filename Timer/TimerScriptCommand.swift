import AppKit

final class TimerScriptCommand: NSScriptCommand {
  override func performDefaultImplementation() -> Any? {
    let command: String
    switch self.commandDescription.commandName {
    case "start timer":
      command = self.directParameter as? String ?? ""

    case "stop timer":
      command = "stop"

    case "reset timer":
      command = "reset"

    case "pause timer":
      command = "pause"

    case "new timer":
      command = "new"

    default:
      return nil
    }

    let window = self.evaluatedArguments?["window"] as? Int

    Task { @MainActor in
      guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { return }
      appDelegate.handleTimerCommand(command, window: window)
    }

    return nil
  }
}
