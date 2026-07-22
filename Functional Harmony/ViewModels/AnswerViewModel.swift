//
//  AnswerViewModel.swift
//  Functional Harmony (iOS)
//
//  Created by Dylan Shade on 4/11/21.
//

import Foundation

class AnsViewModel: ObservableObject {
    @Published var bottom = ""
    @Published var top = ""
            
    func answerInt() -> String {
        
        let ins = Interval(bottom: bottom, top: top)
        return ins.dToName()
    }
}
