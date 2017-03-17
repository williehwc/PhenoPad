//
//  PencilBrush.swift
//  DrawingBoard
//
//  Created by 张奥 on 15/3/18.
//  Copyright (c) 2015年 zhangao. All rights reserved.
//

import UIKit

class PencilBrush: BaseBrush {
    
    func beginScribble(_ point: CGPoint)
    {
        interpolationPoints = [point]
    }
    
    func appendScribble(_ point: CGPoint)
    {
        interpolationPoints.append(point)
        
        hermitePath.removeAllPoints()
        hermitePath.interpolatePointsWithHermite(interpolationPoints)
        
        //drawingLayer.path = hermitePath.cgPath
    }
    
    func endScribble()
    {
        hermitePath.removeAllPoints()
    }
    
    func clearScribble()
    {
        // backgroundLayer.path = nil
    }

    
    override func drawInContext(_ context: CGContext) {
        if let lastPoint = lastPoint {
            context.move(to: CGPoint(x: lastPoint.x, y: lastPoint.y))
            context.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            //context.addPath(hermitePath.cgPath)
        } else {
            context.move(to: CGPoint(x: beginPoint.x, y: beginPoint.y))
            context.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            //beginScribble(beginPoint)
        }
    }
    
    override func supportedContinuousDrawing() -> Bool {
        return true
    }
}
