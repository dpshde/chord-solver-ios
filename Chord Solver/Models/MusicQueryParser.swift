//
//  MusicQueryParser.swift
//  Chord Solver
//
//  Maps natural-language music queries onto Chords / Scales / Vivace state.
//

import Foundation

// MARK: - Result

enum MusicQueryDestination: Equatable {
    case chords
    case scales
    case vivace
}

struct MusicQueryMatch: Equatable {
    let destination: MusicQueryDestination
    /// Human-readable summary, e.g. "C Major 7" or "notes C · E · G".
    let summary: String
    /// Root in app notation (`C`, `C#`, `Bb`). Nil for multi-note Vivace only.
    let root: String?
    let chordQuality: ChordQualityKind?
    let scaleQuality: ScaleQualityKind?
    let vivaceNotes: [String]?
}

enum ChordQualityKind: String, CaseIterable, Equatable {
    case major, minor, aug, dim
    case MM7, Mm7, mm7, hd7, fd7, mM7
    case sus2, sus4
    case itA6, frA6, gerA6, ct7

    var displayName: String {
        switch self {
        case .major: return "Major"
        case .minor: return "Minor"
        case .aug: return "Augmented"
        case .dim: return "Diminished"
        case .MM7: return "Major 7"
        case .Mm7: return "Dominant 7"
        case .mm7: return "Minor 7"
        case .hd7: return "Half Diminished 7"
        case .fd7: return "Fully Diminished 7"
        case .mM7: return "Minor Major 7"
        case .sus2: return "Sus2"
        case .sus4: return "Sus4"
        case .itA6: return "Italian +6"
        case .frA6: return "French +6"
        case .gerA6: return "German +6"
        case .ct7: return "Common Tone °7"
        }
    }
}

enum ScaleQualityKind: String, CaseIterable, Equatable {
    case major, minorNat, minorHarm, minorMel
    case dorian, phrygian, lydian, mixo, locrian
    case pentatonic, wholeTone, octatonic
    case dorB2, lydianAug, lydDom, mixoB6, locNat2, supLoc

    var displayName: String {
        switch self {
        case .major: return "Major"
        case .minorNat: return "Natural Minor"
        case .minorHarm: return "Harmonic Minor"
        case .minorMel: return "Melodic Minor"
        case .dorian: return "Dorian"
        case .phrygian: return "Phrygian"
        case .lydian: return "Lydian"
        case .mixo: return "Mixolydian"
        case .locrian: return "Locrian"
        case .pentatonic: return "Pentatonic"
        case .wholeTone: return "Whole Tone"
        case .octatonic: return "Octatonic"
        case .dorB2: return "Phrygian ♮6"
        case .lydianAug: return "Lydian Augmented"
        case .lydDom: return "Lydian Dominant"
        case .mixoB6: return "Mixolydian ♭6"
        case .locNat2: return "Locrian ♮2"
        case .supLoc: return "Altered"
        }
    }
}

// MARK: - Parser

enum MusicQueryParser {

    /// Parse free text into a chord, scale, or Vivace note list.
    static func parse(_ raw: String) -> MusicQueryMatch? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalized = normalize(trimmed)
        let wantsScale = containsScaleKeyword(normalized)

        // Explicit "scale" / "mode" → always try scale first (before note-list or chord).
        // e.g. "C major scale", "scale of Bb minor", "C D E F G A B scale"
        if wantsScale, let scale = parseScale(normalized) {
            return scale
        }

        // Prefer multi-note identification only when not asking for a scale.
        if !wantsScale, let vivace = parseVivaceNotes(normalized) {
            return vivace
        }

        // Mode names without the word "scale" ("D dorian", "F# mixolydian b6").
        if let scale = parseScale(normalized) {
            return scale
        }

        if let chord = parseChord(normalized) {
            return chord
        }

