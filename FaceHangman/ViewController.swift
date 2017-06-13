//
//  ViewController.swift
//  FaceHangman
//
//  Created by Jacopo Mangiavacchi on 5/23/17.
//  Copyright © 2017 Jacopo. All rights reserved.
//

import UIKit
import Gifu
import SwiftCarousel
import AudioToolbox
import Alamofire


extension SystemSoundID {
    static func playFileNamed(_ fileName: String, withExtenstion fileExtension: String) {
        var sound: SystemSoundID = 0
        if let soundURL = Bundle.main.url(forResource: fileName, withExtension: fileExtension) {
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &sound)
            AudioServicesPlaySystemSound(sound)
        }
    }
}


enum LoadSecretResult {
    case OK(secret: String)
    case Error(error: String)
}



class ViewController: UIViewController, FaceDetectorFilterDelegate {

    let removeSelectedWordFromCarousel = true
    let numberOfLetters = 26
    let carouselSelectedFontSize:CGFloat = 32.0
    let carouselUnselectedFontSize:CGFloat = 28.0
    let greenColor = UIColor(red: 212/255.0, green: 234/255.0, blue: 95/255.0, alpha: 1.0)
    
    
    let topHeight:CGFloat = UIScreen.main.bounds.height / 4
    let statusBarHeight:CGFloat = 10
    let definitionHeight:CGFloat = 60
//    let carouselHeight:CGFloat = ((UIScreen.main.bounds.height / 4) - 20 - 40) / 2
//    let secretHeight:CGFloat = ((UIScreen.main.bounds.height / 4) - 20 - 40) / 2
    func carouselHeight() -> CGFloat { return (topHeight - statusBarHeight - definitionHeight) / 2 }
    func secretHeight() -> CGFloat { return (topHeight - statusBarHeight - definitionHeight) / 2 }

    var eyesStatus: EyesStatus = .nothing
    
    var faceDetectorFilter: FaceDetectorFilter!
    lazy var faceDetector: FaceDetector = {
        var detector = FaceDetector()
        self.faceDetectorFilter = FaceDetectorFilter(faceDetector: detector, delegate: self)
        detector.delegate = self.faceDetectorFilter
        return detector
    }()

    lazy var hangmanImage: UIImageView = {
        var temp = UIImageView(frame: CGRect(x: 0,
                                             y: 0,
                                             width: UIScreen.main.bounds.width,
                                             height: UIScreen.main.bounds.height))
        temp.image = UIImage(named: "hangman_0.png")
        temp.contentMode = .scaleAspectFit
        return temp
    }()

    lazy var faceMaskImage: UIImageView = {
        var temp = UIImageView(frame: CGRect(x: 0,
                                             y: 0,
                                             width: UIScreen.main.bounds.width,
                                             height: UIScreen.main.bounds.height))
        temp.image = UIImage(named: "faceMask.png")
        temp.contentMode = .scaleAspectFit
        temp.alpha = 0.6
        return temp
    }()
    
