//
//  scalesBuildModel.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 4/17/21.
//

import Foundation

struct scalesBuildModel {
    
    var root: String
    var two: String
    var three: String
    var four: String
    var five: String
    var six: String
    var sev: String?
    var eight: String?
    var nine: String?
    
    let notes: [String: Int] = [
        "A###": 0,"B#": 0, "C":0, "Dbb": 0,
        "B##": 1, "C#": 1, "Db": 1, "Ebbb": 1,
        "B###": 2, "C##": 2, "D": 2, "Ebb": 2, "Fbbb": 2,
        "C###": 3, "D#": 3, "Eb": 3, "Fbb": 3,
        "D##": 4, "E": 4, "Fb": 4, "Gbbb":4,
        "E#": 5, "F": 5, "Gbb": 5,
        "E##": 6, "F#": 6, "Gb": 6, "Abbb": 6,
        "F##": 7, "G": 7, "Abb": 7,
        "F###": 8, "G#": 8, "Ab": 8, "Bbbb": 8,
        "G##": 9, "A": 9, "Bbb": 9, "Cbbb": 9,
        "G###": 10, "A#": 10, "Bb": 10, "Cbb":10,
        "A##": 11, "B": 11, "Cb": 11, "Dbbb":11,
        "a###": 0,"b#": 0, "c":0, "dbb": 0,
        "b##": 1, "c#": 1, "db": 1, "ebbb": 1,
        "b###": 2, "c##": 2, "d": 2, "ebb": 2, "fbbb": 2,
        "c###": 3, "d#": 3, "eb": 3, "fbb": 3,
        "d##": 4, "e": 4, "fb": 4, "gbbb":4,
        "e#": 5, "f": 5, "gbb": 5,
        "e##": 6, "f#": 6, "gb": 6, "abbb": 6,
        "f##": 7, "g": 7, "abb": 7,
        "f###": 8, "g#": 8, "ab": 8, "bbbb": 8,
        "g##": 9, "a": 9, "bbb": 9, "cbbb": 9,
        "g###": 10, "a#": 10, "bb": 10, "cbb":10,
        "a##": 11, "b": 11, "cb": 11, "dbbb":11
    ]
    
    func findTwo() -> String {
        
        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == two  && tempInt.baseDist() == "2nd" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        else {
            return ""
        }
    }
    
    func findThree() -> String {
        
        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == three  && tempInt.baseDist() == "3rd" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        else {
            return ""
        }
    }
    
    func findFour() -> String {
    
        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == four  && tempInt.baseDist() == "4th" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        else {
            return ""
        }
    }
    
    
    func findFive() -> String {
        
        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == five  && tempInt.baseDist() == "5th" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        else {
            return ""
        }
    }
    
    func findSix() -> String {
        
        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == six  && tempInt.baseDist() == "6th" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        else {
            return ""
        }
    }
    
    func findSev() -> String {
        
        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == sev  && tempInt.baseDist() == "7th" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        return ""
    }
    func findEight() -> String {
        
        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == sev  && tempInt.baseDist() == "7th" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        return ""
    }
    func findNine() -> String {
        
        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == eight  && tempInt.baseDist() == "P8" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        return ""
    }
    func findOctFive() -> String {
        
        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == five  && tempInt.baseDist() == "4th" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        return ""
    }
    func findOctSix() -> String {
        
        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == six  && tempInt.baseDist() == "5th" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        return ""
    }
    func findOctSev() -> String {
        
        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == sev  && tempInt.baseDist() == "6th" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        return ""
    }
    func findOctEight() -> String {
        
        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == eight  && tempInt.baseDist() == "7th" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        return ""
    }
}
