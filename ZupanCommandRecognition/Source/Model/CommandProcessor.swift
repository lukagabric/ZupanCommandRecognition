//
//  CommandParser.swift
//  ZupanCommandRecognition
//
//  Created by Luka Gabric on 17.08.2023..
//

import Foundation
import Combine

struct CommandProcessor {
    
    //MARK: - Types
    
    enum ProcessingState {
        case command, parameters
    }

    //MARK: - Vars

    private var commandProcessingStateSubject = CurrentValueSubject<ProcessingState, Never>(.command)
    var commandProcessingState: AnyPublisher<ProcessingState, Never> { commandProcessingStateSubject.eraseToAnyPublisher() }
    
    //MARK: - Processing
    
    func process(input: String, localeId: String) -> [Command] {
        let inputComponents = input.components(separatedBy: " ").map { $0.lowercased() }
        
        var commands = [Command]()
        var currentCommand: Command?
        
        for inputComponent in inputComponents {
            if let commandType = Command.CommandType(rawValue: inputComponent) {
                let newCommand = Command(commandType: commandType, localeId: localeId)
                
                let currentState = CommandBehaviorInput(newCommand: newCommand,
                                                        currentCommand: currentCommand,
                                                        commands: commands,
                                                        commandProcessingState: commandProcessingStateSubject.value)
                let newState = newCommand.updateState(input: currentState)
                
                currentCommand = newState.currentCommand
                commands = newState.commands
                commandProcessingStateSubject.send(newState.commandProcessingState)
            } else if let currentCommand {
                currentCommand.processParameter(inputComponent)
            }
        }
        
        return commands
    }
}
