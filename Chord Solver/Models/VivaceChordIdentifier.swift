//
//  VivaceChordIdentifier.swift
//  Chord Solver
//
//  Port of Vivace Theory (https://github.com/dpshde/vivace-theory) chord identification.
//  Enter notes → identify chord / interval (reverse of the Chords builder tab).
//

import Foundation

// MARK: - Public API

enum VivaceChordIdentifier {

    /// Identify an interval (2 notes) or chord (3–4 notes) from pitch spellings.
    /// Notes use letter + optional ♯/♭ (or #/b, normalized internally).
    static func identify(notes: [String]) -> String {
        let cleaned = notes
            .map(normalizeNote)
            .filter { !$0.isEmpty }

        switch cleaned.count {
        case 0:
            return ""
        case 1:
            return "Enter more notes"
        case 2:
            return identifyInterval(cleaned[0], cleaned[1]) ?? "No interval found"
        case 3, 4:
            do {
                return try identifyChord(cleaned)
            } catch {
                return "No chord found"
            }
        default:
            return "Use up to 4 notes"
        }
    }
}

// MARK: - Normalization

/// Letter uppercased; trailing #/b or ♯/♭ normalized to unicode accidentals.
private func normalizeNote(_ raw: String) -> String {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let first = trimmed.first else { return "" }
    let letter = String(first).uppercased()
    let accidentals = trimmed.dropFirst().compactMap { ch -> Character? in
        switch ch {
        case "#", "♯": return "♯"
        case "b", "♭": return "♭"
        default: return nil
        }
    }
    return letter + String(accidentals)
}

// MARK: - Interval identification

private func getDistance(_ a: String, _ b: String) -> Int {
    guard let first = a.first, let second = b.first,
          let firstNote = VivaceResources.baseNotes[String(first)],
          let secondNote = VivaceResources.baseNotes[String(second)] else {
        return 0
    }
    let distance = firstNote > secondNote
        ? firstNote - (secondNote + 7)
        : firstNote - secondNote
    return abs(distance)
}

private func getIntervalSemitones(_ a: String, _ b: String) -> Int? {
    guard let va = VivaceResources.dictionaryNotes[a],
          let vb = VivaceResources.dictionaryNotes[b] else {
        return nil
    }
    let inter = va - vb
    return inter < 0 ? 12 - (inter + 12) : 12 - inter
}

private func identifyInterval(_ a: String, _ b: String) -> String? {
    guard let interval = getIntervalSemitones(a, b) else { return nil }
    let distance = getDistance(a, b)
    guard let candidates = VivaceResources.intervals[distance] else { return nil }
    return candidates.first(where: { $0.value == interval })?.name
}

// MARK: - Chord identification

private enum VivaceError: Error {
    case noChord
}

private func identifyChord(_ args: [String]) throws -> String {
    var notes = args
    guard notes.count == 3 || notes.count == 4 else { throw VivaceError.noChord }

    // Sort upper notes by letter distance from the first note (Vivace order).
    let aLetter = String(notes[0].prefix(1))
    guard let aIndex = VivaceResources.noteArray.firstIndex(of: aLetter) else {
        throw VivaceError.noChord
    }

    func adjustedIndex(_ note: String) -> Int {
        let letter = String(note.prefix(1))
        guard var idx = VivaceResources.noteArray.firstIndex(of: letter) else { return 0 }
        if idx < aIndex { idx += 9 }
        return idx
    }

    let first = notes[0]
    let upper = Array(notes.dropFirst()).sorted { adjustedIndex($0) < adjustedIndex($1) }
    notes = [first] + upper

    switch notes.count {
    case 3:
        let a = notes[0], b = notes[1], c = notes[2]
        guard let firstInterval = identifyInterval(a, b),
              let secondInterval = identifyInterval(b, c),
              let chord = VivaceResources.threeNoteChords[firstInterval]?[secondInterval] else {
            throw VivaceError.noChord
        }
        return formatThreeNote(a: a, b: b, c: c, chord: chord)

    case 4:
        let a = notes[0], b = notes[1], c = notes[2], d = notes[3]
        guard let firstInterval = identifyInterval(a, b),
              let secondInterval = identifyInterval(b, c),
              let thirdInterval = identifyInterval(c, d),
              let chord = VivaceResources.fourNoteChords[firstInterval]?[secondInterval]?[thirdInterval] else {
            throw VivaceError.noChord
        }
        return formatFourNote(a: a, b: b, c: c, d: d, chord: chord)

    default:
        throw VivaceError.noChord
    }
}