        return nil
    }

    /// True when the query mentions scale/mode (singular or plural).
    private static func containsScaleKeyword(_ text: String) -> Bool {
        text.range(of: #"\b(scales?|modes?)\b"#, options: .regularExpression) != nil
    }

    // MARK: Normalize

    private static func normalize(_ s: String) -> String {
        var t = s.lowercased()
        let pairs: [(String, String)] = [
            ("♯", "#"), ("♭", "b"), ("♮", ""),
            ("×", "##"), ("double sharp", "##"), ("double flat", "bb"),
            ("sharp", "#"), ("flat", "b"),
            ("Δ", "maj"), ("△", "maj"), ("ø", "halfdim"),
            ("°", "dim"), ("ᵒ", "dim"),
            ("–", " "), ("—", " "), ("/", " "),
            ("  ", " "),
        ]
        for (a, b) in pairs {
            t = t.replacingOccurrences(of: a, with: b)
        }
        // Collapse punctuation to spaces (keep #)
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "# "))
        t = String(t.unicodeScalars.map { allowed.contains($0) ? Character($0) : " " })
        while t.contains("  ") { t = t.replacingOccurrences(of: "  ", with: " ") }
        return t.trimmingCharacters(in: .whitespaces)
    }

    // MARK: Root extraction

    /// App root notation: natural + optional #/b (up to 3), e.g. `C`, `F#`, `Bbb`.
    /// `#` is non-word, so `\b` after the letter would drop accidentals — use lookarounds.
    private static func extractRoot(from text: String) -> (root: String, rest: String)? {
        let pattern = #"(?i)(?<![a-z0-9#b])([a-g])([#b]{0,3})(?![a-z0-9])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges >= 3,
              let letterRange = Range(match.range(at: 1), in: text),
              let accRange = Range(match.range(at: 2), in: text),
              let full = Range(match.range(at: 0), in: text)
        else { return nil }

        let letter = text[letterRange].uppercased()
        let acc = String(text[accRange])
        let root = letter + acc

        var rest = text
        rest.replaceSubrange(full, with: " ")
        while rest.contains("  ") { rest = rest.replacingOccurrences(of: "  ", with: " ") }
        rest = rest.trimmingCharacters(in: .whitespaces)
        return (root, rest)
    }

    /// Compact forms: `cmaj7`, `bbm7`, `f#dim`, `g7`
    private static func extractCompactRootAndTail(_ text: String) -> (root: String, tail: String)? {
        let pattern = #"(?i)^\s*([a-g])([#b]{0,3})([a-z0-9+#]*)\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges >= 4,
              let l = Range(match.range(at: 1), in: text),
              let a = Range(match.range(at: 2), in: text),
              let t = Range(match.range(at: 3), in: text)
        else { return nil }
        let root = text[l].uppercased() + text[a]
        return (root, String(text[t]))
    }

    // MARK: Vivace notes

    private static func parseVivaceNotes(_ text: String) -> MusicQueryMatch? {
        // Strip intent words
        var t = text
        for w in ["identify", "what is", "whats", "what chord", "what interval",
                  "notes", "note", "chord of", "spell", "name this"] {
            t = t.replacingOccurrences(of: w, with: " ")
        }
        while t.contains("  ") { t = t.replacingOccurrences(of: "  ", with: " ") }
        t = t.trimmingCharacters(in: .whitespaces)

        let tokens = t.split(separator: " ").map(String.init)
        var notes: [String] = []
        let notePattern = #"(?i)^([a-g])([#b]{0,3})$"#
        guard let regex = try? NSRegularExpression(pattern: notePattern) else { return nil }

        for tok in tokens {
            let range = NSRange(tok.startIndex..., in: tok)
            guard let m = regex.firstMatch(in: tok, range: range),
                  let l = Range(m.range(at: 1), in: tok),
                  let a = Range(m.range(at: 2), in: tok)
            else {
                // Non-note token → not a pure note list (unless we already have 2+)
                if notes.count >= 2 { break }
                return nil
            }
            notes.append(tok[l].uppercased() + tok[a])
            if notes.count >= VivaceSessionState.maxNotes { break }
        }

        guard notes.count >= 2 else { return nil }

        // If rest looks like a single chord symbol after one note, defer to chord parser.
        if notes.count == 1 { return nil }

        let summary = "notes " + notes.joined(separator: " · ")
        return MusicQueryMatch(
            destination: .vivace,
            summary: summary,
            root: nil,
            chordQuality: nil,
            scaleQuality: nil,
            vivaceNotes: notes
        )
    }

    // MARK: Scale

    private static func parseScale(_ text: String) -> MusicQueryMatch? {
        // Explicit scale/mode wording, or a scale-only quality (dorian, etc.).
        // Bare "major"/"minor" alone are chords unless "scale"/"mode" is present.
        let explicitScale = containsScaleKeyword(text)
        let modeQuality = scaleModeKeywordMatch(in: text)

        guard explicitScale || modeQuality != nil else { return nil }
        guard let (root, rest) = extractRootForScale(from: text) else { return nil }

        let quality =
            scaleModeKeywordMatch(in: rest)
            ?? scaleModeKeywordMatch(in: text)
            ?? (explicitScale ? scaleMajorMinor(in: rest) : nil)
            ?? (explicitScale ? scaleMajorMinor(in: text) : nil)
            ?? .major

        return MusicQueryMatch(
            destination: .scales,
            summary: "\(root) \(quality.displayName)",
            root: root,
            chordQuality: nil,
            scaleQuality: quality,
            vivaceNotes: nil
        )
    }

    /// Root extraction tuned for scale phrases ("C major scale", "scale of Bb", "Cmaj scale").
    private static func extractRootForScale(from text: String) -> (root: String, rest: String)? {
        let pitches = allPitchMatches(in: text)
        if !pitches.isEmpty {
            // Degree list + "scale" ("C D E F G A B scale") → first note is tonic.
            // Filler before tonic ("play a C major scale") → last pitch is tonic.
            let hasQualityHint =
                scaleModeKeywordMatch(in: text) != nil
                || scaleMajorMinor(in: text) != nil
            let chosen = (pitches.count >= 2 && !hasQualityHint) ? pitches.first! : pitches.last!
            return rootRest(from: text, removing: chosen.range, root: chosen.root)
        }

        // Drop scale/mode filler and retry (never strip lone "a" — that's a valid root).
        var stripped = text
        for w in ["scales", "scale", "modes", "mode", "the", "of", "in", "an"] {
            stripped = stripped.replacingOccurrences(
                of: #"\b\#(w)\b"#,
                with: " ",
                options: .regularExpression
            )
        }
        while stripped.contains("  ") { stripped = stripped.replacingOccurrences(of: "  ", with: " ") }
        stripped = stripped.trimmingCharacters(in: .whitespaces)
        if let hit = extractRoot(from: stripped) {
            return hit
        }

        // Compact leading token: "cmaj scale", "bbmin scale"
        let tokens = stripped.split(separator: " ").map(String.init)
        guard let first = tokens.first,
              let compact = extractCompactRootAndTail(first)
        else { return nil }
        let rest = ([compact.tail] + tokens.dropFirst()).filter { !$0.isEmpty }.joined(separator: " ")
        return (compact.root, rest)
    }

    private struct PitchMatch {
        let root: String
        let range: Range<String.Index>
    }

    private static func allPitchMatches(in text: String) -> [PitchMatch] {
        let pattern = #"(?i)(?<![a-z0-9#b])([a-g])([#b]{0,3})(?![a-z0-9])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: nsRange).compactMap { match -> PitchMatch? in
            guard match.numberOfRanges >= 3,
                  let letterRange = Range(match.range(at: 1), in: text),
                  let accRange = Range(match.range(at: 2), in: text),
                  let full = Range(match.range(at: 0), in: text)
            else { return nil }
            let root = text[letterRange].uppercased() + text[accRange]
            return PitchMatch(root: root, range: full)
        }
    }

    private static func rootRest(
        from text: String,
        removing range: Range<String.Index>,
        root: String
    ) -> (root: String, rest: String) {
        var rest = text
        rest.replaceSubrange(range, with: " ")
        while rest.contains("  ") { rest = rest.replacingOccurrences(of: "  ", with: " ") }
        rest = rest.trimmingCharacters(in: .whitespaces)
        return (root, rest)
    }

    /// Scale-only keywords (modes / specialty scales). Not plain major/minor.
    /// Longer / more specific phrases must appear before shorter prefixes (e.g. mixolydian b6 before mixolydian).
    private static func scaleModeKeywordMatch(in text: String) -> ScaleQualityKind? {
        let rules: [(String, ScaleQualityKind)] = [
            ("harmonic minor", .minorHarm),
            ("melodic minor", .minorMel),
            ("natural minor", .minorNat),
            ("phrygian natural 6", .dorB2),
            ("phrygian nat 6", .dorB2),
            ("phrygian n6", .dorB2),
            ("dorian b2", .dorB2),
            ("dorian flat 2", .dorB2),
            ("lydian augmented", .lydianAug),
            ("lydian aug", .lydianAug),
            ("lydian dominant", .lydDom),
            ("lydian dom", .lydDom),
            // Melodic-minor modes 5–6 (normalize maps ♭→b, ♮→empty, flat/sharp→b/#)
            ("mixolydian b13", .mixoB6),
            ("mixolydian b 13", .mixoB6),
            ("mixolydian b6", .mixoB6),
            ("mixolydian b 6", .mixoB6),
            ("mixo b13", .mixoB6),
            ("mixo b 13", .mixoB6),
            ("mixo b6", .mixoB6),
            ("mixo b 6", .mixoB6),
            ("aeolian dominant", .mixoB6),
            ("hindu scale", .mixoB6),
            ("locrian natural 2", .locNat2),
            ("locrian nat 2", .locNat2),
            ("locrian n2", .locNat2),
            ("locrian #2", .locNat2),
            ("locrian # 2", .locNat2),
            ("locrian 2", .locNat2),
            ("whole tone", .wholeTone),
            ("mixolydian", .mixo),
            ("mixolyd", .mixo),
            ("pentatonic", .pentatonic),
            ("octatonic", .octatonic),
            ("diminished scale", .octatonic),
            ("altered", .supLoc),
            ("super locrian", .supLoc),
            ("locrian", .locrian),
            ("phrygian", .phrygian),
            ("lydian", .lydian),
            ("dorian", .dorian),
            ("aeolian", .minorNat),
            ("ionian", .major),
        ]
        for (key, kind) in rules {
            if text.contains(key) { return kind }
        }
        return nil
    }

    private static func scaleMajorMinor(in text: String) -> ScaleQualityKind? {
        if text.contains("harmonic minor") { return .minorHarm }
        if text.contains("melodic minor") { return .minorMel }
        if text.contains("natural minor") || text.contains("minor") { return .minorNat }
        if text.contains("major") { return .major }
        // Compact tails from "Cmaj scale" / "Bbmin scale"
        let t = text.trimmingCharacters(in: .whitespaces)
        if t == "maj" || t == "ma" { return .major }
        if t == "min" || t == "m" { return .minorNat }
        return nil
    }

    // MARK: Chord

    private static func parseChord(_ text: String) -> MusicQueryMatch? {
        // Compact: cmaj7, bbmin7, g7
        if let compact = extractCompactRootAndTail(text), !compact.tail.isEmpty {
            if let q = chordQuality(from: compact.tail) {
                return matchChord(root: compact.root, quality: q)
            }
        }

        guard let (root, rest) = extractRoot(from: text) else { return nil }

        // "major chord", bare root → major
        let quality = chordQuality(from: rest) ?? .major
        // Never treat scale/mode queries as chords.
        if containsScaleKeyword(text) || containsScaleKeyword(rest) { return nil }

        return matchChord(root: root, quality: quality)
    }

    private static func matchChord(root: String, quality: ChordQualityKind) -> MusicQueryMatch {
        MusicQueryMatch(
            destination: .chords,
            summary: "\(root) \(quality.displayName)",
            root: root,
            chordQuality: quality,
            scaleQuality: nil,
            vivaceNotes: nil
        )
    }

    private static func chordQuality(from text: String) -> ChordQualityKind? {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return nil }

        let rules: [(String, ChordQualityKind)] = [
            // Sevenths / complex first
            ("half diminished 7", .hd7),
            ("half diminished", .hd7),
            ("halfdim7", .hd7),
            ("halfdim", .hd7),
            ("m7b5", .hd7),
            ("min7b5", .hd7),
            ("fully diminished 7", .fd7),
            ("fully diminished", .fd7),
            ("diminished 7", .fd7),
            ("dim7", .fd7),
            // Minor-major 7th (minor triad + major 7): C minor major 7
            ("minor major 7", .mM7),
            ("min maj 7", .mM7),
            ("minmaj7", .mM7),
            ("mmaj7", .mM7),
            // Major-minor 7th = dominant 7 (major triad + minor 7): C major minor 7
            // Must beat bare "minor 7" which is a substring of this phrase.
            ("major minor 7", .Mm7),
            ("maj min 7", .Mm7),
            ("majmin7", .Mm7),
            ("major min 7", .Mm7),
            ("maj minor 7", .Mm7),
            ("major 7", .MM7),
            ("maj7", .MM7),
            ("ma7", .MM7),
            ("mm7", .MM7), // symbol MM7 style
            ("dominant 7", .Mm7),
            ("dom7", .Mm7),
            ("dom 7", .Mm7),
            ("minor 7", .mm7),
            ("min7", .mm7),
            ("m7", .mm7),
            ("italian", .itA6),
            ("french", .frA6),
            ("german", .gerA6),
            ("common tone", .ct7),
            ("ct7", .ct7),
            ("augmented", .aug),
            ("aug", .aug),
            ("diminished", .dim),
            ("dim", .dim),
            ("sus2", .sus2),
            ("sus4", .sus4),
            ("sus 2", .sus2),
            ("sus 4", .sus4),
            ("major", .major),
            ("maj", .major),
            ("minor", .minor),
            ("min", .minor),
            // trailing lone 7 after root handled as dominant
            ("7", .Mm7),
        ]

        // Prefer multi-word / longer keys
        for (key, kind) in rules {
            if t == key || t.contains(key) {
                // Avoid "major" matching inside seventh compounds — rules ordered long→short.
                if key == "major" && (
                    t.contains("major 7") || t.contains("maj7") || t.contains("ma7")
                    || t.contains("major minor") || t.contains("minor major")
                ) {
                    continue
                }
                if key == "minor" && (
                    t.contains("minor 7") || t.contains("min7") || t.contains("m7")
                    || t.contains("minor major") || t.contains("major minor")
                ) {
                    continue
                }
                // Don't let bare "minor 7" win over major-minor / minor-major compounds.
                if key == "minor 7" && (t.contains("major minor") || t.contains("minor major")) {
                    continue
                }
                if key == "major 7" && (t.contains("major minor") || t.contains("minor major")) {
                    continue
                }
                if key == "7" {
                    // only if it's essentially just "7" or ends with " 7" / "7"
                    if t == "7" || t.hasSuffix(" 7") || t.hasSuffix("7") && !t.contains("maj") && !t.contains("min") && !t.contains("dim") {
                        return .Mm7
                    }
                    continue
                }
                return kind
            }
        }

        // Compact tails: maj7, m7, dim, sus4, +
        let compact: [(String, ChordQualityKind)] = [
            ("maj7", .MM7), ("ma7", .MM7), ("m7", .mm7), ("min7", .mm7),
            ("dim7", .fd7), ("dim", .dim), ("aug", .aug),
            ("sus2", .sus2), ("sus4", .sus4), ("sus", .sus4),
            ("maj", .major), ("min", .minor), ("m", .minor),
            ("+", .aug), ("7", .Mm7),
        ]
        let compactTail = t.replacingOccurrences(of: " ", with: "")
        for (key, kind) in compact {
            if compactTail == key || compactTail.hasPrefix(key) && compactTail.count <= key.count + 1 {
                return kind
            }
        }

        return nil
    }
}

