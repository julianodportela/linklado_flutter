import UIKit

// MARK: - Keyboard controller

class Linklado: UIInputViewController {

    // ── Key colors using semantic system colors ───────────────────────────────
    // Using UIColor system semantics means iOS handles dark/light automatically
    // without any hardcoded values. keyboardAppearance is checked first because
    // some text fields force a specific keyboard style regardless of system mode.

    // Native iOS keyboard uses specific grays in dark mode — systemBackground is
    // near-black there, which erases key contrast against the keyboard background.
    private var cKeyNormal:  UIColor { isDark ? UIColor(white: 0.41, alpha: 1) : .white }
    private var cKeyAction:  UIColor { isDark ? UIColor(white: 0.20, alpha: 1) : UIColor(white: 0.68, alpha: 1) }
    private var cKeySpecial: UIColor {
        isDark
            ? UIColor(red: 0.32, green: 0.24, blue: 0.46, alpha: 1)
            : UIColor(red: 0.82, green: 0.76, blue: 0.95, alpha: 1)
    }
    private var cPressed:    UIColor { isDark ? UIColor(white: 0.55, alpha: 1) : .systemGray5 }
    private var cText:       UIColor { .label }
    private var cSubtext:    UIColor { .secondaryLabel }

    private var isDark: Bool {
        // Prefer the text field's explicit keyboard appearance over the system setting.
        switch textDocumentProxy.keyboardAppearance {
        case .dark:  return true
        case .light: return false
        default:
            if #available(iOS 12.0, *) { return traitCollection.userInterfaceStyle == .dark }
            return false
        }
    }

    // ── Spacing constants ─────────────────────────────────────────────────────

    private let keyGap:      CGFloat = 6   // gap between keys in a row
    private let rowEdgePad:  CGFloat = 4   // horizontal padding of each row
    private let keyTopPad:   CGFloat = 4   // key top inset within row
    private let keyBotPad:   CGFloat = 5   // key bottom inset (extra 1px for shadow)

    // ── State ─────────────────────────────────────────────────────────────────

    private enum ShiftState { case off, on, locked }
    private enum Layer      { case letters, numbers, symbols }

    private var shiftState      = ShiftState.off
    private var lastShiftTapTime: Date?           // for double-tap → caps lock detection
    private var currentLayer    = Layer.letters
    private var heightConstraint: NSLayoutConstraint?

    // ── Popup state ───────────────────────────────────────────────────────────

    private var popupWindowView: UIView?
    private var popupView:            UIView?
    private var popupCells:           [UIView] = []
    private var popupAlts:            [String] = []
    private var popupHighlighted:     Int      = 0
    private var popupCellBgNormal:    UIColor  = .clear
    private var popupCellBgHighlight: UIColor  = .clear

    // Captured in touchesBegan so handleInputModeList can receive a real UIEvent
    private var lastTouchEvent: UIEvent?

    private var backspaceTimer: Timer?
    private var longPressTimer: Timer?

    // ── Maps ──────────────────────────────────────────────────────────────────

    private let combiningMap: [String: String] = [
        "~": "\u{0303}", "´": "\u{0301}", "`": "\u{0300}", "^": "\u{0302}",
        "¨": "\u{0308}", "¯": "\u{0304}", "˙": "\u{0307}", "ˇ": "\u{030C}",
    ]

