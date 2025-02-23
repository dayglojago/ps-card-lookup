//
//  ContentView.swift
//  Pullscription Card Lookup
//
//  Created by Jago Lourenco-Goddard on 6/13/24.
//

import SwiftUI
import PrintingKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import SwiftData
import OSLog
import Foundation



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

let pageConfig = Pdf.PageConfiguration(
    pageSize: CGSize(width: 200, height: 6000),
    pageMargins: Pdf.PageMargins(all: 4)
)

//
//func generatePDF(text: String) -> Data {
//    // Custom configuration: 6000pt height, 200pt top margin
//
//
//    let pdfData = createPDFWithText(text: text, configuration: pageConfig)
//    return pdfData
//}
//
//func createPDFWithText(text: String, configuration: Pdf.PageConfiguration) -> Data {
//        let pdfData = NSMutableData()
//        let pageRect = CGRect(origin: .zero, size: configuration.pageSize)
//        
//        let consumer = CGDataConsumer(data: pdfData as CFMutableData)!
//        var mediaBox = pageRect
//        
//        let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)!
//        
//        pdfContext.beginPDFPage(nil)
//        
//        let textRect = CGRect(
//            x: configuration.pageMargins.left,
//            y: configuration.pageSize.height - configuration.pageMargins.top - 100, // Adjusting y for top-down coordinate system
//            width: configuration.pageSize.width - configuration.pageMargins.left - configuration.pageMargins.right,
//            height: configuration.pageSize.height - configuration.pageMargins.top - configuration.pageMargins.bottom
//        )
//        
//        let paragraphStyle = NSMutableParagraphStyle()
//        paragraphStyle.alignment = .left
//        
//        let textAttributes: [NSAttributedString.Key: Any] = [
//            .font: NSFont.systemFont(ofSize: 16),
//            .paragraphStyle: paragraphStyle
//        ]
//        
//        let attributedString = NSAttributedString(string: text, attributes: textAttributes)
//        attributedString.draw(in: textRect)
//        
//        pdfContext.endPDFPage()
//        pdfContext.closePDF()
//        
//        return pdfData as Data
//    }


// Main SwiftUI view
struct CardLookup: View {
    @Environment(\.managedObjectContext) private var viewContext
    // Use this to track window visibility
    @State private var isWindowVisible = true
    //@Query(sort: \SavedSession.date) private var savedSessions: [SavedSession]
    @State private var showPrinterAlert = false
    @State private var processingJob = CardInfoViewModel( inputText: "")
#if os(macOS)
    let boldCenterAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
    ]
#endif
    // Define focus state for text fields
    @FocusState private var focusedField: Field?
    private let printer = Printer()
    
    // Enum to represent different fields
    enum Field: Hashable {
        case toBeProcessed
        case processed
    }

    @State private var selectedItems: [UUID] = []
    
    
    var body: some View {
        ScrollView{
            VStack{
                HStack(alignment: .lastTextBaseline){
                    Text("Magic: The Gathering Card Pick List Generator")
                        .font(.title2)
                        .bold()
                        .padding(.bottom, 0)
                }
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
                                Text("Card data:")
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
                                                Text("Process")
                                                    .padding([.top, .trailing, .bottom])
                                                    .bold()
                                            }
                                        }
                                        .disabled(processingJob.jobProcessed)
                                        Button(action: {
                                            //TODO
#if os(macOS)
                                            processingJob.inputText = copyFromClipboard()
#endif
                                            
                                        }) {
                                            HStack {
                                                Image(systemName: "doc.on.clipboard")
                                                    .font(.title)
                                                    .foregroundColor(.mint)
                                                    .padding(.leading)
                                                Text("Paste")
                                                    .padding([.top, .trailing, .bottom])
                                                    .bold()
                                            }
                                        }
                                        .disabled(processingJob.jobProcessed)
                                        Spacer()
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
                                        .disabled(processingJob.inputText.isEmpty)
                                        
                                        
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
                                        //let pdf = generatePDF(text: processingJob.outputText)
#if os(macOS)
                                        let boldAttributedString = NSAttributedString(string: processingJob.outputText, attributes: boldCenterAttributes)
                                        
                                        
                                        let outputPrint = PrintItem.attributedString(boldAttributedString, configuration: pageConfig)
                                        try? printer.print(outputPrint)
#endif
                                    }) {
                                        HStack {
                                            Image(systemName: "printer.filled.and.paper") .font(.title)
                                                .foregroundColor(.black)
                                                .padding(.leading)
                                            Text("Print")
                                                .padding([.top, .trailing, .bottom])
                                                .bold()
                                        }
                                    }
                                    .disabled(!processingJob.jobProcessed)
                                    Button(action: {
#if os(macOS)
                                        copyToClipboard(text: processingJob.outputText)
#endif
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
                                    .disabled(!processingJob.jobProcessed)
                                    
                                }
                                
                            }
                            
                            
                            Divider()
                            HStack(){
                                Spacer()
                                HStack{
                                    processingJob.jobProcessed ? Text("Press New to Process Other Cards").font(.title3).padding() : Text("").padding()
                                }
                                Button(action: {
                                    processingJob.clear()
                                }) {
                                    HStack {
                                        Image(systemName: "doc.fill.badge.plus")
                                            .foregroundColor(.red)
                                            .font(.title)
                                            .padding(.leading)
                                        
                                        Text("New")
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
        }
        .padding(.bottom, 0)
        .frame(minWidth: 600, minHeight: 850)
        .onDisappear(){
            isWindowVisible = false
        }
        .onAppear(){
            #if os(macOS)
            resizeWindow(width: 900, height: 800)
            #endif
            isWindowVisible = true
            focusedField = .toBeProcessed
            Task{
                globalSetsData = try! await fetchSetCodeList()
            }
        }
        #if os(macOS)
        .onChange(of: NSApp.isActive) { isActive in
            if isActive && !isWindowVisible {
                // If the app becomes active and the window is not visible, reopen it
                NSApp.windows.first?.makeKeyAndOrderFront(nil)
                isWindowVisible = true
            }
        }
#endif
        .navigationTitle("Card Lookup")
    }
}


#Preview {
    CardLookup()
}
