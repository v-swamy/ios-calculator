//
//  GraphViewController.swift
//  Calculator
//
//  Created by Vikram on 2/7/16.
//  Copyright © 2016 Vikram Swamy. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, GraphViewDataSource, UIPopoverPresentationControllerDelegate {
    

    private var brain = CalculatorBrain()
    
    var program: AnyObject {
        get {
            return brain.program
        }
        set {
            brain.program = newValue
        }
    }
    
    func y(x: CGFloat) -> CGFloat? {
        brain.variableValues["M"] = Double(x)
        if let y = brain.evaluate() {
            return CGFloat(y)
        }
        return nil
    }
    

    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: "zoom:"))
            graphView.dataSource = self
            graphView.scale = savedScale
            graphView.savedOrigin = savedOrigin
        }
    }
    
    private var snapshot: UIView?
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    
    private var savedOrigin: CGPoint? {
        get {
            if let newOriginArray = defaults.objectForKey("GraphViewController.savedOrigin") as? [CGFloat] {
                var newOrigin = CGPoint()
                newOrigin.x = newOriginArray.first!
                newOrigin.y = newOriginArray.last!
                return newOrigin
            } else {
                return nil
            }
        }
        set {
            defaults.setObject([newValue!.x, newValue!.y], forKey: "GraphViewController.savedOrigin")
        }
        
    }
    
    private var savedScale: CGFloat {
        get {
            return defaults.objectForKey("GraphViewController.savedScale") as? CGFloat ?? 10.0
        }
        set {
            defaults.setObject(newValue, forKey: "GraphViewController.savedScale")
        }
    }
    
    func zoom(gesture: UIPinchGestureRecognizer) {
        graphView.zoom(gesture)
        if gesture.state == .Ended {
            savedScale = graphView.scale
            savedOrigin = graphView.graphOrigin!
        }
    }
    

    
    
    @IBAction func pan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Began:
            snapshot = graphView.snapshotViewAfterScreenUpdates(false)
            snapshot!.alpha = 0.8
            graphView.addSubview(snapshot!)
        case .Changed:
            let translation = gesture.translationInView(graphView)
            snapshot!.center.x += translation.x
            snapshot!.center.y += translation.y
            gesture.setTranslation(CGPointZero, inView: graphView)
        case .Ended:
            graphView.graphOrigin!.x += snapshot!.frame.origin.x
            graphView.graphOrigin!.y += snapshot!.frame.origin.y
            snapshot!.removeFromSuperview()
            snapshot = nil
            savedOrigin = graphView.graphOrigin!
        default: break
        }
    }
    
    
    @IBAction func doubleTap(gesture: UITapGestureRecognizer) {
        if gesture.state == .Ended {
            graphView.graphOrigin = gesture.locationInView(graphView)
            savedOrigin = graphView.graphOrigin!
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
                case "Show Stats":
                    if let tvc = segue.destinationViewController as? TextViewController {
                        if let ppc = tvc.popoverPresentationController {
                            ppc.delegate = self
                        }
                        if graphView.minY != nil && graphView.maxY != nil {
                            tvc.text = "Min Y: \(graphView.minY!)\nMax Y: \(graphView.maxY!)"
                        } else {
                            tvc.text = "none"
                        }
                }
            default: break
            }
        }
        
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }

}

