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

class ViewController: UIViewController, FaceDetectorFilterDelegate {

    let greenColor = UIColor(red: 212/255.0, green: 234/255.0, blue: 95/255.0, alpha: 1.0)

    var items: [String]?
    var itemsViews: [UILabel]?
    
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
        return temp
    }()

    lazy var faceMaskImage: UIImageView = {
        var temp = UIImageView(frame: CGRect(x: 0,
                                             y: 0,
                                             width: UIScreen.main.bounds.width,
                                             height: UIScreen.main.bounds.height))
        temp.image = UIImage(named: "faceMask.png")
        temp.alpha = 0.6
        return temp
    }()
    
    lazy var rightEyeGif: GIFImageView = {
        let temp = GIFImageView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width / 2.1, height: UIScreen.main.bounds.height / 7.1))  //150x80
        temp.alpha = 0.0
        temp.animate(withGIFNamed: "rightEye_Opening.gif", loopCount: 1)
        return temp
    }()

    lazy var leftEyeGif: GIFImageView = {
        let temp = GIFImageView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width / 2.1, height: UIScreen.main.bounds.height / 7.1)) //150x80
        temp.alpha = 0.0
        temp.animate(withGIFNamed: "leftEye_Opening.gif", loopCount: 1)
        return temp
    }()

//    lazy var faceRect: UIView = {
//        var temp = UIView(frame: CGRect(x: 0,
//                                             y: 0,
//                                             width: UIScreen.main.bounds.width,
//                                             height: UIScreen.main.bounds.height))
//        temp.backgroundColor = UIColor.orange
//        temp.alpha = 0.4
//        return temp
//    }()

    lazy var carousel: SwiftCarousel = {
        var carousel = SwiftCarousel(frame: CGRect(x: 0,
                                         y: 20,
                                         width: UIScreen.main.bounds.width,
                                         height: UIScreen.main.bounds.height / 10))
        self.items = (0..<26).map { String(format: "%c", 65 + $0) }
        
        self.itemsViews = self.items!.map { self.labelForString($0) }
        carousel.items = self.itemsViews!
        carousel.resizeType = .visibleItemsPerPage(5)
        carousel.defaultSelectedIndex = 0
        carousel.delegate = self
        carousel.scrollType = .default
        

        return carousel
    }()

    lazy var label: UILabel = {
        var temp = UILabel(frame: CGRect(x: 0,
                                             y: 20 + UIScreen.main.bounds.height / 10,
                                             width: UIScreen.main.bounds.width,
                                             height: UIScreen.main.bounds.height / 10))
        temp.textColor = self.greenColor
        temp.font = UIFont(name: "HelveticaNeue-Light", size: 32.0)
        temp.textAlignment = .center
        temp.minimumScaleFactor = 10/UIFont.labelFontSize
        temp.adjustsFontSizeToFitWidth = true
        return temp
    }()

    var timer = Timer()
    var isTimerRunning = false
    
    var game: HangmanGame?
    
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
        view.addSubview(label)
        view.addSubview(carousel)
