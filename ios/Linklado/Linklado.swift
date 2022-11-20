//
//  Catboard.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 9/24/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

class Linklado: KeyboardViewController {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func keyPressed(_ key: Key) {
        let textDocumentProxy = self.textDocumentProxy
        
        let keyOutput = key.outputForCase(self.shiftState.uppercase())
        
        if key.type == .character || key.type == .specialCharacter {
            if let context = textDocumentProxy.documentContextBeforeInput {
                if context.count < 2 {
                    textDocumentProxy.insertText(keyOutput)
                    return
                }
                
                var index = context.endIndex
                
                index = context.index(before: index)
                if context[index] != " " {
                    textDocumentProxy.insertText(keyOutput)
                    return
                }
                
                index = context.index(before: index)
                if context[index] == " " {
                    textDocumentProxy.insertText(keyOutput)
                    return
                }
                
                textDocumentProxy.insertText(keyOutput)
                return
            }
            else {
                textDocumentProxy.insertText(keyOutput)
                return
            }
        }
        else {
            textDocumentProxy.insertText(keyOutput)
            return
        }
    }
    
    override func createBanner() -> ExtraView? {
        return LinkladoBanner(globalColors: type(of: self).globalColors, darkMode: false, solidColorMode: self.solidColorMode())
    }
    
    class LinkladoBanner: ExtraView {
        
        var linkladoLabel: UILabel = UILabel()
        
        required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
            super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
            
            self.addSubview(self.linkladoLabel)
            
            self.linkladoLabel.frame.origin = CGPoint(x: self.linkladoLabel.frame.origin.x, y: self.linkladoLabel.frame.origin.y - 15)
            
            self.linkladoLabel.text = "Linklado!"
            
            self.linkladoLabel.sizeToFit()
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func setNeedsLayout() {
            super.setNeedsLayout()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()

            self.linkladoLabel.center = self.center
        }
    }
    
}
