//
//  InputChordSolveView.swift
//  ChordSolver (iOS)
//
//  Created by Dylan Shade on 4/14/21.
//

import SwiftUI

struct InputChordSolveView: View {
    
    @ObservedObject var viewModel = chordSolverVM()
    @Environment(\.colorScheme) var colorScheme


    @State var notes: String = ""

    var body: some View {
        
        ZStack {
            HStack {
                ZStack {
                    Spacing.shapeSmall
                        .frame(minWidth: 0,maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                        .foregroundColor(.white)
                    TextField("Enter a note:", text: $viewModel.input)
                        .frame(minWidth: 0,maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                        .foregroundColor(.black)
                        .padding(10)
                }
            }
        }
        VStack{
            Text(viewModel.returnThird())
                .font(.title)
                .bold()
                .foregroundColor(Color(.white))
            
            Spacer()
        }
        .animation(.easeInOut)

        .padding()
        
    }
}

struct InputChordSolveView_Previews: PreviewProvider {
    static var previews: some View {
        InputChordSolveView()
    }
}
