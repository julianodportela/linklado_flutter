//
//  Utilities.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 10/22/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import Foundation
import UIKit

func memoize<T:Hashable, U>(_ fn : @escaping (T) -> U) -> (T) -> U {
    var cache = [T:U]()
    return {
        (val : T) -> U in
        let value = cache[val]
        if value != nil {
            return value!
        } else {
            let newValue = fn(val)
            cache[val] = newValue
            return newValue
        }
    }
}

var profile: ((_ id: String) -> Double?) = {
    var counterForName = Dictionary<String, Double>()
    var isOpen = Dictionary<String, Double>()
    
    return { (id: String) -> Double? in
        if let startTime = isOpen[id] {
            let diff = CACurrentMediaTime() - startTime
            if let currentCount = counterForName[id] {
                counterForName[id] = (currentCount + diff)
            }
            else {
                counterForName[id] = diff
            }
            
            isOpen[id] = nil
        }
        else {
            isOpen[id] = CACurrentMediaTime()
        }
        
        return counterForName[id]
    }
}()
