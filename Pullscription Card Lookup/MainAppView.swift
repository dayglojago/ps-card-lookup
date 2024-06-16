//
//  ContentView.swift
//  Pullscription Card Lookup
//
//  Created by Jago Lourenco-Goddard on 6/13/24.
//

import SwiftUI
import PrintingKit
import AppKit
import SwiftData
import OSLog
import Foundation

let modelLogger = Logger.init(
    subsystem: "com.picklist.models",
    category: "picklist.debugging"
)

// Model to hold card information
struct Card: Identifiable {
    let id = UUID()
    let quantity: Int
    let name: String
    let setName: String
    let condition: String
}

enum SpecialCardType: Equatable{
    case DFC
    case extendedArt
    case specialFoil(type: String?)
    case foil
    case showcase(type: String?)
    case borderless(type: String?)
    case retro
    case unknown(text: String?)
}

enum NetworkError: Error {
    case invalidURL
    case invalidServerResponse
    case noData
    case decodingError
    case custom(errorMessage: String)
}

//@Model
//class SavedSession: NSManagedObject {
//    @Attribute(.unique) let id = UUID()
//    @Attribute let name: String
//    let processedCardListText: String
//    @Attribute let date: String
//    let inputText: String
//    @Attribute let numberOfCardsTotal: Int
//    
//    @objc override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
//        super.init(entity: entity, insertInto: context)
//        self.id = UUID()
//        self.name = ""
//        self.processedCardListText = ""
//        self.date = ""
//        self.inputText = ""
//        self.numberOfCardsTotal = 0
//    }
//    
//    init(name: String, processedCardListText: String, date: String, inputText: String, numberOfCardsTotal: Int, context: NSManagedObjectContext) {
//        let entity = NSEntityDescription.entity(forEntityName: "SavedSession", in: context)!
//        super.init(entity: entity, insertInto: context)
//        self.id = UUID()
//        self.name = name
//        self.processedCardListText = processedCardListText
//        self.date = date
//        self.inputText = inputText
//        self.numberOfCardsTotal = numberOfCardsTotal
//    }
//    
//}


class PrintTextView: NSView {
    var text: String
    
    init(text: String) {
        self.text = text
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .paragraphStyle: NSMutableParagraphStyle()
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(in: dirtyRect)
    }
    
    override var isFlipped: Bool {
        return true
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

var globalSetsData: [ScryfallSet] = []

func fetchSetCodeList() async throws -> [ScryfallSet] {
    let url = URL(string: "https://api.scryfall.com/sets")!
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        print("Connect user to store: Non-200 Response: \(response as URLResponse)")
        throw NetworkError.invalidServerResponse
    }
    guard let setsData = try? JSONDecoder().decode(ScryfallSetsResponse.self, from: data) else {
        throw NetworkError.decodingError
    }
    
    return setsData.data
}

func matchesWordPlusPattern(for specialCardType: String, cardName input: String) -> Bool {
    // Define the regular expression pattern
    let pattern = "\\("+input+".*\\)"
    
    do {
        // Create the regular expression
        let regex = try NSRegularExpression(pattern: pattern)
        
        // Check if there's a match
        let range = NSRange(location: 0, length: input.utf16.count)
        let match = regex.firstMatch(in: input, options: [], range: range)
        
        // Return true if there's a match, false otherwise
        return match != nil
    } catch {
        print("Invalid regex: \(error.localizedDescription)")
        return false
    }
}

func firstIndexStartingWith(prefix: String, in array: [String]) -> Int? {
    return array.firstIndex { $0.hasPrefix(prefix) }
}

@Observable
class CardInfoViewModel: Identifiable {
    var id = UUID()
    var date = getCurrentTimestamp()
    var customerName: String = ""
    var isLoading: Bool = false
    var inputText: String = ""
    var outputText: String = ""
    // need to insert into here when "process" is tapped
    var numberOfCardsTotal = 0.0
    var numberOfCardsProcessed = 0.0
    var numberOfRares = 0
    var numberOfMythics = 0
    var numberOfOther = 0
    
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
    }
    
    init(isLoading: Bool = false, inputText: String, outputText: String = "",  numberOfCardsTotal: Double = 0.0, numberOfCardsProcessed: Double = 0.0, numberOfRares: Int = 0, numberOfMythics: Int = 0, numberOfOther: Int = 0) {
        self.isLoading = isLoading
        self.inputText = inputText
        self.outputText = outputText
        self.numberOfCardsTotal = numberOfCardsTotal
        self.numberOfCardsProcessed = numberOfCardsProcessed
        self.numberOfRares = numberOfRares
        self.numberOfMythics = numberOfMythics
        self.numberOfOther = numberOfOther
    }
    
