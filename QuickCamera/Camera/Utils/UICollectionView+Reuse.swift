//
//  UICollectionView+Reuse.swift
//  QuickCamera
//
//  Created by Georgij Emelyanov on 15/09/2019.
//  Copyright © 2019 Georgij Emelyanov. All rights reserved.
//

import UIKit

extension UICollectionView {
    func register<TCell: UICollectionViewCell>(_ cellClass: TCell.Type) {
        register(cellClass, forCellWithReuseIdentifier: defaultReuseID(of: cellClass))
    }
    
    func dequeue<TCell: UICollectionViewCell>(_ cellClass: TCell.Type, for indexPath: IndexPath) -> TCell? {
        return dequeueReusableCell(withReuseIdentifier: defaultReuseID(of: cellClass), for: indexPath) as? TCell
    }
    
    func dequeueReusableCellWithAutoregistration<TCell: UICollectionViewCell>(_ cellType: TCell.Type,
                                                                              reuseId: String? = nil,
                                                                              for indexPath: IndexPath) -> TCell? {
        let normalizedReuseId = reuseId ?? defaultReuseID(of: cellType)
        register(cellType, forCellWithReuseIdentifier: normalizedReuseId)
        
        let cell = dequeueReusableCell(withReuseIdentifier: normalizedReuseId, for: indexPath) as? TCell
        assert(cell != nil,
               "UICollectionView cannot dequeue cell with type \(cellType) for reuseId \(normalizedReuseId)")
        return cell
    }
}

public func defaultReuseID(of cellType: UICollectionViewCell.Type) -> String {
    return String(describing: cellType.self)
}
