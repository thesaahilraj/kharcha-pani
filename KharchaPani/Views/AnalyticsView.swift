import SwiftUI

public struct AnalyticsView: View {
    @EnvironmentObject var fileManager: TransactionFileManager
    @EnvironmentObject var regexEngine: RegexRuleEngine
    
    @State private var transactions: [CleanTransaction] = []
    
    public init() {}
    
    var totalOutflow: Double {
        transactions.reduce(0) { $0 + $1.amount }
    }
    
    var dailyAverage: Double {
        guard !transactions.isEmpty else { return 0.0 }
        let dates = transactions.map { Calendar.current.startOfDay(for: $0.date) }
        let uniqueDays = Set(dates).count
        return totalOutflow / Double(max(1, uniqueDays))
    }
    
    var topMerchants: [(merchant: String, total: Double, count: Int)] {
        var map: [String: (total: Double, count: Int)] = [:]
        for txn in transactions {
            let current = map[txn.merchant, default: (total: 0.0, count: 0)]
            map[txn.merchant] = (total: current.total + txn.amount, count: current.count + 1)
        }
        return map.map { (merchant: $0.key, total: $0.value.total, count: $0.value.count) }
            .sorted(by: { $0.total > $1.total })
    }
    
    var dailyTotals: [(dayLabel: String, amount: Double)] {
        let calendar = Calendar.current
        var map: [String: Double] = [:]
        
        let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        for day in daysOfWeek {
            map[day] = 0.0
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        
        for txn in transactions {
            let label = formatter.string(from: txn.date)
            if map[label] != nil {
                map[label]! += txn.amount
            }
        }
        
        return daysOfWeek.map { (dayLabel: $0, amount: map[$0] ?? 0.0) }
    }
    
    public var body: some View {
        ZStack {
            AppleTheme.mainBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Title Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Analytics & Trends")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(AppleTheme.textPrimary)
                            Text("Local Outflow Insights")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(AppleTheme.textMuted)
                        }
                        Spacer()
                        
                        KharchaPaniLogoView(size: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Daily Outflow Monoline Bar Chart
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("WEEKLY SPENDING PEAKS")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(AppleTheme.textMuted)
                                Text("Outflow Intensity")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppleTheme.textPrimary)
                            }
                            Spacer()
                        }
                        
                        let maxVal = max(1.0, dailyTotals.map { $0.amount }.max() ?? 1.0)
                        
                        HStack(alignment: .bottom, spacing: 12) {
                            ForEach(dailyTotals, id: \.dayLabel) { item in
                                VStack(spacing: 8) {
                                    GeometryReader { geo in
                                        VStack {
                                            Spacer()
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .fill(item.amount > 0 ? AppleTheme.accentRed : AppleTheme.tertiaryChip)
                                                .frame(height: max(6, geo.size.height * CGFloat(item.amount / maxVal)))
                                        }
                                    }
                                    
                                    Text(item.dayLabel)
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundColor(AppleTheme.textMuted)
                                }
                            }
                        }
                        .frame(height: 140)
                    }
                    .appleCardStyle(cornerRadius: 22)
                    .padding(.horizontal, 20)
                    
                    // Metrics Grid (Average Outflow & Highest Day)
                    HStack(spacing: 14) {
                        MetricBox(
                            title: "DAILY AVERAGE",
                            value: "₹\(dailyAverage, specifier: "%.2f")",
                            subtitle: "Per active logging day",
                            icon: "chart.line.uptrend.xyaxis"
                        )
                        
                        MetricBox(
                            title: "TOTAL RECORDED",
                            value: "₹\(totalOutflow, specifier: "%.2f")",
                            subtitle: "\(transactions.count) parsed items",
                            icon: "tray.full.fill"
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Top Merchant Rankings List
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Top Destination Ranking")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppleTheme.textPrimary)
                        
                        if topMerchants.isEmpty {
                            Text("No merchant data accumulated yet.")
                                .font(.system(size: 13))
                                .foregroundColor(AppleTheme.textMuted)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(Array(topMerchants.prefix(5).enumerated()), id: \.element.merchant) { index, item in
                                    HStack {
                                        Text("#\(index + 1)")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(AppleTheme.textMuted)
                                            .frame(width: 28)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.merchant)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(AppleTheme.textPrimary)
                                            Text("\(item.count) orders tracked")
                                                .font(.system(size: 12))
                                                .foregroundColor(AppleTheme.textMuted)
                                        }
                                        Spacer()
                                        
                                        Text("₹\(item.total, specifier: "%.2f")")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundColor(AppleTheme.textPrimary)
                                    }
                                    .padding(12)
                                    .background(AppleTheme.mainBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppleTheme.borderLine, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .appleCardStyle(cornerRadius: 22)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            loadAnalyticsData()
        }
    }
    
    private func loadAnalyticsData() {
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
        self.transactions = list
    }
}

struct MetricBox: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(AppleTheme.textMuted)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppleTheme.accentBlue)
            }
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppleTheme.textPrimary)
            
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(AppleTheme.textMuted)
        }
        .appleCardStyle(cornerRadius: 18)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(TransactionFileManager())
        .environmentObject(RegexRuleEngine())
}
