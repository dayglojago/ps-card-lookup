//
//  ShipmentWeek.swift
//  Pullscription Tools
//
//  Created by Jago Lourenco-Goddard on 2/22/25.
//

// The file that describes the object that is the collection of invoices that represent a "week"
// vends: all relevant info for SplitShipment and DataExport



import Foundation

class StoreSplitInfo : Identifiable {
    //var storeNames: [String]
    
}

//enum called shipmnet status which lists things like unprocessed, processed, completed, etc
enum ProcessingStatus: String, Codable {
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
    
    init(id: UUID, quantity: Int, status: ProcessingStatus, cost: Double) {
        self.id = id
        self.quantity = quantity
        self.status = status
        self.cost = cost
    }
    
}

//need to get an example of this kind of invoice
class DiamondExtendedInvoiceLineItem: InvoiceLineItem { }

class DiamondInvoiceLineItem: InvoiceLineItem { }

class LunarInvoiceLineItem: InvoiceLineItem { }

class PRHInvoiceLineItem: InvoiceLineItem { }

class ComicSupplierInvoice: Identifiable {
    var id: UUID
    var invoiceNumber: String
    var invoiceDate: Date
    var totalAmount: Double
    var paymentMethod: String
    var shippingAmount: Double
    var supplierName: ComicSupplier
    var status: ProcessingStatus
    var lineItems: [InvoiceLineItem]
    
    init(id: UUID, invoiceNumber: String, invoiceDate: Date, totalAmount: Double, paidAmount: Double, outstandingAmount: Double, paymentMethod: String, paymentDate: Date? = nil, paymentStatus: String, shippingAmount: Double, supplierName: ComicSupplier, status: ProcessingStatus, lineItems: [InvoiceLineItem]) {
        self.id = id
        self.invoiceNumber = invoiceNumber
        self.invoiceDate = invoiceDate
        self.totalAmount = totalAmount
        self.paymentMethod = paymentMethod
        self.shippingAmount = shippingAmount
        self.supplierName = supplierName
        self.status = status
        self.lineItems = lineItems
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
    
//    enum CodingKeys: String, CodingKey {
//        case id
//        case week
//        case year
//    }
    
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
