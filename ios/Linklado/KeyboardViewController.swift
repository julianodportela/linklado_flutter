import UIKit

class KeyboardButton: UIButton {
    
    var defaultBackgroundColor: UIColor = .white
    var highlightBackgroundColor: UIColor = .lightGray
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = isHighlighted ? highlightBackgroundColor : defaultBackgroundColor
    }
    
    
}


// MARK: - Private Methods
private extension KeyboardButton {
    func commonInit() {
        layer.cornerRadius = 5.0
        layer.masksToBounds = false
        layer.shadowOffset = CGSize(width: 0, height: 1.0)
        layer.shadowRadius = 0.0
        layer.shadowOpacity = 0.35
    }
}

enum KBColorScheme {
    case dark
    case light
}

struct KBColors {
    
    let buttonTextColor: UIColor
    let buttonBackgroundColor: UIColor
    let buttonHighlightColor: UIColor
    let backgroundColor: UIColor
    let previewTextColor: UIColor
    let previewBackgroundColor: UIColor
    let buttonTintColor: UIColor
    
    init(colorScheme: KBColorScheme) {
        switch colorScheme {
        case .light:
            buttonTextColor = .black
            buttonTintColor = .black
            buttonBackgroundColor = .white
            buttonHighlightColor = UIColor(red: 174/255, green: 179/255, blue: 190/255, alpha: 1.0)
            backgroundColor = UIColor(red: 210/255, green: 213/255, blue: 219/255, alpha: 1.0)
            previewTextColor = .white
            previewBackgroundColor = UIColor(red: 186/255, green: 191/255, blue: 200/255, alpha: 1.0)
        case .dark:
            buttonTextColor = .white
            buttonTintColor = .white
            buttonBackgroundColor = UIColor(white: 138/255, alpha: 1.0)
            buttonHighlightColor = UIColor(white: 104/255, alpha: 1.0)
            backgroundColor = UIColor(white:89/255, alpha: 1.0)
            previewTextColor = .white
            previewBackgroundColor = UIColor(white: 80/255, alpha: 1.0)
        }
    }
    
}


//MARK: Color Constatnts

let containerPrimaryViewColor = UIColor.white
let containerSubViewBackgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)

extension UIView {
    
    /** This helps to add VisualForamt Constraints by reducing Duplications in CODE*/
    func addConstraintsWithFormatString(formate: String, views: UIView...) {
        
        var viewsDictionary = [String: UIView]()
        
        for (index, view) in views.enumerated() {
            
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: formate, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDictionary))
        
    }
    
    
    /**Sets border at bottom for the Views */
    func setBottomLineForView(borderColor: UIColor) {
        
        self.backgroundColor = UIColor.clear
        
        let borderLine = UIView()
        let height = 1.0
        borderLine.frame = CGRect(x: 0, y: Double(self.frame.height) - height, width: Double(self.frame.width), height: height)
        
        borderLine.backgroundColor = borderColor
        self.addSubview(borderLine)
    }
    
}


extension UIColor {
    
    /**This returns the RGB Color by taking Parameters Red, Green and Blue Values*/
    static func rgbColor(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        
        return UIColor.init(red: red/255, green: green/255, blue: blue/255, alpha: 1.0)
    }
    
    /**Gives Color from HEX Value, If there is more than 6 characters in HEX String, it returns "Magenta Color". If the HEX String is Correct, it returns it's Color*/
    static func colorFromHexValue(_ hex: String) -> UIColor {
        
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if hexString.hasPrefix("#") {
            
            hexString.remove(at: hexString.startIndex)
        }
        
        if hexString.count != 6 {
            
            return UIColor.magenta
        }
        
        var rgb: UInt32 = 0
        Scanner.init(string: hexString).scanHexInt32(&rgb)
        
        return UIColor.init(red: CGFloat((rgb & 0xFF0000) >> 16)/255,
                            green: CGFloat((rgb & 0x00FF00) >> 8)/255,
                            blue: CGFloat(rgb & 0x0000FF)/255,
                            alpha: 1.0)
    }
    
}


