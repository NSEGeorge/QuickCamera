//
//  ViewController.swift
//  QuickCamera
//
//  Created by Georgij Emelyanov on 15/09/2019.
//  Copyright © 2019 Georgij Emelyanov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private var actionButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(openCamera), for: .touchUpInside)
        button.setTitle("Open camera", for: .normal)
        button.backgroundColor = UIColor.blue
        button.tintColor = UIColor.red
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.yellow
        view.addSubview(actionButton)
        
        actionButton.sizeToFit()
        
        NSLayoutConstraint.activate([
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            actionButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    @objc
    func openCamera() {
        let vc = QuickCameraViewController()
        present(vc, animated: true, completion: nil)
    }
}

