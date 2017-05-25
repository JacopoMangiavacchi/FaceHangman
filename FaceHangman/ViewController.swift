//
//  ViewController.swift
//  FaceHangman
//
//  Created by Jacopo Mangiavacchi on 5/23/17.
//  Copyright © 2017 Jacopo. All rights reserved.
//

import UIKit
import Gifu

class ViewController: UIViewController, FaceDetectorDelegate {
    lazy var faceDetector: FaceDetector = {
        var temp = FaceDetector()
        temp.delegate = self
        return temp
    }()

    lazy var hangmanImage: UIImageView = {
        var temp = UIImageView(frame: CGRect(x: 0,
                                             y: 0,
                                             width: UIScreen.main.bounds.width,
                                             height: UIScreen.main.bounds.height))
        temp.image = UIImage(named: "hangman.png")
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
        let temp = GIFImageView(frame: CGRect(x: 80, y: 250, width: 150, height: 80))
        temp.animate(withGIFNamed: "rightEye.gif")
        return temp
    }()

    lazy var leftEyeGif: GIFImageView = {
        let temp = GIFImageView(frame: CGRect(x: 180, y: 250, width: 150, height: 80))
        temp.animate(withGIFNamed: "leftEye.gif")
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

    let greenColor = UIColor(red: 212/255.0, green: 234/255.0, blue: 95/255.0, alpha: 1.0)

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        faceDetector.beginFaceDetection()
        
        let cameraView = faceDetector.cameraView
        self.view.addSubview(cameraView)
        
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        visualEffectView.frame = self.view.bounds
        visualEffectView.alpha = 0.8
        self.view.addSubview(visualEffectView)
        
        self.view.addSubview(faceMaskImage)
        self.view.addSubview(hangmanImage)
        self.view.addSubview(leftEyeGif)
        self.view.addSubview(rightEyeGif)
//        self.view.addSubview(faceRect)
    }
    
    override var prefersStatusBarHidden : Bool {
        return false
    }

    
    //MARK: FaceDetector Delegate
    
    func faceDetectorEvent(_ events: [FaceDetectorEvent]) {
//        if events.contains(.faceDetected) {
//            DispatchQueue.main.async {
//                UIView.animate(withDuration: 0.5, animations: {
//                    self.faceRect.alpha = 0.5
//                })
//            }
//        }
//        if events.contains(.noFaceDetected) {
//            DispatchQueue.main.async {
//                UIView.animate(withDuration: 0.3, animations: {
//                    self.faceRect.alpha = 0
//                })
//            }
//        }
//        if let bounds = self.faceDetector.faceBounds, self.faceDetector.faceDetected {
//            DispatchQueue.main.async {
//                self.faceRect.frame = bounds
//            }
//        }

        if events.contains(.faceDetected) {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.5, animations: {
                    self.leftEyeGif.alpha = 1.0
                    self.rightEyeGif.alpha = 1.0
                })
            }
        }
        if events.contains(.noFaceDetected) {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3, animations: {
                    self.leftEyeGif.alpha = 0
                    self.rightEyeGif.alpha = 0
                })
            }
        }
        if let leftPos = self.faceDetector.leftEyePosition, let rightPos = self.faceDetector.rightEyePosition, self.faceDetector.faceDetected {
            DispatchQueue.main.async {
                self.leftEyeGif.center = leftPos
                self.rightEyeGif.center = rightPos
            }
        }
        
        
//        if let pos = self.faceDetector.leftEyePosition {
//            self.leftEyeGif.center = pos
//        }
//        if let pos = self.faceDetector.rightEyePosition {
//            self.rightEyeGif.center = pos
//        }
    }
}
