//
//  triadModel.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 4/12/21.
//

import Foundation

struct Triad {
    var first: String
    var third: String
    var fifth: String
    
    let chords: [String: [String: String]] = [
        "M3": [
            "m3": "Major"]
    
    ]
    
    func botTopInts() -> Array<String> {
        let botInt = Interval.init(bottom: first, top: third).dToName()
        let topInt = Interval.init(bottom: third, top: fifth).dToName()
        return [botInt, topInt]
    }
    
    mutating func sortChord(notes: Array<String>) -> Array<String> {
        let theNotes = ["A","B", "C", "D", "E", "F", "G", "A", "B", "C", "D", "E", "F", "G"]
        
        let sortedNotes: Array<String>
        let AIndex = theNotes.firstIndex(of: Array(arrayLiteral: notes[0])[0])
        var BIndex = theNotes.firstIndex(of: Array(arrayLiteral: notes[1])[0])
        var CIndex = theNotes.firstIndex(of: Array(arrayLiteral: notes[2])[0])

        if AIndex == nil || BIndex == nil || CIndex == nil {
            
        }
        else {
            if (BIndex! < AIndex!) {
                BIndex! += 9
            }
            if (CIndex! < AIndex!){
                CIndex! += 9
            }
            if (BIndex! < CIndex!){
                sortedNotes.append(third)
                sortedNotes.append(fifth)
            }

            else {
                sortedNotes.append(fifth)
                sortedNotes.append(third)
            }
            
            first = sortedNotes[0]
            third = sortedNotes[1]
            fifth = sortedNotes[2]
        }

    }
    
    func chordName() {
    
    }
    
}
