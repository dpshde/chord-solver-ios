//
//  triadAnsViewModel.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 4/12/21.
//

import Foundation

class triadBuildViewModel: ObservableObject {
    @Published var root: String = ""
    @Published var major = true
    @Published var minor = false
    @Published var aug = false
    @Published var dim = false
    @Published var MM7 = false
    @Published var Mm7 = false
    @Published var mM7 = false
    @Published var mm7 = false
    @Published var hd7 = false
    @Published var fd7 = false
    @Published var gerA6 = false
    @Published var itA6 = false
    @Published var frA6 = false
    @Published var ct7 = false
    @Published var sus2 = false
    @Published var sus4 = false

    
    func resetButtons() -> Void {
        major = false
        minor = false
        aug = false
        dim = false
        MM7 = false
        Mm7 = false
        mM7 = false
        mm7 = false
        hd7 = false
        fd7 = false
        gerA6 = false
        itA6 = false
        frA6 = false
        ct7 = false
        sus2 = false
        sus4 = false
    }
    
    func quality() -> Array<String> {
        var botTemp = "M3"
        var midTemp = "P5"
        var topTemp = "m3"
        
        if major {
            botTemp = "M3"
            topTemp = "P5"
            return [botTemp, topTemp]
        }
        else if minor {
            botTemp = "m3"
            topTemp = "P5"
            return [botTemp, topTemp]
        }
        else if aug {
            botTemp = "M3"
            topTemp = "Augmented 5th"
            return [botTemp, topTemp]
        }
        else if dim {
            botTemp = "m3"
            topTemp = "Diminished 5th"
            return [botTemp, topTemp]
        }
        else if MM7 {
            botTemp = "M3"
            midTemp = "P5"
            topTemp = "M7"
            return [botTemp, midTemp, topTemp]
        }
        else if Mm7 {
            botTemp = "M3"
            midTemp = "P5"
            topTemp = "m7"
            return [botTemp, midTemp, topTemp]
        }
        else if mm7 {
            botTemp = "m3"
            midTemp = "P5"
            topTemp = "m7"
            return [botTemp, midTemp, topTemp]
        }
        else if hd7 {
            botTemp = "m3"
            midTemp = "Diminished 5th"
            topTemp = "m7"
            return [botTemp, midTemp, topTemp]
        }
        else if fd7 {
            botTemp = "m3"
            midTemp = "Diminished 5th"
            topTemp = "Diminished 7th"
            return [botTemp, midTemp, topTemp]
        }
        else if itA6 {
            botTemp = "m6"
            midTemp = "Augmented 4th"
            topTemp = "Augmented 4th"
            return [botTemp, midTemp, topTemp]
        }
        else if gerA6 {
            botTemp = "m6"
            midTemp = "Augmented 4th"
            topTemp = "m3"
            return [botTemp, midTemp, topTemp]
        }
        else if frA6 {
            botTemp = "m6"
            midTemp = "Augmented 4th"
            topTemp = "M2"
            return [botTemp, midTemp, topTemp]
        }
        else if ct7 {
            botTemp = "Augmented 2nd"
            midTemp = "Augmented 4th"
            topTemp = "M6"
            return [botTemp, midTemp, topTemp]
        }
        else if mM7 {
            botTemp = "m3"
            midTemp = "P5"
            topTemp = "M7"
            return [botTemp, midTemp, topTemp]
        }
        else if sus2 {
            // Empty slot keeps legacy index layout used by sus2nd()/sus2fifth().
            botTemp = "M2"
            topTemp = "P5"
            return ["", botTemp, topTemp]
        }
        else if sus4 {
            botTemp = "P4"
            topTemp = "P5"
            return ["", botTemp, topTemp]
        }
        
        
        return [botTemp , topTemp]
    }

    // MARK: - Interval formula (for UI)

    /// Intervals above the root that build this chord, in compact theory labels.
    /// Example: Major → `["M3", "P5"]`, Dominant 7 → `["M3", "P5", "m7"]`.
    func chordIntervalsFromRoot() -> [String] {
        quality()
            .filter { !$0.isEmpty }
            .map(Self.compactIntervalLabel)
    }

    /// Full stack including the root as `R`, e.g. `["R", "M3", "P5"]`.
    func chordIntervalStack() -> [String] {
        ["R"] + chordIntervalsFromRoot()
    }

    /// Display string: `R · M3 · P5 · m7`
    func chordIntervalFormula() -> String {
        chordIntervalStack().joined(separator: "  ·  ")
    }

    /// Map long quality() strings to compact interval symbols for the UI.
    static func compactIntervalLabel(_ raw: String) -> String {
        switch raw {
        case "Augmented 5th": return "A5"
        case "Diminished 5th": return "d5"
        case "Diminished 7th": return "d7"
        case "Augmented 4th": return "A4"
        case "Augmented 2nd": return "A2"
        case "Augmented 3rd": return "A3"
        default: return raw
        }
    }
    
    func sus2nd() -> String {
        return triadBuild(root: root, botInt: quality()[0], midInt: quality()[1], topInt: quality()[2]).find2nd()
    }
    
    func sus2fifth() -> String {
        return triadBuild(root: root, botInt: quality()[1], midInt: quality()[2], topInt: quality()[2]).findFifth()
    }
    
    func sus4fifth() -> String {
        return triadBuild(root: root, botInt: quality()[1], midInt: quality()[2], topInt: quality()[2]).findFifth()
    }
    
    func find6th() -> String {
        return triadBuild(root: root, botInt: quality()[0], midInt: quality()[1]).find6th()
    }
    
    func find4th() -> String {
        return triadBuild(root: root, botInt: quality()[0], midInt: quality()[1], topInt: quality()[2]).findAug4th()
    }
    
    func augSpic() -> String {
        return triadBuild(root: root, botInt: quality()[0], midInt: quality()[1], topInt: quality()[2]).findAug3()
    }
    
    func augSpic2() -> String {
        return triadBuild(root: root, botInt: quality()[0], midInt: quality()[1], topInt: quality()[2]).findAug2nd()
    }
    
    func ct2nd() -> String {
        return triadBuild(root: root, botInt: quality()[0], midInt: quality()[1], topInt: quality()[2]).ct2()
    }
    
    func ct4th() -> String {
        return triadBuild(root: root, botInt: quality()[0], midInt: quality()[1], topInt: quality()[2]).ct4()
    }
    
    func ct6th() -> String {
        return triadBuild(root: root, botInt: quality()[0], midInt: quality()[1], topInt: quality()[2]).ct6()
    }
    
    func triadThird() -> String {
        return triadBuild(root: root, botInt: quality()[0], midInt: quality()[1], topInt: quality()[1]).findThird()
    }
    func triadFifth() -> String {
        return triadBuild(root: root, botInt: quality()[0], midInt: quality()[1], topInt: quality()[1]).findFifth()
    }
    func triadSev() -> String {
        return triadBuild(root: root, botInt: quality()[0],  midInt: quality()[1], topInt: quality()[2]).findSev()
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
