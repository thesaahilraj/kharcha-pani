import SwiftUI

@main
struct KharchaPaniApp: App {
    @StateObject private var fileManager = TransactionFileManager()
    @StateObject private var regexEngine = RegexRuleEngine()
    @AppStorage("isAppInitialized") private var isInitialized = false
    @State private var selectedTab = 0
    
    init() {
        // Enforce dark mode text contrast HIG compliance for titles
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(AppleTheme.textPrimary)]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(AppleTheme.textPrimary)]
        // Do NOT override UITabBar background to allow system Liquid Glass translucency
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !isInitialized {
                    SplashView(isInitialized: $isInitialized)
                        .environmentObject(fileManager)
                        .environmentObject(regexEngine)
                } else {
                    TabView(selection: $selectedTab) {
                        ExpenseDashboardView()
                            .tabItem {
                                Image(systemName: "square.grid.2x2")
                                Text("Dashboard")
                            }
                            .tag(0)
                        
                        AnalyticsView()
                            .tabItem {
                                Image(systemName: "chart.pie")
                                Text("Analytics")
                            }
                            .tag(1)
                        
                        TransactionLedgerView()
                            .tabItem {
                                Image(systemName: "doc.plaintext")
                                Text("Ledger")
                            }
                            .tag(2)
                        
                        SettingsView()
                            .tabItem {
                                Image(systemName: "gearshape")
                                Text("Settings")
                            }
                            .tag(3)
                    }
                    .tint(AppleTheme.accentBlue)
                    .environmentObject(fileManager)
                    .environmentObject(regexEngine)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
