//
//  ContentView.swift
//  Shared
//
//  Created by Dylan Shade on 4/7/21.
//  App root: tab shell only (no separate landing / home screen).
//

import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light")
            ContentView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")
        }
    }
}
