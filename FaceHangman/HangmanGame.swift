import Foundation

enum tryLetterResult {
    case invalidSecret
    case invalidWord
    case alreadyTried
    case won
    case lost
    case found
    case notFound
}

enum loadGameResult {
    case invalidJson
    case won
    case lost
    case ok
}

struct HangmanGame {
    let characterSet = "abcdefghijklmnopqrstuvwxyz"
    let defaultMaxFailure = 7
    let secretCharacter = "_"
    
    var maxFail: Int
    var secret: String = ""
    var lettersTried: String
    var failedAttempts: Int
    var singleWord: Bool
    var discovered: String { //like secret but with secretCharacter ('-') to replace undiscovered characters
        get {
            var discovered = ""
            
            for index in secret.indices {
                if secret[index] == " " || searchLetterInString(letter: String(secret[index]), string: lettersTried) {
                    discovered.append(secret[index])
                }
                else {
                    discovered.append(secretCharacter)
                }
            }
            
            return discovered
        }
    }
    
    
    init(singleWord:Bool = true) {
        self.maxFail = defaultMaxFailure
        self.singleWord = singleWord
        self.lettersTried = ""
        self.failedAttempts = 0
        self.secret = getSecret(singleWord)
    }
    
    init(singleWord:Bool = true, maxFail: Int) {
        self.init(singleWord: singleWord)
        self.maxFail = maxFail
    }
    
    init(secret: String) {
        self.maxFail = defaultMaxFailure
        self.singleWord = true
        self.lettersTried = ""
        self.failedAttempts = 0
        
        self.secret = clearPhrase(secret)
        
        if self.secret.range(of:" ") != nil {
            self.singleWord = false
        }
    }
    
    init(secret: String, maxFail: Int) {
        self.init(secret: secret)
        self.maxFail = maxFail
    }
    
    
    
    mutating func tryLetter(_ letter: String) -> tryLetterResult {
        guard secret.lengthOfBytes(using: .ascii) > 0 else { return .invalidSecret }
        guard failedAttempts < maxFail else { return .lost }
        
        let clearLetter = clearPhrase(letter)
        
        guard clearLetter.lengthOfBytes(using: .ascii) == 1 else { return .invalidWord }
        
        if searchLetterInString(letter: clearLetter, string: lettersTried) {
            return .alreadyTried
        }
        
        lettersTried.append(clearLetter)
        
        if searchLetterInString(letter: clearLetter, string: secret) {
            if searchLetterInString(letter: secretCharacter, string: discovered) {
                return .found
            }
            else {
                return .won
            }
        }
        
        failedAttempts += 1
        
        if failedAttempts >= maxFail {
            return .lost
        }
        
        return .notFound
    }
    
    func save() throws -> String? {
        let gameDictionary:[String : Any] = ["maxFail" : maxFail, "secret" : secret, "lettersTried" : lettersTried, "failedAttempts" : failedAttempts]
        
        let jsonData = try JSONSerialization.data(withJSONObject: gameDictionary, options: .prettyPrinted)
        let jsonString = String(data: jsonData, encoding: .ascii)
        return jsonString
    }
    
    mutating func load(_ json: String) throws -> loadGameResult {
        if let jsonData = json.data(using: .ascii) {
            let jsonDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String : Any]
            
            self.maxFail = jsonDictionary["maxFail"] as! Int
            self.secret = clearPhrase(jsonDictionary["secret"] as! String)
            self.lettersTried = jsonDictionary["lettersTried"] as! String
            self.failedAttempts = jsonDictionary["failedAttempts"] as! Int
            
            
            if secret.lengthOfBytes(using: .ascii) == 0 {
                return .invalidJson
            }
            
            self.singleWord = true
            if self.secret.range(of:" ") != nil {
                self.singleWord = false
            }
            
            if self.failedAttempts >= self.maxFail {
                return .lost
            }
            
            if searchLetterInString(letter: secretCharacter, string: discovered) {
                return .ok
            }
            else {
                return .won
            }
        }
        
        return .invalidJson
    }
    
    
    internal func searchLetterInString(letter: String, string: String) -> Bool {
        let needle = Character(letter)
        if let _ = string.index(of: needle) {
            //let pos = string.characters.distance(from: string.startIndex, to: _)
            return true
        }
        else {
            return false
        }
    }
    
    internal func clearPhrase(_ phrase: String) -> String {
        let charSet = NSCharacterSet(charactersIn: " " + characterSet).inverted
        let unformatted = phrase.lowercased()
        let cleanedString = unformatted.components(separatedBy: charSet).joined(separator: "")
        let components = cleanedString.components(separatedBy: NSCharacterSet.whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    internal func getSecret(_ singleWorld: Bool) -> String {
        return clearPhrase(singleWord ? "computer" : "it is used for programming")
    }
}
