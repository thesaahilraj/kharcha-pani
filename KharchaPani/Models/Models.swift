import Foundation
import SwiftUI

// MARK: - Raw JSON Line Schema
/// Delimited JSON entry format stored inside `transactional.jsonl`
public struct RawTransactionLine: Codable, Equatable, Identifiable {
    public var id: String { "\(date)_\(sender)_\(body.hashValue)" }
    public let date: String
    public let sender: String
    public let body: String
    
    public init(date: String, sender: String, body: String) {
        self.date = date
        self.sender = sender
        self.body = body
    }
}

// MARK: - Account Type Classification
public enum AccountType: String, Codable, CaseIterable, Identifiable {
    case upi = "UPI"
    case debitCard = "Debit Card"
    case creditCard = "Credit Card"
    case unknown = "Account"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .upi: return "qrcode"
        case .debitCard: return "creditcard.fill"
        case .creditCard: return "creditcard"
        case .unknown: return "building.columns"
        }
    }
    
    public var badgeColor: Color {
        switch self {
        case .upi: return Color(hex: "#30D158")
        case .debitCard: return Color(hex: "#0A84FF")
        case .creditCard: return Color(hex: "#BF5AF2")
        case .unknown: return Color(hex: "#8E8E93")
        }
    }
}

// MARK: - Clean Parsed Transaction Schema
public struct CleanTransaction: Identifiable, Hashable, Codable {
    public let id: String
    public let date: Date
    public let institution: String
    public let amount: Double
    public let merchant: String
    public let type: AccountType
    public var category: String
    public let rawSender: String
    public let rawBody: String
    
    public init(
        id: String,
        date: Date,
        institution: String,
        amount: Double,
        merchant: String,
        type: AccountType,
        category: String,
        rawSender: String = "",
        rawBody: String = ""
    ) {
        self.id = id
        self.date = date
        self.institution = institution
        self.amount = amount
        self.merchant = merchant
        self.type = type
        self.category = category
        self.rawSender = rawSender
        self.rawBody = rawBody
    }
}

// MARK: - Custom Regex Pattern Mapping Rule
public struct RegexRule: Identifiable, Codable, Equatable {
    public let id: UUID
    public var pattern: String
    public var mappedMerchant: String
    public var targetCategory: String
    public var isEnabled: Bool
    
    public init(id: UUID = UUID(), pattern: String, mappedMerchant: String, targetCategory: String, isEnabled: Bool = true) {
        self.id = id
        self.pattern = pattern
        self.mappedMerchant = mappedMerchant
        self.targetCategory = targetCategory
        self.isEnabled = isEnabled
    }
}

// MARK: - File Storage Metrics
public struct FileSystemMetrics: Equatable {
    public let path: String
    public let exists: Bool
    public let sizeInBytes: Int64
    public let lineCount: Int
    public let lastModified: Date?
    
    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: sizeInBytes)
    }
}

// MARK: - Color Hex Extension Utility
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
