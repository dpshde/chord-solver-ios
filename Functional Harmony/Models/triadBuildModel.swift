struct triadBuild {
    
    var root: String
    var botInt: String
    var midInt: String
    var topInt: String?
    
    let notes: [String: Int] = [
        "A###": 0,"B#": 0, "C":0, "Dbb": 0,
        "B##": 1, "C#": 1, "Db": 1, "Ebbb": 1,
        "B###": 2, "C##": 2, "D": 2, "Ebb": 2, "Fbbb": 2,
        "C###": 3, "D#": 3, "Eb": 3, "Fbb": 3,
        "D##": 4, "E": 4, "Fb": 4, "Gbbb":4,
        "E#": 5, "F": 5, "Gbb": 5,
        "E##": 6, "F#": 6, "Gb": 6, "Abbb": 6,
        "F##": 7, "G": 7, "Abb": 7,
        "F###": 8, "G#": 8, "Ab": 8, "Bbbb": 8,
        "G##": 9, "A": 9, "Bbb": 9, "Cbbb": 9,
        "G###": 10, "A#": 10, "Bb": 10, "Cbb":10,
        "A##": 11, "B": 11, "Cb": 11, "Dbbb":11,
        "a###": 0,"b#": 0, "c":0, "dbb": 0,
        "b##": 1, "c#": 1, "db": 1, "ebbb": 1,
        "b###": 2, "c##": 2, "d": 2, "ebb": 2, "fbbb": 2,
        "c###": 3, "d#": 3, "eb": 3, "fbb": 3,
        "d##": 4, "e": 4, "fb": 4, "gbbb":4,
        "e#": 5, "f": 5, "gbb": 5,
        "e##": 6, "f#": 6, "gb": 6, "abbb": 6,
        "f##": 7, "g": 7, "abb": 7,
        "f###": 8, "g#": 8, "ab": 8, "bbbb": 8,
        "g##": 9, "a": 9, "bbb": 9, "cbbb": 9,
        "g###": 10, "a#": 10, "bb": 10, "cbb":10,
        "a##": 11, "b": 11, "cb": 11, "dbbb":11
    ]
    
    func findThird() -> String {

        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == botInt  && tempInt.baseDist() == "3rd" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        else {
            return ""
        }
    }
    
    func find6th() -> String {

        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == botInt  && tempInt.baseDist() == "6th" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        else {
            return ""
        }
    }
    
    func find2nd() -> String {

        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == midInt  && tempInt.baseDist() == "2nd" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        else {
            return ""
        }
    }
    
    func findAug2nd() -> String {
        
        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == topInt  && tempInt.baseDist() == "2nd" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        else {
            return ""
        }
    }
    
    
    func findAug3() -> String {

        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == topInt  && tempInt.baseDist() == "3rd" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        else {
            return ""
        }
    }
    
    func findAug4th() -> String {

        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == midInt  && tempInt.baseDist() == "4th" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        else {
            return ""
        }
    }
    func findFifth() -> String {

        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == midInt  && tempInt.baseDist() == "5th" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        return ""
    }
    
    func findSev() -> String {

        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == topInt  && tempInt.baseDist() == "7th" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        return ""
    }
    
    func ct2() -> String {

        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == botInt  && tempInt.baseDist() == "2nd" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        return ""
    }
    
    func ct4() -> String {

        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == midInt  && tempInt.baseDist() == "4th" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        return ""
    }
    
    func ct6() -> String {

        if root != "" {
            for (key, _) in notes {
                let tempInt = Interval(bottom: root, top: key)
                if tempInt.dToName() == topInt  && tempInt.baseDist() == "6th" {
                    return key
                }
                else {
                    continue
                }
            }
            return ""
        }
        return ""
    }
    
}
