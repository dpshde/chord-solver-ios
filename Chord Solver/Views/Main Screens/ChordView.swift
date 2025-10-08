//
//  ChordView.swift
//  Chord Solver
//
//  Created by Dylan Shade on 4/7/21.
//  NOTE: This file is deprecated. ChordSolverView is now in ChordSolverView.swift
//

import SwiftUI

// Placeholder to prevent build errors - actual implementation is in ChordSolverView.swift
struct ChordView_Deprecated: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var bottom: String = ""
    @State private var top: String = ""
    @State private var num: Int = 0
    

    var body: some View {
        NavigationView {
            ZStack {
                    Color(#colorLiteral(red: 0.9607843137, green: 0.7529411765, blue: 0.7529411765, alpha: 1))
                        .ignoresSafeArea()
                
                    VStack(alignment: .leading) {
                        
                        InputChordSolveView()
                        
                        Spacer()
                        
                        VStack {
                            
                            ZStack(alignment: .topLeading) {
                                Rectangle()
                                    .frame(maxWidth: .infinity, maxHeight: 75)
                                    .foregroundColor(Color(#colorLiteral(red: 0.9607843137, green: 0.7529411765, blue: 0.7529411765, alpha: 1)))
                                    Text("Chord Solver")
                                        .bold()
                                        .foregroundColor(.white)
                                        .font(.title)
                                        .frame(maxWidth: .infinity, maxHeight: 75, alignment: .trailing)
                                        .padding(.horizontal, 15)
                                    
                            }.padding(-10)
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 15)
                                    .frame(maxWidth: .infinity, maxHeight: 75)
                                    .foregroundColor(Color(#colorLiteral(red: 1, green: 0.4431372549, blue: 0.4431372549, alpha: 1)))
                                NavigationLink(destination: TriadView(), label: {
                                    Text("Chords")
                                        .bold()
                                        .foregroundColor(.white)
                                        .font(.title)
                                        .frame(maxWidth: .infinity, maxHeight: 75, alignment: .leading)
                                        .padding(.horizontal, 15)
                                })
                                
                            }.padding(-10)
                            ZStack(alignment: .topLeading) {
                                Rectangle()
                                    .edgesIgnoringSafeArea(.bottom)
                                    .foregroundColor(Color(#colorLiteral(red: 0.6235294118, green: 0.8470588235, blue: 0.8745098039, alpha: 1)))
                                    .frame(maxWidth: .infinity, maxHeight: 75)
                                NavigationLink(destination: IntervalView(), label: {
                                    Text("Intervals")
                                        .bold()
                                        .foregroundColor(.white)
                                        .font(.title)
                                        .frame(maxWidth: .infinity, maxHeight: 75, alignment: .leading)
                                        .padding(.horizontal, 15)
                                }).edgesIgnoringSafeArea(.bottom)
                                    
                            }.padding(-10)

                        }
                    }.padding()
                    .edgesIgnoringSafeArea(.bottom)
                    .navigationBarTitle("Chord Solver")
            }
        }.navigationBarHidden(true)
    }
}

struct ChordView_Deprecated_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChordView_Deprecated()
                .preferredColorScheme(.light)
        }
    }
}
