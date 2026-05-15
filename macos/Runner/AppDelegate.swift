import Cocoa
import FlutterMacOS
import CoreGraphics

@main
class AppDelegate: FlutterAppDelegate {

    // Strong reference — weak would let the channel be deallocated after setupChannel
    // returns, silently breaking all invokeMethod calls from Swift to Flutter.
    private var channel: FlutterMethodChannel?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var tapHealthTimer: Timer?
    weak var mainPanel: NSPanel?

    override func applicationDidFinishLaunching(_ notification: Notification) {
        super.applicationDidFinishLaunching(notification)
        // .accessory after super so Flutter doesn't override it.
        // Required on macOS 15 — .prohibited activation policy causes tapCreate to return nil.
        NSApp.setActivationPolicy(.accessory)
        requestAccessibilityIfNeeded()
        startModifierMonitor()
    }

    private func startModifierMonitor() {
        guard eventTap == nil, AXIsProcessTrusted() else { return }

        let mask: CGEventMask = 1 << CGEventType.flagsChanged.rawValue
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        // .defaultTap requires only Accessibility (which we have).
        // .listenOnly would require Input Monitoring, which can't be granted for ad-hoc builds.
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: modifierTapCallback,
            userInfo: selfPtr
        ) else { return }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        // CGEventTap can be silently disabled after sleep/wake or re-signing.
        tapHealthTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self, let tap = self.eventTap else { return }
            if !CGEvent.tapIsEnabled(tap: tap) {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
        }
    }

    fileprivate func handleFlagsChanged(_ event: CGEvent) {
        let shifted = event.flags.contains(.maskShift) || event.flags.contains(.maskAlphaShift)
        channel?.invokeMethod("shiftChanged", arguments: shifted)
    }

    fileprivate func reenableTap() {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
    }

    func setupChannel(binaryMessenger: FlutterBinaryMessenger) {
        let ch = FlutterMethodChannel(
            name: "com.linklado/keyboard",
            binaryMessenger: binaryMessenger
        )
        self.channel = ch
        ch.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "typeCharacter":
                if let char = call.arguments as? String {
                    self?.typeCharacter(char, result: result)
                } else {
                    result(nil)
                }
            case "checkAccessibility":
                let trusted = AXIsProcessTrusted()
                if trusted { self?.startModifierMonitor() }
                result(trusted)
            case "requestAccessibility":
                self?.openAccessibilitySettings()
                result(nil)
            case "restartApp":
                self?.relaunchApp()
                result(nil)
            case "setWindowSize":
                if let args = call.arguments as? [String: Any],
                   let w = args["width"] as? Double,
                   let h = args["height"] as? Double {
                    DispatchQueue.main.async {
                        guard let panel = self?.mainPanel else { return }
                        var frame = panel.frame
                        frame.origin.y += frame.size.height - h
                        frame.size = NSSize(width: w, height: h)
                        panel.setFrame(frame, display: true, animate: false)
                    }
                }
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        // Start monitor here too in case it was called before Accessibility was granted.
        startModifierMonitor()
    }

    func requestAccessibilityIfNeeded() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func relaunchApp() {
        let path = Bundle.main.bundlePath
        Process.launchedProcess(launchPath: "/bin/sh", arguments: ["-c", "sleep 0.5 && open \"\(path)\""])
        NSApp.terminate(nil)
    }

    private func typeCharacter(_ text: String, result: @escaping FlutterResult) {
        guard let target = NSWorkspace.shared.frontmostApplication,
              target.bundleIdentifier != Bundle.main.bundleIdentifier else {
            result(nil)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.sendUnicode(text, to: target.processIdentifier)
            result(nil)
        }
    }

    private func sendUnicode(_ text: String, to pid: pid_t) {
        let src = CGEventSource(stateID: .combinedSessionState)
        src?.setLocalEventsFilterDuringSuppressionState(
            [.permitLocalMouseEvents, .permitLocalKeyboardEvents, .permitSystemDefinedEvents],
            state: .eventSuppressionStateSuppressionInterval
        )
        var utf16 = Array(text.utf16)
        let keyCode = CGKeyCode(0xFF)

        let dn = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)
        dn?.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
        dn?.postToPid(pid)

        let up = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
        up?.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
        up?.postToPid(pid)
    }

    override func applicationWillTerminate(_ notification: Notification) {
        tapHealthTimer?.invalidate()
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let src = runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes) }
    }

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

// CGEventTapCallBack must be a file-scope function — cannot capture Swift context.
private func modifierTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let ptr = userInfo else { return Unmanaged.passRetained(event) }
    let delegate = Unmanaged<AppDelegate>.fromOpaque(ptr).takeUnretainedValue()
    switch type {
    case .flagsChanged:
        delegate.handleFlagsChanged(event)
    case .tapDisabledByTimeout, .tapDisabledByUserInput:
        delegate.reenableTap()
    default:
        break
    }
    // .defaultTap requires returning the event (passRetained transfers ownership back).
    return Unmanaged.passRetained(event)
}
