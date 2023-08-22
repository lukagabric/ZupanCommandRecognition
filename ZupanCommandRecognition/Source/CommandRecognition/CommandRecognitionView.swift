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
                commandListItemView(commandListItem: item)
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
            horizontalText(title: viewModel.localeTitle, subtitle: viewModel.localeIdentifier)
            horizontalText(title: viewModel.observingTitle, subtitle: viewModel.statusMessage)
            verticalText(title: viewModel.recognizedTextTitle, subtitle: viewModel.recognizedText)
        }
    }
    
    private func horizontalText(title: String, subtitle: String) -> some View {
        HStack {
            Text(title)
            Text(subtitle)
                .bold()
        }.padding(.init(top: 0, leading: 0, bottom: 3, trailing: 0))
    }
    
    private func verticalText(title: String, subtitle: String) -> some View {
        VStack {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .padding(.init(top: 0, leading: 0, bottom: 3, trailing: 0))
                .font(.caption)
        }
    }
    
    private func commandListItemView(commandListItem: CommandListItem) -> some View {
        VStack(alignment: .leading) {
            Text(commandListItem.commandTypeTitle)
            Text(commandListItem.commandValue)
        }
    }
}

struct CommandRecognitionView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = SpeechRecognitionViewModel { locale in
            try! PreviewsSpeechRecognizer(locale: locale)
        }
        return CommandRecognitionView(viewModel: viewModel)
    }
}
