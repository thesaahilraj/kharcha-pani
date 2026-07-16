import Foundation
import Combine

public class RegexRuleEngine: ObservableObject {
    @Published public var customRules: [RegexRule] = []
    
    private let storageKey = "KharchaPani_CustomRegexRules"
    
    public init() {
        loadRules()
        if customRules.isEmpty {
            seedDefaultRules()
        }
    }
    
    public func addRule(pattern: String, merchant: String, category: String) {
        let newRule = RegexRule(pattern: pattern, mappedMerchant: merchant, targetCategory: category, isEnabled: true)
        customRules.append(newRule)
        saveRules()
    }
    
    public func toggleRule(id: UUID) {
        if let idx = customRules.firstIndex(where: { $0.id == id }) {
            customRules[idx].isEnabled.toggle()
            saveRules()
        }
    }
    
    public func deleteRule(at offsets: IndexSet) {
        customRules.remove(atOffsets: offsets)
        saveRules()
    }
    
    public func deleteRule(id: UUID) {
        customRules.removeAll(where: { $0.id == id })
        saveRules()
    }
    
    /// Tests a pattern against arbitrary sample text
    public func testPattern(_ pattern: String, in text: String) -> String? {
        return TransactionParser.shared.matchingGroup(for: pattern, in: text)
    }
    
    private func saveRules() {
        if let data = try? JSONEncoder().encode(customRules) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadRules() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([RegexRule].self, from: data) {
            self.customRules = decoded
        }
    }
    
    private func seedDefaultRules() {
        self.customRules = [
            RegexRule(
                pattern: "(?:Swiggy|SWG)\\s*([A-Za-z0-9_]+)",
                mappedMerchant: "Swiggy Food & Instamart",
                targetCategory: "Food & Dining"
            ),
            RegexRule(
                pattern: "(?:Petrol|Fuel|HPCL|IOCL|BPCL)\\s*([A-Za-z0-9_\\s]+)",
                mappedMerchant: "Fuel Pump Station",
                targetCategory: "Transport"
            )
        ]
        saveRules()
    }
}