// MARK: - Apply to session models

extension triadBuildViewModel {
    func apply(root: String, quality: ChordQualityKind) {
        self.root = root
        resetButtons()
        switch quality {
        case .major: major = true
        case .minor: minor = true
        case .aug: aug = true
        case .dim: dim = true
        case .MM7: MM7 = true
        case .Mm7: Mm7 = true
        case .mm7: mm7 = true
        case .hd7: hd7 = true
        case .fd7: fd7 = true
        case .mM7: mM7 = true
        case .sus2: sus2 = true
        case .sus4: sus4 = true
        case .itA6: itA6 = true
        case .frA6: frA6 = true
        case .gerA6: gerA6 = true
        case .ct7: ct7 = true
        }
    }
}

extension scalesViewModel {
    func apply(root: String, quality: ScaleQualityKind) {
        self.root = root
        resetButtons()
        switch quality {
        case .major: major = true
        case .minorNat: minorNat = true
        case .minorHarm: minorHarm = true
        case .minorMel: minorMel = true
        case .dorian: dorian = true
        case .phrygian: phrygian = true
        case .lydian: lydian = true
        case .mixo: mixo = true
        case .locrian: locrian = true
        case .pentatonic: pentatonic = true
        case .wholeTone: wholeTone = true
        case .octatonic: octatonic = true
        case .dorB2: dorB2 = true
        case .lydianAug: lydianAug = true
        case .lydDom: lydDom = true
        case .mixoB6: mixoB6 = true
        case .locNat2: locNat2 = true
        case .supLoc: supLoc = true
        }
    }
}

