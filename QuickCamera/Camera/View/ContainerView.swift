//
//  ContainerView.swift
//  QuickCamera
//
//  Created by Georgij Emelyanov on 15/09/2019.
//  Copyright © 2019 Georgij Emelyanov. All rights reserved.
//

import UIKit

protocol ContainerViewDelegate: AnyObject {
    func cameraPreviewViewDidTapOnCloseButton()
    func cameraPreviewViewDidTapOnCaptureButton()
    func cameraPreviewViewDidBeginLongPress()
    func cameraPreviewViewDidEndLongPress()
    func cameraPreviewViewDidTapOnSwitchCameraButton()
    func cameraPreviewViewDidTapOnPickerPreview()
    func cameraPreviewViewDidTapOnSwitchFlashButton(_ enabled: Bool)
    func cameraPreviewViewDidTapOnCameraPermissionsButton()
    func cameraPreviewViewDidTapOnAudioPermissionsButton()
}

class ContainerView: UIView {
    lazy var captureView: CaptureView = {
        let view: CaptureView = CaptureView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = UIDevice.current.hasNotch ? 12 : 0
        return view
    }()
    
    weak var delegate: ContainerViewDelegate?
    
    var mode: CameraMode = .photo {
        didSet { captureButton.mode = mode }
    }
    
    var modeTitles: [String] = [] {
        didSet { modePickerView.reloadData() }
    }
    
    var pickerPreviewImage: UIImage? {
        didSet { pickerPreview.image = pickerPreviewImage }
    }
    
    var permissionsState: PermissionsView.State = (false, false) {
        didSet {
            videoAllowed = permissionsState.cameraAllowed
            audioAllowed = permissionsState.audioAllowed
            permissionsView.state = permissionsState
            configureUI(videoAllowed: permissionsState.cameraAllowed,
                        audioAllowed: permissionsState.audioAllowed)
        }
    }
    
    var videoAllowed: Bool = false {
        didSet {
            permissionsView.videoAllowed = videoAllowed
            configureUI(videoAllowed: videoAllowed, audioAllowed: audioAllowed)
        }
    }
    
    var audioAllowed: Bool = false {
        didSet {
            permissionsView.audioAllowed = audioAllowed
            configureUI(videoAllowed: videoAllowed, audioAllowed: audioAllowed)
        }
    }
    
    private lazy var permissionsView: PermissionsView = {
        let view: PermissionsView = PermissionsView()
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.onClose = { [weak self] in
            self?.close()
        }
        view.onCameraPermissions = { [weak self] in
            self?.delegate?.cameraPreviewViewDidTapOnCameraPermissionsButton()
        }
        view.onAudioPermissions = { [weak self] in
            self?.delegate?.cameraPreviewViewDidTapOnAudioPermissionsButton()
        }
        return view
    }()
    
    private var closeButton: UIButton!
    private func createCloseButton() -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(Assets.icClose24, for: UIControl.State.normal)
        button.addTarget(self, action: #selector(close), for: UIControl.Event.touchUpInside)
        button.tintColor = UIColor.white
        return button
    }
    
    private var captureButton: CaptureButton!
    private func createCaptureButton() -> CaptureButton {
        let button = CaptureButton(frame: CGRect(x: 0, y: 0, width: LayoutConfiguration.captureButtonSize.width, height: LayoutConfiguration.captureButtonSize.height))
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.onTouchUp = { [weak self] sender in
            self?.capturePhoto(sender)
        }
        
        button.onTouchDown = { [weak self] sender in
            guard self?.mode == .video else { return }
            self?.capturePhoto(sender)
        }
        
        button.onLongPressBegan = { [weak self] sender in
            guard self?.mode == .photo else { return }
            self?.wantStartRecordVideo()
        }
        
        button.onLongPressEnded = { [weak self] sender in
            guard self?.mode == .photo else { return }
            self?.wantStopRecordVideo()
        }
        
        return button
    }
    
