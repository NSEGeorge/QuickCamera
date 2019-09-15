//
//  CaptureButton.swift
//  QuickCamera
//
//  Created by Georgij Emelyanov on 15/09/2019.
//  Copyright © 2019 Georgij Emelyanov. All rights reserved.
//

import UIKit

enum CameraMode: Int {
    case photo
    case video
}

class CaptureButton: UIButton {
    
    var onLongPressBegan: ((_ : CaptureButton) -> ())?
    var onLongPressEnded: ((_ : CaptureButton) -> ())?
    var onTouchUp: ((_ : CaptureButton) -> ())?
    var onTouchDown: ((_ : CaptureButton) -> ())?
    
    var mode: CameraMode = .photo {
        didSet {
            isSelected = false
            if mode == .photo {
                videoDotLayer.removeFromSuperlayer()
            } else {
                layer.addSublayer(videoDotLayer)
            }
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if !self.isSelected {
                animateIntoStartState()
            }
            UIView.animate(withDuration: 0.3) {
                self.videoDotLayer.frame = self.isSelected ? self.layer.bounds.insetBy(dx: 26, dy: 26) : self.layer.bounds.insetBy(dx: 28, dy: 28)
                self.videoDotLayer.cornerRadius = self.isSelected ? 4 : self.videoDotLayer.frame.height / 2
            }
        }
    }
    
    private lazy var innerCircleLayer: CAShapeLayer = {
        let innerCircleLayer = CAShapeLayer()
        innerCircleLayer.fillColor = UIColor(white: 1.0, alpha: 1.0).cgColor
        
        return innerCircleLayer
    }()
    
