//
//  SequenceSmoother.swift
//  FaceHangman
//
//  Created by Jacopo Mangiavacchi on 20/06/2017.
//  Copyright © 2017 Jacopo. All rights reserved.
//

import Foundation

struct SequenceSmoother<Element> {
    fileprivate var cache: [Element]!
    fileprivate var defaultValue: Element!
    var currentPos = 0
    
    init(defaultValue: Element, cacheSize: Int = 5) {
        self.defaultValue = defaultValue
        cache = Array(repeating: defaultValue, count: cacheSize)
    }
    
    mutating func resetCache() {
        currentPos = 0
        cache = Array(repeating: defaultValue, count: cache.count)
    }
    
    mutating func smooth(_ value: Element) -> Element {
        if currentPos == cache.count {
            //Scroll Cache Array Left
            for i in 0..<currentPos - 1 {
                cache[i] = cache[i+1]
            }
            cache[currentPos] = value
        }
        else {
            cache[currentPos] = value
            currentPos += 1
        }
        
        //Return Average
        return value  // Array(cache[0...currentPos]).reduce(defaultValue, +) / currentPos
    }
}
