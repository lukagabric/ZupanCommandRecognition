//
//  SpeechRecognizer.swift
//  ZupanCommandRecognition
//
//  Created by Luka Gabric on 17.08.2023..
//

import Foundation
import Speech
import Combine

enum SpeechRecognizerError: Error {
    case unauthorized, unsupportedLocale
}

protocol SpeechRecognizer {
    init(locale: Locale) throws
    var recognizedText: AnyPublisher<String, Never> { get }
    func start() async throws
}

class IOSSpeechRecognizer: SpeechRecognizer {
    
    //MARK: - Vars
        
    private let speechRecognizer: SFSpeechRecognizer
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var cancellables = Set<AnyCancellable>()
    
    private var recognizedTextSubject = CurrentValueSubject<String, Never>("")
    var recognizedText: AnyPublisher<String, Never> { recognizedTextSubject.eraseToAnyPublisher() }
    
    //MARK: - Init
    
    required init(locale: Locale) throws {
        guard let speechRecognizer = SFSpeechRecognizer(locale: locale) else { throw SpeechRecognizerError.unsupportedLocale }
        self.speechRecognizer = speechRecognizer
    }
    
    //MARK: - Interaction

    @MainActor
    func start() async throws {
        let authStatus = await requestAuthorization()
        guard authStatus == .authorized else { throw SpeechRecognizerError.unauthorized }
        
        startRecording()
    }
    
    private func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authStatus in
                DispatchQueue.main.async {
                    continuation.resume(returning: authStatus)
                }
            }
        }
    }
    
    private func startRecording() {
        do {
            try startRecordingSession()
        } catch {
            print("[SpeechRecognizer] Recording session error: \(error.localizedDescription)")
        }
    }
        
    private func startRecordingSession() throws {
        let audioEngine = AVAudioEngine()
        self.audioEngine = audioEngine
        
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        self.recognitionRequest = recognitionRequest
        
        let inputNode = audioEngine.inputNode
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }

            DispatchQueue.main.async {
                if let result {
                    let recognizedText = result.bestTranscription.formattedString
                    self.recognizedTextSubject.send(recognizedText)
                } else if let error {
                    print("[SpeechRecognizer] Recognition Error: \(error.localizedDescription)")
                }
            }
        }
    }
}

#if DEBUG
class MockSpeechRecognizer: SpeechRecognizer {
    private var recognizedTextSubject = CurrentValueSubject<String, Never>("")
    var recognizedText: AnyPublisher<String, Never> { recognizedTextSubject.eraseToAnyPublisher() }
    
    private var elements: [String]
    
    required init(locale: Locale) throws {
        switch locale.identifier {
        case "en-US":
            elements = "ignore1 test1 ignore2 test2 count 61 1 twelve three reset reset reset reset one zwei 8 ten ignore4 code 12312 one zwei two sixty test4 code 0 1 2 3 4 5 6 7 8 9 count zero one two three four five six seven eight nine code 1 2 3 reset 1 3 2 count 1 count 2 reset back reset back reset reset reset one two 1 2 code 8 7 5 reset eight 7 six"
                .components(separatedBy: " ")
        case "de-DE":
            elements = "ignore1 test1 ignore2 test2 zählen 61 1 zwölf drei zurücksetzen zurücksetzen zurücksetzen zurücksetzen zählen eins two 8 zehn ignore4 Code 12312 eins two zwei sechzig test4 Code 0 1 2 3 4 5 6 7 8 9 zählen null eins zwei drei vier fünf sechs sieben acht neun Code 1 2 3 zurücksetzen 1 3 2 zählen 1 zählen 2 zurücksetzen zurücksetzen zurück zurücksetzen zurücksetzen zurücksetzen eins zwei 1 2 Code 8 7 5 zurücksetzen Code acht 7 sechs"
                .components(separatedBy: " ")
        default:
            fatalError("Unsupported locale")
        }
    }
        
    private var timerCancellable: AnyCancellable?
    func start() async throws {
        let reportingFrequency: TimeInterval = 0.5
        timerCancellable = Timer.publish(every: reportingFrequency, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard !self.elements.isEmpty else {
                    self.timerCancellable?.cancel()
                    return
                }
                let elementsPerIteration = 1
                let elementsCount = min(elementsPerIteration, self.elements.count)
                let newRecognizedText = Array(self.elements[..<elementsCount])
                    .joined(separator: " ")
                self.elements.removeFirst(elementsCount)
                self.recognizedTextSubject.send(self.recognizedTextSubject.value + " " + newRecognizedText)
            }
    }
}

class FixedInputSpeechRecognizer: SpeechRecognizer {
    convenience init(locale: Locale, mockInput: String) throws {
        try self.init(locale: locale)
        recognizedTextSubject.send(mockInput)
    }
    
    required init(locale: Locale) throws {}
    
    private var recognizedTextSubject = CurrentValueSubject<String, Never>("count 1 three code 8 7 5 count eight 7 six")
    var recognizedText: AnyPublisher<String, Never> { recognizedTextSubject.eraseToAnyPublisher() }
    
    func start() async throws {}
}
#endif
