import SwiftUI

public struct ExpenseDashboardView: View {
    @EnvironmentObject var fileManager: TransactionFileManager
    @EnvironmentObject var regexEngine: RegexRuleEngine
    
    @State private var processedTransactions: [CleanTransaction] = []
    @State private var isSyncing = false
    @State private var lastSyncTime = Date()
    
    public init() {}
    
    var totalExpenses: Double {
        processedTransactions.reduce(0) { $0 + $1.amount }
    }
    
    var categoryTotals: [String: Double] {
        var map: [String: Double] = [
            "Food & Dining": 0.0,
            "Transport": 0.0,
            "Shopping": 0.0,
            "Miscellaneous": 0.0
        ]
        for txn in processedTransactions {
            map[txn.category, default: 0.0] += txn.amount
        }
        return map
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                AppleTheme.mainBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Sync Status Bar
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Kharcha Pani")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(AppleTheme.textPrimary)
                                
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(AppleTheme.accentGreen)
                                        .frame(width: 8, height: 8)
                                        .shadow(color: AppleTheme.accentGreen.opacity(0.6), radius: 4)
                                    Text("Local Ledger Live • Updated \(lastSyncTime, formatter: timeFormatter)")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(AppleTheme.textMuted)
                                }
                            }
                            Spacer()
                            
                            KharchaPaniLogoView(size: 44)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Total Account Outflow Executive Card
                        VStack(spacing: 12) {
                            HStack {
                                Text("TOTAL ACCOUNT OUTFLOW")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(AppleTheme.textMuted)
                                Spacer()
                                Text("\(processedTransactions.count) Txns")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(AppleTheme.tertiaryChip)
                                    .foregroundColor(AppleTheme.textPrimary)
                                    .cornerRadius(10)
                            }
                            
                            HStack(alignment: .firstTextBaseline) {
                                Text(String(format: "₹%.2f", totalExpenses))
                                    .font(.system(size: 38, weight: .bold, design: .rounded))
                                    .foregroundColor(AppleTheme.textPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppleTheme.accentRed)
                                    .padding(10)
                                    .background(AppleTheme.accentRed.opacity(0.15))
                                    .clipShape(Circle())
                            }
                        }
                        .appleCardStyle(cornerRadius: 24)
                        .padding(.horizontal, 20)
                        
                        // Category Outflow Progress Breakdown
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Category Allocation")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppleTheme.textPrimary)
                            
                            let total = totalExpenses > 0 ? totalExpenses : 1.0
                            
                            VStack(spacing: 14) {
                                CategoryProgressRow(
                                    name: "Food & Dining",
                                    icon: "fork.knife",
                                    amount: categoryTotals["Food & Dining"] ?? 0,
                                    percentage: (categoryTotals["Food & Dining"] ?? 0) / total,
                                    barColor: AppleTheme.accentRed
                                )
                                CategoryProgressRow(
                                    name: "Transport",
                                    icon: "car.fill",
                                    amount: categoryTotals["Transport"] ?? 0,
                                    percentage: (categoryTotals["Transport"] ?? 0) / total,
                                    barColor: AppleTheme.accentBlue
                                )
                                CategoryProgressRow(
                                    name: "Shopping",
                                    icon: "bag.fill",
                                    amount: categoryTotals["Shopping"] ?? 0,
                                    percentage: (categoryTotals["Shopping"] ?? 0) / total,
                                    barColor: AppleTheme.accentPurple
                                )
                                CategoryProgressRow(
                                    name: "Miscellaneous",
                                    icon: "square.grid.2x2.fill",
                                    amount: categoryTotals["Miscellaneous"] ?? 0,
                                    percentage: (categoryTotals["Miscellaneous"] ?? 0) / total,
                                    barColor: AppleTheme.textMuted
                                )
                            }
                        }
                        .appleCardStyle(cornerRadius: 22)
                        .padding(.horizontal, 20)
                        
                        // Tracked Outflows Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Recent Tracked Outflows")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(AppleTheme.textPrimary)
                                Spacer()
                                NavigationLink(destination: TransactionLedgerView()) {
                                    Text("View Ledger")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppleTheme.accentBlue)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            if processedTransactions.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 32))
                                        .foregroundColor(AppleTheme.textMuted)
                                    Text("No items detected in transactional.jsonl")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppleTheme.textMuted)
                                    Text("Pull down to refresh or copy shortcut setup.")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppleTheme.textMuted.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 36)
                                .appleCardStyle(cornerRadius: 20)
                                .padding(.horizontal, 20)
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(processedTransactions.prefix(5), id: \.id) { txn in
                                        TransactionCardRow(txn: txn)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
                .refreshable {
                    syncAndProcessDataLog()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                syncAndProcessDataLog()
            }
        }
    }
    
    private func syncAndProcessDataLog() {
        isSyncing = true
        let rawEntries = fileManager.readJSONLines()
        var uniqueSet = Set<String>()
        var validatedTxns: [CleanTransaction] = []
        
        for entry in rawEntries {
            if let parsed = TransactionParser.shared.parse(raw: entry, customRules: regexEngine.customRules) {
                // Deduplication check
                if !uniqueSet.contains(parsed.id) {
                    uniqueSet.insert(parsed.id)
                    validatedTxns.append(parsed)
                }
            }
        }
        
        // Sort chronologically descending
        self.processedTransactions = validatedTxns.sorted(by: { $0.date > $1.date })
        self.lastSyncTime = Date()
        self.isSyncing = false
    }
}

// MARK: - Category Progress Bar Component
struct CategoryProgressRow: View {
    let name: String
    let icon: String
    let amount: Double
    let percentage: Double
    let barColor: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(barColor)
                    Text(name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppleTheme.textPrimary)
                }
                Spacer()
                Text(String(format: "₹%.2f (%d%%)", amount, Int(percentage * 100)))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(AppleTheme.textMuted)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppleTheme.tertiaryChip)
                        .frame(height: 7)
                    Capsule()
                        .fill(barColor)
                        .frame(width: max(0, min(geo.size.width * CGFloat(percentage), geo.size.width)), height: 7)
                }
            }
            .frame(height: 7)
        }
    }
}

// MARK: - Transaction Card Row Component
struct TransactionCardRow: View {
    let txn: CleanTransaction
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppleTheme.tertiaryChip)
                    .frame(width: 42, height: 42)
                Image(systemName: txn.type.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(txn.type.badgeColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(txn.merchant)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppleTheme.textPrimary)
                
                HStack(spacing: 6) {
                    Text(txn.type.rawValue)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(txn.type.badgeColor)
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(AppleTheme.textMuted)
                    Text(txn.institution)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(AppleTheme.textMuted)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "-₹%.2f", txn.amount))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppleTheme.textPrimary)
                
                Text(txn.category)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppleTheme.accentBlue.opacity(0.12))
                    .foregroundColor(AppleTheme.accentBlue)
                    .cornerRadius(6)
            }
        }
        .appleCardStyle(cornerRadius: 16)
    }
}

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    ExpenseDashboardView()
        .environmentObject(TransactionFileManager())
        .environmentObject(RegexRuleEngine())
}
