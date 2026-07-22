//
//  TriadView.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 4/12/21.
//

import SwiftUI

struct TriadView: View {
    
    @StateObject var viewModel = triadBuildViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack{
                Color(#colorLiteral(red: 1, green: 0.4431372549, blue: 0.4431372549, alpha: 1))
                    .ignoresSafeArea()

                VStack(alignment: .center) {
                    
                    InputTriadAns()
                        .frame(maxWidth: 350, maxHeight: 100, alignment: .center)
                        .ignoresSafeArea(.keyboard)
                    Spacer()
                    
                    VStack {
                        ZStack(alignment: .topLeading) {
                            Spacing.shapeMedium
                                .frame(maxWidth: .infinity, maxHeight: 75)
                                .foregroundColor(Color(#colorLiteral(red: 1, green: 0.4431372549, blue: 0.4431372549, alpha: 1)))

                                Text("Chords")
                                    .bold()
                                    .foregroundColor(.white)
                                    .font(.title)
                                    .frame(maxWidth: 428, maxHeight: 75, alignment: .trailing)
                                    .padding(.horizontal, 10)

                        }.padding(-10)
                        ZStack(alignment: .topLeading) {
                            Spacing.shapeMedium
                                .edgesIgnoringSafeArea(.horizontal)
                                .frame(maxWidth: .infinity, maxHeight: 75)
                                .foregroundColor(Color(#colorLiteral(red: 0.7215686275, green: 0.7098039216, blue: 1, alpha: 1)))
                            NavigationLink(destination: ScalesView(), label: {
                                Text("Scales")
                                    .bold()
                                    .foregroundColor(.white)
                                    .font(.title)
                                    .frame(maxWidth: 428, maxHeight: 75, alignment: .leading)
                                    .padding(.horizontal, 15)
                            })
                
                        }.padding(-10)
                        /*
                        ZStack(alignment: .topLeading) {
                            Rectangle(cornerRadius: Spacing.cornerRadiusMedium)
                                .edgesIgnoringSafeArea(.horizontal)
                                .frame(maxWidth: .infinity, maxHeight: 75)
                                .foregroundColor(Color(#colorLiteral(red: 0.9607843137, green: 0.7529411765, blue: 0.7529411765, alpha: 1)))
                            NavigationLink(destination: LegacyChordSpellView(), label: {
                                Text("Functional Harmony")
                                    .bold()
                                    .foregroundColor(.white)
                                    .font(.title)
                                    .frame(maxWidth: 428, maxHeight: 75, alignment: .leading)
                                    .padding(.horizontal, 15)
                            })
                                
                        }.padding(-10)
                         */
                        ZStack(alignment: .topLeading) {
                            Rectangle()
                                .edgesIgnoringSafeArea(.all)
                                .frame(maxWidth: .infinity, maxHeight: 75)
                                .foregroundColor(Color(#colorLiteral(red: 0.6235294118, green: 0.8470588235, blue: 0.8745098039, alpha: 1)))
                            NavigationLink(destination: IntervalView(), label: {
                                Text("Intervals")
                                    .bold()
                                    .foregroundColor(.white)
                                    .font(.title)
                                    .frame(maxWidth: 428, maxHeight: 75, alignment: .leading)
                                    .padding(.horizontal, 15)
                            })
                                
                        }.padding(-10)

                    }
                    .frame(height: 175, alignment: .center)
                    .padding(.top, 100)
                    
                }.padding()
                .edgesIgnoringSafeArea(.bottom)
                .navigationBarTitle("Functional Harmony")
                
            }
    
        }.environmentObject(viewModel)
        .navigationBarHidden(true)
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct TriadView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TriadView()
                .preferredColorScheme(.light)
        }
    }
}

