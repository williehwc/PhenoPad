//
//  FMMarkingMenuContentViewController.swift
//  
//
//  Created by Simon Gladman on 18/06/2015.
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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class FMMarkingMenuContentViewController: UIViewController
{
    var origin = CGPoint.zero
    var layoutMode = FMMarkingMenuLayoutMode.circular
    
    let tau = CGFloat(M_PI * 2)
    let pi = CGFloat(M_PI)
    let radius = CGFloat(100)
    let labelRadius = CGFloat(130)
    
    fileprivate var visualiseTouches: Bool
    {
        return markingMenu.visualiseTouches
    }
    
    fileprivate var touchVisualiser: CAShapeLayer?
    
    fileprivate let markingMenuLayer = CAShapeLayer()
    fileprivate var markingMenuItems: [FMMarkingMenuItem]!
    fileprivate var markingMenuLayers = [CAShapeLayer]()
    fileprivate var markingMenuLabels = [UILabel]()
    
    fileprivate var drawingOffset:CGPoint = CGPoint.zero
    
    fileprivate var valueSliderInitialAngle: CGFloat? // if not nil, indicates we're in "value slider mode"
    {
        didSet
        {
            if valueSliderInitialAngle == nil
            {
                valueSliderProgressLayer?.removeFromSuperlayer()
                valueSliderProgressLayer = nil
                valueSliderInitialValue = nil
                previousSliderValue = nil
            }
            else
            {
                valueSliderProgressLayer = CAShapeLayer()
                markingMenuLayer.addSublayer(valueSliderProgressLayer!)
                
                valueSliderProgressLayer?.fillColor = nil
                valueSliderProgressLayer?.lineJoin = kCALineJoinRound
                valueSliderProgressLayer?.lineCap = kCALineCapRound
            }
        }
    }
    fileprivate var valueSliderIndex: Int?
    fileprivate var valueSliderLabel: UILabel?
    fileprivate var valueSliderMarkingMenuLayer: CAShapeLayer?
    fileprivate var valueSliderInitialValue: CGFloat?
    fileprivate var valueSliderProgressLayer: CAShapeLayer?
    fileprivate var previousSliderValue:CGFloat?
    
    weak var markingMenu: FMMarkingMenu!
    weak var markingMenuDelegate: FMMarkingMenuDelegate?
    
    required init()
    {
        super.init(nibName: nil, bundle: nil)
        
        view.layer.addSublayer(markingMenuLayer)
        markingMenuLayer.frame = view.bounds
        
        markingMenuLayer.strokeColor = UIColor.init(red: 255, green: 59, blue: 48).cgColor
        markingMenuLayer.fillColor = nil
        markingMenuLayer.lineWidth = 3
        markingMenuLayer.lineJoin = kCALineJoinRound
        markingMenuLayer.lineCap = kCALineCapRound
    }

    required init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleMovement(_ locationInView: CGPoint, targetView: UIView)
    {
        if markingMenuLayer.path == nil
        {
            return
        }
        
        if let touchVisualiser = touchVisualiser
        {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            touchVisualiser.frame = CGRect(origin: targetView.convert(locationInView, to: view), size: CGSize.zero)
            
            CATransaction.commit()
        }
        
        let drawPath = UIBezierPath(cgPath: markingMenuLayer.path!)
        let locationInMarkingMenu = CGPoint(x: locationInView.x + drawingOffset.x, y: locationInView.y + drawingOffset.y)
        
        drawPath.addLine(to: locationInMarkingMenu)
        
        markingMenuLayer.path = drawPath.cgPath
        
        let distanceToMenuOrigin = origin.distance(locationInMarkingMenu)
       
        let angle: CGFloat
        
        let segmentIndex: Int
        
        if layoutMode == FMMarkingMenuLayoutMode.circular
        {
            angle = tau - (((pi * 1.5) + atan2(locationInMarkingMenu.x - origin.x, locationInMarkingMenu.y - origin.y)) )
            segmentIndex = Int((angle < 0 ? tau + angle : angle) / sectionArc )
        }
        else
        {
            angle = 0 - (((pi * 0.5) + atan2(locationInMarkingMenu.x - origin.x, locationInMarkingMenu.y - origin.y)) )
            segmentIndex = Int((angle < 0 ? tau + angle : angle) / sectionArc )
        }
        
        if let valueSliderInitialAngle = valueSliderInitialAngle // value slider open....
        {
            let diff: CGFloat
            
            if layoutMode == FMMarkingMenuLayoutMode.circular
            {
                diff = (angle - valueSliderInitialAngle) < pi ? (angle - valueSliderInitialAngle) : (angle - valueSliderInitialAngle - tau)
            }
            else
            {
                diff = (angle - valueSliderInitialAngle) < -pi
                    ? (angle - valueSliderInitialAngle) + tau
                    : (angle - valueSliderInitialAngle) < pi ? (angle - valueSliderInitialAngle) : (angle - valueSliderInitialAngle - tau)
            }
            
            var normalisedValue = min(max(0, valueSliderInitialValue! + (diff / pi)), 1)
            
            if previousSliderValue < 0.1 && normalisedValue == 1
            {
                normalisedValue = 0
            }
            else if previousSliderValue > 0.9 && normalisedValue == 0
            {
                normalisedValue = 1
            }
            
            updateSliderProgressLayer(normalisedValue, distanceToMenuOrigin: CGFloat(distanceToMenuOrigin), touchLocation: locationInView, targetView: targetView)
            
            previousSliderValue = normalisedValue
           
            markingMenuDelegate?.FMMarkingMenuValueSliderChange(markingMenu!, markingMenuItem: markingMenuItems[valueSliderIndex!], newValue: normalisedValue, distanceToMenuOrigin: CGFloat(distanceToMenuOrigin))
        }
        else if CGFloat(distanceToMenuOrigin) > radius && segmentIndex < markingMenuItems.count
        {
            if let subItems = markingMenuItems[segmentIndex].subItems, subItems.count > 0 && valueSliderInitialAngle == nil
            {
                // open sub menu...
                
                markingMenuLayers.forEach({ $0.opacity = $0.opacity * 0.15 })
                markingMenuLabels.forEach(){ $0.alpha = $0.alpha * 0.15 }
                
                origin = locationInMarkingMenu
                openMarkingMenu(locationInView, markingMenuItems: subItems, targetView: targetView, clearPath: false)
            }
            else if markingMenuItems[segmentIndex].isValueSlider
            {
                // enter slider mode...
                
                removeSubComponents(indexToKeep: segmentIndex)
                
                view.layer.shadowColor = nil
                view.layer.shadowOpacity = 0
                
                valueSliderLabel = markingMenuLabels[segmentIndex]
                valueSliderMarkingMenuLayer = markingMenuLayers[segmentIndex]
                valueSliderInitialValue = markingMenuItems[segmentIndex].valueSliderValue
                previousSliderValue = valueSliderInitialValue
                valueSliderInitialAngle = angle
                
                applyDefaultMarkingMenuShadowToLayer(valueSliderLabel!.layer)
                applyDefaultMarkingMenuShadowToLayer(valueSliderMarkingMenuLayer!)
                
                displaySlider(segmentIndex)
                
                updateSliderProgressLayer(valueSliderInitialValue!, distanceToMenuOrigin: CGFloat(distanceToMenuOrigin), touchLocation: locationInView, targetView: targetView)
            }
            else
            {
                // execute sub menu item...
                
                markingMenuDelegate?.FMMarkingMenuItemSelected(markingMenu!, markingMenuItem: markingMenuItems[segmentIndex])
                
                markingMenu.close()
            }
        }
    }
    
    fileprivate func updateSliderProgressLayer(_ normalisedValue: CGFloat, distanceToMenuOrigin: CGFloat, touchLocation: CGPoint, targetView: UIView)
    {
        guard let valueSliderProgressLayer = valueSliderProgressLayer,
            let valueSliderInitialAngle = valueSliderInitialAngle,
            let valueSliderMarkingMenuLayer = valueSliderMarkingMenuLayer,
            let valueSliderIndex = valueSliderIndex,
            let valueSliderLabel = valueSliderLabel else
        {
            return
        }

        
        // position label above touch location
        
        markingMenuItems[valueSliderIndex].valueSliderValue = normalisedValue
        valueSliderLabel.text = labelTextForMarkingMenuItem(markingMenuItemIndex: valueSliderIndex)
        
        let labelWidth = valueSliderLabel.intrinsicContentSize.width
        let labelHeight = valueSliderLabel.intrinsicContentSize.height
        
        let locationInView = targetView.convert(touchLocation, to: view)
        
        valueSliderLabel.frame = CGRect(x: locationInView.x - labelWidth / 2,
            y: locationInView.y - labelHeight - 40,
            width: labelWidth,
            height: labelHeight)
        valueSliderLabel.alpha = 1
        
        let tweakedValueSliderInitialAngle = valueSliderInitialAngle + (0.5 - valueSliderInitialValue!) * pi
        let startAngle = tweakedValueSliderInitialAngle - (pi / 2)  + (layoutMode == FMMarkingMenuLayoutMode.circular ? 0 : pi)
        
        // redraw valueSliderMarkingMenuLayer...
        let endAngle = tweakedValueSliderInitialAngle + (pi / 2) + (layoutMode == FMMarkingMenuLayoutMode.circular ? 0 : pi)
        
        let subLayerPath = UIBezierPath()
        
        var rgb: RGB? = nil
        if markingMenuItems[valueSliderIndex].valueSlideType == 1{
            var v = Float(1)
            if distanceToMenuOrigin < 234 {
                v = Float((distanceToMenuOrigin-50)>0 ? (distanceToMenuOrigin-50) : 0) / Float(234 - 50)
            }
            rgb = HSV.rgb(h: 360.0*Float(normalisedValue), s: 1.0, v: v)
            
            valueSliderMarkingMenuLayer.strokeColor = UIColor.init(colorLiteralRed: rgb!.r, green: rgb!.g, blue: rgb!.b, alpha: 1).cgColor
            valueSliderLabel.text = ""
            valueSliderLabel.backgroundColor = UIColor.init(colorLiteralRed: rgb!.r, green: rgb!.g, blue: rgb!.b, alpha: 1)
        } else if markingMenuItems[valueSliderIndex].valueSlideType == 2{
            valueSliderMarkingMenuLayer.lineWidth = 20 * normalisedValue
        }
        
        subLayerPath.addArc(withCenter: origin, radius: distanceToMenuOrigin, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        
        
        valueSliderMarkingMenuLayer.lineDashPattern = nil
        valueSliderMarkingMenuLayer.path = subLayerPath.cgPath
        valueSliderMarkingMenuLayer.opacity = 1
        
        // draw progress bar...
        /**
        let progressEndAngle = startAngle + (pi * normalisedValue)
        
        valueSliderProgressLayer.lineWidth = 6
        valueSliderProgressLayer.lineDashPattern = [4, 8]
        valueSliderProgressLayer.strokeColor = UIColor.blue.cgColor
        let progressSubLayerPath = UIBezierPath()
        
        if markingMenuItems[valueSliderIndex].valueSlideType == 1{
            valueSliderProgressLayer.strokeColor = UIColor.init(colorLiteralRed: rgb!.r, green: rgb!.g, blue: rgb!.b, alpha: 1).cgColor
        } else if markingMenuItems[valueSliderIndex].valueSlideType == 2{
            valueSliderProgressLayer.lineWidth = 20 * normalisedValue
        }
        
        progressSubLayerPath.addArc(withCenter: origin, radius: distanceToMenuOrigin, startAngle: startAngle, endAngle: progressEndAngle, clockwise: true)
        
        valueSliderProgressLayer.path = progressSubLayerPath.cgPath
        **/
    }
    
    fileprivate func displaySlider(_ segmentIndex: Int)
    {
        guard let valueSliderInitialAngle = valueSliderInitialAngle else
        {
            return
        }

        valueSliderIndex = segmentIndex
        
        let subLayer = markingMenuLayers[segmentIndex]
        
        let tweakedValueSliderInitialAngle = valueSliderInitialAngle + (0.5 - valueSliderInitialValue!) * pi
        let startAngle = tweakedValueSliderInitialAngle - (pi / 2) + (layoutMode == FMMarkingMenuLayoutMode.circular ? 0 : pi)
        let endAngle = tweakedValueSliderInitialAngle + (pi / 2) + (layoutMode == FMMarkingMenuLayoutMode.circular ? 0 : pi)
        
        subLayer.lineWidth = 8
        subLayer.lineDashPattern = [4, 8]
        
        let subLayerPath = UIBezierPath()
        
        subLayerPath.addArc(withCenter: origin, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)

        let labelLineAngle = (sectionArc * (CGFloat(segmentIndex) + 0.5)) + (layoutMode == FMMarkingMenuLayoutMode.circular ? 0 : pi)
        
        addLabelConnectingLineToPath(subLayerPath, angle: labelLineAngle)
        
        subLayer.path = subLayerPath.cgPath
    }
    
    func openMarkingMenu(_ locationInView: CGPoint, markingMenuItems: [FMMarkingMenuItem], targetView: UIView, clearPath: Bool = true)
    {
        self.markingMenuItems = markingMenuItems
        
        applyDefaultMarkingMenuShadowToLayer(view.layer)
        
        drawingOffset = CGPoint(x: origin.x - locationInView.x, y: origin.y - locationInView.y)
        
        let paddingAngle = tau * 0.01
        
        valueSliderInitialAngle = nil
        
        if clearPath
        {
            let originCircle = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: origin.x - 4, y: origin.y - 4), size: CGSize(width: 8, height: 8)))
            markingMenuLayer.path = originCircle.cgPath
            
            if visualiseTouches
            {
                touchVisualiser = CAShapeLayer()
            }
            
            if let touchVisualiser = touchVisualiser
            {
                markingMenuLayer.addSublayer(touchVisualiser)
                
                touchVisualiser.frame = CGRect(x: 10, y: 10, width: 50, height: 50)
                touchVisualiser.strokeColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.5).cgColor
                touchVisualiser.fillColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.25).cgColor
                
                let circle = UIBezierPath()
                circle.addArc(withCenter: CGPoint(x: 0, y: 0), radius: 30, startAngle: 0, endAngle: tau, clockwise: true)
                touchVisualiser.path = circle.cgPath
                
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                touchVisualiser.frame =  CGRect(origin: targetView.convert(locationInView, to: view), size: CGSize.zero)
                CATransaction.commit()
            }
        }
        
        for i in 0  ..< markingMenuItems.count 
        {
            let startAngle = (sectionArc * CGFloat(i)) + paddingAngle + (layoutMode == FMMarkingMenuLayoutMode.circular ? 0 : pi)
            let endAngle = (sectionArc * CGFloat(i + 1)) - paddingAngle + (layoutMode == FMMarkingMenuLayoutMode.circular ? 0 : pi)
            
            let subLayer = CAShapeLayer()
            let subLayerPath = UIBezierPath()
            
            subLayer.strokeColor = UIColor.init(red: 0, green: 122, blue: 255).cgColor
            subLayer.fillColor = nil
            subLayer.lineCap = kCALineCapRound
            
            if (markingMenuItems[i].subItems ?? []).count != 0
            {
                subLayer.lineWidth = 4
                subLayer.lineDashPattern = [4, 8]
            }
            else if (markingMenuItems[i].isValueSlider)
            {
                subLayer.lineWidth = 4
                subLayer.lineDashPattern = [4, 8]
            }
            else
            {
                subLayer.lineWidth = 4
            }
            
            markingMenuLayer.addSublayer(subLayer)
            
            let midAngle = (startAngle + endAngle) / 2
            
            let label = UILabel()
            label.text = labelTextForMarkingMenuItem(markingMenuItemIndex: i)
            label.textColor = markingMenuItems[i].isSelected ? UIColor.init(red: 244, green: 241, blue: 0) : UIColor.white
            label.backgroundColor = UIColor.init(red: 0, green: 122, blue: 255)
            
            markingMenuLabels.append(label)
            
            let labelWidth = label.intrinsicContentSize.width
            let labelHeight = label.intrinsicContentSize.height
            
            let labelXOffsetTweak = (midAngle > pi * 0.45 && midAngle < pi * 0.55) || (midAngle > pi * 1.45 && midAngle < pi * 1.55) ? label.intrinsicContentSize.width / 2 : 15
            
            let labelXOffset = (midAngle > pi * 0.5 && midAngle < pi * 1.5) ? -labelWidth + labelXOffsetTweak : -labelXOffsetTweak
            let labelYOffset = (midAngle > pi) ? -labelHeight : midAngle == pi ? -labelHeight * 0.5 : 0
            
            label.frame = CGRect(origin: CGPoint(
                x: origin.x + labelXOffset + cos(midAngle) * labelRadius,
                y: origin.y + labelYOffset + sin(midAngle) * labelRadius),
                size: CGSize(width: labelWidth, height: labelHeight))
            
            label.layer.backgroundColor = UIColor.lightGray.cgColor
            label.layer.cornerRadius = 4
            label.layer.masksToBounds = false
            label.alpha = 1
            
            subLayerPath.addArc(withCenter: origin, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            
            addLabelConnectingLineToPath(subLayerPath, angle: midAngle)
            
            subLayer.path = subLayerPath.cgPath
    
            markingMenuLayers.append(subLayer)
            view.addSubview(label)
            
            UIView.animate(withDuration: 0.1, animations: {label.alpha = 1})
        }
    }
    
    func closeMarkingMenu()
    {
        removeSubComponents()
        
        valueSliderProgressLayer?.path = nil
        valueSliderProgressLayer?.removeFromSuperlayer()
        
        touchVisualiser?.path = nil
        touchVisualiser?.removeFromSuperlayer()
        touchVisualiser = nil
        
        markingMenuLayers = [CAShapeLayer]()
        markingMenuLabels = [UILabel]()
        
        markingMenuLayer.path = nil
        valueSliderMarkingMenuLayer = nil
    }
    
    // MARK: utilities
    
    func removeSubComponents(indexToKeep: Int = -1)
    {
        for (idx, layerLabelTuple) in zip(markingMenuLayers, markingMenuLabels).enumerated() where idx != indexToKeep
        {
            layerLabelTuple.0.removeFromSuperlayer()
            layerLabelTuple.1.removeFromSuperview()
        }
    }
    
    func labelTextForMarkingMenuItem(markingMenuItemIndex i: Int) -> String
    {
        if markingMenuItems[i].valueSlideType == 1 {
            return " " + markingMenuItems[i].label + " "
        }
        return " " + markingMenuItems[i].label + (markingMenuItems[i].isValueSlider ? " \(Int(markingMenuItems[i].valueSliderValue * 100))% " : " ")
    }
    
    var sectionArc: CGFloat
    {
        let segments = CGFloat(markingMenuItems.count)
        let sectionArc = (tau / segments) / (layoutMode == FMMarkingMenuLayoutMode.circular ? 1.0 : 2.0)
        
        return sectionArc
    }
    
    fileprivate func addLabelConnectingLineToPath(_ path: UIBezierPath, angle: CGFloat)
    {
        path.move(to: CGPoint(
            x: origin.x + cos(angle) * radius,
            y: origin.y + sin(angle) * radius))
        
        path.addLine(to: CGPoint(
            x: origin.x + cos(angle) * (labelRadius + 12),
            y: origin.y + sin(angle) * (labelRadius + 12)))
    }
    
}


