//
//  CameraManager.swift
//  QuickCamera
//
//  Created by Georgij Emelyanov on 15/09/2019.
//  Copyright © 2019 Georgij Emelyanov. All rights reserved.
//

import UIKit
import AVFoundation

extension CameraManager {
    typealias ConfigurationCompletion = ((Error?) -> Void)
    typealias CapturingImageCompletion = ((UIImage?, Error?) -> Void)
    typealias BoolCompletion = ((Bool) -> Void)
    typealias PermissionsStatuses = (camera: AVAuthorizationStatus, audio: AVAuthorizationStatus)
    
    enum CameraPosition {
        case front, back
    }
    
    enum CameraManagerError: Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case noSampleBuffer
        case unknown
    }
    
    private enum SessionSetupResult {
        case notAuthorized
        case readyToStart
    }
}

final class CameraManager: NSObject, UIGestureRecognizerDelegate {
    
    weak var delegate: CameraManagerDelegate?
    var flashMode: AVCaptureDevice.FlashMode = .off
    var outputFolder: String = NSTemporaryDirectory()
    
    private let sessionQueue: DispatchQueue = DispatchQueue(label: "CameraSessionQueue")
    private let captureSession: AVCaptureSession = AVCaptureSession()
    private var currentCameraPosition: CameraPosition = .back
    private var focusMode: AVCaptureDevice.FocusMode = .continuousAutoFocus
    private var isVideoRecording: Bool = false
    private var backgroundRecordingID: UIBackgroundTaskIdentifier? = nil
    
    private var setupResult: SessionSetupResult = .notAuthorized
    
    private var frontCamera: AVCaptureDevice?
    private var backCamera: AVCaptureDevice?
    
    private var frontCameraInput: AVCaptureDeviceInput?
    private var backCameraInput: AVCaptureDeviceInput?
    
    private var photoOutput: AVCapturePhotoOutput?
    private var movieFileOutput: AVCaptureMovieFileOutput?
    
    private var photoCaptureCompletionBlock: CapturingImageCompletion?
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private lazy var focusGesture: UITapGestureRecognizer = {
        let focusGR = UITapGestureRecognizer()
        focusGR.cancelsTouchesInView = false
        return focusGR
    }()
    
    
    func fetchPermissionsStatus() -> PermissionsStatuses {
        return PermissionsStatuses(AVCaptureDevice.authorizationStatus(for: .video),
                                   AVCaptureDevice.authorizationStatus(for: .audio))
    }
    
    func requestVideoAccess(_ completion: @escaping BoolCompletion) {
        AVCaptureDevice.requestAccess(for: .video) { isSuccess in
            completion(isSuccess)
        }
    }
    
    func requestAudioAccess(_ completion: @escaping BoolCompletion) {
        AVCaptureDevice.requestAccess(for: .audio) { isSuccess in
            completion(isSuccess)
        }
    }
    
