//
//  chords.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 4/7/21.
//

import Foundation

struct Interval {
    var bottom: String
    var top: String
    
    
    let baseNotes: [String: Int] = [
        "A": 0,
        "B": 1,
        "C": 2,
        "D": 3,
        "E": 4,
        "F": 5,
        "G": 6,
        "a": 0,
        "b": 1,
        "c": 2,
        "d": 3,
        "e": 4,
        "f": 5,
        "g": 6
    ]
    
    let baseDistDic: [Int: String] = [
        0: "1st",
        1: "2nd",
        2: "3rd",
        3: "4th",
        4: "5th",
        5: "6th",
        6: "7th"
    ]
    
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
    
    let notesArr: [String] = [
        "A###","B#", "C", "Dbb",
        "B##", "C#", "Db", "Ebbb",
        "B###", "C##", "D", "Ebb", "Fbbb",
        "C###", "D#", "Eb", "Fbb",
        "D##", "E", "Fb", "Gbbb",
        "E#", "F", "Gbb",
        "E##", "F#", "Gb", "Abbb",
        "E###", "F##", "G", "Abb",
        "F###", "G#", "Ab", "Bbbb",
        "G##", "A", "Bbb", "Cbbb",
        "G###", "A#", "Bb", "Cbb",
        "A##", "B", "Cb", "Dbbb"
    ]
    
    let dictInts: [Int: String] = [
        0: "Try Real Notes",
        1: "m2",
        2: "M2",
        3: "m3",
        4: "M3",
        5: "P4",
        6: "TT",
        7: "P5",
        8: "m6",
        9: "M6",
        10: "m7",
        11: "M7",
        12: "P8"
    ]
    
    let fancy: [String: Int] = [
        "dim2": 0,
        "m2": 1,
        "M2": 2,
        "aug2": 3,
        "doubaug2": 4,
        "doubdim3": 1,
        "dim3": 2,
        "m3": 3,
        "M3": 4,
        "aug3": 5,
        "doubaug3": 6,
        "doubdim4": 3,
        "dim4": 4,
        "P4": 5,
        "aug4": 6,
        "doubaug4": 7,
        "doubdim5": 5,
        "dim5": 6,
        "P5": 7,
        "aug5": 8,
        "doubaug5": 9,
        "doubdim6": 6,
        "dim6": 7,
        "m6": 8,
        "M6": 9,
        "aug6": 10,
        "doubaug6": 11,
        "doubdim7": 8,
        "dim7": 9,
        "m7": 10,
        "M7": 11,
        "aug7": 12,
        "doubaug7": 13
    ]
    
    
    func baseDist() -> String {
        var baseInt: Int = 0
        if bottom.count == 0 || top.count == 0 {
            return "Empty"
        }
        else {
            let botFirst = Array(bottom)[0]
            let topFirst = Array(top)[0]
                
                if baseNotes[String(botFirst)]! > baseNotes[String(topFirst)]! {
                    baseInt = baseNotes[String(botFirst)]! - (baseNotes[String(topFirst)]! + 7)
                }
                else if baseNotes[String(botFirst)]! == baseNotes[String(topFirst)]! {
                    return "P8"
                }
                else {
                    baseInt = baseNotes[String(botFirst)]! - baseNotes[String(topFirst)]!
                }
                return baseDistDic[abs(baseInt)]!
        }
    }
    
    func distance() -> Int {
        
        var dist: Int = 0
        let firstKey = notes[self.bottom] != nil
        let secondKey = notes[self.top] != nil
        
        if firstKey && secondKey {
            dist = notes[String(self.bottom).capitalized]! - notes[String(self.top).capitalized]!
        }
        
        else {
            return 0
        }
        
        if (dist < 0) {
            dist += 12
            dist = 12 - dist
        }
        else {
            dist = 12 - dist
        }
        
        return dist
    }
    
