//
//  ChordIntervalModel.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 4/16/21.
//

import Foundation

struct ChordIntervalModel {
    var botInt: String
    var topInt: String
    
    let triadNames = [
        "M3": ["M3": "Augmented",
               "m3": "Major"],
        "m3": ["M3": "Minor",
               "m3": "Diminished"]
    ]
    
    func returnName() -> String {
        
        for (key, _) in triadNames {
            
            if botInt == key {
                for (key2, _) in triadNames[key]! {
                    if topInt == key2 {
                        return (triadNames[key]?[key2])!
                    }
                }
            }
        }
        return " DUNNO BRO"
    }
}
