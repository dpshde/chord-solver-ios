//
//  InputTriadAns.swift
//  ChordSolver (iOS)
//
//  Created by Dylan Shade on 4/12/21.
//

import SwiftUI

struct InputTriadAns: View {
    
    var remove: (() -> Void)? = nil
    
    @EnvironmentObject var viewModel: triadBuildViewModel
    @Environment(\.colorScheme) var colorScheme

    @State var offset = CGSize.zero
    @State var root: String = ""
    @State var triad: Bool = true
    @State private var showingKeyboard = false
    
    let notes: [String: Int] = [
        "A###": 0,"B#": 0, "C":0, "Dbb": 0,
        "B##": 1, "C#": 1, "Db": 1, "Ebbb": 1,
        "B###": 2, "C##": 2, "D": 2, "Ebb": 2, "Fbbb": 2,
        "C###": 3, "D#": 3, "Eb": 3, "Fbb": 3,
        "D##": 4, "E": 4, "Fb": 4, "Gbbb":4,
        "E#": 5, "F": 5, "Gbb": 5,
        "E##": 6, "F#": 6, "Gb": 6, "Abbb": 6,
        "E###": 7, "F##": 7, "G": 7, "Abb": 7,
        "F###": 8, "G#": 8, "Ab": 8, "Bbbb": 8,
        "G##": 9, "A": 9, "Bbb": 9, "Cbbb": 9,
        "G###": 10, "A#": 10, "Bb": 10, "Cbb":10,
        "A##": 11, "B": 11, "Cb": 11, "Dbbb":11
    ]