//        self.view.addSubview(faceRect)
        
        label.text = "loading ..."
        
        //Start Game
        let APIKEY = "31b3a219fca1714c8200f0c4bbb0813f18b404b16bb3ee8ae"
        let URL = "https://api.wordnik.com/v4/words.json/randomWords?hasDictionaryDef=true&minCorpusCount=0&minLength=5&maxLength=15&limit=1&api_key=\(APIKEY)"
        
        Alamofire.request(URL).responseJSON { response in
            if let json = response.result.value as? [[String:Any]] {
                print(json)
                self.game = HangmanGame(secret: json[0]["word"] as! String, maxFail: 9)
                self.label.text = self.game?.discovered.uppercased()
            }
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return false
    }

    
    func labelForString(_ string: String) -> UILabel {
        let text = UILabel()
        text.text = string
        text.textColor = .white
        text.textAlignment = .center
        text.font = UIFont(name: "HelveticaNeue-Light", size: 28.0)
        text.numberOfLines = 0
        
        return text
    }

    
    //MARK: FaceDetectorFilter Delegate
    func faceDetected() {
//        UIView.animate(withDuration: 0.5, animations: {
//            self.faceRect.alpha = 0.5
//        })
        
        cancel()
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, animations: {
                self.leftEyeGif.alpha = 1.0
                self.rightEyeGif.alpha = 1.0
            })
        }
    }
    
    func faceUnDetected() {
//        UIView.animate(withDuration: 0.3, animations: {
//            self.faceRect.alpha = 0
//        })
        
        cancel()
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, animations: {
                self.leftEyeGif.alpha = 0
                self.rightEyeGif.alpha = 0
            })
        }
    }
    
    func faceEyePosition(left: CGPoint, right: CGPoint) {
//        if let bounds = self.faceDetector.faceBounds, self.faceDetector.faceDetected {
//            DispatchQueue.main.async {
//                self.faceRect.frame = bounds
//            }
//        }
        
        if let leftPos = self.faceDetector.leftEyePosition, let rightPos = self.faceDetector.rightEyePosition {
            DispatchQueue.main.async {
                self.leftEyeGif.center = leftPos
                self.rightEyeGif.center = rightPos
            }
        }
    }
    
    func cancel() {
        eyesStatus = .blinking
        rightEyeGif.animate(withGIFNamed: "rightEye_Opening.gif", loopCount: 1)
        leftEyeGif.animate(withGIFNamed: "leftEye_Opening.gif", loopCount: 1)
        
        timer.invalidate()
        isTimerRunning = false
    }
    
    func runTimer() {
        if !isTimerRunning {
            isTimerRunning = true
            timer = Timer.scheduledTimer(timeInterval: 0.7, target: self,   selector: (#selector(ViewController.updateTimer)), userInfo: nil, repeats: false)
        }
    }
    
    func updateTimer() {
        SystemSoundID.playFileNamed("tick", withExtenstion: "aiff")
        if eyesStatus == .left {
            carousel.selectItem((carousel.selectedIndex! - 1) % 26, animated: true)
        }
        else if eyesStatus == .right {
            carousel.selectItem((carousel.selectedIndex! + 1) % 26, animated: true)
        }

        timer = Timer.scheduledTimer(timeInterval: 0.2, target: self,   selector: (#selector(ViewController.updateTimer)), userInfo: nil, repeats: false)
    }
    
    func blinking() {
        eyesStatus = .blinking
        rightEyeGif.animate(withGIFNamed: "rightEye_Closing.gif", loopCount: 1)
        leftEyeGif.animate(withGIFNamed: "leftEye_Closing.gif", loopCount: 1)
        
        if let _ = game {
            switch game!.tryLetter(String(format: "%c", 65 + carousel.selectedIndex!)) {
            case .invalidSecret:
                print("invalidSecret")
            case .invalidWord:
                print("invalidWord")
            case .alreadyTried:
                print("alreadyTried")
            case .won:
                print("won")
                label.textColor = UIColor.white
                SystemSoundID.playFileNamed("blink", withExtenstion: "aiff")
            case .lost:
                print("lost")
                label.textColor = UIColor.red
                SystemSoundID.playFileNamed("buzzer", withExtenstion: "aiff")
            case .found:
                print("found")
                SystemSoundID.playFileNamed("blink", withExtenstion: "aiff")
            case .notFound:
                print("notFound")
                (carousel.items[carousel.selectedIndex!] as? UILabel)?.textColor = UIColor.red
                SystemSoundID.playFileNamed("buzzer", withExtenstion: "aiff")
            }

            label.text = game!.discovered.uppercased()
            hangmanImage.image = UIImage(named: "hangman_\(game!.failedAttempts).png")
        }
    }
    
    func leftWinking() {
        eyesStatus = .left
        SystemSoundID.playFileNamed("tick", withExtenstion: "aiff")
        leftEyeGif.animate(withGIFNamed: "leftEye_Closing.gif", loopCount: 1)
        carousel.selectItem((carousel.selectedIndex! - 1) % 26, animated: true)
        runTimer()
    }
    
    func rightWinking() {
        eyesStatus = .right
        SystemSoundID.playFileNamed("tick", withExtenstion: "aiff")
        rightEyeGif.animate(withGIFNamed: "rightEye_Closing.gif", loopCount: 1)
        carousel.selectItem((carousel.selectedIndex! + 1) % 26, animated: true)
        runTimer()
    }
}


extension ViewController: SwiftCarouselDelegate {
    
    func didSelectItem(item: UIView, index: Int, tapped: Bool) -> UIView? {
        if let current = item as? UILabel {
            current.font = UIFont(name: "HelveticaNeue-Bold", size: 38.0)
            
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
    
    func didDeselectItem(item: UIView, index: Int) -> UIView? {
        if let current = item as? UILabel {
            current.font = UIFont(name: "HelveticaNeue-Light", size: 28.0)

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