    private let longPressMap: [String: [String]] = [
        "a": ["á","à","â","ã","ä","ā","ă","æ"],
        "e": ["é","è","ê","ẽ","ë","ē","ə","\u{0259}\u{0303}"],          // ə̃
        "i": ["í","ì","î","ĩ","ï","ī"],
        "o": ["ó","ò","ô","õ","ö","ō"],
        "u": ["ú","ù","û","ũ","ü","\u{00FC}\u{0303}","ǘ","ǜ","ū"],     // ü̃
        "y": ["ỹ","ỳ","ý"],
        "ɛ": ["\u{025B}\u{0303}","\u{025B}\u{0301}","\u{025B}\u{0300}","Ɛ","ə","æ"], // ɛ̃ ɛ́ ɛ̀
        "ɔ": ["\u{0254}\u{0303}","\u{0254}\u{0301}","\u{0254}\u{0300}","Ɔ"],          // ɔ̃ ɔ́ ɔ̀
        "ɨ": ["\u{0268}\u{0303}","\u{0268}\u{0301}","\u{0268}\u{0300}","Ɨ"],          // ɨ̃ ɨ́ ɨ̀
        "ʉ": ["\u{0289}\u{0303}","\u{0289}\u{0301}","\u{0289}\u{0300}","\u{0289}\u{0308}","Ʉ"], // ʉ̃ ʉ́ ʉ̀ ʉ̈
        "ñ": ["Ñ"],
        "ç": ["Ç"],
        "ŋ": ["Ŋ"],
        "ɲ": ["Ɲ"],
        "n": ["ŋ","ɲ"],
        "c": ["ç"],
        "g": ["\u{0067}\u{0303}"],  // g̃
        "s": ["ß"],
        "~": ["^","¨","¯","˙","ˇ","`"],
        "´": ["`","^","¨","¯","˙","ˇ"],
        ".": [":","…","·"],
        ",": [";","«","»"],
        "'": ["\u{2018}","\u{2019}"],
        "\"": ["\u{201C}","\u{201D}","«","»"],
        "-": ["–","—"],
        "?": ["¿"],
        "!": ["¡"],
        "/": ["\\","|"],
        "(": ["[","{","<"],
        ")": ["]","}",">"],
        "[": ["{","<"],
        "]": ["}",">"],
        "1": ["¹","½","¼"],
        "2": ["²","⅔"],
        "3": ["³","¾"],
        "0": ["°","∞"],
        "@": ["©","®","™"],
        "$": ["£","¥","€","¢","₩"],
        "&": ["§"],
        "+": ["±"],
        "=": ["≠","≈","≤","≥"],
        "%": ["‰"],
        "€": ["£","¥","¢","₩","$"],
        "£": ["€","¥","¢","₩"],
        "•": ["·","‣","◦"],
        "_": ["—","–"],
    ]

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do not set a custom background. UIInputViewController's view sits inside
        // the system keyboard window. On iOS 26 that window composites UIGlassEffect
        // at the window level, so any UIBlurEffect we add creates a double-blur that
        // makes the keyboard look different from the native chrome bars.
        // Leaving backgroundColor as nil lets the system handle the keyboard backdrop.

        let hc = view.heightAnchor.constraint(equalToConstant: keyboardHeight())
        hc.priority = UILayoutPriority(999)
        hc.isActive = true
        heightConstraint = hc

