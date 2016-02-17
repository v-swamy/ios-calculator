//
//  ViewController.swift
//  Calculator
//
//  Created by Vikram on 12/14/15.
//  Copyright © 2015 Vikram Swamy. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {
    
    
    @IBOutlet weak var display: UILabel!

    @IBOutlet weak var history: UILabel!

    
    var userIsInTheMiddleOfTypingANumber = false
    
    private var brain = CalculatorBrain()
    
    
    @IBAction func appendDigit(sender: UIButton) {
        
        let digit = sender.currentTitle!
        
        if userIsInTheMiddleOfTypingANumber {
            if digit == "." && display.text!.rangeOfString(".") != nil {
                return
            }
            display.text = display.text! + digit
        } else {
            if digit == "." {
                display.text = "0."
            }
            else {
                display.text = digit
            }
            userIsInTheMiddleOfTypingANumber = true
        }
    }
    
    
    @IBAction func operate(sender: UIButton) {
        
        if userIsInTheMiddleOfTypingANumber {
            enter()
        }
        if let operation = sender.currentTitle {
            if let result = brain.performOperation(operation) {
                displayValue = result
            } else {
                displayValue = nil
            }
            history.text = brain.description
        }
    }
    
  
    @IBAction func enter() {
        userIsInTheMiddleOfTypingANumber = false
        if let currentDisplayAsDouble = displayValue {
            if let result = brain.pushOperand(currentDisplayAsDouble) {
                displayValue = result
            } else {
                displayValue = nil
            }
        }
        history.text = brain.description
    }
    
    
    @IBAction func backspace() {
        let currentDisplayLength = display.text?.characters.count
        
        if displayValue == nil {
            brain.undo()
            history.text = brain.description
        }

        if currentDisplayLength > 1 {
            display.text = String(display.text!.characters.dropLast())
        }
        else {
            displayValue = nil
        }
    }
    
    
    var displayValue: Double? {
        get {
            if let displayAsDouble = NSNumberFormatter().numberFromString(display.text!)?.doubleValue {
                return displayAsDouble
            } else {
                return nil
            }
        }
        set {
            if let value = newValue {
                display.text = "\(value)"
            } else {
                if let errorMessage = brain.evaluateAndReportErrors().error {
                    display.text = errorMessage
                } else {
                    display.text = " "
                }
            }
            userIsInTheMiddleOfTypingANumber = false
        }
    }
    
    

    @IBAction func clear() {
        brain.clear()
        display.text = " "
        history.text = brain.description
    }
    
    
    @IBAction func plusMinus(sender: UIButton) {
        if userIsInTheMiddleOfTypingANumber {
            let displayAsDouble = Double(display.text!)
            displayValue = -displayAsDouble!
        } else {
            userIsInTheMiddleOfTypingANumber = false
            self.operate(sender)
            enter()
        }
    }
    
    @IBAction func setDisplayAsVariable() {
        userIsInTheMiddleOfTypingANumber = false
        if let currentDisplay = displayValue {
            brain.variableValues["M"] = currentDisplay
            if let result = brain.evaluate() {
                displayValue = result
            } else {
                displayValue = nil
            }
        }
    }
    
    @IBAction func pushVariable(sender: UIButton) {
        let variable = sender.currentTitle!
        if let result = brain.pushOperand(variable) {
                displayValue = result
        } else {
            displayValue = nil
        }
        history.text = brain.description
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var destination = segue.destinationViewController as UIViewController
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController!
        }
        if let gvc = destination as? GraphViewController {
            gvc.program = brain.program
            gvc.title = brain.description == "" ? "Graph" : brain.description.componentsSeparatedByString(", ").last
        }
    }
}