private func formatThreeNote(a: String, b: String, c: String, chord: VivaceChordMatch) -> String {
    switch chord.inversion {
    case nil:
        return "\(a) \(chord.name)"
    case "First":
        return "\(c) \(chord.name) First Inversion\nalso  \(c) \(chord.name)/\(a)"
    case "Second":
        return "\(b) \(chord.name) Second Inversion\nalso  \(b) \(chord.name)/\(a)"
    case "+6":
        return "\(b) \(chord.name)"
    default:
        return "\(a) \(chord.name)"
    }
}

private func formatFourNote(a: String, b: String, c: String, d: String, chord: VivaceChordMatch) -> String {
    if (chord.name.contains("♯9") || chord.name.contains("♭9")), chord.inversion != nil {
        return "\(c) \(chord.name) \(chord.inversion!) Inversion\nalso  \(c) \(chord.name)/\(a)"
    }
    switch chord.inversion {
    case nil:
        return "\(a) \(chord.name)"
    case "First":
        return "\(d) \(chord.name) First Inversion\nalso  \(d) \(chord.name)/\(a)"
    case "Second":
        return "\(c) \(chord.name) Second Inversion\nalso  \(c) \(chord.name)/\(a)"
    case "Third":
        return "\(b) \(chord.name) Third Inversion\nalso  \(b) \(chord.name)/\(a)"
    case "+6":
        return "\(b) \(chord.name)"
    default:
        return "\(a) \(chord.name)"
    }
}

// MARK: - Resources (from Vivace Theory Resources.ts)

struct VivaceChordMatch {
    let name: String
    let inversion: String?
}

enum VivaceResources {
    static let noteArray = ["A", "B", "C", "D", "E", "F", "G", "A", "B", "C", "D", "E", "F", "G"]

    static let baseNotes: [String: Int] = [
        "A": 0, "B": 1, "C": 2, "D": 3, "E": 4, "F": 5, "G": 6,
    ]

    static let dictionaryNotes: [String: Int] = [
        "A♯♯♯": 0, "B♯": 0, "C": 0, "D♭♭": 0,
        "B♯♯": 1, "C♯": 1, "D♭": 1, "E♭♭♭": 1,
        "B♯♯♯": 2, "C♯♯": 2, "D": 2, "E♭♭": 2, "F♭♭♭": 2,
        "C♯♯♯": 3, "D♯": 3, "E♭": 3, "F♭♭": 3,
        "D♯♯": 4, "E": 4, "F♭": 4, "G♭♭♭": 4,
        "E♯": 5, "F": 5, "G♭♭": 5,
        "E♯♯": 6, "F♯": 6, "G♭": 6, "A♭♭♭": 6,
        "F♯♯": 7, "G": 7, "A♭♭": 7,
        "F♯♯♯": 8, "G♯": 8, "A♭": 8, "B♭♭♭": 8,
        "G♯♯": 9, "A": 9, "B♭♭": 9, "C♭♭♭": 9,
        "G♯♯♯": 10, "A♯": 10, "B♭": 10, "C♭♭": 10,
        "A♯♯": 11, "B": 11, "C♭": 11, "D♭♭♭": 11,
    ]

    struct IntervalDef {
        let name: String
        let value: Int
    }

