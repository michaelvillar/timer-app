import Cocoa
import Preferences

final class GeneralPreferenceViewController: NSViewController, PreferencePane {
	let preferencePaneIdentifier = Preferences.PaneIdentifier.general
	let preferencePaneTitle = "General"
	let toolbarItemIcon = NSImage(named: NSImage.preferencesGeneralName)!

	override var nibName: NSNib.Name? { "GeneralPreferenceViewController" }

	override func viewDidLoad() {
		super.viewDidLoad()

		// Setup stuff here
	}
}