extension VivaceSessionState {
    func apply(notes newNotes: [String]) {
        notes = Array(newNotes.prefix(Self.maxNotes))
        answer = VivaceChordIdentifier.identify(notes: notes)
    }
}

extension MusicQueryMatch {
    /// Apply this match onto shell-owned session objects.
    func apply(
        triad: triadBuildViewModel,
        scales: scalesViewModel,
        vivace: VivaceSessionState
    ) {
        switch destination {
        case .chords:
            if let root, let chordQuality {
                triad.apply(root: root, quality: chordQuality)
            }
        case .scales:
            if let root, let scaleQuality {
                scales.apply(root: root, quality: scaleQuality)
            }
        case .vivace:
            if let vivaceNotes {
                vivace.apply(notes: vivaceNotes)
            }
        }
    }

    var tab: MainSectionTab {
        switch destination {
        case .chords: return .chords
        case .scales: return .scales
        case .vivace: return .vivace
        }
    }
}

// MARK: - Live preview (no session mutation)

struct MusicQueryPreview: Equatable {
    /// Primary answer line (chord/scale name, or Vivace identify result).
    let title: String
    /// Pitch classes to show as chips.
    let notes: [String]
    /// Optional secondary line (interval formula, Vivace detail).
    let detail: String?
}

enum MusicQueryPreviewResolver {
    /// Compute display answer for Ask live preview.
    static func resolve(_ match: MusicQueryMatch) -> MusicQueryPreview {
        switch match.destination {
        case .chords:
            return chordPreview(match)
        case .scales:
            return scalePreview(match)
        case .vivace:
            return vivacePreview(match)
        }
    }

