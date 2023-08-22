//
//  Command.swift
//  ZupanCommandRecognition
//
//  Created by Luka Gabric on 20.08.2023..
//

import Foundation

class Command {
    
    //MARK: - Vars
    
    enum CommandType: String, CaseIterable {
        case code, count, reset, back
        
        var commandBehavior: CommandBehavior {
            switch self {
            case .code: return ParameterizedCommandBehavior()
            case .count: return ParameterizedCommandBehavior()
            case .reset: return ResetCommandBehavior()
            case .back: return BackCommandBehavior()
            }
        }
        
        var parameterProcessor: ParameterProcessor {
            switch self {
            case .code, .count: return CommandParameterProcessor()
            case .reset, .back: return NoParameterProcessor()
            }
        }
    }
    
    let commandType: CommandType

    private let localeId: String
    private(set) var parameters = [Int]()
    private let commandBehavior: CommandBehavior
    private let parameterProcessor: ParameterProcessor
    
    //MARK: - Init
    
    init(commandType: CommandType, localeId: String) {
        self.commandType = commandType
        commandBehavior = commandType.commandBehavior
        parameterProcessor = commandType.parameterProcessor
        self.localeId = localeId
    }
    
    //MARK: - State Updaters
    
    func updateState(input: CommandBehaviorInput) -> CommandBehaviorOutput {
        commandBehavior.execute(input: input)
    }
    
    func processParameter(_ input: String) {
        guard let processedParameter = parameterProcessor.processParameter(input, localeId: localeId) else { return }
        
        parameters.append(processedParameter)
    }
}
