//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Vikram on 1/1/16.
//  Copyright © 2016 Vikram Swamy. All rights reserved.
//

import Foundation

class CalculatorBrain {
    
    private enum Op: CustomStringConvertible {
        case Operand(Double)
        case UnaryOperation(String, Double -> Double, (Double -> String?)?)
        case BinaryOperation(String, (Double, Double) -> Double, ((Double, Double) -> String?)?)
        case Variable(String)
        case Constant(String, Double)
        
        var description: String {
            get {
                switch self {
                case .Operand(let operand):
                    return "\(operand)"
                case .UnaryOperation(let symbol, _, _):
                    return symbol
                case .BinaryOperation(let symbol, _, _):
                    return symbol
                case .Variable(let symbol):
                    return symbol
                case .Constant(let symbol, _):
                    return symbol
                }
            }
        }
        
        var precedence: Int {
            get {
                switch self {
                case .Operand, .Variable, .Constant, .UnaryOperation:
                    return Int.max
                case .BinaryOperation(let symbol, _, _):
                    switch symbol {
                    case "+", "−":
                        return Int.max - 2
                    default:
                        return Int.max - 1
                    }
                    
                }
            }
        }
    }

    private var opStack = [Op]()
    
    private var knownOps = [String:Op]()
    
    private var error: String?
    
    
    init() {
        knownOps["×"] = Op.BinaryOperation("x", *, nil)
        knownOps["÷"] = Op.BinaryOperation("÷", { $1 / $0 }) { divisor, _ in return divisor == 0 ? "Cannot divide by zero" : nil }
        knownOps["+"] = Op.BinaryOperation("+", +, nil)
        knownOps["−"] = Op.BinaryOperation("−", { $1 - $0 }, nil)
        knownOps["√"] = Op.UnaryOperation("√", sqrt) { return $0 < 0 ? "Cannot SQRT negative number" : nil }
        knownOps["cos"] = Op.UnaryOperation("cos", cos, nil)
        knownOps["sin"] = Op.UnaryOperation("sin", sin, nil)
        knownOps["π"] = Op.Constant("π", M_PI)
        knownOps["+/-"] = Op.UnaryOperation("+/-", { -$0 }, nil)
    }
    
    var program: AnyObject {  // guaranteed to be a PropertyList
        get {
            return opStack.map { $0.description }
        }
        set {
            if let opSymbols = newValue as? Array<String> {
                var newOpStack = [Op]()
                for opSymbol in opSymbols {
                    if let op = knownOps[opSymbol] {
                        newOpStack.append(op)
                } else if let operand = NSNumberFormatter().numberFromString(opSymbol)?.doubleValue {
                        newOpStack.append(.Operand(operand))
                    }
                else {
                    newOpStack.append(.Variable(opSymbol))
                    }
                }
                opStack = newOpStack
            }
        }
    }
    
    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op])
    {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .Operand(let operand):
                return (operand, remainingOps)
            case .Constant(_, let constantValue):
                return (constantValue, remainingOps)
            case .UnaryOperation(_, let operation, let errorTest):
                let operandEvaluation = evaluate(remainingOps)
                if let operand = operandEvaluation.result {
                    if let errorMessage = errorTest?(operand) {
                        error = errorMessage
                        return (nil, operandEvaluation.remainingOps)
                    }
                    return (operation(operand), operandEvaluation.remainingOps)
                }
            case .BinaryOperation(_, let operation, let errorTest):
                let op1Evaluation = evaluate(remainingOps)
                if let operand1 = op1Evaluation.result {
                    let op2Evaluation = evaluate(op1Evaluation.remainingOps)
                    if let operand2 = op2Evaluation.result {
                        if let errorMessage = errorTest?(operand1, operand2) {
                            error = errorMessage
                            return (nil, op2Evaluation.remainingOps)
                        }
                        return (operation(operand1, operand2), op2Evaluation.remainingOps)
                    }
                }
            case .Variable(let variable):
                if let variableValueAsDouble = variableValues[variable] {
                    return (variableValueAsDouble, remainingOps)
                } else {
                    error = "Variable not set"
                    return (nil, remainingOps)
                }
            }
        }
        error = "Not enough operands"
        return (nil, ops)
    }
    
    func evaluateAndReportErrors() -> (result: Double?, error: String?) {
        let (result, _) = evaluate(opStack)
        return (result, error)
    }
    
    
    private func describeAsString(ops: [Op]) -> (resultString: String, remainingOps: [Op], precedence: Int) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .Operand, .Constant, .Variable:
                return (op.description, remainingOps, op.precedence)
            case .UnaryOperation:
                let operand = describeAsString(remainingOps)
                let newString = "\(op.description)(\(operand.resultString))"
                return (newString, operand.remainingOps, op.precedence)
            case .BinaryOperation:
                let operand2 = describeAsString(remainingOps)
                var operand2String = operand2.resultString
                let operand1 = describeAsString(operand2.remainingOps)
                var operand1String = operand1.resultString
                if op.precedence > operand1.precedence {
                    operand1String = "(\(operand1String))"
                }
                if op.precedence > operand2.precedence {
                    operand2String = "(\(operand2String))"
                }
                let newString = operand1String + op.description + operand2String
                return (newString, operand1.remainingOps, op.precedence)
            }
        } else {
            return ("?", ops, Int.max)
        }
    }
    
    var description: String {
        get  {
            let currentOpStack = opStack
            var (opStackString, remainingOps, _) = describeAsString(currentOpStack)
            while remainingOps.count > 0 {
                let (remainingOpsString, newRemainingOps, _) = describeAsString(remainingOps)
                opStackString = remainingOpsString + ", " + opStackString
                remainingOps = newRemainingOps
            }
            return opStackString + " = "
        }
    }
    
    
    
    var variableValues = [String: Double]()
    
    func evaluate() -> Double? {
        error = nil
        let (result, _) = evaluate(opStack)
        return result
    }
    
    func pushOperand(operand: Double) -> Double? {
        opStack.append(Op.Operand(operand))
        return evaluate()
    }
    
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.Variable(symbol))
        return evaluate()
    }
    
    func performOperation(symbol: String) -> Double? {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
        return evaluate()
    }
    
    func clear() {
        opStack = []
        variableValues = [:]
    }
    
    func undo() {
        opStack.removeLast()
    }
}
