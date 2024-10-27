//
//  Untitled.swift
//  Pullscription Card Lookup
//
//  Created by Jago Lourenco-Goddard on 10/25/24.
//

import PrintingKit
import AppKit
import SwiftData
import OSLog
import Foundation

// helper functions
func getCurrentTimestamp() -> String {
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
    return formatter.string(from: date)
}

func copyToClipboard(text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
}

func copyFromClipboard() -> String {
    let pasteboard = NSPasteboard.general
    let clipboardText = pasteboard.string(forType: .string) ?? ""
    return clipboardText
}

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

func fetchSetCodeList() async throws -> [ScryfallSet] {
    let url = URL(string: "https://api.scryfall.com/sets")!
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        modelLogger.log("Connect user to store: Non-200 Response: \(response as URLResponse)")
        throw NetworkError.invalidServerResponse
    }
    guard let setsData = try? JSONDecoder().decode(ScryfallSetsResponse.self, from: data) else {
        throw NetworkError.decodingError
    }
    
    return setsData.data
}

func isInteger(_ string: String) -> Bool {
    return Int(string.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
}

func firstIndexStartingWith(prefix: String, in array: [String]) -> Int? {
    return array.firstIndex { $0.hasPrefix(prefix) }
}

extension Bundle {
    var versionNumber: String {
        return infoDictionary?["CFBundleShortVersionString"] as! String
    }
}
let superheroNames = [
    "Superman",
    "Batman",
    "Wonder Woman",
    "Spider-Man",
    "Iron Man",
    "Captain America",
    "Thor",
    "Hulk",
    "Black Widow",
    "Aquaman",
    "Flash",
    "Green Lantern",
    "Doctor Strange",
    "Black Panther",
    "Scarlet Witch",
    "Vision",
    "Ant-Man",
    "Wasp",
    "Hawkeye",
    "Falcon",
    "Winter Soldier",
    "Cyborg",
    "Martian Manhunter",
    "Green Arrow",
    "Shazam",
    "Captain Marvel",
    "Star-Lord",
    "Gamora",
    "Groot",
    "Rocket Raccoon",
    "Drax the Destroyer",
    "Silver Surfer",
    "Daredevil",
    "Jessica Jones",
    "Luke Cage",
    "Iron Fist",
    "Quicksilver",
    "Wolverine",
    "Storm",
    "Jean Grey",
    "Cyclops",
    "Rogue",
    "Nightcrawler",
    "Beast",
    "Professor X",
    "Magneto",
    "Deadpool",
    "Punisher",
    "Blade",
    "Moon Knight"
]

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

func sortSpecialCards(lhs: SpecialCardType, rhs: SpecialCardType) -> Bool {
    let lhsIndex = customSpecialCardOrder.firstIndex { lhsCase in
        switch (lhs, lhsCase) {
        case (.DFC, .DFC),
             (.extendedArt, .extendedArt),
             (.foil, .foil),
             (.specialFoil, .specialFoil),
             (.showcase, .showcase),
             (.borderless, .borderless),
             (.retro, .retro),
             (.unknown, .unknown):
            return true
        default:
            return false
        }
    } ?? Int.max
    
    let rhsIndex = customSpecialCardOrder.firstIndex { rhsCase in
        switch (rhs, rhsCase) {
        case (.DFC, .DFC),
             (.extendedArt, .extendedArt),
             (.foil, .foil),
             (.specialFoil, .specialFoil),
             (.showcase, .showcase),
             (.borderless, .borderless),
             (.retro, .retro),
             (.unknown, .unknown):
            return true
        default:
            return false
        }
    } ?? Int.max
    
    return lhsIndex < rhsIndex
}

enum NetworkError: Error {
    case invalidURL
    case invalidServerResponse
    case noData
    case decodingError
    case custom(errorMessage: String)
}