    private static func chordPreview(_ match: MusicQueryMatch) -> MusicQueryPreview {
        guard let root = match.root, let quality = match.chordQuality else {
            return MusicQueryPreview(title: match.summary, notes: [], detail: nil)
        }
        let vm = triadBuildViewModel()
        vm.apply(root: root, quality: quality)
        let tones = chordTones(from: vm)
        let notes = tones.map(\.note).filter { !$0.isEmpty }
        let formula = tones.map(\.interval).joined(separator: "  ·  ")
        return MusicQueryPreview(
            title: match.summary,
            notes: notes,
            detail: formula.isEmpty ? nil : formula
        )
    }

    private static func scalePreview(_ match: MusicQueryMatch) -> MusicQueryPreview {
        guard let root = match.root, let quality = match.scaleQuality else {
            return MusicQueryPreview(title: match.summary, notes: [], detail: nil)
        }
        let vm = scalesViewModel()
        vm.apply(root: root, quality: quality)
        let notes = scaleNotes(from: vm)
        return MusicQueryPreview(
            title: match.summary,
            notes: notes.filter { !$0.isEmpty },
            detail: nil
        )
    }

    private static func vivacePreview(_ match: MusicQueryMatch) -> MusicQueryPreview {
        let notes = match.vivaceNotes ?? []
        let answer = VivaceChordIdentifier.identify(notes: notes)
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let title = parts.first ?? match.summary
        var detail: String?
        if parts.count > 1 {
            detail = parts.dropFirst().joined(separator: " · ")
        }
        return MusicQueryPreview(title: title, notes: notes, detail: detail)
    }