    func processCardInfo() {
        isLoading = true
        modelLogger.log("Inside processCardInfo function! InputsText:\n\(self.inputText)")
        let text = inputText
        let lines = text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        var cards: [(Int, String, String, String)] = []
        
        var i = 0
        while i < lines.count {
            let line = lines[i]
            if let quantity = Int(line) {
                if i + 1 < lines.count {
                    let cardInfo = lines[i + 1]
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
        numberOfCardsTotal = Double(cards.count)
        Task {
            modelLogger.log("Here inside fetching card details!")
            await fetchCardDetails(for: cards)
        }
    }
    
    private func parseCardInfo(quantity: Int, cardInfo: String) -> (Int, String, String, String) {
        let parts = cardInfo.split(separator: "[", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        let namePart = parts[0]
        let rest = parts[1].split(separator: "] - [").map { $0.trimmingCharacters(in: .whitespaces) }
        let setName = rest[0]
        let condition = rest[1].replacingOccurrences(of: "]", with: "")
        return (quantity, namePart, setName, condition)
    }

    
    private func fetchCardDetails(for cards: [(Int, String, String, String)]) async {
        var cardDetails: [(Int, String, String, String, String, String)] = []
        var erroredCards: [(Int, String, String, String, String)] = []
        
        var specialCards: [ (String, String?, String, [SpecialCardType]) ] = []
        var specialCardFlag = false
        
        var cardsToModify = cards
        
        for idx in 0...cardsToModify.count-1 {
            var cardName = cardsToModify[idx].1
            let cardSet = cardsToModify[idx].2
            var DFCName: String?
            var newSpecialCard: (String, String?, String, types: [SpecialCardType]) = (cardName, DFCName, cardSet, [])
            //Handle Special Treatments in (Parenthesis)
            if cardName.last == ")" && cardName.contains("("){
                let splitName = cardName.split(separator: " ")
                let splitNameStrings: [String] = splitName.map { String($0) }
                specialCardFlag = true
                let firstIndex = firstIndexStartingWith(prefix: "(", in: splitNameStrings)!
                if firstIndexStartingWith(prefix: "(", in: splitNameStrings)! == splitNameStrings.indices.last {
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
                    //exactly two words in the parenthesis
                    if (splitNameStrings.indices.last! - firstIndex == 1){
                        print(splitNameStrings[splitNameStrings.count - 2])
                        switch splitNameStrings[splitNameStrings.count - 2]{
                        case "(Showcase":
                            newSpecialCard.types.append(.showcase(type: String(splitNameStrings.last!.dropLast())))
                        case "(Foil":
                            newSpecialCard.types.append(.specialFoil(type: String(splitNameStrings.last!.dropLast())))
                        case "(Extended":
                            newSpecialCard.types.append(.extendedArt)

                        case "(Borderless":
                            newSpecialCard.types.append(.borderless(type: String(splitNameStrings.last!.dropLast())))

                        default:
                            newSpecialCard.types.append(.unknown(text: "\(splitNameStrings[splitNameStrings.count - 2]) \(splitNameStrings.last!)"))
                        }
                        modelLogger.log("Split Name: \(splitName), firstIndex: \(firstIndex), Last Index: \(splitName.indices.last!)")
                        cardName = splitName.dropLast().dropLast().joined(separator: " ")
                        modelLogger.log("New Name: \(cardName)")
                        specialCards.append((cardName, nil, cardSet, newSpecialCard.types))
                        cardsToModify[idx].1 = cardName
                    }
                }

            }
            // DFCs
            if cardName.contains(" // "){
                //check for DFCs that may have special treatments applied first
                specialCardFlag = true
                let cardNames = cardName.components(separatedBy: " // ")
                specialCards.append((cardNames[0], cardNames[1], cardSet, [SpecialCardType.DFC]))
                cardsToModify[idx].1 = cardNames[0]
            }
            
        }
        
        for (quantity, cardName, setName, condition) in cardsToModify {
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
                            // If neither main colors nor card faces have colors
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
                print(error)
            }
            numberOfCardsProcessed += 1
        }
        
        if(specialCardFlag){
            var appendedCard: (Int, String, String, String, String, String)
            for (name, DFCName, set, types) in specialCards{
                
                for index in cardDetails.indices {
                    
                    let (quantity, setName, color, rarity, condition, cardName) = cardDetails[index]
                    modelLogger.log("Comparing \(cardName) and \(name)")
                    if cardName == name && setName == set {
                        modelLogger.log("Matched a special card: \(cardName), types: \(types)")
                        var workingCardName = cardName
                        for type in types{
                            switch (type){
                            case .DFC:
                                workingCardName = workingCardName+" (DFC with \(DFCName ?? "DFC Not Found"))"
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
            modelLogger.log("About to Generate Output!")
            generateOutput(cardDetails: cardDetails, erroredCards: erroredCards)
            
            
        }
    }
    
    private func fetchIndividualCardDetails(for cardName: String, setCode: String) async throws -> CardData? {
        let query = "name:\(cardName) set:\(setCode)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let url = URL(string: "https://api.scryfall.com/cards/search?q=\(query)")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Connect user to store: Non-200 Response: \(response as URLResponse)")
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
            print("Failed to look up set code for set name: \(setName) using sanitzed name: \(sanitizedSetName)")
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
                output["Mythics and Rares", default: []].append(cardInfo)
                if rarity == "Rare"{
                    numberOfRares+=1
                }
                if rarity == "Mythic" {
                    numberOfMythics+=1
                }
                    
            } else {
                numberOfOther+=1
                output[setName, default: []].append(cardInfo)
            }
        }
        for (key, value) in output {
            output[key] = value.sorted(by: customSort)
        }
        let sortedSets = output.sorted { $0.value.count > $1.value.count }

        var result = sortedSets.map { "\($0):\n" + $1.joined(separator: "\n") }.joined(separator: "\n\n")
        
        if !erroredCards.isEmpty {
            let sortedErrored = erroredCards.sorted { $0.2 < $1.2 }
            result += "\n\nCards that could not be found:\n"
            result += sortedErrored.map { ("\($0.0)x - \($0.4) - \($0.1) - \($0.2) - \($0.3)") }.joined(separator: "\n")
        }
        
        result = "\(customerName)\n\nPicklist Generation Time:\n \(getCurrentTimestamp()) Pacific\n\n\(Int(numberOfCardsTotal)) Total Cards:\n"+"-> \(numberOfMythics) Mythics\n"+"-> \(numberOfRares) Rares\n-> \(numberOfOther) Other Rarities\n-> \(erroredCards.count) Not Found\n\n"+result
        
        DispatchQueue.main.async {
            modelLogger.log("Basically done!")
            self.isLoading = false
            self.outputText = result
        }
    }
}

// helper functions
func getCurrentTimestamp() -> String {
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
    return formatter.string(from: date)
}
func printText(_ text: String) {
    let printView = PrintTextView(text: text)
    let printInfo = NSPrintInfo.shared
    printInfo.horizontalPagination = .fit
    printInfo.verticalPagination = .automatic
    printInfo.isHorizontallyCentered = false
    printInfo.isVerticallyCentered = false
    printInfo.topMargin = 0
    printInfo.leftMargin = 0
    printInfo.rightMargin = 0
    printInfo.bottomMargin = 0
    
    let printOperation = NSPrintOperation(view: printView, printInfo: printInfo)
    printOperation.canSpawnSeparateThread = true
    printOperation.run()
}

func copyToClipboard(text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
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

// Main SwiftUI view
struct MainAppView: View {
    @Environment(\.managedObjectContext) private var viewContext
    //@Query(sort: \SavedSession.date) private var savedSessions: [SavedSession]
    @State private var processingJob = CardInfoViewModel( inputText: "")
    // Define focus state for text fields
    @FocusState private var focusedField: Field?

    // Enum to represent different fields
    enum Field: Hashable {
        case toBeProcessed
        case processed
    }

    @State private var selectedItems: [UUID] = []
    let printer = Printer.shared
    
    var body: some View {
        
        VStack{
            Image("PSToolsLogo")
                .padding(.top)
                .padding(.bottom, 0)
            Text("Pullscription™ Magic :The Gathering Card Pick List Generator")
                .font(.title2)
                .bold()
                .padding(.bottom, 0)
            HStack(alignment: .firstTextBaseline){
                VStack{
                    
                
                    VStack(alignment: .leading){
                        
                        
                        VStack(alignment: .leading) {
                            HStack{
                                Text("Customer Name")
                                    .font(.headline)
                                Text("Optional")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            HStack{
                                TextField("Customer Name", text: $processingJob.customerName)
                            }
                            Text("Paste card data:")
                                .font(.headline)
                            
                            TextEditor(text: $processingJob.inputText)
                                .focused($focusedField, equals: .toBeProcessed)
                                .border(Color.gray, width: 1)
                            
                            if(processingJob.isLoading){
                                ProgressView("Processing...", value: processingJob.numberOfCardsProcessed, total: processingJob.numberOfCardsTotal)
                                    .progressViewStyle(LinearProgressViewStyle())
                            }else{
                                HStack{
                                    Button(action: {
                                        if(processingJob.customerName.isEmpty){
                                            processingJob.customerName = superheroNames.randomElement()!
                                        }
                                        print("Pressed button!")
                                        processingJob.processCardInfo()
                                    }) {
                                        HStack {
                                            Image(systemName: "checkmark.shield.fill") // SF Symbol
                                                .foregroundColor(.green)
                                            Text("Process List")
                                        }
                                    }
                                    Button(action: {
                                        processingJob.inputText = ""
                                    }) {
                                        HStack {
                                            Image(systemName: "clear.fill")
                                                .foregroundColor(.orange)
                                            Text("Clear")
                                        }
                                    }
                                }
                            }
                            Divider()
                            HStack{
                                Text("Processed Cardlist:")
                                    .font(.headline)
                                    .frame(alignment: .leading)
                                //Text(String(Int($viewModel.numberOfCards))+" Cards Total")
                                //.frame(alignment: .trailing)
                            }
                            VStack{
                                TextEditor(text: $processingJob.outputText)
                                    .focused($focusedField, equals: .processed)
                                    .border(Color.gray, width: 1)
                            }
                            
                            
                            HStack{
                                Button(action: {
                                    let printer = Printer.shared
                                    try? printer.print(.string(processingJob.outputText))
                                }) {
                                    HStack {
                                        Image(systemName: "printer.filled.and.paper") // SF Symbol
                                            .foregroundColor(.gray)
                                        Text("Print Pick List")
                                    }
                                }
                                
                                Button(action: {
                                    copyToClipboard(text: processingJob.outputText)
                                }) {
                                    HStack {
                                        Image(systemName: "doc.on.doc.fill") .foregroundColor(.blue)
                                        Text("Copy")
                                    }
                                }
                                
                            }
                            
                        }
                        
                        
                        Divider()
                        HStack(){
                            Spacer()
                            
                            Button(action: {
                                //let sessionToBeSaved = SavedSession(name: processingJob.customerName, processedCardListText: processingJob.outputText, date: processingJob.date, inputText: processingJob.inputText, numberOfCardsTotal: Int(processingJob.numberOfCardsTotal), context: viewContext)
                                //viewContext.insert(sessionToBeSaved)
                                processingJob.clear()
                                do {
                                            try viewContext.save()
                                        } catch {
                                            print("Error saving session: \(error)")
                                        }
                            }) {
                                HStack {
                                    Image(systemName: "doc.fill.badge.plus") // SF Symbol
                                    
                                    Text("New Job")
                                }
                            }
                        }
                        
                    }.padding()
                    
                }
                VStack(alignment: .leading){
                    
                    Text("History:")
                        .font(.headline)
                        .padding(.bottom, 0)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Date")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Name/First Card")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Total Qty")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(5)
                        .background(Color.gray.opacity(0.2))
                        .frame(maxHeight: 25)
                        .bold()
                        Text("History Coming Soon")
//                        List(savedSessions, id: \.date) { session in
//                            HStack {
//                                Text(session.date)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                Text(session.name)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                Text(String(session.numberOfCardsTotal))
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                            }
//                        }
//                        .padding(.top, 0)
//                        .listStyle(InsetListStyle())
//                        .border(Color.gray, width: 1)
                        HStack(){
                            Spacer()
                            Button(action: {
                                processingJob.inputText = ""
                            }) {
                                HStack {
                                    Image(systemName: "clear.fill") // SF Symbol
                                        .foregroundColor(.red)
                                        .padding(.trailing, 0)
                                    Text("Delete History")
                                        .padding(.leading, 0)
                                }
                            }
                            .disabled(true)
                        }
                    }
                }
            }
            .padding(.top, 0)
            .padding(.bottom)
            .padding(.trailing)
            
        }
        .padding(.bottom, 0)
        .frame(minWidth: 800, minHeight: 700)
        .onAppear(){
            focusedField = .toBeProcessed
            Task{
                globalSetsData = try! await fetchSetCodeList()
            }
        }
    }
}



#Preview {
    MainAppView()
}
