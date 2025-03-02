//
//  ShipmentWeek.swift
//  Pullscription Tools
//
//  Created by Jago Lourenco-Goddard on 2/22/25.
//

// The file that describes the object that is the collection of invoices that represent a "week"
// vends: all relevant info for SplitShipment and DataExport

import Foundation
import SwiftCSV

class StoreSplitInfo : Identifiable {
    //var storeNames: [String]
    
}

//enum called shipmnet status which lists things like unprocessed, processed, completed, etc
enum ProcessingStatus: String, Codable {
    case pending = "Pending"
    case unprocessed = "Unprocessed"
    case partiallyProcessed = "Partially Processed"
    case processed = "Processed"
    case completed = "Completed"
    case error = "Error"
}

enum ComicSupplier: String, Codable {
    case PRH = "Penguin Random House"
    case lunar = "Lunar Distribution"
    case diamond = "Diamond Comic Distributors"
}

protocol SupplierInvoiceProtocol: Identifiable {
    var id: UUID { get }
    var invoiceNumber: String? { get }
    var invoiceDate: Date { get }
    var accountNumber: String { get }
    var totalAmount: Double { get }
    var paymentMethod: String { get set }
    var shippingAmount: Double { get set }
    var supplierName: ComicSupplier { get set }
    var status: ProcessingStatus { get set }
    var lineItems: [InvoiceLineItem] { get }
}

protocol InvoiceLineItemProtocol: Identifiable {
    var id: UUID { get }
    var quantity: Int { get set }
    var cost: Double { get set }
}

protocol CatalogLineItemProtocol: Identifiable {
    var id: UUID { get }
    var title: String { get set }
    var description: String { get set }
    var msrp: Double { get set }
}

class CatalogLineItem: CatalogLineItemProtocol {
    var id: UUID
    var title: String
    var description: String
    var status: ProcessingStatus
    var msrp: Double
    
    init (id: UUID, title: String, description: String, status: ProcessingStatus, msrp: Double) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.msrp = msrp
    }
}

class InvoiceLineItem: InvoiceLineItemProtocol {
    let id: UUID
    var quantity: Int
    var status: ProcessingStatus
    var cost: Double
    
    init(quantity: Int, status: ProcessingStatus, cost: Double) {
        self.id = UUID()
        self.quantity = quantity
        self.status = status
        self.cost = cost
    }
    
}

//need to get an example of this kind of invoice
class DiamondExtendedInvoiceLineItem: InvoiceLineItem { }

class DiamondInvoiceLineItem: InvoiceLineItem {
    let diamondNumber: String
    let title: String
    let msrp: Double
    let unitPrice: Double
    let totalPrice: Double
    let categoryCode: String?
    let orderTypeCode: String?
    let publisher: String?
    
    init(quantity: Int,
         status: ProcessingStatus,
         cost: Double,
         diamondNumber: String,
         title: String,
         msrp: Double,
         unitPrice: Double,
         totalPrice: Double,
         categoryCode: String? = nil,
         orderTypeCode: String? = nil,
         publisher: String? = nil) {
        
        self.diamondNumber = diamondNumber
        self.title = title
        self.msrp = msrp
        self.unitPrice = unitPrice
        self.totalPrice = totalPrice
        self.categoryCode = categoryCode
        self.orderTypeCode = orderTypeCode
        self.publisher = publisher
        
        super.init(quantity: quantity, status: status, cost: cost)
    }
}

class LunarInvoiceLineItem: InvoiceLineItem {
    let lunarCode: String
    let title: String
    let msrp: Double
    let discountPercentage: Double
    let unitPrice: Double
    let totalPrice: Double
    let upc: String?
    let purchaseOrderNumber: String?
    let streetDate: String?  // Assuming this is a date string; adjust if needed
    let itemCategoryCode: String?
    
    init(quantity: Int,
         status: ProcessingStatus,
         cost: Double,
         lunarCode: String,
         title: String,
         msrp: Double,
         discountPercentage: Double,
         unitPrice: Double,
         totalPrice: Double,
         upc: String? = nil,
         purchaseOrderNumber: String? = nil,
         streetDate: String? = nil,
         itemCategoryCode: String? = nil) {
        
        self.lunarCode = lunarCode
        self.title = title
        self.msrp = msrp
        self.discountPercentage = discountPercentage
        self.unitPrice = unitPrice
        self.totalPrice = totalPrice
        self.upc = upc
        self.purchaseOrderNumber = purchaseOrderNumber
        self.streetDate = streetDate
        self.itemCategoryCode = itemCategoryCode
        
        super.init(quantity: quantity, status: status, cost: cost)
    }
}

class PRHInvoiceLineItem: InvoiceLineItem {
    let lineNumber: Int?
    let description: String
    let isbn: String
    let isbn10: String
    let upcSku: String?
    let countryCode: String?
    let msrp: Double
    let discountPercentage: Double
    let wholesalePrice: Double
    let lineItemTotal: Double
    let purchaseOrderNumber: String?
    