    // Mirrors InputTriadAns chord tone stack for preview only.
    private static func chordTones(from vm: triadBuildViewModel) -> [(note: String, interval: String)] {
        if vm.itA6 {
            return [(vm.find6th(), "m6"), (vm.returnRoot(), "R"), (vm.find4th(), "A4")]
        }
        if vm.gerA6 {
            return [
                (vm.find6th(), "m6"), (vm.returnRoot(), "R"),
                (vm.augSpic(), "M3"), (vm.find4th(), "A4"),
            ]
        }
        if vm.frA6 {
            return [
                (vm.find6th(), "m6"), (vm.returnRoot(), "R"),
                (vm.augSpic2(), "M2"), (vm.find4th(), "A4"),
            ]
        }
        if vm.sus2 {
            return [(vm.returnRoot(), "R"), (vm.sus2nd(), "M2"), (vm.sus2fifth(), "P5")]
        }
        if vm.sus4 {
            return [(vm.returnRoot(), "R"), (vm.find4th(), "P4"), (vm.sus4fifth(), "P5")]
        }
        if vm.ct7 {
            return [
                (vm.ct2nd(), "A2"), (vm.ct4th(), "A4"),
                (vm.ct6th(), "M6"), (vm.returnRoot(), "R"),
            ]
        }
        var notes = [vm.returnRoot(), vm.triadThird(), vm.triadFifth()]
        if vm.MM7 || vm.Mm7 || vm.mm7 || vm.fd7 || vm.hd7 || vm.mM7 {
            notes.append(vm.triadSev())
        }
        let intervals = vm.chordIntervalStack()
        return zip(notes, intervals).map { (note: $0.0, interval: $0.1) }
    }

    private static func scaleNotes(from vm: scalesViewModel) -> [String] {
        if vm.pentatonic {
            return [vm.returnRoot(), vm.two(), vm.three(), vm.five(), vm.six()]
        }
        if vm.wholeTone {
            return [vm.returnRoot(), vm.two(), vm.three(), vm.four(), vm.five(), vm.six()]
        }
        if vm.octatonic {
            return [
                vm.returnRoot(), vm.two(), vm.three(), vm.four(),
                vm.octFive(), vm.octSix(), vm.octSev(), vm.octEight(),
            ]
        }
        return [
            vm.returnRoot(), vm.two(), vm.three(), vm.four(),
            vm.five(), vm.six(), vm.sev(),
        ]
    }
}