    static let intervals: [Int: [IntervalDef]] = [
        1: [
            .init(name: "Diminished 2nd", value: 0),
            .init(name: "Minor 2nd", value: 1),
            .init(name: "Major 2nd", value: 2),
            .init(name: "Augmented 2nd", value: 3),
            .init(name: "Doubly Augmented 2nd", value: 4),
        ],
        2: [
            .init(name: "Doubly Diminished 3rd", value: 1),
            .init(name: "Diminished 3rd", value: 2),
            .init(name: "Minor 3rd", value: 3),
            .init(name: "Major 3rd", value: 4),
            .init(name: "Augmented 3rd", value: 5),
            .init(name: "Doubly Augmented 3rd", value: 6),
        ],
        3: [
            .init(name: "Doubly Diminished 4th", value: 3),
            .init(name: "Diminished 4th", value: 4),
            .init(name: "Perfect 4th", value: 5),
            .init(name: "Augmented 4th", value: 6),
            .init(name: "Doubly Augmented 4th", value: 7),
        ],
        4: [
            .init(name: "Doubly Diminished 5th", value: 5),
            .init(name: "Diminished 5th", value: 6),
            .init(name: "Perfect 5th", value: 7),
            .init(name: "Augmented 5th", value: 8),
            .init(name: "Doubly Augmented 5th", value: 9),
        ],
        5: [
            .init(name: "Doubly Diminished 6th", value: 6),
            .init(name: "Diminished 6th", value: 7),
            .init(name: "Minor 6th", value: 8),
            .init(name: "Major 6th", value: 9),
            .init(name: "Augmented 6th", value: 10),
            .init(name: "Doubly Augmented 6th", value: 11),
        ],
        6: [
            .init(name: "Doubly Diminished 7th", value: 8),
            .init(name: "Diminished 7th", value: 9),
            .init(name: "Minor 7th", value: 10),
            .init(name: "Major 7th", value: 11),
            .init(name: "Augmented 7th", value: 12),
        ],
    ]

    static let threeNoteChords: [String: [String: VivaceChordMatch]] = [
        "Minor 2nd": [
            "Major 3rd": .init(name: "Major 7", inversion: "Third"),
        ],
        "Major 2nd": [
            "Perfect 4th": .init(name: "sus2", inversion: nil),
        ],
        "Minor 3rd": [
            "Major 3rd": .init(name: "Minor", inversion: nil),
            "Minor 3rd": .init(name: "Diminished", inversion: nil),
            "Perfect 4th": .init(name: "Major", inversion: "First"),
            "Augmented 4th": .init(name: "Diminished", inversion: "First"),
            "Perfect 5th": .init(name: "Minor 7", inversion: nil),
        ],
        "Major 3rd": [
            "Diminished 3rd": .init(name: "Major ♭5", inversion: nil),
            "Minor 3rd": .init(name: "Major", inversion: nil),
            "Major 3rd": .init(name: "Augmented", inversion: nil),
            "Diminished 4th": .init(name: "Augmented", inversion: "First"),
            "Perfect 4th": .init(name: "Minor", inversion: "First"),
            "Augmented 4th": .init(name: "Italian +6", inversion: "+6"),
            "Diminished 5th": .init(name: "Dominant 7", inversion: nil),
            "Perfect 5th": .init(name: "Major 7", inversion: nil),
        ],
        "Diminished 4th": [
            "Major 3rd": .init(name: "Augmented", inversion: "Second"),
        ],
        "Perfect 4th": [
            "Major 2nd": .init(name: "sus4", inversion: nil),
            "Major 3rd": .init(name: "Major", inversion: "Second"),
            "Minor 3rd": .init(name: "Minor", inversion: "Second"),
        ],
        "Augmented 4th": [
            "Minor 3rd": .init(name: "Diminished", inversion: "Second"),
        ],
        "Diminished 5th": [
            "Major 2nd": .init(name: "Dominant 7", inversion: "First"),
        ],
        "Perfect 5th": [
            "Minor 2nd": .init(name: "Major 7", inversion: "First"),
        ],
    ]

