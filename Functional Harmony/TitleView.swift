//
//  TitleView.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 4/7/21.
//

import SwiftUI

struct TitleView: View {
    var body: some View {
        Text("Functional Harmony")
            .bold()
            .font(.title)
            .foregroundColor(.blue)    }
}

struct TitleView_Previews: PreviewProvider {
    static var previews: some View {
        TitleView()
    }
}
