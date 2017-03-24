//
//  FMMarkingMenuSupportClasses.swift
//  MarkingMenu
//
//  Created by Simon Gladman on 18/06/2015.
//  Copyright (c) 2015 Simon Gladman. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>

import UIKit

class FMMarkingMenuItem
{
    let label: String
    let subItems: [FMMarkingMenuItem]?  // subItems trump isValueSlider
    let isValueSlider:Bool
    var valueSlideType: Int = -1 // 1 for color selector, 2 for width selector, 0 regular
    
    var valueSliderValue: CGFloat = 0.0
    
    // Colors the menu item to indicate selection. Selection logic needs to be implemented in host application
    var isSelected: Bool = false
    
    // Optional category for use in host application
    var category: String?
    
    required init(label: String, subItems: [FMMarkingMenuItem]? = nil, isValueSlider: Bool = false, valueSliderType:Int = -1)
    {
        self.label = label
        self.subItems = subItems
        self.isValueSlider = isValueSlider
    }
    
    convenience init(label: String, valueSliderValue: CGFloat, valueSliderType:Int = 0)
    {
        self.init(label: label, subItems: [], isValueSlider: true)
        
        self.valueSliderValue = valueSliderValue
        self.valueSlideType = valueSliderType
    }
    
    
    convenience init(label: String, category: String, isSelected: Bool = false)
    {
        self.init(label: label, subItems: [], isValueSlider: false)
        
        self.category = category
        self.isSelected = isSelected
    }
}

enum FMMarkingMenuLayoutMode
{
    case circular       // displays menu items over the full circumference of a circle
    case semiCircular   // displays menu items over half the circumference of a circle from 9 o'clock through 3 o'clock (clockwise)
}

enum FMMarkingMenuLaunchMode
{
    case openAtScreenCentre
    case openAtTouchLocation
}

protocol FMMarkingMenuDelegate: NSObjectProtocol
{
    func FMMarkingMenuItemSelected(_ markingMenu: FMMarkingMenu, markingMenuItem: FMMarkingMenuItem)
    
    func FMMarkingMenuValueSliderChange(_ markingMenu: FMMarkingMenu, markingMenuItem: FMMarkingMenuItem, newValue: CGFloat, distanceToMenuOrigin: CGFloat)
    
    
}

// A button like object that opens a marking menu
class FMMarkingMenuWidget: UIView
{
    fileprivate let labelControl = UILabel()
    fileprivate let touchView = UIView()
    fileprivate let markingMenu: FMMarkingMenu
    
    required init(label: String, viewController: UIViewController, markingMenuItems: [FMMarkingMenuItem])
    {
        labelControl.text = label
        labelControl.textAlignment = NSTextAlignment.center
        labelControl.textColor = UIColor.orange
        
        touchView.layer.cornerRadius = 5
        touchView.layer.backgroundColor = UIColor.white.cgColor
        touchView.layer.borderColor = UIColor.orange.cgColor
        touchView.layer.borderWidth = 1
        
        applyDefaultMarkingMenuShadowToLayer(touchView.layer)
        
        markingMenu = FMMarkingMenu(viewController: viewController,
            view: touchView,
            markingMenuItems: markingMenuItems)
        
        super.init(frame: CGRect.zero)
        
        addSubview(touchView)
        addSubview(labelControl)
        
        backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.75)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    var markingMenuDelegate: FMMarkingMenuDelegate?
    {
        set
        {
            markingMenu.markingMenuDelegate = newValue
        }
        get
        {
            return markingMenu.markingMenuDelegate
        }
    }
    
    override func layoutSubviews()
    {
        touchView.frame = bounds.insetBy(dx: 20, dy: 20)
        labelControl.frame = bounds
    }
    
    override var intrinsicContentSize : CGSize
    {
        return CGSize(width: 100, height: 75)
    }
}

// An extended UIPanGestureRecognizer that fires UIGestureRecognizerState.Began
// with the first touch down, i.e. without requiring any movement.
class FMMarkingMenuPanGestureRecognizer: UIPanGestureRecognizer
{
    required init(target: AnyObject?, action: Selector, markingMenu: FMMarkingMenu)
    {
        self.markingMenu = markingMenu
        
        super.init(target: target, action: action)
    }
    
    let markingMenu: FMMarkingMenu
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent)
    {
        if #available(iOS 9.1, *) {
            if touches.first!.type != .stylus {
                let locationInView = touches.first!.location(in: markingMenu.view)
                
                // invoking open on the marking menu gets it to open immediately
                markingMenu.open(locationInView)
                
                super.touchesBegan(touches, with: event)
                
                state = UIGestureRecognizerState.began
            }
        } else {
            // Fallback on earlier versions
        }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        markingMenu.close()
    }
}

extension CGPoint
{
    func distance(_ otherPoint: CGPoint) -> Float
    {
        let xSquare = Float((self.x - otherPoint.x) * (self.x - otherPoint.x))
        let ySquare = Float((self.y - otherPoint.y) * (self.y - otherPoint.y))
        
        return sqrt(xSquare + ySquare)
    }
}

func applyDefaultMarkingMenuShadowToLayer(_ target: CALayer)
{
    /**
    target.shadowColor = UIColor.init(red: 0, green: 122, blue: 255).cgColor
    target.shadowOffset = CGSize(width: 0, height: 0)
    target.shadowOpacity = 1
    target.shadowRadius = 2
 **/
}
