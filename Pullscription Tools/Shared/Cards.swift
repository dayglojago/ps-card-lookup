//
//  Untitled.swift
//  Pullscription Card Lookup
//
//  Created by Jago Lourenco-Goddard on 10/25/24.
//

import PrintingKit

#if os(macOS)
import AppKit
#else
import UIKit
#endif

import SwiftData
import OSLog
import Foundation



// Scryfall API response models
struct ScryfallSetsResponse: Codable {
    let data: [ScryfallSet]
}

struct ScryfallSet: Codable {
    let name: String
    let code: String
}

struct ScryfallCardResponse: Codable {
    let data: [CardData]
}

struct CardData: Codable {
    let colors: [String]?
    let rarity: String
    let type_line: String
    let card_faces: [CardFace]?
}

struct CardFace: Codable {
    let type_line: String
    let colors: [String]
}




let modelLogger = Logger.init(
    subsystem: "com.picklist.models",
    category: "picklist.debugging"
)

extension String {
    func convertToPlainText() -> String {
        let attributedString = try? NSAttributedString(
            data: Data(self.utf8),
            options: [.documentType: NSAttributedString.DocumentType.plain],
            documentAttributes: nil
        )
        return attributedString?.string ?? self
    }
}

// Model to hold card information
struct Card: Identifiable {
    let id = UUID()
    let quantity: Int
    let name: String
    let setName: String
    let condition: String
}

enum SpecialCardType: Equatable, CustomStringConvertible{
    case DFC
    case extendedArt
    case specialFoil(type: String?)
    case foil
    case showcase(type: String?)
    case borderless(type: String?)
    case retro
    case unknown(text: String?)
    
    var description: String {
        switch self {
        case .DFC:
            return "Double-Faced Card"
        case .extendedArt:
            return "Extended Art"
        case .specialFoil(type: let type):
            return type != nil ? "Special Foil: \(String(describing: type))" : "Special Foil (Unknown)"
        case .foil:
            return "Foil"
        case .showcase(type: let type):
            return type != nil ? "Showcase: \(String(describing: type))" : "Showcase (Unknown)"
        case .borderless(type: let type):
            return type != nil ? "Borderless: \(String(describing: type))" : "Borderless (Unknown)"
        case .retro:
            return "Retro"
        case .unknown(text: let text):
            return text != nil ? "Unknown: \(String(describing: text))" : "Unknown"
        }
    }
}

// Define the custom order
let customSpecialCardOrder: [SpecialCardType] = [
    .DFC,
    .extendedArt,
    .foil,
    .specialFoil(type: nil),
    .showcase(type: nil),
    .borderless(type: nil),
    .retro,
    .unknown(text: nil)
]