    lazy var rightEyeGif: GIFImageView = {
        let temp = GIFImageView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width / 2.1, height: UIScreen.main.bounds.height / 7.1))  //150x80
        temp.alpha = 0.0
        temp.animate(withGIFNamed: "rightEye_Opening.gif", loopCount: 1)
        temp.contentMode = .scaleAspectFit
        return temp
    }()

    lazy var leftEyeGif: GIFImageView = {
        let temp = GIFImageView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width / 2.1, height: UIScreen.main.bounds.height / 7.1)) //150x80
        temp.alpha = 0.0
        temp.animate(withGIFNamed: "leftEye_Opening.gif", loopCount: 1)
        temp.contentMode = .scaleAspectFit
        return temp
    }()

    var carouselCharacter: [String]!
    
    lazy var carousel: SwiftCarousel = {
        var carousel = SwiftCarousel()
        self._setCarousel(carousel, index: 0)
        self.loadCarouselCharacter()
        self.loadCarousel(carousel)
        
        return carousel
    }()

    func _setCarousel(_ carousel: SwiftCarousel, index: Int) {
        carousel.frame = CGRect(x: 0,
                                y: 20,
                                width: UIScreen.main.bounds.width,
                                height: carouselHeight())
        carousel.resizeType = .visibleItemsPerPage(5)
        carousel.defaultSelectedIndex = index
        carousel.delegate = self
        carousel.scrollType = .default
        carousel.isUserInteractionEnabled = false
    }
    
    func resetCarousel(_ letter: String?) {
        carousel.removeFromSuperview()

        carousel = SwiftCarousel()
        
        var rightIndex = 0
        if let l = letter {
            if let index = carouselCharacter.index(of: l) {
                rightIndex = index
            }
            
            removeLetterFromCarouselCharacter(l)
        }
        
        if rightIndex >= carouselCharacter.count {
            rightIndex = 0
        }

        _setCarousel(carousel, index: rightIndex)
        loadCarousel(carousel)
        
        view.addSubview(carousel)
    }
    
    func loadCarouselCharacter() {
        carouselCharacter = (0..<numberOfLetters).map { String(format: "%c", 65 + $0) }
    }
    
    
    func removeLetterFromCarouselCharacter(_ letter: String) {
        if let index = carouselCharacter.index(of: letter) {
            carouselCharacter.remove(at: index)
        }
    }

    func loadCarousel(_ carousel: SwiftCarousel) {
        do {
            try carousel.itemsFactory(itemsCount: carouselCharacter.count, factory: { (item) -> UIView in
                return self.labelForCarouselString(carouselCharacter[item])
            })
        }
        catch {
        }
    }
    
    func labelForCarouselString(_ string: String) -> UILabel {
        let text = UILabel()
        text.text = string
        text.textColor = .white
        text.textAlignment = .center
        text.font = UIFont(name: "HelveticaNeue-Light", size: carouselUnselectedFontSize)
        text.numberOfLines = 0
        
        return text
    }
    
    
    lazy var wonLostMessageLabel: UILabel = {
        var temp = UILabel(frame: self.carousel.frame)
        temp.textColor = self.greenColor
        temp.font = UIFont(name: "HelveticaNeue-Light", size: self.carouselSelectedFontSize)
        temp.textAlignment = .center
        temp.minimumScaleFactor = 10/UIFont.labelFontSize
        temp.adjustsFontSizeToFitWidth = true
        temp.isHidden = true
        return temp
    }()


    lazy var secretLabel: UILabel = {
        var temp = UILabel(frame: CGRect(x: 0,
                                             y: self.carousel.frame.origin.y + self.carousel.bounds.height,
                                             width: UIScreen.main.bounds.width,
                                             height: self.secretHeight()))
        temp.textColor = self.greenColor
        temp.font = UIFont(name: "HelveticaNeue-Light", size: self.carouselSelectedFontSize)
        temp.textAlignment = .center
        temp.minimumScaleFactor = 10/UIFont.labelFontSize
        temp.adjustsFontSizeToFitWidth = true
        return temp
    }()

    lazy var definitionLabel: UILabel = {
        var temp = UILabel(frame: CGRect(x: 0,
                                         y: self.secretLabel.frame.origin.y + self.secretLabel.bounds.height,
                                         width: UIScreen.main.bounds.width,
                                         height: self.definitionHeight))
        temp.textColor = self.greenColor
        temp.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        temp.textAlignment = .center
        
        temp.minimumScaleFactor = 10/UIFont.labelFontSize
        temp.adjustsFontSizeToFitWidth = true
        return temp
    }()
    
    var winkingTimer = Timer()
    var isWinkingTimerRunning = false
    
    var game: HangmanGame?
    var definition: String?

    var errorLoading = false

    let firstStartTimerLength = 5.0
    var loadingTimer: Timer?
    var startTimer: Timer?
    var startingGameTime: CFAbsoluteTime?
    var gameLoading = true

    let endingTimerLength = 8.0
    let restartTimerLength = 2.0
    var endingTimer: Timer?
    var gameEnding = false


    internal func spaceString(_ string: String) -> String {
        return string.uppercased().characters.map({ c in "\(c) " }).joined()
    }
    
    
    func getSecret(callback:@escaping (_ result: LoadSecretResult) -> Void) {
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            if let infoDictionary = NSDictionary(contentsOfFile: path) {
                if let baseURL = infoDictionary.object(forKey: "WordnikSecretURL") as? String {
                    if let key = infoDictionary.object(forKey: "WordnikKey") as? String {
                        Alamofire.request(String(format: baseURL, key)).responseJSON { response in
                            if response.result.isSuccess {
                                if let json = response.result.value as? [[String:Any]] {
                                    if json.count > 0 {
                                        callback(LoadSecretResult.OK(secret: json[0]["word"] as! String))
                                    }
                                    else {
                                        callback(LoadSecretResult.Error(error: "JSON ARRAY IS EMPTY"))
                                    }
                                }
                                else {
                                    callback(LoadSecretResult.Error(error: "JSON DO NOT CONTAIN A SECRET"))
                                }
                            }
                            else {
                                callback(LoadSecretResult.Error(error: response.error.debugDescription))
                            }
                        }
                    }
                }
            }
        }
    }

    func getDefinition() {
        self.definition = nil
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            if let infoDictionary = NSDictionary(contentsOfFile: path) {
                if let baseURL = infoDictionary.object(forKey: "WordnikDefinitionURL") as? String {
                    if let key = infoDictionary.object(forKey: "WordnikKey") as? String {
                        if let secret = self.game?.secret {
                            Alamofire.request(String(format: baseURL, secret, key)).responseJSON { response in
                                if response.result.isSuccess {
                                    if let json = response.result.value as? [[String:Any]] {
                                        if json.count > 0 {
                                            self.definition = json[0]["text"] as? String
                                            if !self.gameLoading {
                                                self.definitionLabel.text = self.definition
                                            }
                                        }
                                        else {
                                            print("--- JSON ARRAY IS EMPTY ---")
                                        }
                                    }
                                    else {
                                        print("--- Warning JSON do not contain definition ---")
                                    }
                                }
                                else {
                                    print("--- SECRET Request Error \(response.error) ---")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    

    func showHelp() {
        wonLostMessageLabel.isHidden = true
        wonLostMessageLabel.textColor = greenColor

        secretLabel.textColor = greenColor
        definitionLabel.textColor = greenColor
        
        
        definitionLabel.text =      "Discover the Secret Word one letter at a time"
        wonLostMessageLabel.text =  "Wink with your Left or Rigth Eye to select a letter"
        secretLabel.text =          "Blink with both Eyes to confirn the letter to try"
        
        wonLostMessageLabel.isHidden = false
        carousel.removeFromSuperview()
    }
    
    func hideHelp() {
        secretLabel.textColor = greenColor
        definitionLabel.textColor = greenColor

        definitionLabel.text = ""
        secretLabel.text = ""
        carousel.isHidden = false
        
        wonLostMessageLabel.isHidden = true
        loadCarouselCharacter()
        resetCarousel(nil)
    }
    
    
//    enum LoadSecretResult {
//        case OK(secret: String)
//        case Error(error: String)
//    }
//    
    func startGame(timeOut: Double) {
        errorLoading = false
        
        gameLoading = true
        gameEnding = false
        showHelp()
        startingGameTime = CFAbsoluteTimeGetCurrent()
        
        hangmanImage.image = UIImage(named: "hangman_0.png")

        loadingTimer = Timer.scheduledTimer(timeInterval: timeOut, target: self,   selector: (#selector(ViewController.loadingTimeout)), userInfo: nil, repeats: false)

        //Start Game
        getSecret { (result) in
            switch result {
            case .OK(let secret):
                self.game = HangmanGame(secret: secret, maxFail: 9)
                self.getDefinition()
                
                let differentTime = CFAbsoluteTimeGetCurrent() - self.startingGameTime!
                
                if differentTime > timeOut  {
                    self.reallyStartGame()
                }
                else  {
                    self.startTimer = Timer.scheduledTimer(timeInterval: timeOut - differentTime, target: self,   selector: (#selector(ViewController.reallyStartGame)), userInfo: nil, repeats: false)
                }
            case .Error(let error):
                print("*** \(error) ***")
                self.secretLabel.text = "Network Error"
                self.errorLoading = true
            }
        }
    }
    
    
    func restartNewGame(timeOut: Double, won: Bool) {
        definitionLabel.text = "A new game will start in few seconds"
        
        wonLostMessageLabel.isHidden = false
        if won {
            wonLostMessageLabel.text = "😃 You Won!"
            wonLostMessageLabel.textColor = greenColor
        }
        else {
            wonLostMessageLabel.text = "😞 You Lost!"
            wonLostMessageLabel.textColor = .red
        }
        
        carousel.removeFromSuperview()
        gameEnding = true
        endingTimer = Timer.scheduledTimer(timeInterval: timeOut, target: self,   selector: (#selector(ViewController.endingTimeout)), userInfo: nil, repeats: false)
    }
    
    
    func loadingTimeout() {
        loadingTimer?.invalidate()
        loadingTimer = nil
        
        if gameLoading {
            hideHelp()
            
            if errorLoading {
                secretLabel.text = "Blink both Eyes for retry"
            }
            else {
                secretLabel.text = "loading ..."
            }
        }
    }

    
    func endingTimeout() {
        endingTimer?.invalidate()
        endingTimer = nil

        startGame(timeOut: restartTimerLength)
    }


    func reallyStartGame() {
        loadingTimer?.invalidate()
        loadingTimer = nil
        
        startTimer?.invalidate()
        startTimer = nil
        
        gameLoading = false
        gameEnding = false
        
        hideHelp()
        
        self.secretLabel.text = self.spaceString(self.game!.discovered)
        self.definitionLabel.text = self.definition
        self.carousel.selectItem(0, animated: true)
        saveGame()
    }

    func saveGame() {
        do {
            UserDefaults.standard.setValue(try self.game?.save(), forKey: "LastSavedGame")
            UserDefaults.standard.setValue(definition, forKey: "LastDefinition")
        }
        catch {
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        faceDetector.beginFaceDetection()
        
        let cameraView = faceDetector.cameraView
        view.addSubview(cameraView)
        
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        visualEffectView.frame = view.bounds
        visualEffectView.alpha = 0.8
        view.addSubview(visualEffectView)
        
        view.addSubview(faceMaskImage)
        view.addSubview(hangmanImage)
        view.addSubview(leftEyeGif)
        view.addSubview(rightEyeGif)
        view.addSubview(secretLabel)
        view.addSubview(definitionLabel)
        view.addSubview(carousel)
        view.addSubview(wonLostMessageLabel)
        
        if let lastSavedGame = UserDefaults.standard.value(forKey: "LastSavedGame") as? String {
            do {
                self.game = HangmanGame()
                if try self.game?.load(lastSavedGame) == .ok {
                    self.secretLabel.text = self.spaceString(self.game!.discovered)
                    
                    self.carousel.selectItem(0, animated: true)
                    hangmanImage.image = UIImage(named: "hangman_\(game!.failedAttempts).png")
                    for c in game!.lettersTried.characters {
                        let letter = String(c).uppercased()
                        resetCarousel(letter)
                    }
                    self.carousel.selectItem(0, animated: true)
                    
                    if let definition = UserDefaults.standard.value(forKey: "LastDefinition") as? String {
                        self.definitionLabel.text = definition
                        self.definition = definition
                    }
                    
                    saveGame()
                    gameLoading = false
                    gameEnding = false
                }
                else {
                    self.game = nil
                    startGame(timeOut: firstStartTimerLength)
                }
            }
            catch {
                self.game = nil
                startGame(timeOut: firstStartTimerLength)
            }
        }
        else {
            startGame(timeOut: firstStartTimerLength)
        }
    }
    
    
    override var prefersStatusBarHidden : Bool {
        return false
    }

    
    //MARK: FaceDetectorFilter Delegate
    func faceDetected() {
        cancel()
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, animations: {
                self.leftEyeGif.alpha = 1.0
                self.rightEyeGif.alpha = 1.0
            })
        }
    }
    
    func faceUnDetected() {
        cancel()
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, animations: {
                self.leftEyeGif.alpha = 0
                self.rightEyeGif.alpha = 0
            })
        }
    }
    
    func faceEyePosition(left: CGPoint, right: CGPoint) {
        if let leftPos = self.faceDetector.leftEyePosition, let rightPos = self.faceDetector.rightEyePosition {
            DispatchQueue.main.async {
                self.leftEyeGif.center = leftPos
                self.rightEyeGif.center = rightPos
                
                //better center eyes position based on gif file
                self.leftEyeGif.frame.origin.y -= 4
                self.rightEyeGif.frame.origin.y -= 4
            }
        }
    }
    
    func cancel() {
        eyesStatus = .blinking
        rightEyeGif.animate(withGIFNamed: "rightEye_Opening.gif", loopCount: 1)
        leftEyeGif.animate(withGIFNamed: "leftEye_Opening.gif", loopCount: 1)
        
        winkingTimer.invalidate()
        isWinkingTimerRunning = false
    }
    
    func runWinkerTimer() {
        if !isWinkingTimerRunning {
            isWinkingTimerRunning = true
            winkingTimer = Timer.scheduledTimer(timeInterval: 0.7, target: self,   selector: (#selector(ViewController.updateWinkerTimer)), userInfo: nil, repeats: false)
        }
    }
    
    func updateWinkerTimer() {
        SystemSoundID.playFileNamed("tick", withExtenstion: "aiff")
        if eyesStatus == .left {
            carousel.selectItem((carousel.selectedIndex! - 1) % carousel.items.count, animated: true)
        }
        else if eyesStatus == .right {
            carousel.selectItem((carousel.selectedIndex! + 1) % carousel.items.count, animated: true)
        }

        winkingTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self,   selector: (#selector(ViewController.updateWinkerTimer)), userInfo: nil, repeats: false)
    }
    
    func blinking() {
        if errorLoading {
            SystemSoundID.playFileNamed("blink", withExtenstion: "aiff")
            startGame(timeOut: restartTimerLength)
        }
        else if !gameLoading && !gameEnding {
            eyesStatus = .blinking
            rightEyeGif.animate(withGIFNamed: "rightEye_Closing.gif", loopCount: 1)
            leftEyeGif.animate(withGIFNamed: "leftEye_Closing.gif", loopCount: 1)
            
            if let _ = game {
                let letter = carouselCharacter[carousel.selectedIndex!]
                
                if removeSelectedWordFromCarousel {
                    resetCarousel(letter)
                }
                
                switch game!.tryLetter(letter) {
                case .invalidSecret:
                    print("invalidSecret")
                case .invalidWord:
                    print("invalidWord")
                case .alreadyTried:
                    print("alreadyTried")
                case .won:
                    //print("won")
                    secretLabel.textColor = greenColor
                    secretLabel.text = spaceString(game!.discovered)
                    SystemSoundID.playFileNamed("won", withExtenstion: "aiff")
                    restartNewGame(timeOut: endingTimerLength, won: true)
                case .lost:
                    //print("lost")
                    secretLabel.textColor = UIColor.red
                    definitionLabel.textColor = UIColor.red
                    secretLabel.text = spaceString(game!.secret)
                    SystemSoundID.playFileNamed("lost", withExtenstion: "aiff")
                    restartNewGame(timeOut: endingTimerLength, won: false)
                case .found:
                    //print("found")
                    secretLabel.text = spaceString(game!.discovered)
                    SystemSoundID.playFileNamed("blink", withExtenstion: "aiff")
                case .notFound:
                    //print("notFound")
                    secretLabel.text = spaceString(game!.discovered)
                    SystemSoundID.playFileNamed("buzzer", withExtenstion: "aiff")
                }
                
                hangmanImage.image = UIImage(named: "hangman_\(game!.failedAttempts).png")
                
                saveGame()
            }
        }
    }
    
    func leftWinking() {
        if !gameLoading && !gameEnding {
            eyesStatus = .left
            SystemSoundID.playFileNamed("tick", withExtenstion: "aiff")
            leftEyeGif.animate(withGIFNamed: "leftEye_Closing.gif", loopCount: 1)
            carousel.selectItem((carousel.selectedIndex! - 1) % carousel.items.count, animated: true)
            runWinkerTimer()
        }
    }
    
    func rightWinking() {
        if !gameLoading && !gameEnding {
            eyesStatus = .right
            SystemSoundID.playFileNamed("tick", withExtenstion: "aiff")
            rightEyeGif.animate(withGIFNamed: "rightEye_Closing.gif", loopCount: 1)
            carousel.selectItem((carousel.selectedIndex! + 1) % carousel.items.count, animated: true)
            runWinkerTimer()
        }
    }
}


extension ViewController: SwiftCarouselDelegate {
    
    func didSelectItem(item: UIView, index: Int, tapped: Bool) -> UIView? {
        if let current = item as? UILabel {
            current.font = UIFont(name: "HelveticaNeue-Bold", size: 38.0)
            
            if let g = game {
                if !removeSelectedWordFromCarousel {
                    if g.discovered.contains(current.text!.lowercased()) {
                        current.textColor = greenColor
                    }
                    else if g.lettersTried.contains(current.text!.lowercased()) {
                        current.textColor = UIColor.red
                    }
                    else {
                        current.textColor = UIColor.white
                    }
                }
            }
            else {
                current.textColor = UIColor.white
            }
            
            return current
        }
        
        return item
    }
    
    func didDeselectItem(item: UIView, index: Int) -> UIView? {
        if let current = item as? UILabel {
            current.font = UIFont(name: "HelveticaNeue-Light", size: carouselUnselectedFontSize)

            if let g = game {
                if g.discovered.contains(current.text!.lowercased()) {
                    current.textColor = greenColor
                }
                else if g.lettersTried.contains(current.text!.lowercased()) {
                    current.textColor = UIColor.red
                }
                else {
                    current.textColor = UIColor.white
                }
            }
            else {
                current.textColor = UIColor.white
            }

            return current
        }
        
        return item
    }
    
    func didScroll(toOffset offset: CGPoint) {
    }
    
//    func willBeginDragging(withOffset offset: CGPoint) {
//    }
    
//    func didEndDragging(withOffset offset: CGPoint) {
//    }
}