    private lazy var videoDotLayer: CAGradientLayer = {
        let gradient: CAGradientLayer = CAGradientLayer()
        
        gradient.colors = [
            UIColor(red: 1, green: 0.7, blue: 0.07, alpha: 1).cgColor,
            UIColor(red: 0.93, green: 0.51, blue: 0.03, alpha: 1).cgColor,
            UIColor(red: 0.92, green: 0.17, blue: 0.11, alpha: 1).cgColor,
        ]
        gradient.locations = [0, 0.47, 1]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.9)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.1)
        
        gradient.frame = self.layer.bounds.insetBy(dx: 28, dy: 28)
        gradient.cornerRadius = gradient.frame.height / 2
        return gradient
    }()
    
    private lazy var outerCircleLayer: CAShapeLayer = {
        let outerCircleLayer = CAShapeLayer()
        outerCircleLayer.fillColor = UIColor.clear.cgColor
        outerCircleLayer.strokeColor = UIColor(white: 1.0, alpha: 0.6).cgColor
        outerCircleLayer.lineWidth = 4
        
        return outerCircleLayer
    }()
    
    private lazy var progressLayer: CAShapeLayer = {
        let progressLayer = CAShapeLayer()
        progressLayer.fillColor = nil
        progressLayer.strokeColor = UIColor.black.cgColor
        progressLayer.lineWidth = 4
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        
        return progressLayer
    }()
    
    private lazy var progressGradientLayer: CAGradientLayer = {
        let progressGradientLayer = CAGradientLayer()
        progressGradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        progressGradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        
        progressGradientLayer.colors = [
            UIColor(red: 1, green: 0.7, blue: 0.07, alpha: 1).cgColor,
            UIColor(red: 0.93, green: 0.51, blue: 0.03, alpha: 1).cgColor,
            UIColor(red: 0.92, green: 0.17, blue: 0.11, alpha: 1).cgColor,
        ]
        
        return progressGradientLayer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
        
        innerCircleLayer.frame = layer.bounds.insetBy(dx: 6, dy: 6)
        innerCircleLayer.path = UIBezierPath(ovalIn: innerCircleLayer.bounds).cgPath
        
        outerCircleLayer.frame = layer.bounds
        outerCircleLayer.path = UIBezierPath(ovalIn: outerCircleLayer.bounds).cgPath
        
        redrawProgressLayer()
    }
    
    func redrawProgressLayer() {
        progressGradientLayer.frame = outerCircleLayer.frame.insetBy(dx: -2, dy: -2)
        
        progressLayer.path = UIBezierPath(arcCenter: progressGradientLayer.bounds.boundsCenter,
                                          radius: progressGradientLayer.bounds.width / 2-2,
                                          startAngle: -.pi/2,
                                          endAngle: 2 * .pi,
                                          clockwise: true).cgPath
        progressGradientLayer.mask = progressLayer
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func initialize() {
        layer.addSublayer(outerCircleLayer)
        layer.addSublayer(innerCircleLayer)
        layer.addSublayer(progressGradientLayer)
        
        isExclusiveTouch = true
        
        addTarget(self, action: #selector(touchDown(_:)), for: .touchDown)
        addTarget(self, action: #selector(touchUp(_:)), for: .touchUpInside)
        addTarget(self, action: #selector(touchUp(_:)), for: .touchUpOutside)
        
        let longGR = UILongPressGestureRecognizer(target: self, action: #selector(longPressDown(_:)))
        longGR.minimumPressDuration = 0.15
        addGestureRecognizer(longGR)
    }
    
    @objc
    func touchUp(_ sender: UIButton) {
        guard mode == .photo else { return }
        if !isSelected { animateInnerCircleScaleUp() }
        onTouchUp?(self)
    }
    
    @objc
    func touchDown(_ sender: UIButton) {
        animateInnerCircleScaleDown()
        if mode == .video && !isSelected {
            animateOuterCircleScaleUp()
            animateProgressLayerUp()
            onLongPressBegan?(self)
        } else if mode == .video && isSelected {
            animateIntoStartState()
        }
        onTouchDown?(self)
    }
    
    @objc
    func longPressDown(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            animateOuterCircleScaleUp()
            animateProgressLayerUp()
            onLongPressBegan?(self)
            
        case .ended, .cancelled, .failed:
            if !isSelected {
                animateIntoStartState()
            }
            onLongPressEnded?(self)
            
        default:
            break
        }
    }
}

private extension CaptureButton {
    func animateInnerCircleScaleDown() {
        let opacityAnimation: CABasicAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = innerCircleLayer.presentation()?.opacity
        opacityAnimation.toValue = Configuration.InnerCircleOpacityMinValue
        innerCircleLayer.opacity = Configuration.InnerCircleOpacityMinValue
        
        let scaleDownAnimation: CABasicAnimation = CABasicAnimation(keyPath: "transform")
        scaleDownAnimation.fromValue = innerCircleLayer.presentation()?.affineTransform()
        scaleDownAnimation.toValue = CGAffineTransform.init(scaleX: Configuration.InnerCircleScaleMinValue, y: Configuration.InnerCircleScaleMinValue)
        innerCircleLayer.setAffineTransform(CGAffineTransform.init(scaleX: Configuration.InnerCircleScaleMinValue, y: Configuration.InnerCircleScaleMinValue))
        
        let groupAnimation: CAAnimationGroup = CAAnimationGroup()
        groupAnimation.animations = [opacityAnimation, scaleDownAnimation]
        groupAnimation.duration = Configuration.InnerCircleDownAnimationDuration
        groupAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        innerCircleLayer.removeAnimation(forKey: Configuration.OuterCircleScaleUpKey)
        innerCircleLayer.add(groupAnimation, forKey: Configuration.OuterCircleScaleDownKey)
    }
    
    func animateInnerCircleScaleUp() {
        let opacityAnimation: CABasicAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = innerCircleLayer.presentation()?.opacity
        opacityAnimation.toValue = Configuration.InnerCircleOpacityMaxValue
        innerCircleLayer.opacity = Configuration.InnerCircleOpacityMaxValue
        
        let scaleUpAnimation: CABasicAnimation = CABasicAnimation(keyPath: "transform")
        scaleUpAnimation.fromValue = innerCircleLayer.presentation()?.affineTransform()
        scaleUpAnimation.toValue = CGAffineTransform.init(scaleX: Configuration.InnerCircleScaleMaxValue, y: Configuration.InnerCircleScaleMaxValue)
        innerCircleLayer.setAffineTransform(CGAffineTransform.init(scaleX: Configuration.InnerCircleScaleMaxValue, y: Configuration.InnerCircleScaleMaxValue))
        
        let groupAnimation: CAAnimationGroup = CAAnimationGroup()
        groupAnimation.animations = [opacityAnimation, scaleUpAnimation]
        groupAnimation.duration = Configuration.InnerCircleDownAnimationDuration
        groupAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        innerCircleLayer.removeAnimation(forKey: Configuration.OuterCircleScaleDownKey)
        innerCircleLayer.add(groupAnimation, forKey: Configuration.OuterCircleScaleUpKey)
    }
    
    
    func animateOuterCircleScaleUp() {
        let scaleUpAnimation: CABasicAnimation = CABasicAnimation(keyPath: "transform")
        scaleUpAnimation.fromValue = outerCircleLayer.presentation()?.affineTransform()
        scaleUpAnimation.toValue = CGAffineTransform.init(scaleX: Configuration.OuterCircleScaleMaxValue, y: Configuration.OuterCircleScaleMaxValue)
        scaleUpAnimation.duration = Configuration.OuterCircleUpAnimationDuration
        scaleUpAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        outerCircleLayer.setAffineTransform(CGAffineTransform.init(scaleX: Configuration.OuterCircleScaleMaxValue, y: Configuration.OuterCircleScaleMaxValue))
        outerCircleLayer.removeAnimation(forKey: Configuration.OuterCircleScaleDownKey)
        outerCircleLayer.add(scaleUpAnimation, forKey: Configuration.OuterCircleScaleUpKey)
        
        redrawProgressLayer()
    }
    
    func animateOuterCircleScaleDown() {
        let scaleUpAnimation: CABasicAnimation = CABasicAnimation(keyPath: "transform")
        scaleUpAnimation.fromValue = outerCircleLayer.presentation()?.affineTransform()
        scaleUpAnimation.toValue = CGAffineTransform.init(scaleX: Configuration.OuterCircleScaleMinValue, y: Configuration.OuterCircleScaleMinValue)
        scaleUpAnimation.duration = Configuration.OuterCircleDownAnimationDuration
        scaleUpAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        outerCircleLayer.setAffineTransform(CGAffineTransform.init(scaleX: Configuration.OuterCircleScaleMinValue, y: Configuration.OuterCircleScaleMinValue))
        outerCircleLayer.removeAnimation(forKey: Configuration.OuterCircleScaleUpKey)
        outerCircleLayer.add(scaleUpAnimation, forKey: Configuration.OuterCircleScaleDownKey)
        
        redrawProgressLayer()
    }
    
    func animateProgressLayerUp() {
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = progressLayer.presentation()?.strokeEnd
        animation.toValue = 1
        animation.duration = Configuration.ProgressLayerUpAnimationDuration
        animation.beginTime = CACurrentMediaTime() + 0.2
        
        animation.fillMode = .both
        progressLayer.strokeEnd = 1
        animation.setValue(progressLayer, forKey: "layer")
        
        progressLayer.add(animation, forKey: Configuration.ProgressLayerUpKey)
    }
    
    func animateProgressLayerDown() {
        CALayer.performWithoutAnimation {
            progressLayer.strokeEnd = 0
        }
        progressLayer.removeAnimation(forKey: Configuration.ProgressLayerUpKey)
    }
    
    func animateIntoStartState() {
        animateOuterCircleScaleDown()
        animateInnerCircleScaleUp()
        animateProgressLayerDown()
    }
}

private extension CaptureButton {
    struct Configuration {
        static let InnerCircleScaleUpKey: String = "InnerScaleUp"
        static let InnerCircleScaleDownKey: String = "InnerScaleDown"
        
        static let InnerCircleOpacityMinValue: Float = 0.8
        static let InnerCircleOpacityMaxValue: Float = 1.0
        
        static let InnerCircleScaleMinValue: CGFloat = 0.8
        static let InnerCircleScaleMaxValue: CGFloat = 1.0
        
        static let InnerCircleUpAnimationDuration: CFTimeInterval = 0.3
        static let InnerCircleDownAnimationDuration: CFTimeInterval = 0.3
        
        static let OuterCircleScaleUpKey: String = "OuterScaleUp"
        static let OuterCircleScaleDownKey: String = "OuterScaleDown"
        
        static let OuterCircleScaleMinValue: CGFloat = 1.0
        static let OuterCircleScaleMaxValue: CGFloat = 1.1
        
        static let OuterCircleUpAnimationDuration: CFTimeInterval = 0.3
        static let OuterCircleDownAnimationDuration: CFTimeInterval = 0.3
        
        static let ProgressLayerUpKey: String = "ProgressUp"
        static let ProgressLayerUpAnimationDuration: CFTimeInterval = 15
    }
}

private extension CGRect {
    /// Центр относительно собственной системы координат
    var boundsCenter: CGPoint {
        return CGPoint(x: width / 2, y: height / 2)
    }
}
