//
//  ZupanCommandRecognitionUITests.swift
//  ZupanCommandRecognitionUITests
//
//  Created by Luka Gabric on 17.08.2023..
//

import XCTest

final class ZupanCommandRecognitionUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }
    
    func testProcessingStateAtStartIsCommand() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTestsMockInput", "ignore1 test1 ignore2 test2"]
        app.launch()

        let observingSubtitle = app.staticTexts["observingSubtitle"]
        
        let isReady = observingSubtitle.waitForExistence(timeout: 1)
        XCTAssertTrue(isReady)
        
        XCTAssertEqual(observingSubtitle.label, "Command")
    }
    
    func testProcessingStateAfterCommandDetectionIsParameter() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTestsMockInput", "ignore1 test1 ignore2 test2 code"]
        app.launch()

        let observingSubtitle = app.staticTexts["observingSubtitle"]
        
        let isReady = observingSubtitle.waitForExistence(timeout: 1)
        XCTAssertTrue(isReady)
        
        XCTAssertEqual(observingSubtitle.label, "Parameters")
    }
    
    func testAllCommandItemsAreDisplayed() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTestsMockInput", "ignore1 test1 ignore2 test2 count 61 1 twelve three reset reset reset reset count one zwei 8 ten ignore4 code 12312 one zwei two sixty test4 code 0 1 2 3 4 5 6 7 8 9 count zero one two three four five six seven eight nine code 1 2 3 reset 1 3 2 count 1 count 2 reset reset back reset reset reset one two 1 2 code 8 7 5 reset code eight 7 six"]
        app.launch()

        let numberOfItems = 5
        let indexes = Array(stride(from: 0, through: numberOfItems - 1, by: 1))
        
        let results: [(command: XCUIElement, value: XCUIElement)] = indexes
            .map { (app.staticTexts["commandTypeTitle_\($0)"], app.staticTexts["commandValue_\($0)"]) }
        
        let isReady = results[4].command.waitForExistence(timeout: 1)
        XCTAssertTrue(isReady)
        
        XCTAssertEqual(results[0].command.label, "Type: count")
        XCTAssertEqual(results[0].value.label, "Value: 18")

        XCTAssertEqual(results[1].command.label, "Type: code")
        XCTAssertEqual(results[1].value.label, "Value: 12")

        XCTAssertEqual(results[2].command.label, "Type: code")
        XCTAssertEqual(results[2].value.label, "Value: 0123456789")

        XCTAssertEqual(results[3].command.label, "Type: count")
        XCTAssertEqual(results[3].value.label, "Value: 0123456789")

        XCTAssertEqual(results[4].command.label, "Type: code")
        XCTAssertEqual(results[4].value.label, "Value: 876")
    }
}
