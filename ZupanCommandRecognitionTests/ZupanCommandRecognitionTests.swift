//
//  ZupanCommandRecognitionTests.swift
//  ZupanCommandRecognitionTests
//
//  Created by Luka Gabric on 17.08.2023..
//

import XCTest
import Combine
@testable import ZupanCommandRecognition

final class ZupanCommandRecognitionTests: XCTestCase {
    var cancellables = Set<AnyCancellable>()
    
    func testProcessingResultsInExpectedCommands_en_US() {
        let input = "ignore1 test1 ignore2 test2 count 61 1 twelve three reset reset reset reset count one zwei 8 ten ignore4 code 12312 one zwei two sixty test4 code 0 1 2 3 4 5 6 7 8 9 count zero one two three four five six seven eight nine code 1 2 3 reset 1 3 2 count 1 count 2 reset reset back reset reset reset one two 1 2 code 8 7 5 reset code eight 7 six"
        
        let sut = CommandProcessor()
        let result = sut.process(input: input, localizationService: DefaultLocalizationService(localeId: "en-US"))

        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(result[0].commandType, .count)
        XCTAssertEqual(result[0].parameters, [1, 8])

        XCTAssertEqual(result[1].commandType, .code)
        XCTAssertEqual(result[1].parameters, [1, 2])

        XCTAssertEqual(result[2].commandType, .code)
        XCTAssertEqual(result[2].parameters, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

        XCTAssertEqual(result[3].commandType, .count)
        XCTAssertEqual(result[3].parameters, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        
        XCTAssertEqual(result[4].commandType, .code)
        XCTAssertEqual(result[4].parameters, [8, 7, 6])
    }
    
    func testProcessingResultsInExpectedCommands_de_DE() {
        let input = "ignore1 test1 ignore2 test2 zählen 61 1 zwölf drei zurücksetzen zurücksetzen zurücksetzen zurücksetzen zählen eins two 8 zehn ignore4 Code 12312 eins two zwei sechzig test4 Code 0 1 2 3 4 5 6 7 8 9 zählen null eins zwei drei vier fünf sechs sieben acht neun Code 1 2 3 zurücksetzen 1 3 2 zählen 1 zählen 2 zurücksetzen zurücksetzen zurück zurücksetzen zurücksetzen zurücksetzen eins zwei 1 2 Code 8 7 5 zurücksetzen Code acht 7 sechs"
        let sut = CommandProcessor()
        let result = sut.process(input: input, localizationService: DefaultLocalizationService(localeId: "de-DE"))

        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(result[0].commandType, .count)
        XCTAssertEqual(result[0].parameters, [1, 8])

        XCTAssertEqual(result[1].commandType, .code)
        XCTAssertEqual(result[1].parameters, [1, 2])

        XCTAssertEqual(result[2].commandType, .code)
        XCTAssertEqual(result[2].parameters, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

        XCTAssertEqual(result[3].commandType, .count)
        XCTAssertEqual(result[3].parameters, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        
        XCTAssertEqual(result[4].commandType, .code)
        XCTAssertEqual(result[4].parameters, [8, 7, 6])
    }
    
    func testStateIsCommandProcessingBeforeCommandIsDetected() {
        let input = "ignore1 test1 ignore2 test2"
        let sut = CommandProcessor()
        let exp = expectation(description: "Command state expectation")
        var state: CommandProcessor.ProcessingState? = nil
        sut.commandProcessingState.sink { currentState in
            state = currentState
            exp.fulfill()
        }.store(in: &cancellables)

        _ = sut.process(input: input, localizationService: DefaultLocalizationService(localeId: "en-US"))

        waitForExpectations(timeout: 1)
        
        XCTAssertEqual(state, .command)
    }
    
    func testStateIsParameterProcessingAfterCommandIsDetected() {
        let input = "ignore1 test1 ignore2 test2 count"
        let sut = CommandProcessor()
        let exp = expectation(description: "Parameter state expectation")
        var states = [CommandProcessor.ProcessingState]()
        
        sut.commandProcessingState.sink { currentState in
            states.append(currentState)
            if states.count == 2 {
                exp.fulfill()
            }
        }.store(in: &cancellables)

        _ = sut.process(input: input, localizationService: DefaultLocalizationService(localeId: "en-US"))

        waitForExpectations(timeout: 1)
        
        XCTAssertEqual(states[0], .command)
        XCTAssertEqual(states[1], .parameters)
    }
    
    func testThatMultipleBackCommandsLeadToAnEmptyCommandSet() {
        let input = "count 1 2 3 back back back back back back"
        let sut = CommandProcessor()
        let results = sut.process(input: input, localizationService: DefaultLocalizationService(localeId: "en-US"))
        XCTAssertTrue(results.isEmpty)
    }
    
    func testCommandProcessingAfterManyBackCommands() {
        let input = "count 1 2 3 back back back back back back count 1 8 code 1 2"
        let sut = CommandProcessor()
        let results = sut.process(input: input, localizationService: DefaultLocalizationService(localeId: "en-US"))
        
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].commandType, .count)
        XCTAssertEqual(results[0].parameters, [1, 8])

        XCTAssertEqual(results[1].commandType, .code)
        XCTAssertEqual(results[1].parameters, [1, 2])
    }
}