    func configure(completionHandler: @escaping ConfigurationCompletion) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                self.captureSession.beginConfiguration()
                try self.configureCaptureDevices()
                try self.configureDeviceInputs()
                try self.configurePhotoOutput()
                self.captureSession.commitConfiguration()
                self.captureSession.startRunning()
            }
            catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                return
            }
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    func configureAudioInput(completionHandler: @escaping ConfigurationCompletion) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                self.captureSession.beginConfiguration()
                try self.configureAudioInput()
                self.captureSession.commitConfiguration()
            } catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
            }
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    func configureVideoOutput(completionHandler: @escaping ConfigurationCompletion) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                self.captureSession.beginConfiguration()
                try self.configureVideoOutput()
                self.captureSession.commitConfiguration()
            } catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
            }
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    func stopSession() {
        guard captureSession.isRunning else { return }
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }
    
    func startSession() {
        guard setupResult == .readyToStart else { return }
        sessionQueue.async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    func connectSession(to view: CaptureView) throws {
        view.previewLayer.session = captureSession
        previewLayer = view.previewLayer
    }
    
    func displayPreview(on view: CaptureView) throws {
        guard captureSession.isRunning else { throw CameraManagerError.captureSessionIsMissing }
        
        view.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.previewLayer.connection?.videoOrientation = .portrait
        
        attachFocus(to: view)
    }
    
    func captureImage(completion: @escaping CapturingImageCompletion) {
        guard captureSession.isRunning else {
            completion(nil, CameraManagerError.captureSessionIsMissing)
            return
        }
        
        self.photoCaptureCompletionBlock = completion
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = self.flashMode
        
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    func startVideoRecording() throws {
        guard captureSession.isRunning else { throw CameraManagerError.captureSessionIsMissing }
        
        guard let movieFileOutput = self.movieFileOutput else {
            // throw error
            return
        }
        
        enableFlashIfNeeded()
        
        let previewOrientation = previewLayer?.connection!.videoOrientation
        
        sessionQueue.async { [weak self] in
            guard let self = self else {
                // TODO: выбрасывать ошибки на главном потоке
                return
            }
            
            if movieFileOutput.isRecording {
                movieFileOutput.stopRecording()
            }
            else {
                if UIDevice.current.isMultitaskingSupported {
                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                }
                
                let movieFileOutputConnection = self.movieFileOutput?.connection(with: AVMediaType.video)
                
                if self.currentCameraPosition == .front {
                    movieFileOutputConnection?.isVideoMirrored = true
                }
                
                movieFileOutputConnection?.videoOrientation = previewOrientation!
                
                let outputFileName = UUID().uuidString
                let outputFilePath = (self.outputFolder as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
                movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
                self.isVideoRecording = true
            }
        }
    }
    
    func stopVideoRecording() {
        if self.isVideoRecording == true {
            self.isVideoRecording = false
            movieFileOutput!.stopRecording()
            disableFlashIfNeeded()
        }
    }
    
    func updateVideoOrientation(_ orientation: UIDeviceOrientation, onView view: CaptureView) {
        switch (orientation) {
        case .portrait, .faceDown, .faceUp, .unknown:
            view.previewLayer.connection?.videoOrientation = .portrait
            
        case .landscapeRight:
            view.previewLayer.connection?.videoOrientation = .landscapeLeft
            
        case .landscapeLeft:
            view.previewLayer.connection?.videoOrientation = .landscapeRight
            
        case .portraitUpsideDown:
            view.previewLayer.connection?.videoOrientation = .portraitUpsideDown
            
        @unknown default:
            view.previewLayer.connection?.videoOrientation = .portrait
        }
    }
    
    func switchCameras() throws {
        guard captureSession.isRunning else { throw CameraManagerError.captureSessionIsMissing }
        
        captureSession.beginConfiguration()
        
        func switchToFrontCamera() throws {
            
            guard
                let backCameraInput = self.backCameraInput,
                captureSession.inputs.contains(backCameraInput),
                let frontCamera = self.frontCamera
                else { throw CameraManagerError.invalidOperation }
            
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            
            captureSession.removeInput(backCameraInput)
            
            if captureSession.canAddInput(self.frontCameraInput!) {
                captureSession.addInput(self.frontCameraInput!)
                
                self.currentCameraPosition = .front
            } else {
                throw CameraManagerError.invalidOperation
            }
        }
        
        func switchToRearCamera() throws {
            guard
                let frontCameraInput = self.frontCameraInput,
                captureSession.inputs.contains(frontCameraInput),
                let backCamera = self.backCamera
                else { throw CameraManagerError.invalidOperation }
            
            self.backCameraInput = try AVCaptureDeviceInput(device: backCamera)
            
            captureSession.removeInput(frontCameraInput)
            
            if captureSession.canAddInput(self.backCameraInput!) {
                captureSession.addInput(self.backCameraInput!)
                
                self.currentCameraPosition = .back
            } else {
                throw CameraManagerError.invalidOperation
            }
        }
        
        switch currentCameraPosition {
        case .front:
            try switchToRearCamera()
            
        case .back:
            try switchToFrontCamera()
        }
        
        captureSession.commitConfiguration()
    }
}

private extension CameraManager {
    func configureCaptureDevices() throws {
        let devices: [AVCaptureDevice] = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified).devices
        guard !devices.isEmpty else { throw CameraManagerError.noCamerasAvailable }
        
        try devices.forEach { device in
            if device.position == .front {
                self.frontCamera = device
            }
            if device.position == .back {
                self.backCamera = device
                
                try device.lockForConfiguration()
                device.focusMode = .autoFocus
                device.unlockForConfiguration()
            }
        }
    }
    
    func configureDeviceInputs() throws {
        if let backCamera = self.backCamera {
            self.backCameraInput = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(self.backCameraInput!) {
                captureSession.addInput(self.backCameraInput!)
            }
            self.currentCameraPosition = .back
            
        } else if let frontCamera = self.frontCamera {
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            
            if captureSession.canAddInput(self.frontCameraInput!) {
                captureSession.addInput(self.frontCameraInput!)
            } else {
                throw CameraManagerError.inputsAreInvalid
            }
            
            self.currentCameraPosition = .front
            
        } else {
            throw CameraManagerError.noCamerasAvailable
        }
    }
    
    func configureAudioInput() throws {
        if let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio){
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            if captureSession.canAddInput(audioDeviceInput) {
                captureSession.addInput(audioDeviceInput)
            }
        } else {
            throw CameraManagerError.inputsAreInvalid
        }
    }
    
    func configurePhotoOutput() throws {
        photoOutput = AVCapturePhotoOutput()
        photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecJPEG])], completionHandler: nil)
        
        if captureSession.canAddOutput(self.photoOutput!) {
            captureSession.addOutput(self.photoOutput!)
        }
        setupResult = .readyToStart
    }
    
    func configureVideoOutput() throws {
        let movieFileOutput = AVCaptureMovieFileOutput()
        
        if captureSession.canAddOutput(movieFileOutput) {
            captureSession.addOutput(movieFileOutput)
            if let connection = movieFileOutput.connection(with: AVMediaType.video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            self.movieFileOutput = movieFileOutput
        }
    }
    
    func rotateImageIfNedded(_ originalImage: UIImage, cameraPosition: AVCaptureDevice.Position) -> UIImage {
        let originalOrientation: UIImage.Orientation = originalImage.imageOrientation
        guard originalOrientation == .right && cameraPosition == .front else { return originalImage }
        
        return UIImage(cgImage: originalImage.cgImage!,
                       scale: originalImage.scale,
                       orientation: .leftMirrored)
    }
    
    func attachFocus(to view: UIView) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.focusGesture.addTarget(self, action: #selector(self._focusStart(_:)))
            view.addGestureRecognizer(self.focusGesture)
            self.focusGesture.delegate = self
        }
    }
    
    @objc
    func _focusStart(_ recognizer: UITapGestureRecognizer) {
        
        let device: AVCaptureDevice?
        
        switch currentCameraPosition {
        case .back:
            device = backCamera
        case .front:
            device = frontCamera
        }
        
        _changeExposureMode(mode: .continuousAutoExposure)
        //        translationY = 0
        //        exposureValue = 0.5
        
        if let validDevice = device,
            let validPreviewLayer = previewLayer,
            let view = recognizer.view
        {
            let pointInPreviewLayer = view.layer.convert(recognizer.location(in: view), to: validPreviewLayer)
            let pointOfInterest = validPreviewLayer.captureDevicePointConverted(fromLayerPoint: pointInPreviewLayer)
            
            do {
                try validDevice.lockForConfiguration()
                
                //                _showFocusRectangleAtPoint(pointInPreviewLayer, inLayer: validPreviewLayer)
                
                if validDevice.isFocusPointOfInterestSupported {
                    validDevice.focusPointOfInterest = pointOfInterest
                }
                
                if  validDevice.isExposurePointOfInterestSupported {
                    validDevice.exposurePointOfInterest = pointOfInterest
                }
                
                if validDevice.isFocusModeSupported(focusMode) {
                    validDevice.focusMode = focusMode
                }
                
                //                if validDevice.isExposureModeSupported(exposureMode) {
                //                    validDevice.exposureMode = exposureMode
                //                }
                
                validDevice.unlockForConfiguration()
            }
            catch let error {
                PLog("CameraManager _focusStart error: \(error)")
            }
        }
    }
    
    func _changeExposureMode(mode: AVCaptureDevice.ExposureMode) {
        let device: AVCaptureDevice?
        
        switch currentCameraPosition {
        case .back:
            device = backCamera
        case .front:
            device = frontCamera
        }
        
        guard device?.exposureMode != mode else { return }
        
        do {
            try device?.lockForConfiguration()
        } catch {
            return
        }
        if device?.isExposureModeSupported(mode) == true {
            device?.exposureMode = mode
        }
        device?.unlockForConfiguration()
    }
    
    func enableFlashIfNeeded() {
        if flashMode == .on { toggleFlash() }
    }
    
    func disableFlashIfNeeded() {
        if flashMode == .on { toggleFlash() }
    }
    
    func toggleFlash() {
        guard
            currentCameraPosition == .back,
            let backCamera = backCamera,
            backCamera.hasTorch
            else { return }
        
        do {
            try backCamera.lockForConfiguration()
            if backCamera.torchMode == AVCaptureDevice.TorchMode.on {
                backCamera.torchMode = AVCaptureDevice.TorchMode.off
            } else {
                do {
                    try backCamera.setTorchModeOn(level: 1.0)
                } catch {
                    // throw error
                }
            }
            backCamera.unlockForConfiguration()
        } catch {
            // throw error
        }
    }
}

extension CameraManager : AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let currentBackgroundRecordingID = backgroundRecordingID {
            backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
            
            if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
            }
        }
        
        if let currentError = error {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.cameraManager(self, didFailToRecordVideo: currentError)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.cameraManager(self, didFinishProcessVideoAt: outputFileURL)
            }
        }
    }
}


extension CameraManager: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ captureOutput: AVCapturePhotoOutput,
                            didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
                            previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                            resolvedSettings: AVCaptureResolvedPhotoSettings,
                            bracketSettings: AVCaptureBracketedStillImageSettings?, error: Swift.Error?) {
        
        if let error = error {
            self.photoCaptureCompletionBlock?(nil, error)
            
        } else if let buffer = photoSampleBuffer,
            let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: nil),
            let originalImage = UIImage(data: data) {
            
            self.photoCaptureCompletionBlock?(rotateImageIfNedded(originalImage,
                                                                  cameraPosition: currentCameraPosition == .back ? .back : .front),
                                              nil)
            
        } else {
            self.photoCaptureCompletionBlock?(nil, CameraManagerError.unknown)
        }
    }
}

