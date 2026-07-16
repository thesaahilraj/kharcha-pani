import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var fileManager: TransactionFileManager
    @EnvironmentObject var regexEngine: RegexRuleEngine
    
    @State private var showingExportSheet = false
    @State private var exportText = ""
    @State private var showingOnboarding = false
    @State private var resyncMessage = ""
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AppleTheme.mainBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Settings & Utilities")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(AppleTheme.textPrimary)
                            Text("Storage & Pipeline Config")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(AppleTheme.textMuted)
                        }
                        Spacer()
                        
                        KharchaPaniLogoView(size: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Storage Health Container Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("LOCAL FILE SYSTEM PIPELINE")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(AppleTheme.textMuted)
                            Spacer()
                            Circle()
                                .fill(fileManager.metrics.exists ? AppleTheme.accentGreen : AppleTheme.accentRed)
                                .frame(width: 8, height: 8)
                                .shadow(color: (fileManager.metrics.exists ? AppleTheme.accentGreen : AppleTheme.accentRed).opacity(0.6), radius: 4)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            SettingMetricRow(
                                label: "DOCUMENT ENDPOINT",
                                value: fileManager.metrics.path.isEmpty ? "Not Initialized" : fileManager.metrics.path
                            )
                            
                            SettingMetricRow(
                                label: "FILE STATUS",
                                value: fileManager.metrics.exists ? "Active & Shared to Files App" : "Missing File"
                            )
                            
                            SettingMetricRow(
                                label: "FILE SIZE",
                                value: fileManager.metrics.formattedSize
                            )
                            
                            SettingMetricRow(
                                label: "TOTAL LOGGED LINES",
                                value: "\(fileManager.metrics.lineCount) JSON entries"
                            )
                        }
                        .padding(14)
                        .background(AppleTheme.mainBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppleTheme.borderLine, lineWidth: 1)
                        )
                    }
                    .appleCardStyle(cornerRadius: 22)
                    .padding(.horizontal, 20)
                    
                    // Data Utility Actions Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ledger Controls")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppleTheme.textPrimary)
                        
                        if !resyncMessage.isEmpty {
                            Text(resyncMessage)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(AppleTheme.accentGreen)
                        }
                        
                        Button(action: triggerResync) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Re-Sync Local Ledger")
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(AppleTheme.textPrimary)
                            .padding(14)
                            .background(AppleTheme.tertiaryChip)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppleTheme.borderLine, lineWidth: 1)
                            )
                        }
                        
                        Button(action: prepareExport) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export Raw JSONL Backup")
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(AppleTheme.textPrimary)
                            .padding(14)
                            .background(AppleTheme.tertiaryChip)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppleTheme.borderLine, lineWidth: 1)
                            )
                        }
                        
                        Button(action: { showingOnboarding = true }) {
                            HStack {
                                Image(systemName: "bolt.horizontal.fill")
                                Text("Review iOS Shortcut Setup")
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(AppleTheme.textPrimary)
                            .padding(14)
                            .background(AppleTheme.tertiaryChip)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppleTheme.borderLine, lineWidth: 1)
                            )
                        }
                    }
                    .glassCardStyle(cornerRadius: 22)
                    .padding(.horizontal, 20)
                    
                    // Embedded Regex Rules Engine Management Section
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("REGEX RULE ENGINE & PARSERS")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(AppleTheme.textMuted)
                            Spacer()
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(AppleTheme.accentBlue)
                        }
                        
                        Text("Configure local SMS merchant regex patterns, VPA mappings, and custom financial category overrides.")
                            .font(.system(size: 13))
                            .foregroundColor(AppleTheme.textMuted)
                        
                        NavigationLink(destination: RegexCustomizerView()) {
                            HStack {
                                Image(systemName: "gearshape.2.fill")
                                Text("Manage Custom Regex Rules")
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(AppleTheme.textPrimary)
                            .padding(14)
                            .background(AppleTheme.tertiaryChip)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppleTheme.borderLine, lineWidth: 1)
                            )
                        }
                    }
                    .glassCardStyle(cornerRadius: 22)
                    .padding(.horizontal, 20)
                    
                    // App Architecture Metadata Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("APP ENVIRONMENT")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(AppleTheme.textMuted)
                        
                        HStack {
                            Text("Kharcha Pani Version")
                                .font(.system(size: 14))
                                .foregroundColor(AppleTheme.textMuted)
                            Spacer()
                            Text("v1.0.0 (Open-Source)")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(AppleTheme.textPrimary)
                        }
                        
                        HStack {
                            Text("Info.plist Exposure")
                                .font(.system(size: 14))
                                .foregroundColor(AppleTheme.textMuted)
                            Spacer()
                            Text("UIFileSharingEnabled")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(AppleTheme.accentGreen)
                        }
                    }
                    .appleCardStyle(cornerRadius: 20)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            JSONLExportSheet(jsonText: exportText)
        }
        .sheet(isPresented: $showingOnboarding) {
            ShortcutOnboardingView()
        }
    }
    
    private func triggerResync() {
        fileManager.refreshMetrics()
        _ = fileManager.readJSONLines()
        withAnimation {
            resyncMessage = "✓ Local ledger re-indexed and synchronized."
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                resyncMessage = ""
            }
        }
    }
    
    private func prepareExport() {
        self.exportText = fileManager.exportRawJSONL()
        self.showingExportSheet = true
    }
}

struct SettingMetricRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(AppleTheme.textMuted)
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(AppleTheme.textPrimary)
                .lineLimit(2)
        }
    }
}

struct JSONLExportSheet: View {
    let jsonText: String
    @Environment(\.dismiss) var dismiss
    @State private var copied = false
    
    var body: some View {
        ZStack {
            AppleTheme.secondaryCard.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Raw transactional.jsonl Export")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(AppleTheme.textPrimary)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppleTheme.textMuted)
                    }
                }
                
                TextEditor(text: .constant(jsonText))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(AppleTheme.accentGreen)
                    .padding(8)
                    .background(AppleTheme.mainBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppleTheme.borderLine, lineWidth: 1)
                    )
                
                Button(action: copyToClipboard) {
                    HStack {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Export Content Copied" : "Copy Raw JSONL Text")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(copied ? .white : AppleTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(copied ? AppleTheme.accentGreen : AppleTheme.tertiaryChip)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppleTheme.borderLine, lineWidth: 1)
                    )
                }
            }
            .padding(20)
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = jsonText
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copied = false }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(TransactionFileManager())
        .environmentObject(RegexRuleEngine())
}
