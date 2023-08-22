//
//  CommandBehavior.swift
//  ZupanCommandRecognition
//
//  Created by Luka Gabric on 20.08.2023..
//

import Foundation

protocol CommandBehavior {
    func execute(input: CommandBehaviorInput) -> CommandBehaviorOutput
}

struct CommandBehaviorInput {
    let newCommand: Command
    let currentCommand: Command?
    let commands: [Command]
    let commandProcessingState: CommandProcessor.ProcessingState
}

struct CommandBehaviorOutput {
    let currentCommand: Command?
    let commands: [Command]
    let commandProcessingState: CommandProcessor.ProcessingState
}

struct ParameterizedCommandBehavior: CommandBehavior {
    func execute(input: CommandBehaviorInput) -> CommandBehaviorOutput {
        var newCommands = input.commands
        newCommands.append(input.newCommand)
        return CommandBehaviorOutput(currentCommand: input.newCommand, commands: newCommands, commandProcessingState: .parameters)
    }
}

struct ResetCommandBehavior: CommandBehavior {
    func execute(input: CommandBehaviorInput) -> CommandBehaviorOutput {
        guard input.commandProcessingState == .parameters, input.currentCommand != nil else {
            return CommandBehaviorOutput(currentCommand: input.currentCommand, commands: input.commands, commandProcessingState: input.commandProcessingState)
        }
        var newCommands = input.commands
        if !newCommands.isEmpty {
            newCommands.removeLast()
        }
        return CommandBehaviorOutput(currentCommand: nil, commands: newCommands, commandProcessingState: .command)
    }
}

struct BackCommandBehavior: CommandBehavior {
    func execute(input: CommandBehaviorInput) -> CommandBehaviorOutput {
        var newCommands = input.commands
        if !newCommands.isEmpty {
            newCommands.removeLast()
        }
        return CommandBehaviorOutput(currentCommand: nil, commands: newCommands, commandProcessingState: .command)
    }
}