    private var switchCameraButton: UIButton!
    private func createSwitchCameraButton() -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(Assets.icMediaRepeat32, for: UIControl.State.normal)
        button.addTarget(self, action: #selector(switchCamera), for: UIControl.Event.touchUpInside)
        button.tintColor = UIColor.white
        return button
    }
    
    private var flashButton: UIButton!
    private func createFlashButton() -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(Assets.icLightningOff32, for: UIControl.State.normal)
        button.setImage(Assets.icLightning32, for: UIControl.State.selected)
        button.addTarget(self, action: #selector(switchFlash), for: UIControl.Event.touchUpInside)
        button.tintColor = UIColor.white
        return button
    }
    
    private var gradient: CAGradientLayer!
    private func createGradient() -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.clear.cgColor,
                           UIColor(red: 0, green: 0, blue: 0, alpha: 0.3).cgColor]
        return gradient
    }
    
    private var modePickerView: ModePickerView!
    private func createModePickerView() -> ModePickerView {
        let picker = ModePickerView(frame: CGRect(x: 0,
                                                          y: self.bounds.height - LayoutConfiguration.pickerHeight - LayoutConfiguration.pickerBottomOffset,
                                                          width: self.bounds.width,
                                                          height: LayoutConfiguration.pickerHeight))
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.delegate = self
        picker.dataSource = self
        return picker
    }
    
    private var pickerPreview: UIImageView!
    private func createPickerPreview() -> UIImageView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .center
        imageView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.image = Assets.icoPhotoAlbum24
        imageView.tintColor = .white
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapOnPickerPreview)))
        return imageView
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.backgroundColor = UIColor.black.cgColor
        layer.masksToBounds = true
        configureLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        
        gradient.frame = CGRect(x: 0,
                                y: self.bounds.height - LayoutConfiguration.gradientHeight,
                                width: self.bounds.width,
                                height: LayoutConfiguration.gradientHeight)
    }
    
    func addPersmissionsSubview() {
        self.addSubview(permissionsView)
        
        NSLayoutConstraint.activate([
            permissionsView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            permissionsView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            permissionsView.topAnchor.constraint(equalTo: self.topAnchor),
            permissionsView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            ])
    }
    
    
    @objc
    func close() {
        delegate?.cameraPreviewViewDidTapOnCloseButton()
    }
    
    @objc
    func capturePhoto(_ sender: UIButton) {
        switch mode {
        case .photo:
            delegate?.cameraPreviewViewDidTapOnCaptureButton()
        case .video:
            if sender.isSelected {
                wantStopRecordVideo()
            } else {
                wantStartRecordVideo()
            }
            
            sender.isSelected.toggle()
        }
        
        if #available(iOS 10.0, *) {
            captureFeedback()
        }
    }
    
    @objc
    func switchCamera() {
        delegate?.cameraPreviewViewDidTapOnSwitchCameraButton()
        if #available(iOS 10.0, *) {
            switchCameraFeedback()
        }
    }
    
    @objc
    func switchFlash() {
        flashButton.isSelected.toggle()
        delegate?.cameraPreviewViewDidTapOnSwitchFlashButton(flashButton.isSelected)
        if #available(iOS 10.0, *) {
            switchFlashFeedback()
        }
    }
    
    @objc
    func tapOnPickerPreview() {
        delegate?.cameraPreviewViewDidTapOnPickerPreview()
    }
    
    func configureUI(videoAllowed: Bool, audioAllowed: Bool) {
        typealias EmptyAction = (() -> ())
        
        let noneAllowedAction: EmptyAction = {
            self.addPersmissionsSubview()
            
            self.closeButton.alpha = 0.0
            self.captureButton.alpha = 0.0
            self.switchCameraButton.alpha = 0.0
            self.flashButton.alpha = 0.0
            self.modePickerView.alpha = 0.0
            self.pickerPreview.alpha = 0.0
        }
        
        let onlyVideoAllowedAction: EmptyAction = {
            self.closeButton.alpha = 0.0
            self.captureButton.alpha = 0.0
            self.switchCameraButton.alpha = 0.0
            self.flashButton.alpha = 0.0
            self.modePickerView.alpha = 0.0
            self.pickerPreview.alpha = 0.0
        }
        
        let onlyAudioAllowedAction: EmptyAction = {
            self.closeButton.alpha = 0.0
            self.captureButton.alpha = 0.0
            self.switchCameraButton.alpha = 0.0
            self.flashButton.alpha = 0.0
            self.modePickerView.alpha = 0.0
            self.pickerPreview.alpha = 0.0
        }
        
        let allAllowedAction: EmptyAction = {
            self.permissionsView.removeFromSuperview()
            
            self.closeButton.alpha = 1.0
            self.captureButton.alpha = 1.0
            self.switchCameraButton.alpha = 1.0
            self.flashButton.alpha = 1.0
            self.modePickerView.alpha = 1.0
            self.pickerPreview.alpha = 1.0
        }
        
        if videoAllowed && audioAllowed {
            allAllowedAction()
        } else if videoAllowed && !audioAllowed {
            onlyVideoAllowedAction()
        } else if audioAllowed && !videoAllowed {
            onlyAudioAllowedAction()
        } else {
            noneAllowedAction()
        }
        
        permissionsView.state = (videoAllowed, audioAllowed)
    }
}


