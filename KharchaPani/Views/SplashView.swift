import SwiftUI

public struct SplashView: View {
    @EnvironmentObject var fileManager: TransactionFileManager
    @Binding var isInitialized: Bool
    @State private var showingFeedback = false
    @State private var statusMessage = ""
    
    public init(isInitialized: Binding<Bool>) {
        self._isInitialized = isInitialized
    }
    
    public var body: some View {
        ZStack {
            AppleTheme.mainBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Minimalist Emblem Header
                VStack(spacing: 20) {
                    KharchaPaniLogoView(size: 96)
                    
                    VStack(spacing: 8) {
                        Text("Kharcha Pani")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(AppleTheme.textPrimary)
                        
                        Text("Private SMS-automated expense ledger")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(AppleTheme.textMuted)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Core Feature Highlights Pill Card
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(
                        icon: "lock.shield.fill",
                        title: "100% Local Privacy",
                        subtitle: "No cloud servers, no banking logins, zero API trackers."
                    )
                    
                    FeatureRow(
                        icon: "bolt.horizontal.circle.fill",
                        title: "Hands-Free SMS Logging",
                        subtitle: "iOS Shortcuts append bank text messages directly."
                    )
                    
                    FeatureRow(
                        icon: "doc.text.magnifyingglass",
                        title: "On-Device Parsing",
                        subtitle: "Regex parsing engine converts bank SMS into structured records."
                    )
                }
                .appleCardStyle(cornerRadius: 22)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Initialization Action Footer
                VStack(spacing: 16) {
                    if showingFeedback {
                        Text(statusMessage)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(AppleTheme.accentGreen)
                            .transition(.opacity)
                    }
                    
                    Button(action: initializeSandbox) {
                        HStack {
                            Text("Initialize Local Sandbox")
                                .font(.system(size: 17, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [AppleTheme.accentBlue, Color(hex: "#0076E4")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: AppleTheme.accentBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 24)
                    
                    Text("Creates On My iPhone/KharchaPani/transactional.jsonl")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(AppleTheme.textMuted)
                }
                .padding(.bottom, 32)
            }
        }
    }
    
    private func initializeSandbox() {
        fileManager.initializeFilePlaceholderIfMissing()
        fileManager.seedSampleDataIfEmpty()
        
        withAnimation {
            statusMessage = "✓ Initialized transactional.jsonl successfully"
            showingFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                isInitialized = true
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppleTheme.accentBlue.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppleTheme.accentBlue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppleTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppleTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    SplashView(isInitialized: .constant(false))
        .environmentObject(TransactionFileManager())
}
