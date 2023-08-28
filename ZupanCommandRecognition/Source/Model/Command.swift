//
//  Command.swift
//  ZupanCommandRecognition
//
//  Created by Luka Gabric on 20.08.2023..
//

import Foundation

class Command {
    
    //MARK: - Vars
    
    enum CommandType: CaseIterable {
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
        
        private var commandLocalizationKey: String { "command.\(self)" }
        
        func localizedString(localizationService: LocalizationService) -> String {
            localizationService.localization(for: commandLocalizationKey).lowercased()
        }
        
        static func commandType(from localizedInput: String, localizationService: LocalizationService) -> CommandType? {
            for type in CommandType.allCases {
                if type.localizedString(localizationService: localizationService) == localizedInput { return type }
            }
            
            return nil
        }
    }
    
    let commandType: CommandType

    private let localizationService: LocalizationService
    private(set) var parameters = [Int]()
    private let commandBehavior: CommandBehavior
    private let parameterProcessor: ParameterProcessor
    
    //MARK: - Init
    
    init(commandType: CommandType, localizationService: LocalizationService) {
        self.commandType = commandType
        commandBehavior = commandType.commandBehavior
        parameterProcessor = commandType.parameterProcessor
        self.localizationService = localizationService
    }
    
    //MARK: - State Updaters
    
    func updateState(input: CommandBehaviorInput) -> CommandBehaviorOutput {
        commandBehavior.execute(input: input)
    }
    
    func processParameter(_ input: String) {
        guard let processedParameter = parameterProcessor.processParameter(input, localizationService: localizationService) else { return }
        
        parameters.append(processedParameter)
    }
}