    static let fourNoteChords: [String: [String: [String: VivaceChordMatch]]] = [
        "Diminished 5th": [
            "Major 2nd": [
                "Augmented 2nd": .init(name: "Dominant ♯9", inversion: "First"),
                "Minor 2nd": .init(name: "Dominant ♭9", inversion: "First"),
            ],
        ],
        "Perfect 4th": [
            "Major 2nd": [
                "Minor 3rd": .init(name: "sus7", inversion: nil),
            ],
        ],
        "Major 3rd": [
            "Minor 2nd": [
                "Minor 3rd": .init(name: "Minor Major 7", inversion: "Second"),
                "Major 3rd": .init(name: "Major 7", inversion: "Second"),
            ],
            "Major 2nd": [
                "Minor 3rd": .init(name: "Half Diminished 7", inversion: "Second"),
                "Major 3rd": .init(name: "French +6", inversion: "+6"),
                "Diminished 4th": .init(name: "Lydian Dominant 7", inversion: nil),
            ],
            "Diminished 3rd": [
                "Augmented 4th": .init(name: "Minor 7 ♭5", inversion: nil),
            ],
            "Minor 3rd": [
                "Major 2nd": .init(name: "Minor 7", inversion: "First"),
                "Augmented 2nd": .init(name: "German +6", inversion: "+6"),
                "Minor 3rd": .init(name: "Dominant 7", inversion: nil),
                "Major 3rd": .init(name: "Major 7", inversion: nil),
            ],
            "Major 3rd": [
                "Minor 2nd": .init(name: "Minor Major 7", inversion: "First"),
            ],
            "Perfect 4th": [
                "Minor 2nd": .init(name: "Dominant 13", inversion: nil),
                "Major 2nd": .init(name: "Major 13", inversion: nil),
            ],
        ],
        "Minor 3rd": [
            "Major 3rd": [
                "Minor 3rd": .init(name: "Minor 7", inversion: nil),
                "Minor 2nd": .init(name: "Major 7", inversion: "First"),
                "Major 2nd": .init(name: "Half Diminished 7", inversion: "First"),
                "Major 3rd": .init(name: "Minor Major 7", inversion: nil),
            ],
            "Minor 3rd": [
                "Major 2nd": .init(name: "Dominant 7", inversion: "First"),
                "Minor 3rd": .init(name: "Fully Diminished 7", inversion: nil),
                "Augmented 2nd": .init(name: "Fully Diminished 7", inversion: "First"),
                "Major 3rd": .init(name: "Half Diminished 7", inversion: nil),
            ],
            "Major 2nd": [
                "Augmented 2nd": .init(name: "Dominant ♯9", inversion: "Second"),
                "Minor 3rd": .init(name: "Minor 7", inversion: "Second"),
                "Major 3rd": .init(name: "Dominant 7", inversion: "Second"),
            ],
        ],
        "Major 2nd": [
            "Major 2nd": [
                "Minor 3rd": .init(name: "Major 9", inversion: nil),
                "Diminished 5th": .init(name: "Dominant 9", inversion: nil),
            ],
            "Minor 3rd": [
                "Major 3rd": .init(name: "Minor 7", inversion: "Third"),
                "Minor 3rd": .init(name: "Half Diminished 7", inversion: "Third"),
            ],
            "Major 3rd": [
                "Minor 3rd": .init(name: "Dominant 7", inversion: "Third"),
            ],
        ],
        "Minor 2nd": [
            "Augmented 2nd": [
                "Diminished 5th": .init(name: "Dominant ♭9", inversion: nil),
            ],
            "Minor 3rd": [
                "Major 3rd": .init(name: "Minor Major 7", inversion: "Third"),
            ],
            "Major 3rd": [
                "Minor 3rd": .init(name: "Major 7", inversion: "Third"),
            ],
        ],
        "Augmented 2nd": [
            "Minor 2nd": [
                "Diminished 5th": .init(name: "Dominant ♯9", inversion: nil),
            ],
            "Minor 3rd": [
                "Minor 3rd": .init(name: "Fully Diminished 7", inversion: "Third"),
            ],
        ],
    ]
}
