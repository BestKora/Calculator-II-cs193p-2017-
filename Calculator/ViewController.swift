//
//  ViewController.swift
//  Calculator
//
//  Created by Tatiana Kornilova on 3/8/17.
//  All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var history: UILabel!
    @IBOutlet weak var tochka: UIButton!{
        didSet {
            tochka.setTitle(decimalSeparator, for: UIControlState())
        }
    }
    
    @IBOutlet weak var displayM: UILabel!
    
    let decimalSeparator = formatter.decimalSeparator ?? "."
    var userInTheMiddleOfTyping = false
    
    @IBAction func touchDigit(_ sender: UIButton) {
        let digit = sender.currentTitle!
        if userInTheMiddleOfTyping {
            let textCurrentlyInDisplay = display.text!
            if (digit != decimalSeparator) || !(textCurrentlyInDisplay.contains(decimalSeparator)) {
                display.text = textCurrentlyInDisplay + digit
            }
        } else {
            display.text = digit
            userInTheMiddleOfTyping = true
        }
    }
    
    var displayValue: Double? {
        get {
            if let text = display.text, let value = Double(text){
                return value
            }
            return nil
        }
        set {
            if let value = newValue {
                display.text = formatter.string(from: NSNumber(value:value))
            }
        }
    }
    
    
    var displayResult: (result: Double?, isPending: Bool, description: String) = (nil, false," "){
        // Наблюдатель Свойства модифицирует две IBOutlet метки
        didSet {
            displayValue = displayResult.result
            if displayResult.result == nil && displayResult.description == " "{
                displayValue = 0
            }
            history.text = displayResult.description != " " ?
                displayResult.description + (displayResult.isPending ? " …" : " =") : " "
            displayM.text = formatter.string(from: NSNumber(value:variableValues["M"] ?? 0))
        }
    }
    
    // MARK: - Model
    
    private var brain = CalculatorBrain ()
    private var variableValues = [String: Double]()
    
    @IBAction func performOPeration(_ sender: UIButton) {
        if userInTheMiddleOfTyping {
            if let value = displayValue{
                brain.setOperand(value)
            }
            userInTheMiddleOfTyping = false
        }
        if  let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        displayResult = brain.evaluate(using: variableValues)
    }
    
    @IBAction func setM(_ sender: UIButton) {
        userInTheMiddleOfTyping = false
        let symbol = String((sender.currentTitle!).characters.dropFirst())
        
        variableValues[symbol] = displayValue
        displayResult = brain.evaluate(using: variableValues)
    }
    
    @IBAction func pushM(_ sender: UIButton) {
        brain.setOperand(variable: sender.currentTitle!)
        displayResult = brain.evaluate(using: variableValues)
    }
    
    @IBAction func clearAll(_ sender: UIButton) {
        brain.clear()
        variableValues = [:]
        displayResult = brain.evaluate()
    }
    
    @IBAction func backspace(_ sender: UIButton) {
        if userInTheMiddleOfTyping {
            guard !display.text!.isEmpty else { return }
            display.text = String (display.text!.characters.dropLast())
            if display.text!.isEmpty{
                displayValue = 0
                userInTheMiddleOfTyping = false
                displayResult = brain.evaluate(using: variableValues)
            }
        } else {
            brain.undo()
            displayResult = brain.evaluate(using: variableValues)
            
        }
    }
}