    func dToName() -> String {
        
        if !notesArr.contains(bottom) || !notesArr.contains(top) {
            return ""
        }
        
        let Second = [fancy["dim2"], fancy["m2"], fancy["M2"], fancy["aug2"], fancy["doubaug2"]]
        let Third = [fancy["doubdim3"], fancy["dim3"], fancy["m3"], fancy["M3"], fancy["aug3"], fancy["doubaug3"]]
        let Fourth = [fancy["doubdim4"], fancy["dim4"], fancy["P4"], fancy["aug4"], fancy["doubaug4"]]
        let Fifth = [fancy["doubdim5"], fancy["dim5"], fancy["P5"], fancy["P5"], fancy["aug5"], fancy["doubaug5"]]
        let Sixth = [fancy["doubdim6"], fancy["dim6"], fancy["m6"], fancy["M6"], fancy["aug6"], fancy["doubaug6"]]
        let Seventh = [fancy["doubdim7"], fancy["dim7"], fancy["m7"], fancy["M7"], fancy["aug7"],fancy["doubaug7"]]
        
        
        do {
            
            switch baseDist() {
                case "2nd":
                    for i in 0..<5 {
                        if (distance() == Second[i]){
                            if (Second[i] == 0){
                                return "Diminished 2nd"}
                            if (Second[i] == 1) {
                                return "m2"}
                            if (Second[i] == 2){
                                return "M2"}
                            if (Second[i] == 3){
                                return "Augmented 2nd"}
                            if (Second[i] == 4){
                                return "Doubly Augmented 2nd"}
                        }
                        else {
                            continue
                        }
                    }
                case "3rd":
                    for i in 0..<6 {
                            if (distance() == Third[i]!){
                                if (Third[i] == 1) {
                                    return "Doubly Diminished 3rd"}
                                if (Third[i] == 2){
                                    return "Diminished 3rd"}
                                if (Third[i] == 3){
                                    return "m3"}
                                if (Third[i] == 4){
                                    return "M3"}
                                if (Third[i] == 5){
                                    return "Augmented 3rd"}
                                if (Third[i] == 6){
                                    return "Doubly Augmented 3rd"}
                            }
                            else {
                                continue
                            }
                    }
                case "4th":
                    for i in 0..<5 {
                        if (distance() == Fourth[i]!){
                            if (Fourth[i] == 3){
                                return "Doubly Diminished 4th"}
                            if (Fourth[i] == 4){
                                return "Diminished 4th"}
                            if (Fourth[i] == 5){
                                return "P4"}
                            if (Fourth[i] == 6){
                                return "Augmented 4th"}
                            if (Fourth[i] == 7){
                                return "Doubly Augmented 4th"}
                        }
                        else {
                            continue
                        }
                    }
                case "5th":
                    for i in 0..<6 {
                        if (distance() == Fifth[i]!){
                            if (Fifth[i] == 5){
                                return "Doubly Diminished 5th"}
                            if (Fifth[i] == 6){
                                return "Diminished 5th"}
                            if (Fifth[i] == 7){
                                return "P5"}
                            if (Fifth[i] == 8){
                                return "Augmented 5th"}
                            if (Fifth[i] == 9){
                                return "Doubly Augmented 5th"}
                        }
                        else {
                            continue
                        }
                    }
                case "6th":
                    for  i in 0..<6 {
                        if (distance() == Sixth[i]!){
                            if (Sixth[i] == 6){
                                return "Doubly Diminished 6th"}
                            if (Sixth[i] == 7){
                                return "Diminished 6th"}
                            if (Sixth[i] == 8){
                                return "m6"}
                            if (Sixth[i] == 9){
                                return"M6"}
                            if (Sixth[i] == 10){
                                return "Augmented 6th"}
                            if (Sixth[i] == 11){
                                return "Doubly Augmented 6th"}
                        }
                        else {
                            continue
                        }
                    }
                case "7th":
                    for i in 0..<6 {
                            if (distance() == Seventh[i]!){
                                if (Seventh[i] == 8){
                                    return "Doubly Diminished 7th"}
                                if (Seventh[i] == 9){
                                    return"Diminished 7th"}
                                if (Seventh[i] == 10){
                                    return "m7"}
                                if (Seventh[i] == 11){
                                    return "M7"}
                                if (Seventh[i] == 12){
                                    return "Augmented 7th"}
                                if (Seventh[i] == 13){
                                    return "Doubly Augmented 7th"}
                            }
                            else {
                                continue
                            }
                    }
                case "P8":
                    return "P8"
                default:
                    return ""
                    
                }
        }
        return ""
    }
}
