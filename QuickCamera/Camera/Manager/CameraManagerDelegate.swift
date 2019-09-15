//
//  CameraManagerDelegate.swift
//  QuickCamera
//
//  Created by Georgij Emelyanov on 15/09/2019.
//  Copyright © 2019 Georgij Emelyanov. All rights reserved.
//

import UIKit

protocol CameraManagerDelegate: class {
    
    func cameraManagerSessionDidStartRunning(_ cameraManager: CameraManager)
    
    func cameraManagerSessionDidStopRunning(_ cameraManager: CameraManager)
    
    func cameraManager(_ cameraManager: CameraManager, didTake photo: UIImage)
    
    func cameraManager(_ cameraManager: CameraManager, didBeginRecordingVideo camera: CameraManager.CameraPosition)
    
    func cameraManager(_ cameraManager: CameraManager, didFinishRecordingVideo camera: CameraManager.CameraPosition)
    
    func cameraManager(_ cameraManager: CameraManager, didFinishProcessVideoAt url: URL)
    
    func cameraManager(_ cameraManager: CameraManager, didFailToRecordVideo error: Error)
}

extension CameraManagerDelegate {
    func cameraManagerSessionDidStartRunning(_ cameraManager: CameraManager) { }
    
    func cameraManagerSessionDidStopRunning(_ cameraManager: CameraManager) { }
    
    func cameraManager(_ cameraManager: CameraManager, didTake photo: UIImage) { }
    
    func cameraManager(_ cameraManager: CameraManager, didBeginRecordingVideo camera: CameraManager.CameraPosition) { }
    
    func cameraManager(_ cameraManager: CameraManager, didFinishRecordingVideo camera: CameraManager.CameraPosition) { }
    
    func cameraManager(_ cameraManager: CameraManager, didFinishProcessVideoAt url: URL) { }
    
    func cameraManager(_ cameraManager: CameraManager, didFailToRecordVideo error: Error) { }
}
