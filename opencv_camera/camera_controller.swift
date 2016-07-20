//
//  camera_controller.swift
//  opencv_camera
//
//  Created by dyno on 7/18/16.
//  Copyright © 2016 dyno. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

public enum CameraFlash: Int {
    case Yes, No, Auto
}

public enum CameraQuality: Int {
    case Low, Medium, High, PresetPhoto
}

public class CameraController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    public var savePhotoToLibrary = true
    
    public let screenWidth = UIScreen.mainScreen().bounds.size.width
    public let screenHeight = UIScreen.mainScreen().bounds.size.height
    public let sectionInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    private let devices = AVCaptureDevice.devices()
    private var captureDevice : AVCaptureDevice?
    private let captureSession = AVCaptureSession()
    private var previewLayer : AVCaptureVideoPreviewLayer?
    private let stillImageOutput = AVCaptureStillImageOutput()
    private var cameraPosition = AVCaptureDevicePosition.Back
    
    private var cmbuffer:CMSampleBuffer?
    private let video_writer = VideoWriterObj.create()
    
    func initialize(file:String, view:UIView, fps:Int) {
        video_writer.iniliaze(file);
        
        device(AVCaptureDevicePosition.Back)
        if captureDevice == nil {
            return
        }
        
        do {
            try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
        } catch {
            print("Error")
        }
        
        do{
            try captureDevice?.lockForConfiguration()
            //let min = captureDevice?.activeFormat.videoSupportedFrameRateRanges[0].minFrameDuration
            //let max = captureDevice?.activeFormat.videoSupportedFrameRateRanges[0].maxFrameDuration
            captureDevice?.activeVideoMinFrameDuration = CMTimeMake(1, Int32(30));
            captureDevice?.activeVideoMaxFrameDuration = CMTimeMake(1, Int32(30));
            
            for range in (captureDevice?.activeFormat.videoSupportedFrameRateRanges)! {
                let raterage = range as? AVFrameRateRange
                NSLog("max frame:\(raterage?.maxFrameRate) min frame:\(raterage?.minFrameRate)")
            }
            
            captureDevice?.unlockForConfiguration()
        } catch let error as NSError {
            NSLog("lockForConfiguration err: \(error)")
        }
        
        outputToView(view)
        outputToBuffer()

    }
    
    private func outputToView(view:UIView){
        
        stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        if captureSession.canAddOutput(stillImageOutput) {
            captureSession.addOutput(stillImageOutput)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.frame = CGRectMake(0, 0, view.frame.width, view.frame.height)
        view.layer.addSublayer(previewLayer!)
    }
    
    private func outputToBuffer(){
        // Acquisition of output data
        let videoDataOutput:AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        
        // Set of color channel
        let dctPixelFormatType : Dictionary<NSString, NSNumber> = [kCVPixelBufferPixelFormatTypeKey : NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]
        videoDataOutput.videoSettings = dctPixelFormatType
        
        // Specified queue to capture the image
        //var videoDataOutputQueue: dispatch_queue_t = dispatch_queue_create("CtrlVideoQueue", DISPATCH_QUEUE_SERIAL)
        videoDataOutput.setSampleBufferDelegate(self, queue: dispatch_get_main_queue())
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
    }
    
    private var last:Double = NSDate().timeIntervalSince1970
    @objc public func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {

        cmbuffer = sampleBuffer
        
        let now:Double = NSDate().timeIntervalSince1970
        if record && now - last > 0.5 {
            video_writer.writerFrame(sampleBuffer);
            print("handleTimer \((now - last)*1000)")
            last = now
        }
        
        //print("handleTimer \((now - last)*1000)")
        //last = now
        
    }
    
    public var record = false {
        didSet{
            if record == false {
                video_writer.releaseObj()
            }
        }
    }
    
    public var flashMode = CameraFlash.No {
        willSet {
            for device in AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) {
                let captureDevice = device as! AVCaptureDevice
                if (captureDevice.position == AVCaptureDevicePosition.Back) {
                    let avFlashMode = AVCaptureFlashMode(rawValue: flashMode.rawValue)
                    if (captureDevice.isFlashModeSupported(avFlashMode!)) {
                        do {
                            try captureDevice.lockForConfiguration()
                            captureSession.beginConfiguration()
                            captureDevice.flashMode = avFlashMode!
                            captureSession.commitConfiguration()
                            captureDevice.unlockForConfiguration()
                        } catch {
                            return
                        }
                    }
                }
            }
        }
    }
    
    public var cameraQuality = CameraQuality.High {
        didSet {
            var sessionPreset = AVCaptureSessionPresetLow
            switch (cameraQuality) {
            case CameraQuality.Low:
                sessionPreset = AVCaptureSessionPresetLow
            case CameraQuality.Medium:
                sessionPreset = AVCaptureSessionPresetMedium
            case CameraQuality.High:
                sessionPreset = AVCaptureSessionPresetHigh
            case CameraQuality.PresetPhoto:
                sessionPreset = AVCaptureSessionPresetPhoto
            }
            captureSession.beginConfiguration()
            captureSession.sessionPreset = sessionPreset
            captureSession.commitConfiguration()
        }
    }
    
    public func startCamera(){
        
        captureSession.startRunning()
    }
    
    public func stopCamera(){
        captureSession.stopRunning();
    }
    
    public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?, view: UIView) {
        
        let focusX = touches.first!.locationInView(view).x / self.screenWidth
        let focusY = touches.first!.locationInView(view).y / self.screenHeight
        
        if cameraPosition == .Back {
            if let device = captureDevice {
                do {
                    try device.lockForConfiguration()
                    device.focusPointOfInterest = CGPointMake(focusX, focusY)
                    device.focusMode = AVCaptureFocusMode.AutoFocus
                    device.exposurePointOfInterest = CGPointMake(focusX, focusY)
                    device.exposureMode = AVCaptureExposureMode.ContinuousAutoExposure
                    device.unlockForConfiguration()
                } catch let error as NSError {
                    print(error.code)
                }
            }
        }
        
    }
    
    public func takePicture(view: UIView, imageGenerated: (UIImage?, NSError?) -> Void) {
        dispatch_async(dispatch_get_main_queue(), {
            if let videoConnection = self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo){
                self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {
                    (sampleBuffer, error) in
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProviderCreateWithCFData(imageData)
                    let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault )
                    let image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.Right)
                    
                    if (self.savePhotoToLibrary) {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    }
                    
                    self.captureSession.stopRunning()
                    
                    imageGenerated(image, nil)
                })
            }
        })
    }
    
    private func imageFromBuffer(buffer: CMSampleBuffer) -> UIImage{
        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
        let dataProvider = CGDataProviderCreateWithCFData(imageData)
        let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault )
        let image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.Right)
        return image;
    }
    
    public func changeCameraPosition() {
        let currentInput = captureSession.inputs[0] as! AVCaptureInput
        captureSession.removeInput(currentInput)
        
        cameraPosition = cameraPosition == .Back ? .Front : .Back
        self.device(cameraPosition)
    }
    
    private func device(type: AVCaptureDevicePosition) -> Bool {
        for device in devices {
            if (device.hasMediaType(AVMediaTypeVideo)) {
                if(device.position == type) {
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        
        if nil == captureDevice {
            NSLog("capture device error")
        }
        
        return captureDevice != nil
    }
    
    public func flashStatus(flashIcon: UIButton){
        switch self.flashMode{
        case .Yes:
            self.flashMode = .No
            flashIcon.setImage(UIImage(named: "no-flash.png"), forState: UIControlState.Normal)
        case .No:
            self.flashMode = .Yes
            flashIcon.setImage(UIImage(named: "flash.png"), forState: UIControlState.Normal)
        default:
            self.flashMode = .Auto
        }
    }
    
    private func imageToBase64(image: UIImage) -> String {
        let imageData = UIImagePNGRepresentation(image)
        
        let base64Encoded = imageData!.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        return base64Encoded
    }
    
}