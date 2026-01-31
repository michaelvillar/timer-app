import Foundation

enum TimerLogic {

  private static let scaleOriginal: CGFloat = 6
  private static let scaleActual: CGFloat = 3

  // MARK: - Progress Scale Conversion

  static func convertProgressToScale(_ progress: CGFloat, minutes: CGFloat) -> CGFloat {
    if minutes <= 60 {
      if progress <= scaleOriginal / 60 {
        return progress / (scaleOriginal / scaleActual)
      } else {
        return (progress * 60 - scaleOriginal + scaleActual) / (60 - scaleActual)
      }
    }
    return progress
  }

  static func invertProgressToScale(_ progress: CGFloat, minutes: CGFloat) -> CGFloat {
    if minutes > 60 {
      return progress
    }

    if progress <= scaleActual / 60 {
      return progress * (scaleOriginal / scaleActual)
    } else {
      return (progress * (60 - scaleActual) - scaleActual + scaleOriginal) / 60
    }
  }

  // MARK: - Display Strings

  static func minutesDisplayString(seconds: CGFloat) -> String {
    if seconds < 60 {
      return NSString(format: "%i\"", Int(seconds)) as String
    } else {
      return NSString(format: "%i'", Int(floor(seconds / 60))) as String
    }
  }

  static func secondsDisplayString(seconds: CGFloat) -> String {
    if seconds < 60 {
      return ""
    } else {
      return NSString(format: "%i\"", Int(seconds.truncatingRemainder(dividingBy: 60))) as String
    }
  }

  static func badgeString(minutes: Int, seconds: Int) -> String {
    NSString(format: "%02d:%02d", minutes, seconds) as String
  }

  // MARK: - Keyboard Input

  struct DigitInputResult {
    let seconds: CGFloat
    let accepted: Bool
  }

  static func processDigitInput(
    digit: Int,
    currentSeconds: CGFloat,
    currentMinutes: CGFloat,
    totalSeconds: CGFloat,
    inputSeconds: Bool
  ) -> DigitInputResult {
    var newSeconds: CGFloat

    if inputSeconds {
      if currentSeconds < 6 || currentMinutes == 0 {
        newSeconds = currentMinutes * 60 + currentSeconds * 10 + CGFloat(digit)
      } else {
        newSeconds = totalSeconds
      }
    } else {
      newSeconds = currentMinutes * 600 + currentSeconds + CGFloat(digit) * 60
    }

    if newSeconds < 999 * 60 {
      return DigitInputResult(seconds: newSeconds, accepted: true)
    }
    return DigitInputResult(seconds: totalSeconds, accepted: false)
  }

  static func processBackspace(
    currentSeconds: CGFloat,
    currentMinutes: CGFloat,
    inputSeconds: Bool
  ) -> CGFloat {
    if inputSeconds {
      return currentMinutes * 60 + floor(currentSeconds / 10)
    } else {
      return floor(currentMinutes / 10) * 60 + currentSeconds
    }
  }

  // MARK: - Sound

  static func soundFilename(forIndex index: Int) -> String? {
    switch index {
    case -1:
      return nil

    case 0:
      return "alert-sound"

    case 1:
      return "alert-sound-2"

    case 2:
      return "alert-sound-3"

    default:
      return "alert-sound"
    }
  }
}
