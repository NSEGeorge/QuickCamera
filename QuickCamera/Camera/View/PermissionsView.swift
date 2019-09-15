//
//  PermissionsView.swift
//  QuickCamera
//
//  Created by Georgij Emelyanov on 15/09/2019.
//  Copyright © 2019 Georgij Emelyanov. All rights reserved.
//

import UIKit

class PermissionsView: UIView {
    typealias State = (cameraAllowed: Bool, audioAllowed: Bool)
    
    var onClose: (() -> ())?
    var onCameraPermissions: (() -> ())?
    var onAudioPermissions: (() -> ())?
    
    var state: State = (false, false) {
        didSet {
            blurView.isHidden = !state.cameraAllowed
            videoAllowed = state.cameraAllowed
            audioAllowed = state.audioAllowed
        }
    }
    
    var videoAllowed: Bool = false {
        didSet {
            cameraButton.isSelected = videoAllowed
            cameraButton.isUserInteractionEnabled = !videoAllowed
        }
    }
    
    var audioAllowed: Bool = false {
        didSet {
            audioButton.isSelected = audioAllowed
            audioButton.isUserInteractionEnabled = !audioAllowed
        }
    }
    
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(Assets.icClose24, for: .normal)
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        button.tintColor = UIColor.white
        return button
    }()
    
    private lazy var container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "CAMERA_PERMISSIONS_TITLE".localized
        label.font = UIFont.headerSemiboldFont
        label.textColor = UIColor.white
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "CAMERA_PERMISSIONS_SUBTITLE_DAILY_PHOTO".localized
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.subheadlineFont
        label.textColor = UIColor.gray
        return label
    }()
    
    private lazy var cameraButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("CAMERA_PERMISSIONS_CAMERA".localized, for: .normal)
        button.setTitleColor(UIColor.orange, for: .normal)
        button.setTitleColor(.white, for: .selected)
        button.setImage(Assets.icCheck16, for: .selected)
        button.imageEdgeInsets = Configuration.permissionsButtonImageInsets
        button.tintColor = .white
        button.titleLabel?.font = UIFont.subheadlineSemiboldFont
        button.addTarget(self, action: #selector(cameraButtonDidTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var audioButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("CAMERA_PERMISSIONS_MICROPHONE".localized, for: .normal)
        button.setTitleColor(UIColor.orange, for: .normal)
        button.setTitleColor(.white, for: .selected)
        button.setImage(Assets.icCheck16, for: .selected)
        button.imageEdgeInsets = Configuration.permissionsButtonImageInsets
        button.tintColor = .white
        button.titleLabel?.font = UIFont.subheadlineSemiboldFont
        button.addTarget(self, action: #selector(audioButtonDidTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var blurView: UIVisualEffectView = {
        let blur: UIBlurEffect
        
        if #available(iOS 10.0, *) {
            blur = UIBlurEffect(style: .regular)
        } else {
            blur = UIBlurEffect(style: .light)
        }
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = self.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return blurView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        blurView.frame = self.bounds
    }
    
    @objc
    func close() {
        onClose?()
    }
    
    @objc
    func cameraButtonDidTapped() {
        onCameraPermissions?()
    }
    
    @objc
    func audioButtonDidTapped() {
        onAudioPermissions?()
    }
}

private extension PermissionsView {
    func configureLayout() {
        self.addSubviews([
            blurView,
            container,
            closeButton,
            ])
        
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: self.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            ])
        
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            container.centerYAnchor.constraint(equalTo: self.centerYAnchor)
            ])
        
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: Configuration.closeButtonLeadingInset),
            closeButton.topAnchor.constraint(equalTo: self.actualLayoutGuide.topAnchor, constant: Configuration.closeButtonTopInset),
            closeButton.widthAnchor.constraint(equalToConstant: Configuration.closeButtonSize.width),
            closeButton.heightAnchor.constraint(equalToConstant: Configuration.closeButtonSize.height),
            ])
        
        container.addSubviews([
            titleLabel,
            subtitleLabel,
            cameraButton,
            audioButton,
            ])
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Configuration.titleLeadingOffset),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Configuration.titleLeadingOffset),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: Configuration.titleTopOffset),
            ])
        
        NSLayoutConstraint.activate([
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Configuration.subtitleLeadingOffset),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Configuration.subtitleLeadingOffset),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Configuration.subtitleTopOffset),
            ])
        
        NSLayoutConstraint.activate([
            cameraButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Configuration.cameraLeadingOffset),
            cameraButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Configuration.cameraTrailingOffset),
            cameraButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: Configuration.cameraTopOffset),
            ])
        
        NSLayoutConstraint.activate([
            audioButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Configuration.audioLeadingOffset),
            audioButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Configuration.audioTrailingOffset),
            audioButton.topAnchor.constraint(equalTo: cameraButton.bottomAnchor, constant: Configuration.audioTopOffset),
            audioButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Configuration.audioBottomOffset),
            ])
    }
}

private extension PermissionsView {
    struct Configuration {
        
        static let closeButtonLeadingInset: CGFloat = 7
        static let closeButtonTopInset: CGFloat = 5
        static let closeButtonSize: CGSize = CGSize(width: 44, height: 44)
        
        static let titleLeadingOffset: CGFloat = 20
        static let titleTrailingOffset: CGFloat = 20
        static let titleTopOffset: CGFloat = 0
        
        static let subtitleLeadingOffset: CGFloat = 20
        static let subtitleTrailingOffset: CGFloat = 20
        static let subtitleTopOffset: CGFloat = 8
        
        static let cameraTopOffset: CGFloat = 23
        static let cameraLeadingOffset: CGFloat = 20
        static let cameraTrailingOffset: CGFloat = 20
        
        static let audioTopOffset: CGFloat = 23
        static let audioLeadingOffset: CGFloat = 20
        static let audioTrailingOffset: CGFloat = 20
        static let audioBottomOffset: CGFloat = 0
        
        static let permissionsButtonImageInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: -9, bottom: 0, right: 0)
    }
}