extension UIInputView: UIInputViewAudioFeedback {
    
    public var enableInputClicksWhenVisible: Bool {
        get {
            return true
        }
    }
    
    func playInputClick​() {
        UIDevice.current.playInputClick()
    }
    
}

extension String {
    
    var length : Int {
        get{
            return self.count
        }
    }
}



extension Notification.Name {
    
    static var containerShowAndHideNotification = Notification.Name.init("containerShowAndHideNotification")
    
    static var textProxyForContainer = Notification.Name.init("HandleContainerText")
    
    static var textProxyNilNotification = Notification.Name.init("TextProxyNilNotification")
    
    // For notifying From Child View Controllers
    
    static var childVCInformation = Notification.Name.init("ChildVC Information")

}


extension UIReturnKeyType {
    
    func get (rawValue: Int)-> String {
        
        switch self.rawValue {
        case UIReturnKeyType.default.rawValue:
            return "Return"
        case UIReturnKeyType.continue.rawValue:
            return "Continue"
        case UIReturnKeyType.google.rawValue:
            return "google"
        case UIReturnKeyType.done.rawValue:
            return "Done"
        case UIReturnKeyType.search.rawValue:
            return "Search"
        case UIReturnKeyType.join.rawValue:
            return "Join"
        case UIReturnKeyType.next.rawValue:
            return "Next"
        case UIReturnKeyType.emergencyCall.rawValue:
            return "Emg Call"
        case UIReturnKeyType.route.rawValue:
            return "Route"
        case UIReturnKeyType.send.rawValue:
            return "Send"
        case UIReturnKeyType.yahoo.rawValue:
            return "search"
            
        default:
            return "Default"
        }
        
    }
    
}



extension UIViewController {
    
//    /**Adds View controoler as a child view controller, on current View  */
//    func addViewControllerAsChildViewController(childViewController: UIViewController) {
//
//        addChildViewController(childViewController)
//        view.addSubview(childViewController.view)
//        childViewController.view.frame = CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height-225)
//        childViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        childViewController.didMove(toParentViewController: self)
//
//    }
//
//    /**Removes View controoler from  child view controller, on current View  */
//    func removeViewControllerAsChildViewController(childViewController: UIViewController) {
//
//        childViewController.willMove(toParentViewController: nil)
//        childViewController.view.removeFromSuperview()
//        childViewController.removeFromParentViewController()
//
//    }
    
    
}



class KeyboardViewController: UIInputViewController {
    

    var capButton: KeyboardButton!
    var numericButton: KeyboardButton!
    var deleteButton: KeyboardButton!
    var nextKeyboardButton: KeyboardButton!
    var returnButton: KeyboardButton!
    
    var isCapitalsShowing = false
    
    var areLettersShowing = true {
        
        didSet{
            
            if areLettersShowing {
                for view in mainStackView.arrangedSubviews {
                    view.removeFromSuperview()
                }
                self.addKeyboardButtons()
                
            }else{
                displayNumericKeys()
            }
            
        }
        
    }
    
    var allTextButtons = [KeyboardButton]()
    
    var keyboardHeight: CGFloat = 225
    var KeyboardVCHeightConstraint: NSLayoutConstraint!
    var containerViewHeight: CGFloat = 0
    
    var userLexicon: UILexicon?
    
