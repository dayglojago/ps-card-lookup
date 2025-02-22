//
//  CardInfoViewModel.swift
//  Pullscription Tools
//
//  Created by Jago Lourenco-Goddard on 2/21/25.
//

import SwiftUI
#if os(macOS)
import PrintingKit
import AppKit
#else
import UIKit
#endif
import SwiftData
import OSLog
import Foundation

var globalSetsData: [ScryfallSet] = []

@Observable
class CardInfoViewModel: Identifiable {
    var id = UUID()
    var date = getCurrentTimestamp()
    var customerName: String = ""
    var isLoading: Bool = false
    var jobProcessed: Bool = false
    var inputText: String = ""
    var outputText: String = ""
    // need to insert into here when "process" is tapped
    var numberOfCardsTotal = 0.0
    var numberOfCardsProcessed = 0.0
    var numberOfRares = 0
    var numberOfMythics = 0
    var numberOfOther = 0
    var foundFirstCard = false
    var shopifyOnlineOrder = false
    public func clear(){
        self.id = UUID()
        self.date = getCurrentTimestamp()
        self.customerName = ""
        self.isLoading = false
        self.inputText = ""
        self.outputText = ""
        // need to insert into here when "process" is tapped
        self.numberOfCardsTotal = 0.0
        self.numberOfCardsProcessed = 0.0
        self.numberOfRares = 0
        self.numberOfMythics = 0
        self.numberOfOther = 0
        self.jobProcessed = false
        self.foundFirstCard = false
        self.shopifyOnlineOrder = false
    }
    
    init(isLoading: Bool = false, inputText: String, outputText: String = "",  numberOfCardsTotal: Double = 0.0, numberOfCardsProcessed: Double = 0.0, numberOfRares: Int = 0, numberOfMythics: Int = 0, numberOfOther: Int = 0, shopifyOnlineOrder: Bool = false) {
        self.isLoading = isLoading
        self.inputText = inputText
        self.outputText = outputText
        self.numberOfCardsTotal = numberOfCardsTotal
        self.numberOfCardsProcessed = numberOfCardsProcessed
        self.numberOfRares = numberOfRares
        self.numberOfMythics = numberOfMythics
        self.numberOfOther = numberOfOther
        self.shopifyOnlineOrder = shopifyOnlineOrder
    }
    
    func processCardInfo() {
        
        
        modelLogger.log("Inside processCardInfo function! InputsText:\n\(self.inputText)")
        let text = inputText
        if(text == ""){
            self.outputText = "Empty text submitted, please retry with actual input."
            return
        }
        var lines = text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        //filter out entries which are just line breaks or whitespace
        lines.removeAll(where: { $0.isEmpty })
        var cards: [(Int, String, String, String, Double)] = []
        
        isLoading = true
        
        var i = 0
            while i < lines.count {
                let line = lines[i]
                if(lines[2].contains("SKU:") || lines[2].contains(" x ")){
                    shopifyOnlineOrder = true
                }
                if(shopifyOnlineOrder){
                    modelLogger.log("Found Shopify Online Order; line: \(lines[i])")
                    var lineOffset = 0
                    //check to see if the SKU line is included
                    lineOffset = lines[i+2].contains("SKU:") ? 3 : 2;
                    let splitStringPriceAndQuantity = lines[i+lineOffset].split(separator: " ")
                    let quantity = Int(splitStringPriceAndQuantity[2])!
                    let price = splitStringPriceAndQuantity[0]
                    let cardInfo = lines[i] + " - [" + lines[i + 1] + "] (" + String(price) + ")"
                    cards.append(parseCardInfo(quantity: quantity, cardInfo: cardInfo))
                    i+=lineOffset+2
                    continue;
                }
                if !isInteger(line) && !foundFirstCard{
                    i += 1
                    continue
                }else{
                    modelLogger.log("Found first card")
                    foundFirstCard = true
                }
                if line.starts(with: "** "){
                    break
                }
                if let quantity = Int(line) {
                    if i + 1 < lines.count {
                        let cardInfo = lines[i + 1] + " (" + lines[i + 2] + ")"
                        cards.append(parseCardInfo(quantity: quantity, cardInfo: cardInfo))
                        i += 2
                    } else {
                        i += 1
                    }
                } else {
                    let parts = line.split(separator: " ", maxSplits: 1).map { String($0) }
                    if parts.count == 2, let quantity = Int(parts[0]) {
                        let cardInfo = parts[1]
                        cards.append(parseCardInfo(quantity: quantity, cardInfo: cardInfo))
                        i += 1
                    } else {
                        i += 1
                    }
                }
                
            }
        let total = cards.reduce(0) { sum, card in
            sum + card.0
        }

        numberOfCardsTotal = Double(total)
        let cardsToSend = cards
        Task {
            modelLogger.log("Here inside fetching card details!")
            await fetchCardDetails(for: cardsToSend)
        }
    }
    
