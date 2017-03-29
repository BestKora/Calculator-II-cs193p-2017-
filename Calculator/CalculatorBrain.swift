//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Tatiana Kornilova on 3/8/17.
//  All rights reserved.
//

import Foundation

struct CalculatorBrain {
    
    private enum OpStack {
        case operand(Double)        // операнд
        case operation(String)      // операция
        case variable(String)       // переменная
        
    }
    
    private var internalProgram = [OpStack]()
    
    mutating func setOperand (_ operand: Double){
        internalProgram.append(OpStack.operand(operand))
    }
    
    mutating func setOperand(variable named: String) {
        internalProgram.append(OpStack.variable(named))
    }
    
    mutating func performOperation(_ symbol: String) {
        internalProgram.append(OpStack.operation(symbol))
    }
    
    mutating func clear() {
        internalProgram.removeAll()
    }
    
    mutating func undo() {
        if !internalProgram.isEmpty {
            internalProgram = Array(internalProgram.dropLast())
        }
    }
    
    private enum Operation {
        case nullaryOperation(() -> Double,String)
        case constant (Double)
        case unaryOperation ((Double) -> Double,((String) -> String)?)
        case binaryOperation ((Double, Double) -> Double, ((String, String) -> String)?)
        case equals
        
    }
    
    private var operations : Dictionary <String,Operation> = [
        "Ran": Operation.nullaryOperation({ Double(arc4random()) / Double(UInt32.max)}, "rand()"),
        "π": Operation.constant(Double.pi),
        "e": Operation.constant(M_E),
        "±": Operation.unaryOperation({ -$0 },nil),           //standard { "±(" + $0 + ")"}
        "√": Operation.unaryOperation(sqrt,nil),              //standard  { "√(" + $0 + ")"}
        "cos": Operation.unaryOperation(cos,nil),             //standard  { "cos(" + $0 + ")"}
        "sin": Operation.unaryOperation(sin,nil),             //standard  { "sin(" + $0 + ")"}
        "tan": Operation.unaryOperation(tan,nil),             //standard  { "tan(" + $0 + ")"}
        "sin⁻¹" : Operation.unaryOperation(asin,nil),         //standard  { "sin⁻¹(" + $0 + ")"}
        "cos⁻¹" : Operation.unaryOperation(acos,nil),         //standard  { "cos⁻¹(" + $0 + ")"}
        "tan⁻¹" : Operation.unaryOperation(atan, nil),        //standard  { "tan⁻¹(" + $0 + ")"}
        "ln" : Operation.unaryOperation(log,nil),             //standard   { "ln(" + $0 + ")"}
        "x⁻¹" : Operation.unaryOperation({1.0/$0}, {"(" + $0 + ")⁻¹"}),
        "х²" : Operation.unaryOperation({$0 * $0}, { "(" + $0 + ")²"}),
        "×": Operation.binaryOperation(*, nil),                //standard  { $0 + " × " + $1 }
        "÷": Operation.binaryOperation(/, nil),                //standard  { $0 + " ÷ " + $1 }
        "+": Operation.binaryOperation(+, nil),                //standard  { $0 + " + " + $1 }
        "−": Operation.binaryOperation(-, nil),                //standard  { $0 + " - " + $1 }
        "xʸ" : Operation.binaryOperation(pow, { $0 + " ^ " + $1 }),
        "=": Operation.equals
    ]
    struct PendingBinaryOperation {
        let function: (Double,Double) -> Double
        let firstOperand: Double
        var descriptionFunction: (String, String) -> String
        var descriptionOperand: String
        func perform (with secondOperand: Double) -> Double {
            return function (firstOperand, secondOperand)
        }
        func performDescription (with secondOperand: String) -> String {
            return descriptionFunction ( descriptionOperand, secondOperand)
        }
    }
    
    //-------------------------------------------------------------------------
    // MARK: - evaluate
    