    init(quantity: Int,
         status: ProcessingStatus,
         cost: Double,
         lineNumber: Int? = nil,
         description: String,
         isbn: String,
         isbn10: String,
         upcSku: String? = nil,
         countryCode: String? = nil,
         msrp: Double,
         discountPercentage: Double,
         wholesalePrice: Double,
         lineItemTotal: Double,
         purchaseOrderNumber: String? = nil) {
        
        self.lineNumber = lineNumber
        self.description = description
        self.isbn = isbn
        self.isbn10 = isbn10
        self.upcSku = upcSku
        self.countryCode = countryCode
        self.msrp = msrp
        self.discountPercentage = discountPercentage
        self.wholesalePrice = wholesalePrice
        self.lineItemTotal = lineItemTotal
        self.purchaseOrderNumber = purchaseOrderNumber
        
        super.init(quantity: quantity, status: status, cost: cost)
    }
}

class ComicSupplierInvoice: SupplierInvoiceProtocol {
    var id: UUID
    var invoiceNumber: String?
    var invoiceDate: Date
    var accountNumber: String
    var totalAmount: Double
    var paymentMethod: String
    var shippingAmount: Double
    var supplierName: ComicSupplier
    var status: ProcessingStatus
    var lineItems: [InvoiceLineItem]
    
    init(invoiceNumber: String? = nil, invoiceDate: Date, accountNumber: String, totalAmount: Double, paymentMethod: String, shippingAmount: Double, supplierName: ComicSupplier, status: ProcessingStatus, lineItems: [InvoiceLineItem]) {
        self.id = UUID()
        self.invoiceNumber = invoiceNumber
        self.invoiceDate = invoiceDate
        self.accountNumber = accountNumber
        self.totalAmount = totalAmount
        self.paymentMethod = paymentMethod
        self.shippingAmount = shippingAmount
        self.supplierName = supplierName
        self.status = status
        self.lineItems = lineItems
    }
}

