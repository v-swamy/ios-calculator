//
//  GraphView.swift
//  Calculator
//
//  Created by Vikram on 2/7/16.
//  Copyright © 2016 Vikram Swamy. All rights reserved.
//

import UIKit

protocol GraphViewDataSource: class {
    func y(x: CGFloat) -> CGFloat?
}

@IBDesignable
class GraphView: UIView {
    
    @IBInspectable
    var scale: CGFloat = 10.0 { didSet { setNeedsDisplay() } }
    
    var graphOrigin: CGPoint? {
        get {
            if originFromCenter != nil {
                var origin = originFromCenter!
                origin.x += center.x
                origin.y += center.y
                return origin
            } else {
                return nil
            }            
        }
        set {
            if newValue != nil {
                var origin = newValue!
                origin.x -= center.x
                origin.y -= center.y
                originFromCenter = origin
            }
        }
    }
    
    var originFromCenter: CGPoint? { didSet { setNeedsDisplay() } }
    
    var savedOrigin: CGPoint?
    
    var color = UIColor.blackColor()
    var lineWidth: CGFloat = 1
    
    weak var dataSource: GraphViewDataSource?
    
    
    func zoom(gesture: UIPinchGestureRecognizer) {
        if gesture.state == .Changed {
            scale *= gesture.scale
            gesture.scale = 1
        }
    }
    
    var minY: Double?
    var maxY: Double?

    
    override func drawRect(rect: CGRect) {
        
        if savedOrigin != nil {
            graphOrigin = savedOrigin
            savedOrigin = nil
        }
        
        if graphOrigin == nil {
            graphOrigin = CGPoint(x: bounds.midX, y: bounds.midY)
        }

        let axes = AxesDrawer(contentScaleFactor: contentScaleFactor)
        axes.drawAxesInRect(bounds, origin: graphOrigin!, pointsPerUnit: scale )
        
        color.set()
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        var moveNotDraw = true
        minY = nil
        maxY = nil
        for var i = 0; i <= Int(bounds.size.width * contentScaleFactor); i++ { //iterate over each pixel
            var point = CGPoint()
            point.x = CGFloat(i) / contentScaleFactor  // the pixel in point coordinate system
            let graphX = round(point.x - graphOrigin!.x) / scale
            if let graphY = dataSource?.y(graphX) {
                if graphY.isNormal || graphY.isZero {
                    point.y = graphOrigin!.y - (graphY * scale)
                    if i == 0 || moveNotDraw {
                        path.moveToPoint(point)
                    } else {
                        path.addLineToPoint(point)
                    }
                    if minY == nil || Double(graphY) < minY {
                        print(Double(graphY))
                        print(minY)
                        minY = Double(graphY)
                    }
                    
                    if maxY == nil || Double(graphY) > maxY {
                        maxY = Double(graphY)
                    }
                    
                    moveNotDraw = false
                } else {
                    moveNotDraw = true
                }
            } else {
                moveNotDraw = true
            }
        }
        path.stroke()
    }
}

