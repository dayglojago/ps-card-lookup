//
//  HelperFunctions.swift
//  Pullscription Tools
//
//  Created by Jago Lourenco-Goddard on 2/23/25.
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

func parseDate(_ dateString: String) -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd/yy"
    return formatter.date(from: dateString) ?? Date() // Defaults to today if invalid
}

// helper functions
func getCurrentTimestamp() -> String {
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
    return formatter.string(from: date)
}

#if os(macOS)
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
#endif

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
