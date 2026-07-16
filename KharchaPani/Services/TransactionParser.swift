import Foundation

public class TransactionParser {
    public static let shared = TransactionParser()
    
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
    
    private init() {}
    
    /// Parses a raw transactional line into a hydrated CleanTransaction struct
    public func parse(raw: RawTransactionLine, customRules: [RegexRule] = []) -> CleanTransaction? {
        let text = raw.body
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return nil }
        
        // 1. Generate Deterministic Unique ID for De-duplication
        let uniqueString = "\(raw.date)_\(text)"
        let uniqueID = Data(uniqueString.utf8).base64EncodedString()
        
        // Check custom user rules first if enabled
        for rule in customRules where rule.isEnabled {
            if let matched = matchingGroup(for: rule.pattern, in: text) {
                // Custom rule matched
                let parsedDate = isoFormatter.date(from: raw.date) ?? Date()
                let amount = extractAmount(from: text) ?? 0.0
                if amount <= 0 { continue } // financial check
                
                return CleanTransaction(
                    id: uniqueID,
                    date: parsedDate,
                    institution: raw.sender,
                    amount: amount,
                    merchant: rule.mappedMerchant.isEmpty ? matched : rule.mappedMerchant,
                    type: classifyAccountType(from: text),
                    category: rule.targetCategory.isEmpty ? autoCategorize(merchant: matched) : rule.targetCategory,
                    rawSender: raw.sender,
                    rawBody: raw.body
                )
            }
        }
        
        // 2. Extrapolate Amount via Regex Pattern Mapping
        guard let amount = extractAmount(from: text), amount > 0 else {
            return nil // Exclude non-financial or invalid SMS messages
        }
        
        // 3. Extrapolate Merchant/Destination Target
        let merchantPattern = "(?:to|at|vpa|spent on|info:)\\s+([^\\s,.]+([\\s][^\\s,.]+)?)"
        let rawMerchant = matchingGroup(for: merchantPattern, in: text) ?? fallbackMerchant(from: text, sender: raw.sender)
        let cleanMerchant = cleanMerchantName(rawMerchant)
        
        // 4. Classify Account Mechanism
        let detectedType = classifyAccountType(from: text)
        
        // 5. Parse Date & Categorize
        let parsedDate = isoFormatter.date(from: raw.date) ?? Date()
        let derivedCategory = autoCategorize(merchant: cleanMerchant)
        
        return CleanTransaction(
            id: uniqueID,
            date: parsedDate,
            institution: raw.sender,
            amount: amount,
            merchant: cleanMerchant,
            type: detectedType,
            category: derivedCategory,
            rawSender: raw.sender,
            rawBody: raw.body
        )
    }
    
    /// Regex pattern solver for amount extraction
    public func extractAmount(from text: String) -> Double? {
        let amountPatterns = [
            "(?:Rs\\.|INR|Rs|debited by|spent|paid)\\s*([\\d,]+\\.?\\d*)",
            "(?:amount of)\\s*([\\d,]+\\.?\\d*)"
        ]
        
        for pattern in amountPatterns {
            if let amountStr = matchingGroup(for: pattern, in: text) {
                let sanitized = amountStr.replacingOccurrences(of: ",", with: "")
                if let val = Double(sanitized) {
                    return val
                }
            }
        }
        return nil
    }
    
    /// RegEx matching group helper
    public func matchingGroup(for pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let nsString = text as NSString
        let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        guard let match = results.first, match.numberOfRanges > 1 else { return nil }
        let range = match.range(at: 1)
        if range.location != NSNotFound {
            return nsString.substring(with: range)
        }
        return nil
    }
    
    /// Sanitizes and formats extracted raw merchant names
    public func cleanMerchantName(_ raw: String) -> String {
        var clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.lowercased().hasSuffix(" on") { clean = String(clean.dropLast(3)) }
        if clean.lowercased().hasSuffix(" via") { clean = String(clean.dropLast(4)) }
        if clean.hasSuffix(".") || clean.hasSuffix(",") { clean.removeLast() }
        
        // Capitalize words nicely
        if clean.contains("@") {
            let parts = clean.split(separator: "@")
            if let first = parts.first {
                clean = String(first).capitalized
            }
        } else {
            clean = clean.capitalized
        }
        
        return clean.isEmpty ? "Merchant" : clean
    }
    
    /// Account mechanism detection
    public func classifyAccountType(from text: String) -> AccountType {
        let lower = text.lowercased()
        if lower.contains("upi") || lower.contains("vpa") {
            return .upi
        } else if lower.contains("credit") || lower.contains("cc") {
            return .creditCard
        } else if lower.contains("debit") || lower.contains("dc") || lower.contains("card ending") {
            return .debitCard
        }
        return .unknown
    }
    
    /// Automatic Spending Category Rules Engine
    public func autoCategorize(merchant: String) -> String {
        let lower = merchant.lowercased()
        if lower.contains("swiggy") || lower.contains("zomato") || lower.contains("restaurant") ||
           lower.contains("blinkit") || lower.contains("zepto") || lower.contains("food") || lower.contains("cafe") {
            return "Food & Dining"
        }
        if lower.contains("uber") || lower.contains("ola") || lower.contains("petrol") ||
           lower.contains("fuel") || lower.contains("rapido") || lower.contains("shell") {
            return "Transport"
        }
        if lower.contains("amazon") || lower.contains("flipkart") || lower.contains("myntra") ||
           lower.contains("nykaa") || lower.contains("retail") || lower.contains("mall") {
            return "Shopping"
        }
        return "Miscellaneous"
    }
    
    private func fallbackMerchant(from text: String, sender: String) -> String {
        let lower = text.lowercased()
        if lower.contains("swiggy") { return "Swiggy" }
        if lower.contains("uber") { return "Uber" }
        if lower.contains("flipkart") { return "Flipkart" }
        if lower.contains("blinkit") { return "Blinkit" }
        if lower.contains("myntra") { return "Myntra" }
        return sender.split(separator: "-").last.map(String.init) ?? "Local Merchant"
    }
}