extension ContainerView: ModePickerViewDataSource {
    func numberOfItems(in modePickerView: ModePickerView) -> Int {
        return self.modeTitles.count
    }
    func modePickerView(_ modePickerView: ModePickerView, titleForItem item: Int) -> String {
        return self.modeTitles[item]
    }
}

extension ContainerView: ModePickerViewDelegate {
    func modePickerView(_ modePickerView: ModePickerView, didSelectItem item: Int) {
        guard let newMode = CameraMode(rawValue: item) else { return }
        
        mode = newMode
    }
}

private extension ContainerView {
    func wantStartRecordVideo() {
        delegate?.cameraPreviewViewDidBeginLongPress()
        hideActionsViews()
    }
    
    func wantStopRecordVideo() {
        delegate?.cameraPreviewViewDidEndLongPress()
        showActionsViews()
    }
}


private extension ContainerView {
    func configureLayout() {
        gradient = createGradient()
        closeButton = createCloseButton()
        captureButton = createCaptureButton()
        switchCameraButton = createSwitchCameraButton()
        flashButton = createFlashButton()
        modePickerView = createModePickerView()
        pickerPreview = createPickerPreview()
        
        addSubview(captureView)
        
        layer.addSublayer(gradient)
        
        NSLayoutConstraint.activate([
            captureView.leadingAnchor.constraint(equalTo: leadingAnchor),
            captureView.trailingAnchor.constraint(equalTo: trailingAnchor),
            captureView.topAnchor.constraint(equalTo: topAnchor,
                                             constant: LayoutConfiguration.cameraCaptureViewMaxTopOffset),
            captureView.bottomAnchor.constraint(equalTo: self.actualLayoutGuide.bottomAnchor,
                                                constant: UIDevice.current.hasNotch ? -LayoutConfiguration.cameraCaptureViewMaxBottomOffset : 0),
            ])
        
        self.addSubviews([closeButton,
                             captureButton,
                             switchCameraButton,
                             flashButton,
                             modePickerView,
                             pickerPreview
            ])
        
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: LayoutConfiguration.closeButtonLeadingInset),
            closeButton.topAnchor.constraint(equalTo: self.actualLayoutGuide.topAnchor, constant: LayoutConfiguration.closeButtonTopInset),
            closeButton.widthAnchor.constraint(equalToConstant: LayoutConfiguration.closeButtonSize.width),
            closeButton.heightAnchor.constraint(equalToConstant: LayoutConfiguration.closeButtonSize.height),
            ])
        
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: LayoutConfiguration.captureButtonSize.width),
            captureButton.heightAnchor.constraint(equalToConstant: LayoutConfiguration.captureButtonSize.height),
            captureButton.bottomAnchor.constraint(equalTo: modePickerView.topAnchor,
                                                  constant: UIDevice.current.hasNotch ? -LayoutConfiguration.modePickerTopOffsetWithNotch : -LayoutConfiguration.captureButtonBottomInset),
            ])
        
        NSLayoutConstraint.activate([
            switchCameraButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            switchCameraButton.widthAnchor.constraint(equalToConstant: LayoutConfiguration.switchCameraButtonSize.width),
            switchCameraButton.heightAnchor.constraint(equalToConstant: LayoutConfiguration.switchCameraButtonSize.height),
            switchCameraButton.leadingAnchor.constraint(equalTo: captureButton.trailingAnchor, constant: LayoutConfiguration.captureButtonHorizontalOffset),
            ])
        
        NSLayoutConstraint.activate([
            flashButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            flashButton.widthAnchor.constraint(equalToConstant: LayoutConfiguration.switchCameraButtonSize.width),
            flashButton.heightAnchor.constraint(equalToConstant: LayoutConfiguration.switchCameraButtonSize.height),
            flashButton.trailingAnchor.constraint(equalTo: captureButton.leadingAnchor, constant: -LayoutConfiguration.captureButtonHorizontalOffset),
            ])
        
        NSLayoutConstraint.activate([
            pickerPreview.centerYAnchor.constraint(equalTo: flashButton.centerYAnchor),
            pickerPreview.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: LayoutConfiguration.pickerPreviewLeadingOffset),
            pickerPreview.heightAnchor.constraint(equalToConstant: LayoutConfiguration.pickerPreviewSize.height),
            pickerPreview.widthAnchor.constraint(equalToConstant: LayoutConfiguration.pickerPreviewSize.width),
            ])
        
        
        NSLayoutConstraint.activate([
            modePickerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            modePickerView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            modePickerView.heightAnchor.constraint(equalToConstant: LayoutConfiguration.pickerHeight),
            modePickerView.bottomAnchor.constraint(equalTo: self.actualLayoutGuide.bottomAnchor,
                                                   constant: UIDevice.current.hasNotch ? -16 : -LayoutConfiguration.pickerBottomOffset)
            ])
    }
    
    func hideActionsViews() {
        UIView.animate(withDuration: 0.1) {
            self.closeButton.alpha = 0.0
            self.switchCameraButton.alpha = 0.0
            self.flashButton.alpha = 0.0
            self.modePickerView.alpha = 0.0
            self.pickerPreview.alpha = 0.0
        }
    }
    
    func showActionsViews() {
        UIView.animate(withDuration: 0.1) {
            self.closeButton.alpha = 1.0
            self.switchCameraButton.alpha = 1.0
            self.flashButton.alpha = 1.0
            self.modePickerView.alpha = 1.0
            self.pickerPreview.alpha = 1.0
        }
    }
}

private extension ContainerView {
    func captureFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func switchCameraFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func switchFlashFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}


private struct LayoutConfiguration {
    
    static var cameraCaptureViewMaxTopOffset: CGFloat {
        if #available(iOS 11.0, *) {
            return UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0
        } else {
            return 0
        }
    }
    
    static var cameraCaptureViewMaxBottomOffset: CGFloat = 68
    
    static let closeButtonLeadingInset: CGFloat = 7
    static let closeButtonTopInset: CGFloat = 5
    
    static let closeButtonSize: CGSize = CGSize(width: 44, height: 44)
    
    static let captureButtonSize: CGSize = CGSize(width: 72, height: 72)
    static let captureButtonBottomInset: CGFloat = 12
    
    static let switchCameraButtonSize: CGSize = CGSize(width: 44, height: 44)
    
    static let pickerBottomOffset: CGFloat = 12
    static let pickerHeight: CGFloat = 28
    
    static let pickerPreviewSize: CGSize = CGSize(width: 32, height: 32)
    static let pickerPreviewLeadingOffset: CGFloat = 12
    
    static let gradientHeight: CGFloat = 140
    static let captureButtonHorizontalOffset: CGFloat = 36
    static let modePickerTopOffsetWithNotch: CGFloat = 36
}
