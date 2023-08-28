//
//  ParameterProcessor.swift
//  ZupanCommandRecognition
//
//  Created by Luka Gabric on 20.08.2023..
//

import Foundation

protocol ParameterProcessor {
    func processParameter(_ input: String, localizationService: LocalizationService) -> Int?
}

struct CommandParameterProcessor: ParameterProcessor {
    func processParameter(_ input: String, localizationService: LocalizationService) -> Int? {
        parameter(from: input, localeId: localizationService.localeId)
    }
            
    private func parameter(from string: String, localeId: String) -> Int? {
        if let value = Int(string), 0...9 ~= value {
            return value
        }
        
        if let value = integer(from: string, localeId: localeId), 0...9 ~= value {
            return value
        }
        
        return nil
    }
    
    private func integer(from string: String, localeId: String) -> Int? {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: localeId)
        numberFormatter.numberStyle = .spellOut
        if let number = numberFormatter.number(from: string) {
            return number.intValue
        }
        
        return nil
    }
}

struct NoParameterProcessor: ParameterProcessor {
    func processParameter(_ input: String, localizationService: LocalizationService) -> Int? {
        nil
    }
}
