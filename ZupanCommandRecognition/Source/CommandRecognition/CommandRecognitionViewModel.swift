//
//  CommandRecognitionViewModel.swift
//  ZupanCommandRecognition
//
//  Created by Luka Gabric on 17.08.2023..
//

import Foundation
import Combine

class SpeechRecognitionViewModel: ObservableObject {
    
    //MARK: - Vars
    
    private var speechRecognizer: SpeechRecognizer?
    private var locale: Locale {
        didSet {
            didUpdateLocale()
        }
    }
    private var cancellables = Set<AnyCancellable>()
    private let commandProcessor = CommandProcessor()
    
    private var currentInput: String?
    private var bundle: Bundle
    
    typealias SpeechRecognizerFactory = (_ locale: Locale) throws -> SpeechRecognizer
    private let speechRecognizerFactory: SpeechRecognizerFactory

    @Published private(set) var toggleLocaleTitle = ""
    @Published private(set) var localeTitle = ""
    @Published private(set) var observingTitle = ""
    @Published private(set) var recognizedTextTitle = ""
    @Published private(set) var recognizedText = ""
    @Published private(set) var statusMessage = ""
    @Published private(set) var localeIdentifier: String
    @Published private(set) var commandListItems = [CommandListItem]()
    
    //MARK: - Init
    
    init(speechRecognizerFactory: @escaping SpeechRecognizerFactory) {
        self.speechRecognizerFactory = speechRecognizerFactory
        let localeIdentifier = "en-US"
        locale = Locale(identifier: localeIdentifier)
        self.localeIdentifier = localeIdentifier
        bundle = Self.loadBundle(localeIdentifier: localeIdentifier)
        updateStrings()
    }
    
    static func loadBundle(localeIdentifier: String) -> Bundle {
        guard let bundlePath = Bundle.main.path(forResource: localeIdentifier, ofType: "lproj"),
              let bundle = Bundle(path: bundlePath) else { fatalError("Bundle must exist at this point") }
        
        return bundle
    }
    
    //MARK: - User Interaction
    
    func start() {
        recognizedText = ""
        statusMessage = ""
        commandListItems = []
        cancellables = []
        Task {
            await configureSpeechRecognizer()
        }
    }
    
    @MainActor
    private func configureSpeechRecognizer() async {
        do {
            self.speechRecognizer = nil
            let speechRecognizer = try speechRecognizerFactory(locale)
            self.speechRecognizer = speechRecognizer
            try await speechRecognizer.start()
            configureBinding(speechRecognizer: speechRecognizer)
        } catch SpeechRecognizerError.unauthorized {
            statusMessage = "User has not authorized speech recognition or microphone access"
        } catch SpeechRecognizerError.unsupportedLocale {
            statusMessage = "The locale selected is not supported"
        } catch {
            print(error)
        }
    }
    
    private func configureBinding(speechRecognizer: SpeechRecognizer) {
        speechRecognizer.recognizedText
            .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] recognizedText in
                self?.showLatestText(input: recognizedText)
                self?.process(input: recognizedText)
            }.store(in: &cancellables)
        
        commandProcessor.commandProcessingState
            .map { [weak self] type in
                let key = type == .command ? "commandRecognitionView.command" : "commandRecognitionView.parameters"
                return self?.localization(for: key) ?? ""
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$statusMessage)
    }
    
    private func process(input: String) {
        let typeTitle = localization(for: "commandRecognitionView.type")
        let valueTitle = localization(for: "commandRecognitionView.value")
        commandListItems = commandProcessor.process(input: input, localeId: locale.identifier)
            .map { command in
                let type = command.commandType.rawValue
                let value = command.parameters
                    .map(String.init)
                    .joined()
                return CommandListItem(commandTypeTitle: "\(typeTitle): \(type)", commandValue: "\(valueTitle): \(value)")
            }
    }
    
    private func showLatestText(input: String) {
        let wordsToShow = 20
        var components = input.components(separatedBy: " ")
        
        if components.count > wordsToShow {
            components = Array(components[(components.count - wordsToShow)..<components.count])
        }
        
        recognizedText = components.joined(separator: " ")
        currentInput = input
    }
    
    func toggleLocale() {
        if locale.identifier == "en-US" {
            locale = Locale(identifier: "de-DE")
        } else {
            locale = Locale(identifier: "en-US")
        }
        start()
    }
    
    private func didUpdateLocale() {
        localeIdentifier = locale.identifier
        bundle = Self.loadBundle(localeIdentifier: localeIdentifier)
        updateStrings()
    }
    
    private func updateStrings() {
        toggleLocaleTitle = localization(for: "commandRecognitionView.toggleLocale")
        localeTitle = localization(for: "commandRecognitionView.locale")
        observingTitle = localization(for: "commandRecognitionView.observing")
        recognizedTextTitle = localization(for: "commandRecognitionView.recognizedText")
    }
    
    private func localization(for key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
