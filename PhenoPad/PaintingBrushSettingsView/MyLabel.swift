//
//  MyLabel.swift
//  PhenoPad
//
//  Created by Jixuan Wang on 2017-03-06.
//  Copyright © 2017 CCM. All rights reserved.
//

import Foundation

class MyLabel: UIView {
    fileprivate let labelControl = UILabel()
    fileprivate let touchView = UIView()
    
    required init(_ label: String)
    {
        labelControl.text = label
        labelControl.textAlignment = NSTextAlignment.center
        labelControl.textColor = UIColor.orange
        
        touchView.layer.cornerRadius = 5
        touchView.layer.backgroundColor = UIColor.white.cgColor
        touchView.layer.borderColor = UIColor.orange.cgColor
        touchView.layer.borderWidth = 1
        
        applyDefaultMarkingMenuShadowToLayer(touchView.layer)
        
        super.init(frame: CGRect.zero)
        
        addSubview(touchView)
        addSubview(labelControl)
        
        backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.75)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews()
    {
        touchView.frame = bounds.insetBy(dx: 2, dy: 2)
        labelControl.frame = bounds
    }
    override var intrinsicContentSize : CGSize
    {
        return CGSize(width: 40, height: 30)
    }
}