    var body: some View {
        VStack(spacing: 0) {

            // Note input section
            VStack(spacing: Spacing.md) {
                Text("Root Note")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: {
                    withAnimation(AppAnimation.quickSpring) {
                        showingKeyboard.toggle()
                    }
                    HapticManager.shared.lightImpact()
                }) {
                    HStack {
                        Text(viewModel.root.isEmpty ? "Tap to enter" : viewModel.root)
                            .foregroundColor(viewModel.root.isEmpty ? .textTertiary : .textPrimary)
                            .font(.noteName)

                        Spacer()

                        Image(systemName: showingKeyboard ? "keyboard.chevron.compact.down" : "keyboard")
                            .foregroundColor(.textSecondary)
                    }
                    .padding(Spacing.contentPadding)
                    .background(
                        RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall)
                            .fill(Color.white.opacity(0.3))
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // Custom note keyboard (shown when active)
                if showingKeyboard {
                    TriadNotePickerKeyboard(noteText: $viewModel.root)
                        .transition(.slideFromBottom)
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.top, Spacing.md)

            // Chord Quality - Single horizontal scroll with all options
            if !viewModel.root.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Chord Quality")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, Spacing.screenPadding)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            // Common triads
                            ChordQualityButton(label: "Major", isActive: viewModel.major) {
                                viewModel.resetButtons()
                                viewModel.major = true
                            }
                            ChordQualityButton(label: "Minor", isActive: viewModel.minor) {
                                viewModel.resetButtons()
                                viewModel.minor = true
                            }
                            ChordQualityButton(label: "+", isActive: viewModel.aug) {
                                viewModel.resetButtons()
                                viewModel.aug = true
                            }
                            ChordQualityButton(label: "°", isActive: viewModel.dim) {
                                viewModel.resetButtons()
                                viewModel.dim = true
                            }

                            Divider()
                                .frame(height: 30)
                                .background(Color.white.opacity(0.3))

                            // Seventh chords
                            ChordQualityButton(label: "MM7", isActive: viewModel.MM7) {
                                viewModel.resetButtons()
                                viewModel.MM7 = true
                            }
                            ChordQualityButton(label: "Mm7", isActive: viewModel.Mm7) {
                                viewModel.resetButtons()
                                viewModel.Mm7 = true
                            }
                            ChordQualityButton(label: "mm7", isActive: viewModel.mm7) {
                                viewModel.resetButtons()
                                viewModel.mm7 = true
                            }
                            ChordQualityButton(label: "ø7", isActive: viewModel.hd7) {
                                viewModel.resetButtons()
                                viewModel.hd7 = true
                            }
                            ChordQualityButton(label: "°7", isActive: viewModel.fd7) {
                                viewModel.resetButtons()
                                viewModel.fd7 = true
                            }
                            ChordQualityButton(label: "mM7", isActive: viewModel.mM7) {
                                viewModel.resetButtons()
                                viewModel.mM7 = true
                            }

                            Divider()
                                .frame(height: 30)
                                .background(Color.white.opacity(0.3))

                            // Sus chords
                            ChordQualityButton(label: "Sus2", isActive: viewModel.sus2) {
                                viewModel.resetButtons()
                                viewModel.sus2 = true
                            }
                            ChordQualityButton(label: "Sus4", isActive: viewModel.sus4) {
                                viewModel.resetButtons()
                                viewModel.sus4 = true
                            }

                            Divider()
                                .frame(height: 30)
                                .background(Color.white.opacity(0.3))

                            // Augmented sixths
                            ChordQualityButton(label: "It+6", isActive: viewModel.itA6) {
                                viewModel.resetButtons()
                                viewModel.itA6 = true
                            }
                            ChordQualityButton(label: "Fr+6", isActive: viewModel.frA6) {
                                viewModel.resetButtons()
                                viewModel.frA6 = true
                            }
                            ChordQualityButton(label: "Ger+6", isActive: viewModel.gerA6) {
                                viewModel.resetButtons()
                                viewModel.gerA6 = true
                            }
                            ChordQualityButton(label: "CT°7", isActive: viewModel.ct7) {
                                viewModel.resetButtons()
                                viewModel.ct7 = true
                            }
                        }
                        .padding(.horizontal, Spacing.screenPadding)
                    }
                }
                .padding(.top, Spacing.md)
                .transition(.scaleAndFade)
            }

            // Result Display - Chord Notes
            if !viewModel.root.isEmpty && (viewModel.major || viewModel.minor || viewModel.aug || viewModel.dim ||
                viewModel.MM7 || viewModel.Mm7 || viewModel.mm7 || viewModel.hd7 || viewModel.fd7 || viewModel.mM7 ||
                viewModel.sus2 || viewModel.sus4 || viewModel.itA6 || viewModel.frA6 || viewModel.gerA6 || viewModel.ct7) {

                Spacer()

                VStack(spacing: Spacing.lg) {
                    Text("Chord Notes")
                        .font(.bodyRegular)
                        .foregroundColor(.textSecondary)

                        HStack(spacing: Spacing.sm) {
                            if viewModel.itA6 {
                                NoteCard(note: viewModel.find6th())
                                NoteCard(note: viewModel.returnRoot())
                                NoteCard(note: viewModel.find4th())
                            }
                            else if viewModel.gerA6 {
                                NoteCard(note: viewModel.find6th())
                                NoteCard(note: viewModel.returnRoot())
                                NoteCard(note: viewModel.augSpic())
                                NoteCard(note: viewModel.find4th())
                            }
                            else if viewModel.frA6 {
                                NoteCard(note: viewModel.find6th())
                                NoteCard(note: viewModel.returnRoot())
                                NoteCard(note: viewModel.augSpic2())
                                NoteCard(note: viewModel.find4th())
                            }
                            else if viewModel.sus2 {
                                NoteCard(note: viewModel.returnRoot())
                                NoteCard(note: viewModel.sus2nd())
                                NoteCard(note: viewModel.sus2fifth())
                            }
                            else if viewModel.sus4 {
                                NoteCard(note: viewModel.returnRoot())
                                NoteCard(note: viewModel.find4th())
                                NoteCard(note: viewModel.sus4fifth())
                            }
                            else if viewModel.ct7 {
                                NoteCard(note: viewModel.ct2nd())
                                NoteCard(note: viewModel.ct4th())
                                NoteCard(note: viewModel.ct6th())
                                NoteCard(note: viewModel.returnRoot())
                            }
                            else {
                                NoteCard(note: viewModel.returnRoot())
                                NoteCard(note: viewModel.triadThird())
                                NoteCard(note: viewModel.triadFifth())

                                if viewModel.MM7 || viewModel.Mm7 || viewModel.mm7 || viewModel.fd7 || viewModel.hd7 || viewModel.mM7 {
                                    NoteCard(note: viewModel.triadSev())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.bottom, Spacing.xxl)
                    .transition(.scaleAndFade)

                Spacer()
                }
        }
    }
}

