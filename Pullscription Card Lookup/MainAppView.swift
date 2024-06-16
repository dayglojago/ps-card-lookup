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
func listFiles(at path: String) {
    
    let fileManager = FileManager.default
    do {
        let files = try fileManager.contentsOfDirectory(atPath: NSTemporaryDirectory())
        for file in files {
            print(file)
        }
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}
func writeAndPrintFile(text: String) {
    let text = text
    let filePath = FileManager.default.temporaryDirectory.appendingPathComponent("print/tmp_\(UUID()).txt")
    let dirPath = FileManager.default.temporaryDirectory.appendingPathComponent("print/")
    let filePathString = filePath.absoluteString
    print("File Path String: \(filePathString)")
    do {
        Task {
        if !FileManager.default.fileExists(atPath: filePathString) {
            try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: filePathString, contents: nil, attributes: nil)
            
            
            }
        
            try text.write(toFile: filePathString, atomically: true, encoding: .utf8)
            modelLogger.log("File created!")
        }
        listFiles(at: dirPath.absoluteString)
        
        // AppleScript to print the file using Finder
        let script = """
            tell application "TextEdit"
                activate
                open POSIX file "\(filePathString)"
                delay 1
                print document 1
                delay 1
                close document 1 saving no
            end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("Error: \(error)")
            }
        }
    } catch {
        print("Error writing to file: \(error)")
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
func isInteger(_ string: String) -> Bool {
    return Int(string.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
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
        
        
        modelLogger.log("Inside processCardInfo function! InputsText:\n\(self.inputText)")
        let text = inputText
        if(text == ""){
            self.outputText = "Empty text submitted, please retry with actual input."
            return
        }
        let lines = text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        var cards: [(Int, String, String, String)] = []
        
        isLoading = true

        var i = 0
        while i < lines.count {
            let line = lines[i]
            
            if !isInteger(line) && !foundFirstCard{
                i += 1
                continue
            }else{
                print("Found first card")
                foundFirstCard = true
            }
            if line.starts(with: "** "){
                break
            }
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
        let total = cards.reduce(0) { sum, card in
            sum + card.0
        }
        numberOfCardsTotal = Double(total)
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
            modelLogger.log("Processed++!")
            numberOfCardsProcessed += 1
        }
        modelLogger.log("Post-Processing!")
        modelLogger.log("\(specialCards.count)")
        modelLogger.log("\(specialCardFlag)")
        if(specialCardFlag){
            modelLogger.log("Dealing with special cards!")
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
                    numberOfRares+=quantity
                }
                if rarity == "Mythic" {
                    numberOfMythics+=quantity
                }
                    
            } else {
                numberOfOther+=quantity
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
            self.jobProcessed = true
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
    @State private var showPrinterAlert = false
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
                                .onChange(of: processingJob.inputText) { newText in
                                    processingJob.inputText = newText.convertToPlainText()
                                }
                            
                            if (processingJob.isLoading){
                            HStack {
                                Text("\(Int(processingJob.numberOfCardsProcessed))")
                                    .font(.subheadline)
                                    .bold()
                                Text("/")
                                    .font(.subheadline)
                                Text("\(Int(processingJob.numberOfCardsTotal))")
                                    .font(.subheadline)
                                    .bold()
                                
                                ProgressView("Processing...", value: processingJob.numberOfCardsProcessed, total: processingJob.numberOfCardsTotal)
                                    .progressViewStyle(LinearProgressViewStyle())
                            }
                            }else{
                                HStack(){
                                    Button(action: {
                                        if(processingJob.customerName.isEmpty){
                                            processingJob.customerName = superheroNames.randomElement()!
                                        }
                                        
                                        processingJob.processCardInfo()
                                    }) {
                                        HStack {
                                            Image(systemName: "checkmark.shield.fill") // SF Symbol
                                                .font(.title)
                                                .foregroundColor(.green)
                                                .padding(.leading)
                                            Text("Process List")
                                                .padding([.top, .trailing, .bottom])
                                                .bold()
                                        }
                                    }
                                    .disabled(processingJob.jobProcessed)
                                    
                                    Button(action: {
                                        processingJob.inputText = ""
                                    }) {
                                        HStack {
                                            Image(systemName: "clear.fill")
                                                .font(.title)
                                                .foregroundColor(.orange)
                                                .padding(.leading)
                                            Text("Clear")
                                                .padding([.top, .trailing, .bottom])
                                                .bold()
                                        }
                                    }
                                    .disabled(processingJob.jobProcessed)
                                    HStack{
                                        processingJob.jobProcessed ? Text("Start New Job to Process New Cards ↘").font(.caption2).padding() : Text("").padding()
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
                                    showPrinterAlert = true
                                    
                                }) {
                                    HStack {
                                        Image(systemName: "printer.filled.and.paper") .font(.title)
                                            .foregroundColor(.gray)
                                            .padding(.leading)
                                        Text("Print Pick List")
                                            .padding([.top, .trailing, .bottom])
                                            .bold()
                                        
                                    }
                                }
                                .alert("Printing is Unreliable", isPresented: $showPrinterAlert) {
                                                Button("Print Anyway") { try? printer.print(.string(processingJob.outputText)) }
                                    /*Button("Print Alternate Way") {
                                        writeAndPrintFile(text: processingJob.outputText)
                                    }*/
                                    Button("Cancel") {}
                                        .foregroundColor(.red)
                                            } message: {
                                                Text("Printing currently gets cut off after about 40 cards. For larger lists, Copy the text and print from TextEdit.")
                                            }
                                
                                Button(action: {
                                    copyToClipboard(text: processingJob.outputText)
                                }) {
                                    HStack {
                                        Image(systemName: "doc.on.doc.fill") 
                                            .font(.title)
                                            .foregroundColor(.blue)
                                            .padding(.leading)
                                        Text("Copy")
                                            .padding([.top, .trailing, .bottom])
                                            .bold()
                                    }
                                }
                                
                            }
                            
                        }
                        
                        
                        Divider()
                        HStack(){
                            Spacer()
                            
                            Button(action: {
                                processingJob.clear()
                                /*
                                let sessionToBeSaved = SavedSession(name: processingJob.customerName, processedCardListText: processingJob.outputText, date: processingJob.date, inputText: processingJob.inputText, numberOfCardsTotal: Int(processingJob.numberOfCardsTotal), context: viewContext)
                                viewContext.insert(sessionToBeSaved)
                                
                                do {
                                            //try viewContext.save()
                                        } catch {
                                            print("Error saving session: \(error)")
                                        }
                                */
                            }) {
                                HStack {
                                    Image(systemName: "doc.fill.badge.plus")
                                        .font(.title)
                                        .padding(.leading)
                                    
                                    Text("New Job")
                                        .padding([.top, .trailing, .bottom])
                                        .bold()
                                }
                            }
                        }
                        
                    }.padding()
                    
                }
//                VStack(alignment: .leading){
//                    
//                    Text("History:")
//                        .font(.headline)
//                        .padding(.bottom, 0)
//                    
//                    VStack(alignment: .leading) {
//                        HStack {
//                            Text("Date")
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                            Text("Name/First Card")
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                            Text("Total Qty")
//                                .frame(maxWidth: .infinity, alignment: .trailing)
//                        }
//                        .padding(5)
//                        .background(Color.gray.opacity(0.2))
//                        .frame(maxHeight: 25)
//                        .bold()
//                        Text("History Coming Soon")
////                        List(savedSessions, id: \.date) { session in
////                            HStack {
////                                Text(session.date)
////                                    .frame(maxWidth: .infinity, alignment: .leading)
////                                Text(session.name)
////                                    .frame(maxWidth: .infinity, alignment: .leading)
////                                Text(String(session.numberOfCardsTotal))
////                                    .frame(maxWidth: .infinity, alignment: .leading)
////                            }
////                        }
////                        .padding(.top, 0)
////                        .listStyle(InsetListStyle())
////                        .border(Color.gray, width: 1)
//                        HStack(){
//                            Spacer()
//                            Button(action: {
//                                processingJob.inputText = ""
//                            }) {
//                                HStack {
//                                    Image(systemName: "clear.fill") // SF Symbol
//                                        .foregroundColor(.red)
//                                        .padding(.trailing, 0)
//                                    Text("Delete History")
//                                        .padding(.leading, 0)
//                                }
//                            }
//                            .disabled(true)
//                        }
//                    }
//                }
            }
            .padding(.top, 0)
            .padding(.bottom)
            .padding(.trailing)
            
        }
        .padding(.bottom, 0)
        .frame(minWidth: 600, minHeight: 850)
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
