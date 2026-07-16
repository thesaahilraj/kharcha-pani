import SwiftUI

public struct ShortcutOnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("isShortcutAdded") private var isShortcutAdded = false
    @State private var copiedToClipboard = false
    @State private var currentStep = 0
    @State private var showRequirementAlert = false
    var onComplete: (() -> Void)? = nil
    
    let steps: [(step: String, title: String, description: String, icon: String, codeSnippet: String?)] = [
        (
            step: "STEP 1 OF 3 • TAP TO ADD",
            title: "Create Message Trigger",
            description: "Open iOS Shortcuts -> Automations tab -> Create Personal Automation. Select Message: When message contains 'debited' OR 'spent' OR 'UPI'.",
            icon: "message.fill",
            codeSnippet: nil
        ),
        (
            step: "STEP 2 OF 3 • TAP TO ADD",
            title: "Enable Immediate Execution",
            description: "Uncheck 'Ask Before Running' and select 'Run Immediately' to ensure background hands-free transactional text logging.",
            icon: "bolt.fill",
            codeSnippet: nil
        ),
        (
            step: "STEP 3 OF 3 • TAP TO ADD",
            title: "Append JSON Line File",
            description: "Format current date as ISO8601 and append the JSON line block to On My iPhone/KharchaPani/transactional.jsonl.",
            icon: "doc.text.fill",
            codeSnippet: "{\"date\":\"[ISO_Date]\",\"sender\":\"[Sender]\",\"body\":\"[Body]\"}"
        )
    ]
    
    public init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        ZStack {
            AppleTheme.mainBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Navigation Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("iOS Automation Setup")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AppleTheme.textPrimary)
                        Text("3-Step Hands-Free Pipeline")
                            .font(.system(size: 13))
                            .foregroundColor(AppleTheme.textMuted)
                    }
                    Spacer()
                    
                    KharchaPaniLogoView(size: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Carousel Step Indicator
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { idx in
                        Capsule()
                            .fill(idx == currentStep ? AppleTheme.accentBlue : AppleTheme.tertiaryChip)
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 20)
                
                // Step Carousel Card (Tappable Tile Action)
                TabView(selection: $currentStep) {
                    ForEach(0..<steps.count, id: \.self) { idx in
                        Button(action: copyShortcutPayload) {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text(steps[idx].step)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(AppleTheme.accentBlue.opacity(0.15))
                                        .foregroundColor(AppleTheme.accentBlue)
                                        .cornerRadius(8)
                                    Spacer()
                                    Image(systemName: steps[idx].icon)
                                        .font(.system(size: 26))
                                        .foregroundColor(AppleTheme.accentBlue)
                                }
                                
                                Text(steps[idx].title)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(AppleTheme.textPrimary)
                                
                                Text(steps[idx].description)
                                    .font(.system(size: 15))
                                    .foregroundColor(AppleTheme.textMuted)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                if let snippet = steps[idx].codeSnippet {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("LINE FORMAT:")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(AppleTheme.textMuted)
                                        Text(snippet)
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(AppleTheme.accentGreen)
                                            .padding(12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(AppleTheme.mainBackground)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(AppleTheme.borderLine, lineWidth: 1)
                                            )
                                    }
                                    .padding(.top, 8)
                                }
                                
                                Spacer()
                            }
                            .glassCardStyle(cornerRadius: 24)
                            .padding(.horizontal, 20)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .tag(idx)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Requirement Warning Banner & Action Controls
                VStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: isShortcutAdded ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(isShortcutAdded ? AppleTheme.accentGreen : AppleTheme.accentOrange)
                        Text(isShortcutAdded ? "iOS Shortcut Registered & Copied" : "Shortcut required: Tap tile or button to add")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(isShortcutAdded ? AppleTheme.accentGreen : AppleTheme.accentOrange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background((isShortcutAdded ? AppleTheme.accentGreen : AppleTheme.accentOrange).opacity(0.12))
                    .cornerRadius(8)
                    
                    Button(action: copyShortcutPayload) {
                        HStack {
                            Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                            Text(copiedToClipboard ? "Shortcut Copied & Shortcuts Opened!" : "Copy & Open iOS Shortcuts")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(copiedToClipboard ? .white : AppleTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(copiedToClipboard ? AppleTheme.accentGreen : AppleTheme.tertiaryChip)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppleTheme.borderLine, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Button(action: finishOnboarding) {
                        Text("Go to Expense Dashboard")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: isShortcutAdded ? [AppleTheme.accentBlue, Color(hex: "#0076E4")] : [Color.gray, Color.gray.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(16)
                            .opacity(isShortcutAdded ? 1.0 : 0.45)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    private func copyShortcutPayload() {
        let template = """
        Kharcha Pani iOS Personal Automation Payload Template:
        Format Date: ISO8601
        Line Format: {"date":"shortcut_date","sender":"shortcut_sender","body":"shortcut_body"}
        Target Path: On My iPhone/KharchaPani/transactional.jsonl
        """
        UIPasteboard.general.string = template
        withAnimation {
            copiedToClipboard = true
            isShortcutAdded = true
        }
        
        #if canImport(UIKit)
        if let shortcutsURL = URL(string: "shortcuts://"), UIApplication.shared.canOpenURL(shortcutsURL) {
            UIApplication.shared.open(shortcutsURL)
        }
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copiedToClipboard = false
            }
        }
    }
    
    private func finishOnboarding() {
        guard isShortcutAdded else {
            showRequirementAlert = true
            return
        }
        if let onComplete = onComplete {
            onComplete()
        } else {
            dismiss()
        }
    }
}

#Preview {
    ShortcutOnboardingView()
}
