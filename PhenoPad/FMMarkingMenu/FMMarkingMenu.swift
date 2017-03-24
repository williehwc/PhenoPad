//
//  FMMarkingMenu.swift
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

class FMMarkingMenu: NSObject
{
    var markingMenuItems:[FMMarkingMenuItem]
    var layoutMode = FMMarkingMenuLayoutMode.semiCircular
    var launchMode = FMMarkingMenuLaunchMode.openAtTouchLocation
    var visualiseTouches: Bool = false
    
    let markingMenuContentViewController: FMMarkingMenuContentViewController
    let viewController: UIViewController
    let view: UIView
    
    fileprivate var tap: FMMarkingMenuPanGestureRecognizer!
    fileprivate var previousTouchLocation = CGPoint.zero
    
    weak var markingMenuDelegate: FMMarkingMenuDelegate?
    {
        didSet
        {
            markingMenuContentViewController.markingMenuDelegate = markingMenuDelegate
        }
    }
    
    init(viewController: UIViewController, view: UIView, markingMenuItems:[FMMarkingMenuItem])
    {
        self.markingMenuItems = markingMenuItems
     
        markingMenuContentViewController = FMMarkingMenuContentViewController()
        
        self.viewController = viewController
        self.view = view
        self.view.isUserInteractionEnabled = true
        
        super.init();
        
        markingMenuContentViewController.markingMenu = self
        
        tap = FMMarkingMenuPanGestureRecognizer(target: self, action: #selector(FMMarkingMenu.tapHandler(_:)), markingMenu: self)

        view.addGestureRecognizer(tap)
    }
    
    deinit
    {
        viewController.view.removeGestureRecognizer(tap)
    }
    
    func tapHandler(_ recognizer: FMMarkingMenuPanGestureRecognizer)
    {
        if recognizer.state == UIGestureRecognizerState.began
        {
            // nothing to do here, FMMarkingMenuPanGestureRecognizer
            // invokes open() on touchesBegan
        }
        else if recognizer.state == UIGestureRecognizerState.changed
        {
            markingMenuContentViewController.handleMovement(recognizer.location(in: view), targetView: view)
        }
        else
        {
           close()
        }
    }
    
    func close()
    {
        markingMenuContentViewController.closeMarkingMenu()
        viewController.dismiss(animated: false, completion: nil)
    }
    
    func open(_ locationInView: CGPoint)
    {        
        markingMenuContentViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        markingMenuContentViewController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        
        markingMenuContentViewController.view.frame = view.bounds
        
        markingMenuContentViewController.layoutMode = layoutMode
        
        viewController.present(markingMenuContentViewController, animated: false)
        {
            let markingMenuOrigin: CGPoint
            
            if self.launchMode == .openAtScreenCentre
            {
                markingMenuOrigin = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 2)
            }
            else
            {
                markingMenuOrigin = self.view.convert(locationInView, to: self.viewController.view)
            }
            
            self.markingMenuContentViewController.origin = markingMenuOrigin
            self.markingMenuContentViewController.openMarkingMenu(locationInView, markingMenuItems: self.markingMenuItems, targetView: self.view)
        }
    }
    
    // MARK: Utilities...
    
    static func setExclusivelySelected(_ markingMenuItem: FMMarkingMenuItem, markingMenuItems: [FMMarkingMenuItem])
    {
        let items = getMenuItemsByCategory(markingMenuItem.category!, markingMenuItems: markingMenuItems)
        
        for item in items where item !== markingMenuItem
        {
            item.isSelected = false
        }
        
        markingMenuItem.isSelected = true
    }
    
    static func getMenuItemsByCategory(_ category:String, markingMenuItems: [FMMarkingMenuItem]) -> [FMMarkingMenuItem]
    {
        var returnArray = [FMMarkingMenuItem]()
        
        for item in markingMenuItems
        {
            if item.category == category
            {
                returnArray.append(item)
            }
            
            if let subItems = item.subItems
            {
                returnArray.append(contentsOf: FMMarkingMenu.getMenuItemsByCategory(category, markingMenuItems: subItems))
            }
        }
        
        return returnArray
    }
}


