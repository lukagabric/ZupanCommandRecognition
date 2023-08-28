//
//  LocalizationService.swift
//  ZupanCommandRecognition
//
//  Created by Luka Gabric on 28.08.2023..
//

import Foundation

protocol LocalizationService {
    var localeId: String { get }
    func localization(for key: String) -> String
}

struct DefaultLocalizationService: LocalizationService {
    var localeId: String
    private let bundle: Bundle
    
    init(localeId: String) {
        guard let bundlePath = Bundle.main.path(forResource: localeId, ofType: "lproj"),
              let bundle = Bundle(path: bundlePath) else { fatalError("Bundle must exist at this point") }
        self.bundle = bundle
        self.localeId = localeId
    }
    
    func localization(for key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
