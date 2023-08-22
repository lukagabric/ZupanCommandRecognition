//
//  CommandListItem.swift
//  ZupanCommandRecognition
//
//  Created by Luka Gabric on 21.08.2023..
//

import Foundation

struct CommandListItem: Hashable {
    private let id = UUID().uuidString
    let commandTypeTitle: String
    let commandValue: String
}
