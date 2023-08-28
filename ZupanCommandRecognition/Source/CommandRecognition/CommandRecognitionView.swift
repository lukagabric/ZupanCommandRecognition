//
//  CommandRecognitionView.swift
//  ZupanCommandRecognition
//
//  Created by Luka Gabric on 17.08.2023..
//

import SwiftUI

struct CommandRecognitionView: View {
    
    //MARK: - Vars
    
    @ObservedObject private var viewModel: SpeechRecognitionViewModel
    
    //MARK: - Init
    
    init(viewModel: SpeechRecognitionViewModel) {
        self.viewModel = viewModel
    }
    
    //MARK: - Body
    
    var body: some View {
        VStack {
            headerView()
            List(viewModel.commandListItems, id: \.self) { item in
                let index = viewModel.commandListItems.firstIndex(of: item) as Int? ?? 0
                commandListItemView(commandListItem: item, index: index)
            }
        }
        .onAppear {
            viewModel.start()
        }
    }
    
    private func headerView() -> some View {
        VStack {
            Button(viewModel.toggleLocaleTitle) {
                viewModel.toggleLocale()
            }
            .padding(.init(top: 5, leading: 0, bottom: 5, trailing: 0))
            horizontalText(title: viewModel.localeTitle,
                           titleAccessibilityIdentifier: "localeTitle",
                           subtitle: viewModel.localeIdentifier,
                           subtitleAccessibilityIdentifier: "localeSubtitle")
            horizontalText(title: viewModel.observingTitle,
                           titleAccessibilityIdentifier: "observingTitle",
                           subtitle: viewModel.statusMessage,
                           subtitleAccessibilityIdentifier: "observingSubtitle")
            verticalText(title: viewModel.recognizedTextTitle,
                         titleAccessibilityIdentifier: "recognizedTextTitle",
                         subtitle: viewModel.recognizedText,
                         subtitleAccessibilityIdentifier: "recognizedTextSubtitle")
        }
    }
    
    private func horizontalText(title: String,
                                titleAccessibilityIdentifier: String,
                                subtitle: String,
                                subtitleAccessibilityIdentifier: String) -> some View {
        HStack {
            Text(title)
                .accessibilityIdentifier(titleAccessibilityIdentifier)
            Text(subtitle)
                .bold()
                .accessibilityIdentifier(subtitleAccessibilityIdentifier)
        }.padding(.init(top: 0, leading: 0, bottom: 3, trailing: 0))
    }
    
    private func verticalText(title: String,
                              titleAccessibilityIdentifier: String,
                              subtitle: String,
                              subtitleAccessibilityIdentifier: String) -> some View {
        VStack {
            Text(title)
                .font(.headline)
                .accessibilityIdentifier(titleAccessibilityIdentifier)
            Text(subtitle)
                .padding(.init(top: 0, leading: 0, bottom: 3, trailing: 0))
                .font(.caption)
                .accessibilityIdentifier(subtitleAccessibilityIdentifier)
        }
    }
    
    private func commandListItemView(commandListItem: CommandListItem, index: Int) -> some View {
        VStack(alignment: .leading) {
            Text(commandListItem.commandTypeTitle)
                .accessibilityIdentifier("commandTypeTitle_\(index)")
            Text(commandListItem.commandValue)
                .accessibilityIdentifier("commandValue_\(index)")
        }
    }
}

struct CommandRecognitionView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = SpeechRecognitionViewModel(
            localizationServiceFactory: { DefaultLocalizationService(localeId: $0)},
            speechRecognizerFactory: { try! FixedInputSpeechRecognizer(locale: $0) }
        )
        return CommandRecognitionView(viewModel: viewModel)
    }
}
