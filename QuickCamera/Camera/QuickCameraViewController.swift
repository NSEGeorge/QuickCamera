//
//  QuickCameraViewController.swift
//  QuickCamera
//
//  Created by Georgij Emelyanov on 15/09/2019.
//  Copyright © 2019 Georgij Emelyanov. All rights reserved.
//

import UIKit
import Photos

protocol QuickCameraViewControllerDelegate: AnyObject {
    func quickCameraViewController(_ ctrl: QuickCameraViewController, didMakePhoto photo: UIImage)
    func quickCameraViewController(_ ctrl: QuickCameraViewController, didCaptureVideos videosURL: [URL])
    func quickCameraViewControllerDidTapOnPickerPreview(_ ctrl: QuickCameraViewController)
}


class QuickCameraViewController: UIViewController {
    let cameraManager: CameraManager = CameraManager()
    
    weak var delegate: QuickCameraViewControllerDelegate!
    
    private var cameraContainer: ContainerView {
        return view as! ContainerView
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    override var prefersStatusBarHidden: Bool { return !UIDevice.current.hasNotch }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }
    
    override func loadView() {
        super.loadView()
        view = ContainerView()
        cameraContainer.delegate = self
        cameraManager.delegate = self
        checkPermissions()
        try? cameraManager.connectSession(to: cameraContainer.captureView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupObserving()
        
        cameraContainer.modeTitles = ["PHOTO".localized, "VIDEO".localized]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkGalleryPermissions()
        cameraManager.startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraManager.stopSession()
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        cameraManager.updateVideoOrientation(UIDevice.current.orientation, onView: cameraContainer.captureView)
    }
}

extension QuickCameraViewController: ContainerViewDelegate {
    func cameraPreviewViewDidTapOnCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    func cameraPreviewViewDidBeginLongPress() {
        do {
            try cameraManager.startVideoRecording()
        } catch {
            PLog("cameraPreviewViewDidBeginLongPress error: \(error)")
        }
    }
    
    func cameraPreviewViewDidEndLongPress() {
        cameraManager.stopVideoRecording()
    }
    
    func cameraPreviewViewDidTapOnSwitchCameraButton() {
        do {
            try cameraManager.switchCameras()
        } catch {
            PLog("cameraPreviewViewDidTapOnSwitchCameraButton error: \(error)")
        }
    }
    
    func cameraPreviewViewDidTapOnCaptureButton() {
        cameraManager.captureImage {(image, error) in
            guard let image = image else {
                PLog("Image capture error")
                return
            }
            
            self.delegate?.quickCameraViewController(self, didMakePhoto: image)
        }
    }
    
    func cameraPreviewViewDidTapOnSwitchFlashButton(_ enabled: Bool) {
        if cameraManager.flashMode == .on {
            cameraManager.flashMode = .off
        } else {
            cameraManager.flashMode = .on
        }
    }
    
    func cameraPreviewViewDidTapOnPickerPreview() {
        self.delegate?.quickCameraViewControllerDidTapOnPickerPreview(self)
    }
    
    func cameraPreviewViewDidTapOnCameraPermissionsButton() {
        let statuses: CameraManager.PermissionsStatuses = cameraManager.fetchPermissionsStatus()
        
        if statuses.camera == .notDetermined {
            cameraManager.requestVideoAccess { [weak self] isAuthorized in
                DispatchQueue.main.async {
                    self?.cameraContainer.videoAllowed = isAuthorized
                }
                
                if isAuthorized {
                    self?.configureCameraManager()
                }
            }
        } else {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }
    }
    
    func cameraPreviewViewDidTapOnAudioPermissionsButton() {
        let statuses: CameraManager.PermissionsStatuses = cameraManager.fetchPermissionsStatus()
        
        if statuses.audio == .notDetermined {
            cameraManager.requestAudioAccess { [weak self] isAuthorized in
                DispatchQueue.main.async {
                    self?.cameraContainer.audioAllowed = isAuthorized
                }
                
                if isAuthorized {
                    self?.configureVideoSetup()
                }
            }
        } else {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }
    }
}

extension QuickCameraViewController: CameraManagerDelegate { }

private extension QuickCameraViewController {
    func checkPermissions() {
        let statuses: CameraManager.PermissionsStatuses = cameraManager.fetchPermissionsStatus()
        
        if statuses.camera == .authorized {
            configureCameraManager()
        }
        
        if statuses.audio == .authorized {
            configureVideoSetup()
        }
        
        if statuses.audio != .authorized || statuses.camera != .authorized {
            cameraContainer.addPersmissionsSubview()
            cameraContainer.permissionsState = (statuses.camera == .authorized,
                                                statuses.audio == .authorized)
        }
    }
    
    func configureCameraManager() {
        cameraManager.configure { error in
            if let error = error {
                PLog("configureCameraManager error: \(error)")
            }
            
            try? self.cameraManager.displayPreview(on: self.cameraContainer.captureView)
        }
    }
    
    func configureVideoSetup() {
        cameraManager.configureAudioInput { error in
            if let error = error {
                PLog("configureAudioInput error: \(error)")
            }
        }
        cameraManager.configureVideoOutput { error in
            if let error = error {
                PLog("configureVideoOutput error: \(error)")
            }
        }
    }
    
    func checkGalleryPermissions() {
        let status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        guard status == .authorized else { return }
        
        fetchPickerPreviewImage()
    }
    
    func setupObserving() {
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc
    func appWillResignActive() {
        cameraManager.stopSession()
    }
    
    @objc
    func appDidBecomeActive() {
        cameraManager.startSession()
    }
    
    func fetchPickerPreviewImage() { }
}

