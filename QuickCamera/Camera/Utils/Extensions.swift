//
//  Extensions.swift
//  QuickCamera
//
//  Created by Georgij Emelyanov on 15/09/2019.
//  Copyright © 2019 Georgij Emelyanov. All rights reserved.
//

import UIKit

extension CALayer {
    static func performWithoutAnimation(_ action: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        action()
        CATransaction.commit()
    }
}

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}


extension UIView {
    func addSubviews(_ subviews: [UIView]) {
        subviews.forEach { addSubview($0) }
    }
    
    var actualLayoutGuide: UILayoutGuide {
        if #available(iOS 11, *) {
            return self.safeAreaLayoutGuide
        }
        
        return self.layoutMarginsGuide
    }
}

extension UIDevice {
    var hasNotch: Bool {
        if #available(iOS 11.0, *) {
            let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
            return bottom > 0
        } else {
            return false
        }
    }
}

func PLog<T>(_ object: @autoclosure () -> (T), filename: NSString = #file, line: Int = #line, funcname: String = #function) {
    #if DEBUG
    let file = filename.lastPathComponent
    let threadId = Thread.current.description
    
    func dateFormatter() -> DateFormatter {
        if let dateFormatter = Thread.current.threadDictionary["--date-formatter"] as? DateFormatter {
            return dateFormatter
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
        Thread.current.threadDictionary["--date-formatter"] = dateFormatter
        
        return dateFormatter
    }
    
    print("\(dateFormatter().string(from: Date())))[\(threadId)] \(file)(\(line)) \(funcname): \(object())")
    #endif
}