    func evaluate(using variables: Dictionary<String,Double>? = nil) ->
        (result: Double?, isPending: Bool, description: String){
            
            // MARK: - Local variables evaluate
            
            var cache: (accumulator: Double?, descriptionAccumulator: String?) // tuple
            
            var pendingBinaryOperation: PendingBinaryOperation?
            
            var description: String? {
                get {
                    if pendingBinaryOperation == nil {
                        return cache.descriptionAccumulator
                    } else {
                        return  pendingBinaryOperation!.descriptionFunction(
                            pendingBinaryOperation!.descriptionOperand,
                            cache.descriptionAccumulator ?? "")
                    }
                }
            }
            
            var result: Double? {
                get {
                    return cache.accumulator
                }
            }
            
            var resultIsPending: Bool {
                get {
                    return pendingBinaryOperation != nil
                }
            }
            
            // MARK: - Nested function evaluate
            
            func setOperand (_ operand: Double){
                cache.accumulator = operand
                if let value = cache.accumulator {
                    cache.descriptionAccumulator =
                        formatter.string(from: NSNumber(value:value)) ?? ""
                }
            }
            
            func setOperand (variable named: String) {
                cache.accumulator = variables?[named] ?? 0
                cache.descriptionAccumulator = named
            }
            
            func performOperation(_ symbol: String) {
                if let operation = operations[symbol]{
                    switch operation {
                        
                    case .nullaryOperation(let function, let descriptionValue):
                        cache = (function(), descriptionValue)
                        
                    case .constant(let value):
                        cache = (value,symbol)
                        
                    case .unaryOperation (let function, var descriptionFunction):
                        if cache.accumulator != nil {
                            cache.accumulator = function (cache.accumulator!)
                            if  descriptionFunction == nil{
                                descriptionFunction = {symbol + "(" + $0 + ")"}   //standard
                            }
                            cache.descriptionAccumulator =
                                descriptionFunction!(cache.descriptionAccumulator!)
                        }
                    case .binaryOperation (let function, var descriptionFunction):
                        performPendingBinaryOperation()
                        if cache.accumulator != nil {
                            if  descriptionFunction == nil{
                                descriptionFunction = {$0 + " " + symbol + " " + $1}   //standard
                            }
                            pendingBinaryOperation = PendingBinaryOperation (function: function,
                                                                             firstOperand: cache.accumulator!,
                                                                             descriptionFunction: descriptionFunction!,
                                                                             descriptionOperand: cache.descriptionAccumulator!)
                            cache = (nil, nil)
                            
                        }
                    case .equals:
                        performPendingBinaryOperation()
                        
                    }
                }
            }
            
            func  performPendingBinaryOperation() {
                if pendingBinaryOperation != nil && cache.accumulator != nil {
                    
                    cache.accumulator =  pendingBinaryOperation!.perform(with: cache.accumulator!)
                    cache.descriptionAccumulator =
                        pendingBinaryOperation!.performDescription(with: cache.descriptionAccumulator!)
                    
                    pendingBinaryOperation = nil
                }
            }
            
            
            // MARK: - Body evaluate
            
            //------ body of  evaluate-----------------------------
            guard !internalProgram.isEmpty else {return (nil,false," ")}
            for op in internalProgram {
                switch op{
                case .operand(let operand):
                    setOperand(operand)
                case .operation(let operation):
                    performOperation(operation)
                case .variable(let symbol):
                    setOperand (variable:symbol)
                    
                }
            }
            return (result, resultIsPending, description ?? " ")
    }
    //---------------------------------------------------------
    
    @available(iOS, deprecated, message: "No longer needed")
    var description: String {
        get {
            return evaluate().description
        }
    }
    @available(iOS, deprecated, message: "No longer needed")
    var result: Double? {
        get {
            return evaluate().result
        }
    }
    
    @available(iOS, deprecated, message: "No longer needed")
    var resultIsPending: Bool {
        get {
            return evaluate().isPending
        }
    }
}

let formatter:NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 6
    formatter.notANumberSymbol = "Error"
    formatter.groupingSeparator = " "
    formatter.locale = Locale.current
    return formatter
    
} ()
