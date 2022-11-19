//
//  KeyboardInputTraits.swift
//  RussianPhoneticKeyboard
//
//  Created by Alexei Baboulevitch on 11/1/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import Foundation
import QuartzCore
import UIKit

var traitPollingTimer: CADisplayLink?

extension KeyboardViewController {
    
    func addInputTraitsObservers() {
        traitPollingTimer?.invalidate()
        traitPollingTimer = UIScreen.main.displayLink(withTarget: self, selector: #selector(KeyboardViewController.pollTraits))
        traitPollingTimer?.add(to: RunLoop.current, forMode: RunLoop.Mode.default)
    }
    
    @objc func pollTraits() {
        let proxy = self.textDocumentProxy
        
        if let layout = self.layout {
            let appearanceIsDark = (proxy.keyboardAppearance == UIKeyboardAppearance.dark)
            if appearanceIsDark != layout.darkMode {
                self.updateAppearances(appearanceIsDark)
            }
        }
    }
}