    private func parseCardInfo(quantity: Int, cardInfo: String) -> (Int, String, String, String, Double) {
        let parts = cardInfo.split(separator: "[", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        let namePart = parts[0]
        let rest = parts[1].split(separator: "] - [").map { $0.trimmingCharacters(in: .whitespaces) }
        let setName = rest[0]
        let condition = rest[1].replacingOccurrences(of: "]", with: "")
        let price = 0.00
        return (quantity, namePart, setName, condition, price)
    }

    
    private func fetchCardDetails(for cards: [(Int, String, String, String, Double)]) async {
        var cardDetails: [(Int, String, String, String, String, String)] = []
        var erroredCards: [(Int, String, String, String, String)] = []
        var cardNames: [String] = []
        var specialCards: [ (String, String?, String, [SpecialCardType]) ] = []
        var specialCardFlag = false
        
        var cardsToModify = cards
        
        for idx in 0...cardsToModify.count-1 {
            var cardName = cardsToModify[idx].1
            let cardSet = cardsToModify[idx].2
            var DFCName: String?
            var newSpecialCard: (String, String?, String, types: [SpecialCardType]) = (cardName, DFCName, cardSet, [])
            //Handle Special Treatments in (Parenthesis)
            //Check for DFCs
            if cardName.contains(" // "){
                specialCardFlag = true
                cardNames = cardName.components(separatedBy: " // ")
                newSpecialCard.types.append(.DFC)
            }
            if cardName.last == ")" && cardName.contains("("){
                modelLogger.log("Processing Card: \(cardName) and found parens")
                let splitName = cardName.split(separator: " ")
                let splitNameStringsTemp: [String] = splitName.map { String($0) }
                let firstIndex = firstIndexStartingWith(prefix: "(", in: splitNameStringsTemp)!
                let splitNameStrings = splitNameStringsTemp[firstIndex...]
                specialCardFlag = true

                if splitNameStrings.count == 1 {
                    switch splitNameStrings.last {
                        case "(Showcase)":
                        newSpecialCard.types.append(.showcase(type: nil))
                        case "(Foil)":
                        newSpecialCard.types.append(.foil)
                        case "(Retro)":
                        newSpecialCard.types.append(.retro)
                        case "(Borderless)":
                        newSpecialCard.types.append(.borderless(type: nil))
                    default:
                        newSpecialCard.types.append(.unknown(text: splitNameStrings.last))
                            
                    }
                    modelLogger.log("Split Name: \(splitName), firstIndex: \(firstIndex)")
                    cardName = splitName.dropLast().joined(separator: " ")
                    modelLogger.log("New Name: \(splitName)")
                    specialCards.append((cardName, nil, cardSet, newSpecialCard.types))
                    cardsToModify[idx].1 = cardName
                }else{
                    //more than one word in the paren, typically just 2
                    if (splitNameStrings.count > 1){
                        let string = splitNameStrings.joined(separator: " ")
                        modelLogger.log("Processing String: \(string)")
                        //find the type of special card by extracting the second and subsequent words
                        let type: String

                        if splitNameStrings.indices.contains(1) {
                            // Safely access elements starting from index 1 if it exists
                            type = splitNameStrings[1...].joined(separator: " ")
                        } else {
                            // Default to empty string if not enough elements
                            type = ""
                        }
                        switch splitNameStrings.first{
                        case "(Showcase":
                            
                            newSpecialCard.types.append(.showcase(type: String(splitNameStrings.dropFirst().joined(separator: " ").dropLast())))
                        case "(Foil":
                            
                            newSpecialCard.types.append(.specialFoil(type: String(splitNameStrings.dropFirst().joined(separator: " ").dropLast())))
                        case "(Extended":
                            
                            newSpecialCard.types.append(.extendedArt)
                        case "(Borderless":
                            
                            newSpecialCard.types.append(.borderless(type: String(splitNameStrings.dropFirst().joined(separator: " ").dropLast())))
                        case "(Retro":
                            newSpecialCard.types.append(.retro)
                        default:
                            newSpecialCard.types.append(.unknown(text: "\(splitNameStrings.joined(separator: " ").dropFirst().dropLast())"))
                        }

                        modelLogger.log("Split Name: \(splitName), firstIndex: \(firstIndex), Last Index: \(splitName.indices.last!)")
                        cardName = splitName.dropLast().dropLast().joined(separator: " ")
                        modelLogger.log("New Name: \(cardName)")
                        modelLogger.log("Types: \(newSpecialCard.types)")

                        
                    }
                }

            }
            
            if newSpecialCard.types.contains(.DFC){
                modelLogger.log("card \(cardName) is DFC")
                let splitBackFace = cardNames[1].split(separator: " ")
                modelLogger.log("DFC Split backFaceName: \(splitBackFace)")
                let splitBackFaceTemp: [String] = splitBackFace.map { String($0) }
                let firstIndexToRemove = firstIndexStartingWith(prefix: "(", in: splitBackFaceTemp) ?? 0
                modelLogger.log("firstIndexToRemove: \(firstIndexToRemove)")
                let numberToRemove = firstIndexToRemove != 0 ? splitBackFace.count - firstIndexToRemove : 0
                let backFaceName = splitBackFace.dropLast(numberToRemove).joined(separator: " ")
                modelLogger.log("DFC backFaceName: \(backFaceName)")
                specialCards.append((cardNames[0], backFaceName, cardSet, newSpecialCard.types))
            }
            else{
                specialCards.append((cardName, nil, cardSet, newSpecialCard.types))
            }
            if newSpecialCard.types.contains(.DFC){
                cardsToModify[idx].1 = cardNames[0]
            }else{
                cardsToModify[idx].1 = cardName
            }
            
            
        }
        for (quantity, cardName, setName, condition, price) in cardsToModify {
            do {
                if let setCode = fetchSetCode(for: setName) {
                    if let cardData = try await fetchIndividualCardDetails(for: cardName, setCode: setCode) {
                        let color: String
                        
                        // Check the main colors first
                        if let colors = cardData.colors, !colors.isEmpty {
                            if colors.count > 1 {
                                color = "Multicolor"
                            } else {
                                color = colors[0]
                            }
                        } else if let cardFaces = cardData.card_faces, !cardFaces.isEmpty {
                            // Fall back to card faces
                            let frontFace = cardFaces[0]
                            if !frontFace.colors.isEmpty {
                                if frontFace.colors.count > 1 {
                                    color = "Multicolor"
                                } else {
                                    color = frontFace.colors[0]
                                }
                            } else {
                                if frontFace.type_line.contains("Land"){
                                    color = "Land"
                                } else if frontFace.type_line.contains("Artifact"){
                                    color = "Artifact"
                                } else {
                                    color = "Colorless"
                                }
                            }
                        } else {
                            // If neither main card nor card faces have colors
                            if cardData.type_line.contains("Land"){
                                color = "Land"
                            } else if cardData.type_line.contains("Artifact"){
                                color = "Artifact"
                            } else {
                                color = "Colorless"
                            }
                        }
                        let rarity = cardData.rarity.capitalized
                        cardDetails.append((quantity, setName, color, rarity, condition, cardName))
                    } else {
                        erroredCards.append((quantity, setName, condition, "Card name Retrieval Failed", cardName))
                    }
                } else {
                    erroredCards.append((quantity, setName, condition, "Set Name Retrieval Failed", cardName))
                }
            } catch {
                erroredCards.append((quantity, setName, condition, "Unknown Error", cardName))
                modelLogger.log("\(error)")
            }
//            modelLogger.log("Processed++!")
            numberOfCardsProcessed += 1
        }
        
//        modelLogger.log("Post-Processing!")
//        modelLogger.log("\(specialCards.count)")
//        modelLogger.log("\(specialCardFlag)")
        if(specialCardFlag){
            modelLogger.log("Dealing with special cards!")
            var appendedCard: (Int, String, String, String, String, String)
            for (name, DFCName, set, types) in specialCards{
                
                for index in cardDetails.indices {
                    
                    let (quantity, setName, color, rarity, condition, cardName) = cardDetails[index]
                    modelLogger.log("Comparing \(DFCName ?? "") and \(name)")
                    if (cardName == name || cardName == (name + " // " + (DFCName ?? ""))) && setName == set {
                        modelLogger.log("Matched a special card: \(cardName), types: \(types)")
                        var workingCardName = cardName
                        modelLogger.log("Before type in types: \(cardName) has types \(types)")
                        let sortedTypes = types.sorted(by: sortSpecialCards)
                        for type in sortedTypes{
                            modelLogger.log("\(cardName) has type \(type.description)")
                            switch (type){
                            case .DFC:
                                workingCardName = workingCardName+" (DFC with \(DFCName ?? "DFC Name Not Found"))"
                            case .borderless(let type):
                                workingCardName = workingCardName+" (Borderless"+((type != nil) ? " \(type!)" : "")+")"
                            case .extendedArt:
                                workingCardName = workingCardName+" (Extended Art)"
                            case .retro:
                                workingCardName = workingCardName+" (Retro)"
                            case .showcase(let type):
                                workingCardName = workingCardName+" (Showcase"+((type != nil) ? " \(type!)" : "")+")"
                            case .specialFoil(let type):
                                workingCardName = workingCardName+" (Foil"+((type != nil) ? " \(type!)" : "")+")"
                            default:
                                workingCardName
                            }
                        }
                        appendedCard = (quantity, setName, color, rarity, condition, workingCardName)
                        cardDetails[index] = appendedCard
                    }
                }
            }
        } //end special card processing
        modelLogger.log("At the end of special card processing!")
        modelLogger.log("About to Generate Output!")
        generateOutput(cardDetails: cardDetails, erroredCards: erroredCards)
    }
    
    private func fetchIndividualCardDetails(for cardName: String, setCode: String) async throws -> CardData? {
        let query = "name:\(cardName) set:\(setCode)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let url = URL(string: "https://api.scryfall.com/cards/search?q=\(query)")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            modelLogger.log("Connect user to store: Non-200 Response: \(response as URLResponse)")
            throw NetworkError.invalidServerResponse
        }
        
        guard let cardResponse = try? JSONDecoder().decode(ScryfallCardResponse.self, from: data) else {
            modelLogger.log("URL for \(cardName): https://api.scryfall.com/cards/search?q=\(query)")
            throw NetworkError.decodingError
        }
        return cardResponse.data.first
    }
    
