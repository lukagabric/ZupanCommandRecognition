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
    
    typealias SpeechRecognizerFactory = (_ locale: Locale) throws -> SpeechRecognizer
    private let speechRecognizerFactory: SpeechRecognizerFactory
    
    typealias LocalizationServiceFactory = (_ localeId: String) -> LocalizationService
    private let localizationServiceFactory: LocalizationServiceFactory
    
    private var localizationService: LocalizationService

    @Published private(set) var toggleLocaleTitle = ""
    @Published private(set) var localeTitle = ""
    @Published private(set) var observingTitle = ""
    @Published private(set) var recognizedTextTitle = ""
    @Published private(set) var recognizedText = ""
    @Published private(set) var statusMessage = ""
    @Published private(set) var localeIdentifier: String
    @Published private(set) var commandListItems = [CommandListItem]()
    
    //MARK: - Init
    
    init(localizationServiceFactory: @escaping LocalizationServiceFactory,
         speechRecognizerFactory: @escaping SpeechRecognizerFactory) {
        self.speechRecognizerFactory = speechRecognizerFactory
        self.localizationServiceFactory = localizationServiceFactory
        let localeIdentifier = "en-US"
        localizationService = localizationServiceFactory(localeIdentifier)
        locale = Locale(identifier: localeIdentifier)
        self.localeIdentifier = localeIdentifier
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
                return self?.localizationService.localization(for: key) ?? ""
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$statusMessage)
    }
    
    private func process(input: String) {
        let typeTitle = localizationService.localization(for: "commandRecognitionView.type")
        let valueTitle = localizationService.localization(for: "commandRecognitionView.value")
        commandListItems = commandProcessor.process(input: input, localizationService: localizationService)
            .map { command in
                let type = command.commandType.localizedString(localizationService: localizationService)
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
        localizationService = localizationServiceFactory(locale.identifier)
        localeIdentifier = locale.identifier
        updateStrings()
    }
    
    private func updateStrings() {
        toggleLocaleTitle = localizationService.localization(for: "commandRecognitionView.toggleLocale")
        localeTitle = localizationService.localization(for: "commandRecognitionView.locale")
        observingTitle = localizationService.localization(for: "commandRecognitionView.observing")
        recognizedTextTitle = localizationService.localization(for: "commandRecognitionView.recognizedText")
    }
}
