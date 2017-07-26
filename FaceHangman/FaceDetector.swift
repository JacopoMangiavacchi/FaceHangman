//
//  FaceDetector.swift
//  FaceDetector
//
//  Created by Jacopo Mangiavacchi on 5/23/17.
//  Copyright © 2017 Jacopo. All rights reserved.
//
//  Readapted from Visage.swift  Created by Julian Abentheuer on 21.12.14.
//  Copyright (c) 2014 Aaron Abentheuer. All rights reserved.
//

import UIKit
import CoreImage
import AVFoundation
import ImageIO

enum FaceDetectorEvent {
    case noFaceDetected
    case faceDetected
    case smiling
    case notSmiling
    case blinking
    case notBlinking
    case winking
    case notWinking
    case leftEyeClosed
    case leftEyeOpen
    case rightEyeClosed
    case rightEyeOpen
}

protocol FaceDetectorDelegate {
    func faceDetectorEvent(_ events: [FaceDetectorEvent])
}

class FaceDetector: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var delegate: FaceDetectorDelegate?
    
    var cameraView : UIView = UIView()
    
    //Private properties of the detected face that can be accessed (read-only) by other classes.
    fileprivate(set) var faceDetected  = false
    fileprivate(set) var hasSmile = false
    fileprivate(set) var isBlinking = false
    fileprivate(set) var isWinking = false
    fileprivate(set) var leftEyeClosed = false
    fileprivate(set) var rightEyeClosed = false
    fileprivate(set) var faceBounds: CGRect?
    fileprivate(set) var faceAngle: CGFloat?
    fileprivate(set) var faceAngleDifference: CGFloat?
    fileprivate(set) var leftEyePosition: CGPoint?
    fileprivate(set) var rightEyePosition: CGPoint?
    fileprivate(set) var mouthPosition: CGPoint?
    
    //Private variables that cannot be accessed by other classes in any way.
    fileprivate var detector : CIDetector?
    fileprivate var videoDataOutput : AVCaptureVideoDataOutput?
    fileprivate var videoDataOutputQueue : DispatchQueue?
    fileprivate var cameraPreviewLayer : AVCaptureVideoPreviewLayer?
    fileprivate var captureSession : AVCaptureSession = AVCaptureSession()
    fileprivate var currentOrientation : Int?
    
    override init()  {
        super.init()
        
        captureSetup(AVCaptureDevice.Position.front)
        detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh as AnyObject])
    }
    
    //MARK: SETUP OF VIDEOCAPTURE
    func beginFaceDetection() {
        self.captureSession.startRunning()
    }
    
    func endFaceDetection() {
        self.captureSession.stopRunning()
    }
    
    fileprivate func captureSetup (_ position : AVCaptureDevice.Position) {
        var captureError : NSError?
        
        let devices = AVCaptureDevice.DiscoverySession(__deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: .video, position: AVCaptureDevice.Position.front).devices
        
        if devices.count > 0 {
            let captureDevice = devices[0]
            var deviceInput : AVCaptureDeviceInput?
            do {
                deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            } catch let error as NSError {
                captureError = error
                deviceInput = nil
            }
            captureSession.sessionPreset = AVCaptureSession.Preset.high
            
            if captureError == nil {
                if captureSession.canAddInput(deviceInput!) {
                    captureSession.addInput(deviceInput!)
                }
                
                self.videoDataOutput = AVCaptureVideoDataOutput()
                self.videoDataOutput!.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: Int(kCVPixelFormatType_32BGRA)]
                self.videoDataOutput!.alwaysDiscardsLateVideoFrames = true
                self.videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue", attributes: [])
                self.videoDataOutput!.setSampleBufferDelegate(self, queue: self.videoDataOutputQueue!)
                
                if captureSession.canAddOutput(self.videoDataOutput!) {
                    captureSession.addOutput(self.videoDataOutput!)
                }
            }
            
            cameraView.frame = UIScreen.main.bounds
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = UIScreen.main.bounds
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            cameraView.layer.addSublayer(previewLayer)
        }
    }
    
    var options : [String : AnyObject]?
    
    //MARK: CAPTURE-OUTPUT/ANALYSIS OF FACIAL-FEATURES
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let opaqueBuffer = Unmanaged<CVImageBuffer>.passUnretained(imageBuffer!).toOpaque()
        let pixelBuffer = Unmanaged<CVPixelBuffer>.fromOpaque(opaqueBuffer).takeUnretainedValue()
        let sourceImage = CIImage(cvPixelBuffer: pixelBuffer, options: nil)
        //options = [CIDetectorSmile : true as AnyObject, CIDetectorEyeBlink: true as AnyObject, CIDetectorImageOrientation : 5 as AnyObject]  //6
        options = [CIDetectorEyeBlink: true as AnyObject, CIDetectorImageOrientation : 5 as AnyObject]  //6
        
        let features = self.detector!.features(in: sourceImage, options: options)
        
        var delegateEvents = [FaceDetectorEvent]()
        
        if features.count != 0 {
            if !faceDetected {
                faceDetected = true
                delegateEvents.append(.faceDetected)
            }
            
            //for feature in features as! [CIFaceFeature] {
            //Detect only the first face !!!
            let faceFeatures = features as! [CIFaceFeature]
            if faceFeatures.count > 0 {
                let feature = faceFeatures[0]
                faceBounds = transformFacialFeatureRect(feature.bounds, videoRect: sourceImage.extent, previewRect: self.cameraView.bounds, isMirrored: true)
                
                if feature.hasFaceAngle {
                    
                    if (faceAngle != nil) {
                        faceAngleDifference = CGFloat(feature.faceAngle) - faceAngle!
                    } else {
                        faceAngleDifference = CGFloat(feature.faceAngle)
                    }
                    
                    faceAngle = CGFloat(feature.faceAngle)
                }
                
                if feature.hasLeftEyePosition {
                    leftEyePosition = transformFacialFeaturePoint(feature.leftEyePosition, videoRect: sourceImage.extent, previewRect: self.cameraView.bounds, isMirrored: true)
                }
                
                if feature.hasRightEyePosition {
                    rightEyePosition = transformFacialFeaturePoint(feature.rightEyePosition, videoRect: sourceImage.extent, previewRect: self.cameraView.bounds, isMirrored: true)
                }
                
                if feature.hasMouthPosition {
                    mouthPosition = transformFacialFeaturePoint(feature.mouthPosition, videoRect: sourceImage.extent, previewRect: self.cameraView.bounds, isMirrored: true)
                }
                
                if hasSmile != feature.hasSmile {
                    if feature.hasSmile {
                        delegateEvents.append(.smiling)
                    } else {
                        delegateEvents.append(.notSmiling)
                    }
                }
                hasSmile = feature.hasSmile

                if feature.leftEyeClosed && feature.rightEyeClosed {
                    if !isBlinking {
                        delegateEvents.append(.blinking)
                        isBlinking = true
                    }
                    if isWinking {
                        delegateEvents.append(.notWinking)
                        isWinking = false
                    }
                    if !leftEyeClosed {
                        delegateEvents.append(.leftEyeClosed)
                        leftEyeClosed = true
                    }
                    if !rightEyeClosed {
                        delegateEvents.append(.rightEyeClosed)
                        rightEyeClosed = true
                    }
                }
                else if feature.leftEyeClosed || feature.rightEyeClosed {
                    if !isWinking {
                        delegateEvents.append(.winking)
                        isWinking = true
                    }
                    if isBlinking {
                        delegateEvents.append(.notBlinking)
                        isBlinking = false
                    }
                    if feature.leftEyeClosed && !leftEyeClosed {
                        delegateEvents.append(.leftEyeClosed)
                        leftEyeClosed = true
                        if rightEyeClosed {
                            delegateEvents.append(.rightEyeOpen)
                            rightEyeClosed = false
                        }
                    }
                    else if feature.rightEyeClosed && !rightEyeClosed {
                        delegateEvents.append(.rightEyeClosed)
                        rightEyeClosed = true
                        if leftEyeClosed {
                            delegateEvents.append(.leftEyeOpen)
                            leftEyeClosed = false
                        }
                    }
                }
                else { //Both eyes opened
                    if isBlinking {
                        delegateEvents.append(.notBlinking)
                        isBlinking = false
                    }
                    if isWinking {
                        delegateEvents.append(.notWinking)
                        isWinking = false
                    }
                    if leftEyeClosed {
                        delegateEvents.append(.leftEyeOpen)
                        leftEyeClosed = false
                    }
                    if rightEyeClosed {
                        delegateEvents.append(.rightEyeOpen)
                        rightEyeClosed = false
                    }
                }
            }
        }
        else {
            if faceDetected {
                delegateEvents.append(.noFaceDetected)
                faceDetected = false
            }
            if hasSmile {
                delegateEvents.append(.notSmiling)
                hasSmile = false
            }
            if isBlinking {
                delegateEvents.append(.notBlinking)
                isBlinking = false
            }
            if isWinking {
                delegateEvents.append(.notWinking)
                isWinking = false
            }
            if leftEyeClosed {
                delegateEvents.append(.leftEyeOpen)
                leftEyeClosed = false
            }
            if rightEyeClosed {
                delegateEvents.append(.rightEyeOpen)
                rightEyeClosed = false
            }
        }
        
        delegate?.faceDetectorEvent(delegateEvents)
    }
    
    internal func transformFacialFeaturePoint(_ position: CGPoint, videoRect: CGRect, previewRect: CGRect, isMirrored: Bool) -> CGPoint {
        var featureRect = CGRect(origin: position, size: CGSize(width: 0, height: 0))
        let widthScale = previewRect.size.width / videoRect.size.height
        let heightScale = previewRect.size.height / videoRect.size.width
        
        let transform = isMirrored ? CGAffineTransform(a: 0, b: heightScale, c: -widthScale, d: 0, tx: previewRect.size.width, ty: 0) :
            CGAffineTransform(a: 0, b: heightScale, c: widthScale, d: 0, tx: 0, ty: 0)
        
        featureRect = featureRect.applying(transform)
        
        featureRect = featureRect.offsetBy(dx: previewRect.origin.x, dy: previewRect.origin.y)
        
        return featureRect.origin
    }

    internal func transformFacialFeatureRect(_ featureRect: CGRect, videoRect: CGRect, previewRect: CGRect, isMirrored: Bool) -> CGRect {
        let widthScale = previewRect.size.width / videoRect.size.height
        let heightScale = previewRect.size.height / videoRect.size.width
        
        let transform = isMirrored ? CGAffineTransform(a: 0, b: heightScale, c: -widthScale, d: 0, tx: previewRect.size.width, ty: 0) :
            CGAffineTransform(a: 0, b: heightScale, c: widthScale, d: 0, tx: 0, ty: 0)
        
        var transformedRect = featureRect.applying(transform)
        
        transformedRect = transformedRect.offsetBy(dx: previewRect.origin.x, dy: previewRect.origin.y)
        
        return transformedRect
    }
}
