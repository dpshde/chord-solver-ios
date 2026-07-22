//
//  ChordIntervalViewModel.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 4/14/21.
//

import Foundation

class ChordIntervalViewModel: ObservableObject {
    @Published var input = ""
    
    func inputToVars() -> Array<String> {
        let count = input.components(separatedBy: " ").count
        let bot: String = ""
        let mid: String = ""
        let top: String = ""
        
        
        if count >= 1 {
            var bot: String = ""
            
            bot = input.components(separatedBy: " ")[0]
            return [bot]
        }
        if count >= 2 {
            var mid: String = ""
            
            mid = input.components(separatedBy: " ")[1]
            
            return [bot, mid]
        }
        
        if count >= 3 {

            var top: String = ""
            
            top = input.components(separatedBy: " ")[2]
            
            return [bot, mid, top]
        }
        return [bot, mid, top]


    }
    
    func returnRoot() -> String {
        return inputToVars()[0]
    }
    
    func returnThird() -> String {
        return inputToVars()[1]
    }
    
    /*

    func triadToInts() -> Array<String> {
        let botInt = ""
        var topInt = ""
        
        if inputToVars().count >= 2 && inputToVars()[1] != "" {
            
            let botInt = Interval.init(bottom: inputToVars()[0], top: inputToVars()[1]).dToName()
            let topInt = Interval.init(bottom: inputToVars()[1], top: inputToVars()[2]).dToName()
            
            print(botInt, topInt)
            
            return [botInt, topInt]
        }
        
        return [botInt, topInt]
    }
    
    func triadQuality() -> String {
        return ChordIntervalModel.init(botInt: triadToInts()[0], topInt: triadToInts()[1]).returnName()
    }
 */
}