    private func fetchSetCode(for setName: String) -> String? {
        var sanitizedSetName = setName
        if setName.starts(with: "Innistrad: ") && setName.contains("Commander") {
            sanitizedSetName = setName.replacingOccurrences(of: "Innistrad: ", with: "")
        }else if setName.starts(with: "Kamigawa: ") && setName.contains("Commander") {
            sanitizedSetName = setName.replacingOccurrences(of: "Kamigawa: ", with: "")
        }else if setName.starts(with: "The Lord of the Rings: ") && setName.contains("Commander") {
            sanitizedSetName = setName.replacingOccurrences(of: "The Lord of the Rings: ", with: "")
        }
        let result = globalSetsData.first { $0.name.lowercased() == sanitizedSetName.lowercased() }?.code
        if (result ?? "") == ""{
            modelLogger.log("Failed to look up set code for set name: \(setName) using sanitized name: \(sanitizedSetName)")
        }
        return result
    }
    
    private func generateOutput(cardDetails: [(Int, String, String, String, String, String)], erroredCards: [(Int, String, String, String, String)]) {
        let customColorOrder: [String: Int] = [
            "W": 0, "U": 1, "B": 2, "R": 3, "G": 4,
            "Multicolor": 5, "Colorless": 6
        ]
        func customSort(card1: String, card2: String) -> Bool {
            let components1 = card1.components(separatedBy: " - ")
            let components2 = card2.components(separatedBy: " - ")
            
            guard components1.count > 4, components2.count > 4 else {
                return card1 < card2
            }
            
            let color1 = components1[1]
            let color2 = components2[1]
            let name1 = components1[2]
            let name2 = components2[2]
            
            let order1 = customColorOrder[color1] ?? Int.max
            let order2 = customColorOrder[color2] ?? Int.max
            
            if order1 == order2 {
                return name1 < name2
            }
            return order1 < order2
        }
        var output: [String: [String]] = [:]
        
        for (quantity, setName, color, rarity, condition, cardName) in cardDetails {
            let cardInfo = "\(quantity)x - \(color) - \(cardName) - \(rarity) - \(condition)"
            if rarity == "Rare" || rarity == "Mythic" {
                output["Mythics and Rares", default: []].append(cardInfo + " - \(setName)\n")
                if rarity == "Rare"{
                    numberOfRares+=quantity
                }
                if rarity == "Mythic" {
                    numberOfMythics+=quantity
                }
                    
            } else {
                numberOfOther+=quantity
                output[setName, default: []].append(cardInfo + "\n")
            }
        }
        for (key, value) in output {
            output[key] = value.sorted(by: customSort)
        }
        let sortedSets = output.sorted { $0.value.count > $1.value.count }

        var result = sortedSets.map { "\($0):\n" + $1.joined(separator: "\n") }.joined(separator: "\n\n")
        
        if !erroredCards.isEmpty {
            let sortedErrored = erroredCards.sorted { $0.2 < $1.2 }
            modelLogger.log("\(sortedErrored)")
            result += "\n\nCards that could not be found:\n"
            result += sortedErrored.map { ("\($0.0)x - \($0.4) - \($0.1) - \($0.2) - \($0.3)") }.joined(separator: "\n")
        }
        
        result = "Customer: \(customerName)\n\nPicklist Generation Time:\n \(getCurrentTimestamp()) Pacific\n\n\(Int(numberOfCardsTotal)) Total Cards:\n"+"-> \(numberOfMythics) Mythics\n"+"-> \(numberOfRares) Rares\n-> \(numberOfOther) Other Rarities\n-> \(erroredCards.count) Not Found\n\n"+result
        
        DispatchQueue.main.async {
            //modelLogger.log("Basically done!")
            self.isLoading = false
            self.jobProcessed = true
            self.outputText = result
        }
    }
}
