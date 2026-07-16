import SwiftUI

public struct TransactionLedgerView: View {
    @EnvironmentObject var fileManager: TransactionFileManager
    @EnvironmentObject var regexEngine: RegexRuleEngine
    
    @State private var searchText = ""
    @State private var selectedFilter: AccountFilter = .all
    @State private var transactions: [CleanTransaction] = []
    @State private var selectedTxn: CleanTransaction? = nil
    
    enum AccountFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case upi = "UPI"
        case debitCard = "Debit Card"
        case creditCard = "Credit Card"
        
        var id: String { rawValue }
    }
    
    public init() {}
    
    var filteredTransactions: [CleanTransaction] {
        transactions.filter { txn in
            let matchesSearch = searchText.isEmpty ||
                txn.merchant.lowercased().contains(searchText.lowercased()) ||
                txn.institution.lowercased().contains(searchText.lowercased()) ||
                txn.category.lowercased().contains(searchText.lowercased()) ||
                txn.rawBody.lowercased().contains(searchText.lowercased())
            
            let matchesFilter: Bool
            switch selectedFilter {
            case .all: matchesFilter = true
            case .upi: matchesFilter = txn.type == .upi
            case .debitCard: matchesFilter = txn.type == .debitCard
            case .creditCard: matchesFilter = txn.type == .creditCard
            }
            
            return matchesSearch && matchesFilter
        }
    }
    
    public var body: some View {
        ZStack {
            AppleTheme.mainBackground.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Master Ledger")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(AppleTheme.textPrimary)
                        Text("\(filteredTransactions.count) of \(transactions.count) records")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(AppleTheme.textMuted)
                    }
                    Spacer()
                    
                    KharchaPaniLogoView(size: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Minimalist Dark Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppleTheme.textMuted)
                    TextField("Search merchant, sender ID, category...", text: $searchText)
                        .font(.system(size: 15))
                        .foregroundColor(AppleTheme.textPrimary)
                        .accentColor(AppleTheme.accentBlue)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppleTheme.textMuted)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppleTheme.secondaryCard)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppleTheme.borderLine, lineWidth: 1)
                )
                .padding(.horizontal, 20)
                
                // Filter Chips Row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AccountFilter.allCases) { filter in
                            Button(action: { selectedFilter = filter }) {
                                Text(filter.rawValue)
                                    .font(.system(size: 13, weight: selectedFilter == filter ? .bold : .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedFilter == filter ? AppleTheme.accentBlue : AppleTheme.secondaryCard)
                                    .foregroundColor(selectedFilter == filter ? .white : AppleTheme.textMuted)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(selectedFilter == filter ? AppleTheme.accentBlue : AppleTheme.borderLine, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Master Ledger Table View
                if filteredTransactions.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(AppleTheme.textMuted)
                        Text("No matching transactions")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppleTheme.textPrimary)
                        Text("Try modifying search query or filter selection.")
                            .font(.system(size: 13))
                            .foregroundColor(AppleTheme.textMuted)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(filteredTransactions, id: \.id) { txn in
                                Button(action: { selectedTxn = txn }) {
                                    LedgerRow(txn: txn)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120)
                    }
                }
            }
        }
        .sheet(item: $selectedTxn) { txn in
            RawTransactionDetailSheet(txn: txn)
        }
        .onAppear {
            loadLedgerData()
        }
    }
    
    private func loadLedgerData() {
        let raw = fileManager.readJSONLines()
        var uniqueSet = Set<String>()
        var list: [CleanTransaction] = []
        for line in raw {
            if let parsed = TransactionParser.shared.parse(raw: line, customRules: regexEngine.customRules) {
                if !uniqueSet.contains(parsed.id) {
                    uniqueSet.insert(parsed.id)
                    list.append(parsed)
                }
            }
        }
        self.transactions = list.sorted(by: { $0.date > $1.date })
    }
}

struct LedgerRow: View {
    let txn: CleanTransaction
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(txn.merchant)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppleTheme.textPrimary)
                
                HStack(spacing: 6) {
                    Text(txn.rawSender.isEmpty ? txn.institution : txn.rawSender)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppleTheme.tertiaryChip)
                        .foregroundColor(AppleTheme.textMuted)
                        .cornerRadius(6)
                    
                    Text(txn.date, formatter: dateFormatter)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(AppleTheme.textMuted)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "₹%.2f", txn.amount))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppleTheme.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: txn.type.iconName)
                        .font(.system(size: 10))
                    Text(txn.type.rawValue)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                }
                .foregroundColor(txn.type.badgeColor)
            }
        }
        .appleCardStyle(cornerRadius: 16)
    }
}

struct RawTransactionDetailSheet: View {
    let txn: CleanTransaction
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppleTheme.secondaryCard.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Raw Record Inspector")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(AppleTheme.textPrimary)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppleTheme.textMuted)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    DetailField(label: "PARSED MERCHANT", value: txn.merchant)
                    DetailField(label: "EXTRACTED AMOUNT", value: "₹\(txn.amount)")
                    DetailField(label: "ACCOUNT CLASSIFICATION", value: "\(txn.type.rawValue) (\(txn.institution))")
                    DetailField(label: "DERIVED CATEGORY", value: txn.category)
                    DetailField(label: "SMS SENDER CODE", value: txn.rawSender)
                }
                .padding(16)
                .background(AppleTheme.tertiaryChip)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppleTheme.borderLine, lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("RAW SMS TEXT BODY:")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(AppleTheme.textMuted)
                    
                    Text(txn.rawBody.isEmpty ? "No raw text body recorded." : txn.rawBody)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(AppleTheme.accentGreen)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppleTheme.mainBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppleTheme.borderLine, lineWidth: 1)
                        )
                }
                
                Spacer()
            }
            .padding(20)
        }
    }
}

struct DetailField: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(AppleTheme.textMuted)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppleTheme.textPrimary)
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    TransactionLedgerView()
        .environmentObject(TransactionFileManager())
        .environmentObject(RegexRuleEngine())
}
