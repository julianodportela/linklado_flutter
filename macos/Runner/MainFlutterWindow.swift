import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSPanel {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        self.contentViewController = flutterViewController

        self.setContentSize(NSSize(width: 310, height: 200))
        self.center()

        // nonactivatingPanel prevents this window from stealing focus when clicked.
        // The target app stays frontmost and its text field stays focused.
        self.styleMask = [.nonactivatingPanel, .titled, .closable, .miniaturizable]
        self.level = .floating
        self.isFloatingPanel = true
        self.becomesKeyOnlyIfNeeded = false
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.title = "Linklado"

        let appDelegate = NSApp.delegate as? AppDelegate
        appDelegate?.mainPanel = self
        appDelegate?.setupChannel(
            binaryMessenger: flutterViewController.engine.binaryMessenger
        )

        RegisterGeneratedPlugins(registry: flutterViewController)
        super.awakeFromNib()
    }

    // Never become key so clicks never steal focus from the user's text field.
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