// MARK: - Chord Quality Button Component

struct ChordQualityButton: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            HapticManager.shared.mediumImpact()
        }) {
            Text(label)
                .font(.buttonLabel)
                .foregroundColor(.textPrimary)
                .padding(.horizontal, Spacing.contentPadding)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall)
                        .fill(isActive ? Color.white.opacity(0.4) : Color.white.opacity(0.25))
                        .shadow(color: Color.black.opacity(isActive ? 0.25 : 0.15), radius: isActive ? 6 : 4, x: 0, y: isActive ? 3 : 2)
                )
                .scaleEffect(isActive ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(AppAnimation.quickSpring, value: isActive)
    }
}

// MARK: - Note Card Component

struct NoteCard: View {
    let note: String
    @State private var appeared = false

    var body: some View {
        Text(note)
            .font(.system(size: 36, weight: .bold, design: .monospaced))
            .foregroundColor(.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .padding(.horizontal, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                    .fill(Color.white.opacity(0.35))
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(appeared ? 1.0 : 0.8)
            .opacity(appeared ? 1.0 : 0.0)
            .onAppear {
                withAnimation(AppAnimation.bouncySpring) {
                    appeared = true
                }
            }
    }
}

// Custom Note Picker Keyboard
struct TriadNotePickerKeyboard: View {
    @Binding var noteText: String
    @State private var pressedButton: String? = nil

    private let naturalNotes = ["C", "D", "E", "F", "G", "A", "B"]

    var body: some View {
        VStack(spacing: 8) {
            // Natural notes (C D E F G A B)
            HStack(spacing: 6) {
                ForEach(naturalNotes, id: \.self) { note in
                    TriadNoteButton(label: note, isPressed: pressedButton == note) {
                        appendNote(note)
                    }
                }
            }

            // Accidentals (# b) and backspace
            HStack(spacing: 6) {
                TriadNoteButton(label: "♯", isPressed: pressedButton == "♯", backgroundColor: Color.white.opacity(0.15)) {
                    appendAccidental("#")
                }

                TriadNoteButton(label: "♭", isPressed: pressedButton == "♭", backgroundColor: Color.white.opacity(0.15)) {
                    appendAccidental("b")
                }

                Spacer()

                TriadNoteButton(label: "⌫", isPressed: pressedButton == "⌫", backgroundColor: Color.red.opacity(0.3)) {
                    backspace()
                }
            }
        }
    }

    private func appendNote(_ note: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            noteText = note
        }
        pressedButton = note
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pressedButton = nil
        }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func appendAccidental(_ accidental: String) {
        if !noteText.isEmpty {
            let hasSharp = noteText.contains("#")
            let hasFlat = noteText.contains("b")

            // If switching between sharps and flats, replace all existing accidentals with one of the new type
            if (accidental == "#" && hasFlat) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    // Remove all flats and add one sharp
                    noteText = String(noteText.filter { $0 != "b" }) + "#"
                }
            } else if (accidental == "b" && hasSharp) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    // Remove all sharps and add one flat
                    noteText = String(noteText.filter { $0 != "#" }) + "b"
                }
            } else if noteText.filter({ $0 == "#" || $0 == "b" }).count < 3 {
                // Same accidental type, just append if under limit
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    noteText += accidental
                }
            }
        }
        pressedButton = accidental == "#" ? "♯" : "♭"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pressedButton = nil
        }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func backspace() {
        if !noteText.isEmpty {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                noteText.removeLast()
            }
        }
        pressedButton = "⌫"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pressedButton = nil
        }
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
}

// Custom Note Button
struct TriadNoteButton: View {
    let label: String
    let isPressed: Bool
    var backgroundColor: Color = Color.white.opacity(0.3)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(backgroundColor)
                        .shadow(color: Color.black.opacity(isPressed ? 0.3 : 0.15), radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InputTriadAns_Previews: PreviewProvider {
    static var previews: some View {
        InputTriadAns()
    }
}


