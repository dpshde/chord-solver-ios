//
//  ScalesView.swift
//  ChordSolver (iOS)
//
//  Created by Dylan Shade on 4/17/21.
//  Redesigned on 10/8/25 - Modern UI refresh
//

import SwiftUI

struct ScalesView: View {

    /// Provided by MainTabView so the scale root survives tab switches.
    @EnvironmentObject var viewModel: scalesViewModel

    var body: some View {
        scalesAnsView()
            .environmentObject(viewModel)
    }
}

struct ScalesView_Previews: PreviewProvider {
    static var previews: some View {
        ScalesView()
            .environmentObject(scalesViewModel())
    }
}
