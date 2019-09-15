//
//  ModePickerCell.swift
//  QuickCamera
//
//  Created by Georgij Emelyanov on 15/09/2019.
//  Copyright © 2019 Georgij Emelyanov. All rights reserved.
//

import UIKit

class ModePickerCell: UICollectionViewCell {
    lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .white
        label.lineBreakMode = .byTruncatingTail
        label.font = font
        return label
    }()
    
    lazy var substrateView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        view.layer.cornerRadius = view.bounds.height / 2
        return view
    }()
    
    lazy var font: UIFont = UIFont.subheadlineSemiboldFont
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var _isSelected: Bool = false {
        didSet {
            guard self._isSelected != oldValue else { return }
            UIView.animate(withDuration: 0.3) {
                self.substrateView.isHidden = !self._isSelected
                self.label.textColor = self._isSelected ? .white : .init(white: 1.0, alpha: 0.6)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        substrateView.layer.cornerRadius = substrateView.bounds.height / 2
    }
}

private extension ModePickerCell {
    func configureLayout() {
        contentView.addSubview(substrateView)
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            substrateView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            substrateView.topAnchor.constraint(equalTo: contentView.topAnchor),
            substrateView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            substrateView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ])
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ])
        
        layoutIfNeeded()
    }
}

struct Assets {
    static var icClose24: UIImage {
        return #imageLiteral(resourceName: "icClose24.pdf")
    }
    
    static var icCheck16: UIImage {
        return #imageLiteral(resourceName: "icCheck16.pdf")
    }
    
    static var icMediaRepeat32: UIImage {
        return #imageLiteral(resourceName: "icMediaRepeat24.pdf")
    }
    
    static var icLightningOff32: UIImage {
        return #imageLiteral(resourceName: "icLightningOff32.pdf")
    }
    
    static var icLightning32: UIImage {
        return #imageLiteral(resourceName: "icLightning32.pdf")
    }
    
    static var icoPhotoAlbum24: UIImage {
        return #imageLiteral(resourceName: "icPhotoAlbum24.pdf")
    }
}
