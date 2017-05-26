//
//  FaceDetectorFilter.swift
//  FaceDetectorFilter
//
//  Created by Jacopo Mangiavacchi on 5/26/17.
//  Copyright © 2017 Jacopo. All rights reserved.
//

import UIKit

enum EyesStatus {
    case nothing
    case blinking
    case left
    case right
}

protocol FaceDetectorFilterDelegate {
    func faceDetected()
    func faceUnDetected()
    func faceEyePosition(left: CGPoint, right: CGPoint)
    func cancel()
    func blinking()
    func leftWinking()
    func rightWinking()
}

class FaceDetectorFilter: FaceDetectorDelegate {
    
    let faceDetector: FaceDetector!
    var delegate: FaceDetectorFilterDelegate!

    var eyesStatus: EyesStatus = .nothing
    //TODO: ADD CACHED eyesStatus !!!
    
    init(faceDetector: FaceDetector, delegate: FaceDetectorFilterDelegate) {
        self.faceDetector = faceDetector
        self.delegate = delegate
    }
    
    func faceDetectorEvent(_ events: [FaceDetectorEvent]) {
        if events.contains(.noFaceDetected) {
            DispatchQueue.main.async {
                self.delegate.faceUnDetected()
            }
        }
        
        if events.contains(.faceDetected) {
            DispatchQueue.main.async {
                self.delegate.faceDetected()
            }
        }
        
        if self.faceDetector.faceDetected {
            if let leftPos = self.faceDetector.leftEyePosition, let rightPos = self.faceDetector.rightEyePosition {
                DispatchQueue.main.async {
                    self.delegate.faceEyePosition(left: leftPos, right: rightPos)
                }
            }
            
            if events.contains(.blinking) {
                eyesStatus = .blinking
                DispatchQueue.main.async {
                    self.delegate.blinking()
                }
            }
            else if events.contains(.notBlinking) {
                eyesStatus = .nothing
                DispatchQueue.main.async {
                    self.delegate.cancel()
                }
            }
            else if events.contains(.winking) {
                if events.contains(.leftEyeClosed) {
                    eyesStatus = .left
                    DispatchQueue.main.async {
                        self.delegate.leftWinking()
                    }
                }
                else if events.contains(.rightEyeClosed) {
                    eyesStatus = .right
                    DispatchQueue.main.async {
                        self.delegate.rightWinking()
                    }
                }
            }
            else if events.contains(.notWinking) {
                eyesStatus = .nothing
                DispatchQueue.main.async {
                    self.delegate.cancel()
                }
            }
            else {
                if  (eyesStatus == .blinking && !self.faceDetector.isBlinking) ||
                    (eyesStatus == .left && !self.faceDetector.leftEyeClosed) ||
                    (eyesStatus == .right && !self.faceDetector.rightEyeClosed) {
                    eyesStatus = .nothing
                    DispatchQueue.main.async {
                        self.delegate.cancel()
                    }
                }
            }
        }
    }
}
