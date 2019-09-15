//
//  ModePickerView.swift
//  QuickCamera
//
//  Created by Georgij Emelyanov on 15/09/2019.
//  Copyright © 2019 Georgij Emelyanov. All rights reserved.
//

import UIKit

protocol ModePickerViewDataSource: AnyObject {
    func numberOfItems(in modePickerView: ModePickerView) -> Int
    func modePickerView(_ modePickerView: ModePickerView, titleForItem item: Int) -> String
}

protocol ModePickerViewDelegate: UIScrollViewDelegate {
    func modePickerView(_ modePickerView: ModePickerView, didSelectItem item: Int)
}

class ModePickerView: UIView {
    weak var dataSource: ModePickerViewDataSource!
    weak var delegate: ModePickerViewDelegate!
    
    lazy var font: UIFont = UIFont.subheadlineSemiboldFont
    
    private var selectedItem: Int = 0
    private var prevIndex: Int = 0
    
    private var collectionView: UICollectionView!
    
    private lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0.0
        return layout
    }()
    
    var contentOffset: CGPoint {
        get { return collectionView.contentOffset }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func selectItem(_ item: Int, animated: Bool = false) {
        selectItem(item, animated: animated, notifySelection: true)
    }
    
    func scrollToItem(_ item: Int, animated: Bool = false) {
        collectionView.scrollToItem(at: IndexPath(item: item, section: 0),
                                    at: .centeredHorizontally,
                                    animated: animated)
    }
    
    func reloadData() {
        invalidateIntrinsicContentSize()
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
        
        guard (dataSource?.numberOfItems(in: self)) != nil else { return }
        collectionView.setNeedsDisplay()
        selectItem(selectedItem, animated: false, notifySelection: false)
    }
}


private extension ModePickerView {
    func configure() {
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: collectionViewLayout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.decelerationRate = .fast
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addSubview(collectionView)
    }
    
    func sizeForString(_ string: NSString) -> CGSize {
        let size = string.size(withAttributes: [NSAttributedString.Key.font: self.font])
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
    
    func didEndScrolling() {
        let center = convert(collectionView.center, to: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: center) {
            selectItem(indexPath.item, animated: true, notifySelection: true)
        }
    }
    
    func selectItem(_ item: Int, animated: Bool, notifySelection: Bool) {
        collectionView.selectItem(at: IndexPath(item: item, section: 0),
                                  animated: animated,
                                  scrollPosition: .centeredHorizontally)
        
        scrollToItem(item, animated: animated)
        selectedItem = item
        if notifySelection {
            delegate.modePickerView(self, didSelectItem: item)
        }
    }
}

private extension ModePickerView {
    func switchModeFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}


extension ModePickerView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfItems(in: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCellWithAutoregistration(ModePickerCell.self, for: indexPath) else {
            return UICollectionViewCell()
        }
        
        cell.label.text = dataSource.modePickerView(self, titleForItem: indexPath.item)
        cell._isSelected = indexPath.item == selectedItem
        return cell
    }
}


extension ModePickerView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectItem(indexPath.item, animated: true)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.isTracking == false {
            didEndScrolling()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            didEndScrolling()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let cells = collectionView.visibleCells
        
        cells.forEach {
            ($0 as? ModePickerCell)?._isSelected = false
        }
        
        let x = collectionView.contentOffset.x + collectionView.bounds.width / 2
        
        if let indexPath = collectionView.indexPathForItem(at: CGPoint(x: x, y: collectionView.contentOffset.y)),
            let cell = collectionView.cellForItem(at: indexPath) as? ModePickerCell {
            
            cell._isSelected = true
            if indexPath.row != prevIndex {
                if #available(iOS 10.0, *) {
                    switchModeFeedback()
                }
                delegate.modePickerView(self, didSelectItem: indexPath.row)
                prevIndex = indexPath.row
            }
        }
    }
}

extension ModePickerView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = CGSize(width: 0, height: collectionView.frame.size.height)
        let title = dataSource.modePickerView(self, titleForItem: indexPath.item)
        size.width += self.sizeForString(title as NSString).width + 12 * 2
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let number = collectionView.numberOfItems(inSection: section)
        let firstIndexPath = IndexPath(item: 0, section: section)
        let firstSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: firstIndexPath)
        let lastIndexPath = IndexPath(item: number - 1, section: section)
        let lastSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: lastIndexPath)
        return UIEdgeInsets(
            top: 0, left: (collectionView.bounds.size.width - firstSize.width) / 2,
            bottom: 0, right: (collectionView.bounds.size.width - lastSize.width) / 2
        )
    }
}