    var notificationDictionary = [String: Any]()
    
    
    var currentWord: String? {
        var lastWord: String?
        // 1
        if let stringBeforeCursor = textDocumentProxy.documentContextBeforeInput {
            // 2
            stringBeforeCursor.enumerateSubstrings(in: stringBeforeCursor.startIndex...,
                                                   options: .byWords)
            { word, _, _, _ in
                // 3
                if let word = word {
                    lastWord = word
                }
            }
        }
        return lastWord
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addKeyboardButtons()
        self.setNextKeyboardVisible(needsInputModeSwitchKey)
        self.KeyboardVCHeightConstraint = NSLayoutConstraint(item: self.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: keyboardHeight+containerViewHeight)
        self.view.addConstraint(self.KeyboardVCHeightConstraint)
        self.requestSupplementaryLexicon { (lexicon) in
            self.userLexicon = lexicon
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.removeConstraint(KeyboardVCHeightConstraint)
        self.view.addConstraint(self.KeyboardVCHeightConstraint)
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        // Add custom view sizing constraints here
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        let colorScheme: KBColorScheme
        if textDocumentProxy.keyboardAppearance == .dark {
            colorScheme = .dark
        } else {
            colorScheme = .light
        }
        self.setColorScheme(colorScheme)
    }
    
    //Handles NextKeyBoard Button Appearance..
    
    func setNextKeyboardVisible(_ visible: Bool) {
        nextKeyboardButton.isHidden = !visible
    }
    
    //Set color scheme For keyboard appearance...
    func setColorScheme(_ colorScheme: KBColorScheme) {
        
        let themeColor = KBColors(colorScheme: colorScheme)
    
        self.capButton.defaultBackgroundColor = themeColor.buttonHighlightColor
        self.deleteButton.defaultBackgroundColor = themeColor.buttonHighlightColor
        self.numericButton.defaultBackgroundColor = themeColor.buttonHighlightColor
        self.nextKeyboardButton.defaultBackgroundColor = themeColor.buttonHighlightColor
        self.returnButton.defaultBackgroundColor = themeColor.buttonHighlightColor
        
        self.capButton.highlightBackgroundColor = themeColor.buttonBackgroundColor
        self.deleteButton.highlightBackgroundColor = themeColor.buttonBackgroundColor
        self.nextKeyboardButton.highlightBackgroundColor = themeColor.buttonBackgroundColor
        self.returnButton.highlightBackgroundColor = themeColor.buttonBackgroundColor
        self.numericButton.highlightBackgroundColor = themeColor.buttonBackgroundColor
        
        for button in allTextButtons {
            button.tintColor = themeColor.buttonTintColor
            button.defaultBackgroundColor = themeColor.buttonBackgroundColor
            button.highlightBackgroundColor = themeColor.buttonHighlightColor
            button.setTitleColor(themeColor.buttonTextColor, for: .normal)
            
        }
    
    }
    
    var mainStackView: UIStackView!
    
    private func addKeyboardButtons() {
        //My Custom Keys...
        
        let firstRowView = addRowsOnKeyboard(kbKeys: ["q","w","e","r","t","y","u","ʉ", "i","ɨ","o","p"])
        let secondRowView = addRowsOnKeyboard(kbKeys: ["a","s","d","f","g","h","j","k","l", "'"])
                
        let thirdRowkeysView = addRowsOnKeyboard(kbKeys: ["z","x","c","v","b","n","ñ","m"])
                
        let fourthRowkeysView = addRowsOnKeyboard(kbKeys: ["̃","̂","́","̀","̈","ç"])
                
        let (fourthRowSV,fifthRowSV) = serveiceKeys(midRow: fourthRowkeysView)
                
                // Add Row Views on Keyboard View... With a Single Stack View..
                
        self.mainStackView = UIStackView(arrangedSubviews: [firstRowView,secondRowView,thirdRowkeysView,fourthRowSV,fifthRowSV])
        mainStackView.axis = .vertical
        mainStackView.spacing = 3.0
        mainStackView.distribution = .fillEqually
        mainStackView.alignment = .fill
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStackView)
        
        mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 2).isActive = true
        mainStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 2).isActive = true
        mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -2).isActive = true
        mainStackView.heightAnchor.constraint(equalToConstant: keyboardHeight).isActive = true

    }
    
    func serveiceKeys(midRow: UIView)->(UIStackView, UIStackView) {
        self.capButton = accessoryButtons(title: nil, img: #imageLiteral(resourceName: "captial1"), tag: 1)
        self.deleteButton = accessoryButtons(title: nil, img: #imageLiteral(resourceName: "backspace"), tag: 2)
        
        let thirdRowSV = UIStackView(arrangedSubviews: [self.capButton,midRow,self.deleteButton])
        thirdRowSV.distribution = .fillProportionally
        thirdRowSV.spacing = 5
        
        self.numericButton = accessoryButtons(title: "123", img: nil, tag: 3)
        self.nextKeyboardButton = accessoryButtons(title: nil, img: #imageLiteral(resourceName: "globe"), tag: 4)
        let spaceKey = accessoryButtons(title: "space", img: nil, tag: 6)
        self.returnButton = accessoryButtons(title: "return", img: nil, tag: 7)
        
        let fourthRowSV = UIStackView(arrangedSubviews: [self.numericButton,self.nextKeyboardButton,spaceKey,self.returnButton])
        fourthRowSV.distribution = .fillProportionally
        fourthRowSV.spacing = 4
        
        return (thirdRowSV,fourthRowSV)
    }
    
    
    // Adding Keys on UIView with UIStack View..
    func addRowsOnKeyboard(kbKeys: [String]) -> UIView {
        
        let RowStackView = UIStackView.init()
        RowStackView.spacing = 5
        RowStackView.axis = .horizontal
        RowStackView.alignment = .fill
        RowStackView.distribution = .fillEqually
        
        for key in kbKeys {
            RowStackView.addArrangedSubview(createButtonWithTitle(title: key))
        }
        
        let keysView = UIView()
        keysView.backgroundColor = .clear
        keysView.addSubview(RowStackView)
        keysView.addConstraintsWithFormatString(formate: "H:|[v0]|", views: RowStackView)
        keysView.addConstraintsWithFormatString(formate: "V:|[v0]|", views: RowStackView)
        return keysView
    }

    // Creates Buttons on Keyboard...
    func createButtonWithTitle(title: String) -> KeyboardButton {
        
        let button = KeyboardButton(type: .system)
        button.setTitle(title, for: .normal)
        button.sizeToFit()
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapButton(sender:)), for: .touchUpInside)
        allTextButtons.append(button)
        
        return button
    }
    
    @objc func didTapButton(sender: UIButton) {
        
        let button = sender as UIButton
        guard let title = button.titleLabel?.text else { return }
        let proxy = self.textDocumentProxy
        
        UIView.animate(withDuration: 0.25, animations: {
            button.transform = CGAffineTransform(scaleX: 1.20, y: 1.20)
            self.inputView?.playInputClick​()
            proxy.insertText(title)
            
        }) { (_) in
            UIView.animate(withDuration: 0.10, animations: {
                button.transform = CGAffineTransform.identity
            })
        }
        
    }
    
    func accessoryButtons(title: String?, img: UIImage?, tag: Int) -> KeyboardButton {
        
        let button = KeyboardButton.init(type: .system)
        
        if let buttonTitle = title {
            button.setTitle(buttonTitle, for: .normal)
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        }
        
        if let buttonImage = img {
            button.setImage(buttonImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
       
        button.sizeToFit()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = tag
        
        //For Capitals...
        if button.tag == 1 {
            button.addTarget(self, action: #selector(handleCapitalsAndLowerCase(sender:)), for: .touchUpInside)
            button.widthAnchor.constraint(equalToConstant: 45).isActive = true
            return button
        }
        //For BackDelete Key // Install Once Only..
        if button.tag == 2 {
            let longPrssRcngr = UILongPressGestureRecognizer.init(target: self, action: #selector(onLongPressOfBackSpaceKey(longGestr:)))
            
            //if !(button.gestureRecognizers?.contains(longPrssRcngr))! {
            longPrssRcngr.minimumPressDuration = 0.5
            longPrssRcngr.numberOfTouchesRequired = 1
            longPrssRcngr.allowableMovement = 0.1
            button.addGestureRecognizer(longPrssRcngr)
            //}
            button.widthAnchor.constraint(equalToConstant: 45).isActive = true
        }
        //Switch to and From Letters & Numeric Keys
        if button.tag == 3 {
            button.addTarget(self, action: #selector(handleSwitchingNumericsAndLetters(sender:)), for: .touchUpInside)
            button.widthAnchor.constraint(equalToConstant: 50).isActive = true

            return button
        }
        //Next Keyboard Button... Globe Button Usually...
        if button.tag == 4 {
            button.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
            button.widthAnchor.constraint(equalToConstant: 50).isActive = true

            return button
        }        //White Space Button...
        if button.tag == 6 {

            button.addTarget(self, action: #selector(insertWhiteSpace), for: .touchUpInside)
            button.widthAnchor.constraint(equalToConstant: 250).isActive = true

            return button
        }
        //Handle return Button...//Usually depends on Texyfiled'd return Type...
        if button.tag == 7 {
            button.addTarget(self, action: #selector(handleReturnKey(sender:)), for: .touchUpInside)
            return button
        }
        //Else Case... For Others
        button.addTarget(self, action: #selector(manualAction(sender:)), for: .touchUpInside)
        return button
        
    }
    
    @objc func onLongPressOfBackSpaceKey(longGestr: UILongPressGestureRecognizer) {
        
        switch longGestr.state {
        case .began:
            self.textDocumentProxy.deleteBackward()
            
        case .ended:
            print("Ended")
            return
        default:
            self.textDocumentProxy.deleteBackward()
            //deleteLastWord()
        }
        
    }
    
    @objc func handleCapitalsAndLowerCase(sender: UIButton) {
        for button in allTextButtons {
            
            if let title = button.currentTitle {
                button.setTitle(isCapitalsShowing ? title.lowercased() : title.uppercased(), for: .normal)
            }
        }
        isCapitalsShowing = !isCapitalsShowing
    }
    
    @objc func handleSwitchingNumericsAndLetters(sender: UIButton) {
        
        areLettersShowing = !areLettersShowing
        print("Switching To and From Numeric and Alphabets")
    }
    
    @objc func insertWhiteSpace() {
        
        attemptToReplaceCurrentWord()
        let proxy = self.textDocumentProxy
        proxy.insertText(" ")
        print("white space")
    }
    
    @objc func handleReturnKey(sender: UIButton) {
//        if let _ = self.textDocumentProxy.documentContextBeforeInput {
             self.textDocumentProxy.insertText("\n")
//        }
       
       // print("Return Type is handled here...")
    }
    
    
    @objc func manualAction(sender: UIButton) {
        let proxy = self.textDocumentProxy
        
        proxy.deleteBackward()
        print("Else Case... Remaining Keys")
    }
    
    func displayNumericKeys() {
        
        for view in mainStackView.arrangedSubviews {
            view.removeFromSuperview()
        }
        
        let nums = ["1","2","3","4","5","6","7","8","9","0"]
        let splChars1 = ["-","/",":",";","(",")","$","&","@","*"]
        let splChars2 = [".",",","?","!","#"]
        
        let numsRow = self.addRowsOnKeyboard(kbKeys: nums)
        let splChars1Row = self.addRowsOnKeyboard(kbKeys: splChars1)
        let splChars2Row = self.addRowsOnKeyboard(kbKeys: splChars2)

         let (thirdRowSV,fourthRowSV) = serveiceKeys(midRow: splChars2Row)
        
        mainStackView.addArrangedSubview(numsRow)
        mainStackView.addArrangedSubview(splChars1Row)
        mainStackView.addArrangedSubview(thirdRowSV)
        mainStackView.addArrangedSubview(fourthRowSV)

    }
    
    
    
}


private extension KeyboardViewController {
    func attemptToReplaceCurrentWord() {
        // 1
        guard let entries = userLexicon?.entries,
            let currentWord = currentWord?.lowercased() else {
                return
        }
        
        // 2
        let replacementEntries = entries.filter {
            $0.userInput.lowercased() == currentWord
        }
        
        if let replacement = replacementEntries.first {
            // 3
            for _ in 0..<currentWord.count {
                textDocumentProxy.deleteBackward()
            }
            
            // 4
            textDocumentProxy.insertText(replacement.documentText)
        }
    }
}
