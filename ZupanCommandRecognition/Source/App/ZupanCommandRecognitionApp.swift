//
//  ZupanCommandRecognitionApp.swift
//  ZupanCommandRecognition
//
//  Created by Luka Gabric on 17.08.2023..
//

import SwiftUI

@main
struct ZupanCommandRecognitionApp: App {
    
    private static var viewModel: SpeechRecognitionViewModel = {
#if DEBUG
        if let uiTestsMockInput = UITestsArguments.uiTestsMockInput {
            return SpeechRecognitionViewModel { locale in
                try! FixedInputSpeechRecognizer(locale: Locale(identifier: "en-US"), mockInput: uiTestsMockInput)
            }
        } else if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" ||
                    ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
                    ProcessInfo.processInfo.environment["SIMULATOR_UDID"] != nil {
            return SpeechRecognitionViewModel { locale in
                try! MockSpeechRecognizer(locale: locale)
            }
        }
#endif
        
        return SpeechRecognitionViewModel { locale in
            try! IOSSpeechRecognizer(locale: locale)
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            CommandRecognitionView(viewModel: Self.viewModel)
        }
    }
}

#if DEBUG
struct UITestsArguments {
    static var uiTestsMockInput: String? {
        ProcessInfo.processInfo.launchArgumentValue(for: "-uiTestsMockInput")
    }
}

extension ProcessInfo {
    func launchArgumentValue(for key: String) -> String? {
        if let index = arguments.firstIndex(of: key),
           index + 1 < arguments.count {
            let value = arguments[index + 1]
            return value
        }
        
        return nil
    }
}
#endif