        buildKeyboard()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        heightConstraint?.constant = keyboardHeight()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 12.0, *) {
            guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        }
        buildKeyboard()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchEvent = event
        super.touchesBegan(touches, with: event)
    }

    override func textWillChange(_ textInput: UITextInput?) {}
    override func textDidChange(_ textInput: UITextInput?) {}

    // ── Height ────────────────────────────────────────────────────────────────

    private func rowCount() -> Int {
        switch currentLayer {
        case .letters: return 5
        case .numbers, .symbols: return 4
        }
    }
    private func keyboardHeight() -> CGFloat {
        // Gives the system a height hint. topPad(8) + rows + botPad(2) + safe area.
        return CGFloat(rowCount()) * 54 + 10 + bottomInset()
    }
    private func bottomInset() -> CGFloat { view.safeAreaInsets.bottom }

    // ── Build ─────────────────────────────────────────────────────────────────

    private func buildKeyboard() {
        view.subviews.forEach { $0.removeFromSuperview() }
        // Resize to fit the exact number of rows for this layer
        heightConstraint?.constant = keyboardHeight()
        switch currentLayer {
        case .letters: buildLetters(in: view)
        case .numbers: buildNumbers(in: view)
        case .symbols: buildSymbols(in: view)
        }
    }

    // ── Layers ────────────────────────────────────────────────────────────────

    private func buildLetters(in parent: UIView) {
        let up = shiftState != .off
        func s(_ v: String) -> String {
            guard up, v.count == 1, let c = v.unicodeScalars.first,
                  CharacterSet.letters.contains(c) else { return v }
            return v.uppercased()
        }
        layoutRows([
            [.char(s("q")), .char(s("w")), .char(s("e")), .char(s("r")),
             .char(s("t")), .char(s("y")), .char(s("u")), .char(s("ʉ"), sp: true),
             .char(s("i")), .char(s("ɨ"), sp: true), .char(s("o")), .char(s("p"))],
            [.char(s("a")), .char(s("s")), .char(s("d")), .char(s("f")),
             .char(s("g")), .char(s("h")), .char(s("j")), .char(s("k")),
             .char(s("l")), .char(s("'"))],
            [.shift(wt: 1.5), .char(s("z")), .char(s("x")), .char(s("c")), .char(s("v")),
             .char(s("b")), .char(s("n")), .char(s("ñ"), sp: true), .char(s("m")),
             .backspace(wt: 1.5)],
            [.char(s("ɛ"), sp: true), .char(s("ɔ"), sp: true), .char(s("ŋ"), sp: true),
             .char(s("ç"), sp: true), .char("ʔ", sp: true), .char("ʼ", sp: true),
             .char("~", sp: true), .char("´", sp: true)],
            [.action("123", wt: 1.5), .globe, .space(wt: 5), .returnKey(wt: 1.5)],
        ], in: parent)
    }

    private func buildNumbers(in parent: UIView) {
        layoutRows([
            ["1","2","3","4","5","6","7","8","9","0"].map { .char($0) },
            ["-","/",":",";","(",")","$","&","@","\""].map { .char($0) },
            [.action("#+=", wt: 1.5), .char("."), .char(","), .char("?"), .char("!"),
             .char("'"), .backspace(wt: 1.5)],
            [.action("ABC", wt: 1.5), .space(wt: 5), .returnKey(wt: 1.5)],
        ], in: parent)
    }

    private func buildSymbols(in parent: UIView) {
        layoutRows([
            ["[","]","{","}","#","%","^","*","+","="].map { .char($0) },
            ["_","\\","|","~","<",">","€","£","¥","•"].map { .char($0) },
            [.action("123", wt: 1.5), .char("."), .char(","), .char("!"), .char("?"),
             .char("'"), .backspace(wt: 1.5)],
            [.action("ABC", wt: 1.5), .space(wt: 5), .returnKey(wt: 1.5)],
        ], in: parent)
    }

    // ── Layout engine ─────────────────────────────────────────────────────────

    private indirect enum KeySpec {
        case char(String, sp: Bool = false, wt: CGFloat = 1)
        case shift(wt: CGFloat = 1.5)
        case backspace(wt: CGFloat = 1.5)
        case space(wt: CGFloat)
        case returnKey(wt: CGFloat = 1.5)
        case action(String, wt: CGFloat = 1.5)
        case globe

        var weight: CGFloat {
            switch self {
            case .char(_, _, let w):  return w
            case .shift(let w):       return w
            case .backspace(let w):   return w
            case .space(let w):       return w
            case .returnKey(let w):   return w
            case .action(_, let w):   return w
            case .globe:              return 1
            }
        }
    }

    // Pins the first row to the top and the last row to the bottom, with equal-height
    // rows filling the space between. This fills whatever height the system grants the
    // keyboard view, eliminating any gap that would appear if we used a fixed row height.
    private func layoutRows(_ rows: [[KeySpec]], in parent: UIView) {
        guard !rows.isEmpty else { return }
        let topPad: CGFloat = 8
        let botPad: CGFloat = bottomInset() + 2
        var rowViews: [UIView] = []

        for row in rows {
            let rv = UIView()
            rv.backgroundColor = .clear
            rv.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(rv)
            NSLayoutConstraint.activate([
                rv.leadingAnchor.constraint(equalTo: parent.leadingAnchor,   constant:  rowEdgePad),
                rv.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -rowEdgePad),
            ])
            buildRowKeys(row, in: rv)
            rowViews.append(rv)
        }

        let n = rowViews.count
        // Top of first row touches the top of the keyboard
        rowViews[0].topAnchor.constraint(equalTo: parent.topAnchor, constant: topPad).isActive = true
        // Bottom of last row touches the bottom of the keyboard (above safe area)
        rowViews[n-1].bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -botPad).isActive = true
        // Stack rows consecutively; all rows share the same height
        for i in 0..<(n-1) {
            rowViews[i+1].topAnchor.constraint(equalTo: rowViews[i].bottomAnchor).isActive = true
            rowViews[i+1].heightAnchor.constraint(equalTo: rowViews[0].heightAnchor).isActive = true
        }
    }

    // Proportional width formula:
    //   width_i = (rowWidth - totalGap) × weight_i / totalWeight
    //           = rowWidth × (weight_i/totalWeight) - totalGap × (weight_i/totalWeight)
    // This distributes gap space proportionally so every inter-key gap is exactly keyGap.
    private func buildRowKeys(_ specs: [KeySpec], in rv: UIView) {
        let n           = specs.count
        let totalWeight = specs.reduce(0) { $0 + $1.weight }
        let totalGap    = CGFloat(n - 1) * keyGap   // (N-1) gaps between N keys
        var prevTrail: NSLayoutXAxisAnchor = rv.leadingAnchor

        for (i, spec) in specs.enumerated() {
            let kv = makeKey(spec)
            rv.addSubview(kv)
            NSLayoutConstraint.activate([
                kv.topAnchor.constraint(equalTo: rv.topAnchor, constant: keyTopPad),
                kv.bottomAnchor.constraint(equalTo: rv.bottomAnchor, constant: -keyBotPad),
                kv.leadingAnchor.constraint(equalTo: prevTrail, constant: i == 0 ? 0 : keyGap),
                kv.widthAnchor.constraint(
                    equalTo: rv.widthAnchor,
                    multiplier: spec.weight / totalWeight,
                    constant: -(totalGap * spec.weight / totalWeight)
                ),
            ])
            prevTrail = kv.trailingAnchor
        }
    }

    private func makeKey(_ spec: KeySpec) -> UIView {
        switch spec {
        case .char(let l, let sp, _): return charKey(label: l, special: sp)
        case .shift:                  return shiftKey()
        case .backspace:              return backspaceKey()
        case .space:                  return spaceKey()
        case .returnKey:              return returnKeyView()
        case .action(let l, _):       return actionKey(label: l)
        case .globe:                  return globeKey()
        }
    }

    // ── Individual key builders ───────────────────────────────────────────────

    private func charKey(label: String, special: Bool) -> UIView {
        let bg  = special ? cKeySpecial : cKeyNormal
        let lbl = keyLabel(label, size: 18, color: cText)
        let v   = keyView(bg: bg, shadow: true)
        v.addSubview(lbl); pin(lbl, to: v)

        let alts = longPressMap[label.lowercased()] ?? longPressMap[label]
        assoc(v, bg: bg, label: label, alts: alts, type: "char")
        attachGesture(to: v)
        return v
    }

    private func shiftKey() -> UIView {
        let (sym, bg) = shiftLook()
        let icon = sfSymbol(sym, size: 17, color: cText)
        let v    = keyView(bg: bg, shadow: false)
        v.addSubview(icon); pin(icon, to: v)
        assoc(v, bg: bg, type: "shift")
        attachGesture(to: v)
        return v
    }

    private func backspaceKey() -> UIView {
        let icon = sfSymbol("delete.left", size: 17, color: cText)
        let v    = keyView(bg: cKeyAction, shadow: false)
        v.addSubview(icon); pin(icon, to: v)
        assoc(v, bg: cKeyAction, type: "backspace")
        attachGesture(to: v)
        return v
    }

    private func spaceKey() -> UIView {
        let v = keyView(bg: cKeyNormal, shadow: true)

        let mainLbl = keyLabel("espaço", size: 13, color: cSubtext)
        v.addSubview(mainLbl)
        NSLayoutConstraint.activate([
            mainLbl.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            mainLbl.centerYAnchor.constraint(equalTo: v.centerYAnchor),
        ])

        let brandLbl = keyLabel("linklado", size: 8, color: cSubtext)
        v.addSubview(brandLbl)
        NSLayoutConstraint.activate([
            brandLbl.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            brandLbl.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -3),
        ])

        assoc(v, bg: cKeyNormal, type: "space")
        attachGesture(to: v)
        return v
    }

    private func returnKeyView() -> UIView {
        let icon = sfSymbol("return", size: 17, color: cText)
        let v    = keyView(bg: cKeyAction, shadow: false)
        v.addSubview(icon); pin(icon, to: v)
        assoc(v, bg: cKeyAction, type: "return")
        attachGesture(to: v)
        return v
    }

    private func globeKey() -> UIView {
        let icon = sfSymbol("face.smiling", size: 17, color: cText)
        let v    = keyView(bg: cKeyAction, shadow: false)
        v.addSubview(icon); pin(icon, to: v)
        assoc(v, bg: cKeyAction, type: "globe")
        attachGesture(to: v)
        return v
    }

    private func actionKey(label: String) -> UIView {
        let lbl = keyLabel(label, size: 13, color: cText)
        let v   = keyView(bg: cKeyAction, shadow: false)
        v.addSubview(lbl); pin(lbl, to: v)
        assoc(v, bg: cKeyAction, type: "action", actionLabel: label)
        attachGesture(to: v)
        return v
    }

    private func attachGesture(to v: UIView) {
        let g = UILongPressGestureRecognizer(target: self, action: #selector(handleKeyGesture(_:)))
        g.minimumPressDuration = 0
        g.allowableMovement    = 9999
        v.addGestureRecognizer(g)
    }

    // ── UI factories ──────────────────────────────────────────────────────────

    private func keyView(bg: UIColor, shadow: Bool) -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor    = bg
        v.layer.cornerRadius = 10
        v.layer.masksToBounds = false
        if shadow {
            v.layer.shadowColor   = UIColor.black.cgColor
            v.layer.shadowOffset  = CGSize(width: 0, height: 1.5)
            v.layer.shadowRadius  = 1.5
            v.layer.shadowOpacity = isDark ? 0.45 : 0.28
        }
        return v
    }

    private func keyLabel(_ text: String, size: CGFloat, color: UIColor) -> UILabel {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text          = text
        l.font          = UIFont.systemFont(ofSize: size, weight: .regular)
        l.textColor     = color
        l.textAlignment = .center
        l.isUserInteractionEnabled = false
        return l
    }

    private func pin(_ child: UIView, to parent: UIView) {
        NSLayoutConstraint.activate([
            child.centerXAnchor.constraint(equalTo: parent.centerXAnchor),
            child.centerYAnchor.constraint(equalTo: parent.centerYAnchor),
        ])
    }

    // Returns the SF Symbol name and background for the current shift state.
    // Native iOS: off=gray+outline, on=white+filled, locked=gray+capslock icon (never blue).
    private func shiftLook() -> (String, UIColor) {
        switch shiftState {
        case .off:    return ("shift",         cKeyAction)
        case .on:     return ("shift.fill",    cKeyNormal)
        case .locked: return ("capslock.fill", cKeyAction)
        }
    }

    // Creates a UIImageView using an SF Symbol, falling back to a text label.
    private func sfSymbol(_ name: String, size: CGFloat, color: UIColor) -> UIView {
        let cfg = UIImage.SymbolConfiguration(pointSize: size, weight: .regular)
        if let img = UIImage(systemName: name, withConfiguration: cfg) {
            let iv = UIImageView(image: img)
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.tintColor = color
            iv.contentMode = .scaleAspectFit
            iv.isUserInteractionEnabled = false
            return iv
        }
        return keyLabel(name, size: size, color: color)
    }

    // ── Associated-object helpers ─────────────────────────────────────────────

    private func assoc(_ v: UIView,
                       bg:          UIColor,
                       label:       String?   = nil,
                       alts:        [String]? = nil,
                       type:        String,
                       actionLabel: String?   = nil) {
        objc_setAssociatedObject(v, &AK.bg,   bg,          .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(v, &AK.type, type,        .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        if let l = label       { objc_setAssociatedObject(v, &AK.label, l,  .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        if let a = alts        { objc_setAssociatedObject(v, &AK.alts,  a,  .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        if let al = actionLabel { objc_setAssociatedObject(v, &AK.act,  al, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private func getType(_ v: UIView) -> String?  { objc_getAssociatedObject(v, &AK.type)  as? String  }
    private func getBg(_ v: UIView)   -> UIColor? { objc_getAssociatedObject(v, &AK.bg)    as? UIColor }
    private func getLabel(_ v: UIView) -> String? { objc_getAssociatedObject(v, &AK.label) as? String  }
    private func getAlts(_ v: UIView) -> [String]?{ objc_getAssociatedObject(v, &AK.alts)  as? [String]}
    private func getAct(_ v: UIView)  -> String?  { objc_getAssociatedObject(v, &AK.act)   as? String  }

    // ── Gesture handler ───────────────────────────────────────────────────────

    @objc private func handleKeyGesture(_ g: UILongPressGestureRecognizer) {
        guard let v = g.view, let type = getType(v), let bg = getBg(v) else { return }

        switch g.state {

        case .began:
            v.backgroundColor = cPressed

            if type == "char", let alts = getAlts(v), !alts.isEmpty {
                longPressTimer?.invalidate()
                longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.36, repeats: false) { [weak self] _ in
                    self?.showPopup(alts: alts, anchor: v)
                }
            } else if type == "backspace" {
                handleBackspace()
                backspaceTimer?.invalidate()
                backspaceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                    self?.backspaceTimer = Timer.scheduledTimer(withTimeInterval: 0.045, repeats: true) { [weak self] _ in
                        self?.handleBackspace()
                    }
                }
            }

        case .changed:
            if popupView != nil { updatePopupHover(at: g.location(in: view)) }

        case .ended:
            longPressTimer?.invalidate(); longPressTimer = nil
            v.backgroundColor = bg

            if type == "backspace" {
                backspaceTimer?.invalidate(); backspaceTimer = nil
                return
            }
            if popupView != nil { commitAndDismissPopup(); return }

            switch type {
            case "char":
                if let label = getLabel(v) { handleChar(label) }
            case "shift":
                let now = Date()
                let isDoubleTap = lastShiftTapTime.map { now.timeIntervalSince($0) < 0.4 } ?? false
                lastShiftTapTime = now
                switch shiftState {
                case .off:
                    shiftState = .on
                case .on:
                    // Quick second tap → caps lock; slow second tap → cancel shift
                    shiftState = isDoubleTap ? .locked : .off
                case .locked:
                    shiftState = .off
                }
                buildKeyboard()
            case "space":   textDocumentProxy.insertText(" ")
            case "return":  textDocumentProxy.insertText("\n")
            case "globe":
                if let event = lastTouchEvent {
                    handleInputModeList(from: v, with: event)
                } else {
                    advanceToNextInputMode()
                }
            case "action":
                switch getAct(v) {
                case "123":  currentLayer = .numbers; buildKeyboard()
                case "#+=":  currentLayer = .symbols; buildKeyboard()
                case "ABC":  currentLayer = .letters; buildKeyboard()
                default: break
                }
            default: break
            }

        case .cancelled, .failed:
            longPressTimer?.invalidate();  longPressTimer  = nil
            backspaceTimer?.invalidate();  backspaceTimer  = nil
            v.backgroundColor = bg
            dismissPopup()

        default: break
        }
    }

    // ── Text input ────────────────────────────────────────────────────────────

    private func handleChar(_ raw: String) {
        if currentLayer == .letters, let c = combiningMap[raw] {
            textDocumentProxy.insertText(c); return
        }
        textDocumentProxy.insertText(applyShift(raw))
        autoDownShift()
    }

    private func applyShift(_ raw: String) -> String {
        // Only shift single-scalar letters. Multi-scalar strings (e.g. ü̃ = U+00FC+U+0303)
        // are already the intended character and must not be transformed.
        guard shiftState != .off, raw.unicodeScalars.count == 1,
              let s = raw.unicodeScalars.first,
              CharacterSet.letters.contains(s) else { return raw }
        return raw.uppercased()
    }

    private func autoDownShift() {
        if shiftState == .on { shiftState = .off; buildKeyboard() }
    }

    private func handleBackspace() { textDocumentProxy.deleteBackward() }

    // ── Popup ─────────────────────────────────────────────────────────────────

    private func showPopup(alts: [String], anchor: UIView) {
        dismissPopup()
        guard !alts.isEmpty else { return }

        // When shift is active, uppercase the alts for display and output.
        // Special cases:
        //   • "ß" has no conventional uppercase — keep as-is ("SS" via .uppercased() is wrong)
        //   • Characters that are already accessible as direct keyboard keys in shifted state
        //     are redundant in the popup and must be removed.
        let shiftOn = shiftState != .off
        let shifted: [String] = shiftOn
            ? alts.map { $0 == "ß" ? "ß" : $0.uppercased() }
            : alts

        // Characters that are standalone keys when shift is ON — showing in popup is redundant.
        let redundantWhenShifted: Set<String> = ["Ɛ","Ɔ","Ŋ","Ç","Ɨ","Ʉ","Ñ"]
        // Characters that are standalone keys when shift is OFF — showing in popup is redundant.
        let redundantWhenUnshifted: Set<String> = ["ŋ","ç"]
        let filtered: [String]
        if shiftOn {
            filtered = shifted.filter { !redundantWhenShifted.contains($0) }
        } else {
            filtered = shifted.filter { !redundantWhenUnshifted.contains($0) }
        }

        var seen = Set<String>()
        let uniqueAlts = filtered.filter { seen.insert($0).inserted }
        guard !uniqueAlts.isEmpty else { return }

        let cellW:   CGFloat = 44
        let cellH:   CGFloat = 44
        let cellGap: CGFloat = 6
        let pad:     CGFloat = 8
        let screenW  = UIScreen.main.bounds.width

        let maxCols = max(1, Int((screenW - 2*pad + cellGap) / (cellW + cellGap)))
        let rows    = uniqueAlts.chunked(into: maxCols)
        let ncols   = min(maxCols, uniqueAlts.count)
        let innerW  = CGFloat(ncols)*cellW + CGFloat(ncols-1)*cellGap
        let totalW  = innerW + 2*pad
        let totalH  = CGFloat(rows.count)*cellH + CGFloat(rows.count-1)*cellGap + 2*pad

        let wrapper = UIView()
        wrapper.backgroundColor     = .clear
        wrapper.layer.masksToBounds = false
        wrapper.layer.shadowColor   = UIColor.black.cgColor
        wrapper.layer.shadowOpacity = isDark ? 0.45 : 0.22
        wrapper.layer.shadowRadius  = 10
        wrapper.layer.shadowOffset  = CGSize(width: 0, height: 3)

        let blurStyle: UIBlurEffect.Style = isDark ? .systemMaterialDark : .systemMaterialLight
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        blurView.frame              = CGRect(origin: .zero, size: CGSize(width: totalW, height: totalH))
        blurView.layer.cornerRadius = 14
        blurView.clipsToBounds      = true
        wrapper.addSubview(blurView)

        let contentView = blurView.contentView
        let cellBgNormal:    UIColor = .clear
        let cellBgHighlight: UIColor = isDark
            ? UIColor.white.withAlphaComponent(0.22)
            : UIColor.white.withAlphaComponent(0.70)
        var allCells: [UIView] = []

        for (r, rowLabels) in rows.enumerated() {
            let rowInnerW = CGFloat(rowLabels.count)*cellW + CGFloat(rowLabels.count-1)*cellGap
            let rowStartX = pad + (innerW - rowInnerW)/2
            let rowY      = pad + CGFloat(r)*(cellH+cellGap)
            for (c, lbl) in rowLabels.enumerated() {
                let cellX = rowStartX + CGFloat(c)*(cellW+cellGap)
                let cell  = UIView(frame: CGRect(x: cellX, y: rowY, width: cellW, height: cellH))
                cell.backgroundColor    = cellBgNormal
                cell.layer.cornerRadius = 10
                let label = UILabel(frame: cell.bounds)
                label.text = lbl; label.font = .systemFont(ofSize: 19)
                label.textColor = cText; label.textAlignment = .center
                cell.addSubview(label)
                contentView.addSubview(cell)
                allCells.append(cell)
            }
        }
        popupCellBgNormal    = cellBgNormal
        popupCellBgHighlight = cellBgHighlight

        // Walk to the topmost superview and disable clipping on every ancestor so the
        // popup can render outside the keyboard view's own bounds.
        var container: UIView = view
        while let sv = container.superview { sv.clipsToBounds = false; container = sv }
        view.clipsToBounds = false

        // Position in the topmost container's coordinate space.
        // Use anchor.convert(_, to: container) — stays entirely within the view hierarchy,
        // no window-space arithmetic needed.
        let anchorFrame = anchor.convert(anchor.bounds, to: container)
        let containerW  = container.bounds.width > 0 ? container.bounds.width : screenW

        var popX = anchorFrame.midX - totalW/2
        popX = max(4, min(popX, containerW - totalW - 4))
        // Prefer above the key. If that would go outside the keyboard window's bounds
        // (negative Y), the compositor clips it — show below the key instead.
        let aboveY = anchorFrame.minY - totalH - 6
        let popY   = aboveY >= 0 ? aboveY : anchorFrame.maxY + 6

        wrapper.frame = CGRect(x: popX, y: popY, width: totalW, height: totalH)
        container.addSubview(wrapper)

        popupWindowView  = wrapper
        popupView        = contentView
        popupCells       = allCells
        popupAlts        = uniqueAlts   // already shifted — inserted directly without re-shifting
        popupHighlighted = 0
        highlightCell(0)
    }

    private func updatePopupHover(at point: CGPoint) {
        guard !popupCells.isEmpty, let pv = popupView else { return }
        // All views share the same window — direct coordinate conversion.
        let local = view.convert(point, to: pv)
        for (i, cell) in popupCells.enumerated() {
            if cell.frame.contains(local) {
                if i != popupHighlighted { highlightCell(i) }
                return
            }
        }
        var best = popupHighlighted, bestD = CGFloat.infinity
        for (i, cell) in popupCells.enumerated() {
            let d = hypot(local.x - cell.frame.midX, local.y - cell.frame.midY)
            if d < bestD { bestD = d; best = i }
        }
        if best != popupHighlighted { highlightCell(best) }
    }

    private func highlightCell(_ idx: Int) {
        for (i, cell) in popupCells.enumerated() {
            cell.backgroundColor = (i == idx) ? popupCellBgHighlight : popupCellBgNormal
        }
        popupHighlighted = idx
    }

    private func commitAndDismissPopup() {
        if popupHighlighted < popupAlts.count { handleChar(popupAlts[popupHighlighted]) }
        dismissPopup()
    }

    private func dismissPopup() {
        popupWindowView?.removeFromSuperview(); popupWindowView = nil
        popupView = nil; popupCells = []; popupAlts = []
        popupHighlighted = 0; popupCellBgNormal = .clear; popupCellBgHighlight = .clear
    }
}

// MARK: - Associated-object key store

private enum AK {
    static var bg    = "bg"
    static var label = "lbl"
    static var alts  = "alts"
    static var type  = "type"
    static var act   = "act"
}

// MARK: - Array chunk helper

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