class DiamondInvoice: ComicSupplierInvoice {
    init(csvFile: String) throws {
        var rows: [[String: String]] = []
        print("\(csvFile)")
        do{
            guard let csv = try? CSV<Named>(
                name: csvFile,
                bundle: .main
            ) else {
                throw NSError(domain: "DiamondInvoice", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load CSV"])
            }
            
            rows = csv.rows
            
            guard rows.count > 4 else {
                throw NSError(domain: "DiamondInvoice", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid file structure"])
            }
        } catch let parseError as CSVParseError {
            let parserErrorDescription: String
            if case .generic(message: "Could not load CSV") = parseError {
                parserErrorDescription = "Could not load CSV"
            } else {
                parserErrorDescription = "\(parseError)"
            }
            print("Failed to parse CSV: \(parserErrorDescription)")
            // Catch errors from parsing invalid CSV
        } catch {
            // Catch errors from trying to load files
        }


        let accountNumber = rows[1]["Column1"] ?? ""
        let invoiceDateString = rows[3]["Column1"] ?? ""
        let invoiceDate = parseDate(invoiceDateString)

        // Parse line items starting from row 5
        var lineItems: [DiamondInvoiceLineItem] = []
        for row in rows.dropFirst(4) {  // Skip the first four metadata rows
            if let quantity = Int(row["Column1"] ?? ""),
               let msrp = Double(row["Column4"] ?? ""),
               let unitPrice = Double(row["Column5"] ?? ""),
               let totalPrice = Double(row["Column6"] ?? "") {
                
                let lineItem = DiamondInvoiceLineItem(
                    quantity: quantity,
                    status: .pending,  // Assuming a default status
                    cost: totalPrice,
                    diamondNumber: row["Column2"] ?? "",
                    title: row["Column3"] ?? "",
                    msrp: msrp,
                    unitPrice: unitPrice,
                    totalPrice: totalPrice,
                    categoryCode: row["Column7"],
                    orderTypeCode: row["Column8"],
                    publisher: row["Column9"]
                )
                lineItems.append(lineItem)
            }
        }

        super.init(
            invoiceNumber: nil, // Not explicitly provided
            invoiceDate: invoiceDate,
            accountNumber: accountNumber,
            totalAmount: lineItems.reduce(0) { $0 + $1.cost },
            paymentMethod: "Unknown", // Not specified in the file
            shippingAmount: 0.0, // No shipping info provided
            supplierName: .diamond, // Assuming Diamond as supplier
            status: .pending, // Default processing status
            lineItems: lineItems
        )
    }
}

class LunarInvoice: ComicSupplierInvoice {
    init(csvFile: String) throws {
        let csv = try CSV<Named>(name: csvFile)
        
        // Extract metadata from the header rows
        let rows = csv!.rows
        guard rows.count > 17 else {
            throw NSError(domain: "LunarInvoice", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid file structure"])
        }
        
        let invoiceNumber = rows[2]["Column1"]?.replacingOccurrences(of: "Invoice #", with: "") ?? ""
        let accountNumber = rows[3]["Column1"]?.replacingOccurrences(of: "Account No: ", with: "") ?? ""
        let invoiceDateString = rows[4]["Column1"]?.replacingOccurrences(of: "Invoice Date: ", with: "") ?? ""
        let invoiceDate = parseDate(invoiceDateString)
        
        // Parse line items starting from row 18
        var lineItems: [LunarInvoiceLineItem] = []
        for row in rows.dropFirst(17) {  // Skip metadata rows
            if let quantity = Int(row["Column3"] ?? ""),
               let msrp = Double(row["Column4"] ?? ""),
               let discountPercentage = Double(row["Column5"] ?? ""),
               let unitPrice = Double(row["Column6"] ?? ""),
               let totalPrice = Double(row["Column7"] ?? "") {
                
                let lineItem = LunarInvoiceLineItem(
                    quantity: quantity,
                    status: .pending,  // Default status
                    cost: totalPrice,
                    lunarCode: row["Column1"] ?? "",
                    title: row["Column2"] ?? "",
                    msrp: msrp,
                    discountPercentage: discountPercentage,
                    unitPrice: unitPrice,
                    totalPrice: totalPrice,
                    upc: row["Column8"],
                    purchaseOrderNumber: row["Column9"],
                    streetDate: row["Column10"],
                    itemCategoryCode: row["Column11"]
                )
                lineItems.append(lineItem)
            }
        }
        
        super.init(
            invoiceNumber: invoiceNumber,
            invoiceDate: invoiceDate,
            accountNumber: accountNumber,
            totalAmount: lineItems.reduce(0) { $0 + $1.cost },
            paymentMethod: "Unknown", // Not specified in the file
            shippingAmount: 0.0, // No shipping info provided
            supplierName: .lunar, // Assuming Lunar as supplier
            status: .pending, // Default processing status
            lineItems: lineItems
        )
        ("")
    }
}

class PRHInvoice: ComicSupplierInvoice {
    init(csvFile: String) throws {
        let csv = try CSV<Named>(name: csvFile)
        
        // Extract metadata from the header rows
        let rows = csv!.rows
        guard rows.count > 17 else {
            throw NSError(domain: "PRHInvoice", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid file structure"])
        }
        
        let invoiceNumber = rows[0]["Column2"] ?? ""
        let accountNumber = rows[1]["Column2"] ?? ""
        let invoiceDateString = rows[10]["Column2"] ?? ""
        let invoiceDate = parseDate(invoiceDateString)
        
        // Parse line items starting from row 18
        var lineItems: [PRHInvoiceLineItem] = []
        for row in rows.dropFirst(17) {  // Skip metadata rows
            if let lineNumber = Int(row["Column1"] ?? ""),
               let msrp = Double(row["Column7"]?.replacingOccurrences(of: "$", with: "") ?? ""),
               let discountPercentage = Double(row["Column8"] ?? ""),
               let wholesalePrice = Double(row["Column9"]?.replacingOccurrences(of: "$", with: "") ?? ""),
               let quantity = Int(row["Column10"] ?? ""),
               let lineItemTotal = Double(row["Column11"]?.replacingOccurrences(of: "$", with: "") ?? "") {
                
                let lineItem = PRHInvoiceLineItem(
                    quantity: quantity,
                    status: .pending,  // Default status
                    cost: lineItemTotal,
                    lineNumber: lineNumber,
                    description: row["Column2"] ?? "",
                    isbn: row["Column3"] ?? "",
                    isbn10: row["Column4"] ?? "",
                    upcSku: row["Column5"],
                    countryCode: row["Column6"],
                    msrp: msrp,
                    discountPercentage: discountPercentage,
                    wholesalePrice: wholesalePrice,
                    lineItemTotal: lineItemTotal,
                    purchaseOrderNumber: row["Column12"]
                )
                lineItems.append(lineItem)
            }
        }
        
        super.init(
            invoiceNumber: invoiceNumber,
            invoiceDate: invoiceDate,
            accountNumber: accountNumber,
            totalAmount: lineItems.reduce(0) { $0 + $1.cost },
            paymentMethod: "Unknown", // Not specified in the file
            shippingAmount: 0.0, // No shipping info provided
            supplierName: .PRH, // Assuming PRH as supplier
            status: .pending, // Default processing status
            lineItems: lineItems
        )
    }
}

class Shipment: Identifiable {
    
    var id: UUID
    var week: Int
    var year: Int
    var invoices: [ComicSupplierInvoice]
    var fullCatalogItems: [CatalogLineItem]
    var status: ProcessingStatus
    var suppliers: [ComicSupplier]
    //var storeSplitInfo: [StoreSplitInfo]
    
    init(id: UUID, week: Int, year: Int, invoices: [ComicSupplierInvoice], fullCatalogItems: [CatalogLineItem], status: ProcessingStatus, suppliers: [ComicSupplier]) {
        self.id = id
        self.week = week
        self.year = year
        self.invoices = invoices
        self.fullCatalogItems = fullCatalogItems
        self.status = status
        self.suppliers = suppliers
    }
}
