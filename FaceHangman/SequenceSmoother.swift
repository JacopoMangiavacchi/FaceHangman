//
//  SequenceSmoother.swift
//  FaceHangman
//
//  Created by Jacopo Mangiavacchi on 20/06/2017.
//  Copyright © 2017 Jacopo. All rights reserved.
//

import Foundation

struct SequenceSmoother<Element> {
    fileprivate var cache = [Element]()
    fileprivate var maxCacheSize = 5
    fileprivate var currentPos = 0
    
    init(cacheSize: Int = 5) {
            maxCacheSize = cacheSize
    }
    
    mutating func resetCache() {
        currentPos = 0
        cache = [Element]()
    }
    
    mutating func smooth(_ value: Element) -> Element {
        if cache.count < maxCacheSize {
            cache.append(value)
        }
        else {
            cache[currentPos] = value
        }
        
        currentPos = (currentPos + 1) % maxCacheSize
        
        //Return Average
        return value //cache.reduce(nil, +) / cache.count
    }
}
