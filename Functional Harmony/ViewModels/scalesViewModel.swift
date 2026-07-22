//
//  triadAnsViewModel.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 4/12/21.
//

import Foundation

class scalesViewModel: ObservableObject {
    @Published var root: String = ""
    @Published var major = true
    @Published var minorNat = false
    @Published var minorHarm = false
    @Published var minorMel = false
    @Published var pentatonic = false
    @Published var wholeTone = false
    @Published var octatonic = false
    @Published var hexatonic = false
    @Published var dorian = false
    @Published var phrygian = false
    @Published var lydian = false
    @Published var mixo = false
    @Published var locrian = false
    @Published var dorB2 = false
    @Published var lydianAug = false
    @Published var lydDom = false
    @Published var mixoB6 = false
    @Published var locNat2 = false
    @Published var supLoc = false
    
    func resetButtons() -> Void {
        major = false
        minorNat = false
        minorHarm = false
        minorMel = false
        pentatonic = false
        wholeTone = false
        octatonic = false
        hexatonic = false
        dorian = false
        phrygian = false
        lydian = false
        mixo = false
        locrian = false
        dorB2 = false
        lydianAug = false
        lydDom = false
        mixoB6 = false
        locNat2 = false
        supLoc = false
    }
    
    func quality() -> Array<String> {
        var two = "M2"
        var three = "M3"
        var four = "P4"
        var five = "P5"
        var six = "M6"
        var sev = "M7"
        var eight = "P8"
        var nine = "P8"
        
        if major {
            two = "M2"
            three = "M3"
            four = "P4"
            five = "P5"
            six = "M6"
            sev = "M7"
            eight = "P8"
            return [two, three, four, five, six, sev, eight]
        }
        else if minorNat {
            two = "M2"
            three = "m3"
            four = "P4"
            five = "P5"
            six = "m6"
            sev = "m7"
            eight = "P8"
            return [two, three, four, five, six, sev, eight]
        }
        else if minorHarm {
            two = "M2"
            three = "m3"
            four = "P4"
            five = "P5"
            six = "m6"
            sev = "M7"
            eight = "P8"
            return [two, three, four, five, six, sev, eight]
        }
        else if minorMel {
            two = "M2"
            three = "m3"
            four = "P4"
            five = "P5"
            six = "M6"
            sev = "M7"
            eight = "P8"
            return [two, three, four, five, six, sev, eight]
        }
        else if pentatonic {
            two = "M2"
            three = "M3"
            four = "P4"
            five = "P5"
            six = "M6"
            sev = "M7"
            eight = "P8"
            return [two, three, four, five, six, sev, eight]
        }
        else if wholeTone {
            two = "M2"
            three = "M3"
            four = "Augmented 4th"
            five = "Augmented 5th"
            six = "Augmented 6th"
            sev = "P8"
            return [two, three, four, five, six, sev, "", ""]
        }
        else if octatonic {
            two = "M2"
            three = "m3"
            four = "P4"
            five = "Augmented 4th"
            six = "Augmented 5th"
            sev = "M6"
            eight = "M7"
            nine = "P8"
            return [two, three, four, five, six, sev, eight, nine]
        }
        else if dorian {
            two = "M2"
            three = "m3"
            four = "P4"
            five = "P5"
            six = "M6"
            sev = "m7"
            eight = "P8"
            return [two, three, four, five, six, sev, eight]
        }
        else if phrygian {
            two = "m2"
            three = "m3"
            four = "P4"
            five = "P5"
            six = "m6"
            sev = "m7"
            eight = "P8"
            return [two, three, four, five, six, sev, eight]
        }
        else if lydian {
            two = "M2"
            three = "M3"
            four = "Augmented 4th"
            five = "P5"
            six = "M6"
            sev = "M7"
            eight = "P8"
            return [two, three, four, five, six, sev, eight]
        }
        else if mixo {
            two = "M2"
            three = "M3"
            four = "P4"
            five = "P5"
            six = "M6"
            sev = "m7"
            eight = "P8"
            return [two, three, four, five, six, sev, eight]
        }
        else if locrian {
            two = "m2"
            three = "m3"
            four = "P4"
            five = "Diminished 5th"
            six = "m6"
            sev = "m7"
            eight = "P8"
            return [two, three, four, five, six, sev, eight]
        }
        else if dorB2 {
            two = "m2"
            three = "m3"
            four = "P4"
            five = "P5"
            six = "M6"
            sev = "m7"
            eight = "P8"
            return [two, three, four, five, six, sev, eight]
        }
        else if lydianAug {
            two = "M2"
            three = "M3"
            four = "Augmented 4th"
            five = "Augmented 5th"
            six = "M6"
            sev = "M7"
            eight = "P8"
            return [two, three, four, five, six, sev, eight]
        }
        else if lydDom {
            two = "M2"
            three = "M3"
            four = "Augmented 4th"
            five = "P5"
            six = "M6"
            sev = "m7"
            eight = "P8"
            return [two, three, four, five, six, sev, eight]
        }
        else if mixoB6 {
            two = "M2"
            three = "M3"
            four = "P4"
            five = "P5"
            six = "m6"
            sev = "m7"
            eight = "P8"
            return [two, three, four, five, six, sev, eight]
        }
        else if locNat2 {
            two = "M2"
            three = "m3"
            four = "P4"
            five = "Diminished 5th"
            six = "m6"
            sev = "m7"
            eight = "P8"
            return [two, three, four, five, six, sev, eight]
        }
        else if supLoc {
            two = "m2"
            three = "m3"
            four = "Diminished 4th"
            five = "Diminished 5th"
            six = "m6"
            sev = "m7"
            eight = "P8"
            return [two, three, four, five, six, sev, eight]
        }
        return [two, three, four, five, six, sev, eight]
    }
    func two() -> String {
        return scalesBuildModel(root: root, two: quality()[0], three: quality()[1], four: quality()[2], five: quality()[3], six: quality()[4], sev: quality()[5], eight: quality()[6]).findTwo()
    }
    func three() -> String {
        return scalesBuildModel(root: root, two: quality()[0], three: quality()[1], four: quality()[2], five: quality()[3], six: quality()[4], sev: quality()[5], eight: quality()[6]).findThree()
    }
    func four() -> String {
        return scalesBuildModel(root: root, two: quality()[0], three: quality()[1], four: quality()[2], five: quality()[3], six: quality()[4], sev: quality()[5], eight: quality()[6]).findFour()
    }
    func five() -> String {
        return scalesBuildModel(root: root, two: quality()[0], three: quality()[1], four: quality()[2], five: quality()[3], six: quality()[4], sev: quality()[5], eight: quality()[6]).findFive()
    }
    func six() -> String {
        return scalesBuildModel(root: root, two: quality()[0], three: quality()[1], four: quality()[2], five: quality()[3], six: quality()[4], sev: quality()[5], eight: quality()[6]).findSix()
    }
    func sev() -> String {
        return scalesBuildModel(root: root, two: quality()[0], three: quality()[1], four: quality()[2], five: quality()[3], six: quality()[4], sev: quality()[5], eight: quality()[6]).findSev()
    }
    func eight() -> String {
        return scalesBuildModel(root: root, two: quality()[0], three: quality()[1], four: quality()[2], five: quality()[3], six: quality()[4], sev: quality()[5], eight: quality()[6]).findEight()
    }
    func octFive() -> String {
        return scalesBuildModel(root: root, two: quality()[0], three: quality()[1], four: quality()[2], five: quality()[3], six: quality()[4], sev: quality()[5], eight: quality()[6], nine: quality()[7]).findOctFive()
    }
    func octSix() -> String {
        return scalesBuildModel(root: root, two: quality()[0], three: quality()[1], four: quality()[2], five: quality()[3], six: quality()[4], sev: quality()[4], eight: quality()[5], nine: quality()[6]).findOctSix()
    }
    func octSev() -> String {
        return scalesBuildModel(root: root, two: quality()[0], three: quality()[1], four: quality()[2], five: quality()[3], six: quality()[4], sev: quality()[5], eight: quality()[6], nine: quality()[7]).findOctSev()
    }
    func octEight() -> String {
        return scalesBuildModel(root: root, two: quality()[0], three: quality()[1], four: quality()[2], five: quality()[3], six: quality()[4], sev: quality()[5], eight: quality()[6], nine: quality()[7]).findOctEight()
    }
    
    func returnRoot() -> String {
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
    
        if !notesArr.contains(root) {
            return ""
        }
        else {
            return root
        }
    }
}
