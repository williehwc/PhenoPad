//
//  DashLineBrush.swift
//  DrawingBoard
//
//  Created by ZhangAo on 15-2-16.
//  Copyright (c) 2015年 zhangao. All rights reserved.
//

import UIKit

class DashLineBrush: BaseBrush {
    
    override func drawInContext(_ context: CGContext) {
        let lengths: [CGFloat] = [self.strokeWidth * 3, self.strokeWidth * 3]
        //CGContextSetLineDash(context, 0, lengths, 2)
        context.setLineDash(phase: 0, lengths: lengths)
        context.move(to: CGPoint(x: beginPoint.x, y: beginPoint.y))
        context.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
    }
}
