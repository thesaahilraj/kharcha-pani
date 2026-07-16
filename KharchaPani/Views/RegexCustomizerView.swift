import SwiftUI

public struct RegexCustomizerView: View {
    @EnvironmentObject var regexEngine: RegexRuleEngine
    
    // Live Test State
    @State private var testSMSText = "Alert: Spent Rs.450.00 via UPI to Swiggy@HDFC on 16-07-26."
    @State private var testPattern = "(?:to|vpa|spent on)\\s+([^\\s]+)"
    @State private var testResult: String? = nil
    
    // Add Rule Modal State
    @State private var showingAddModal = false
    @State private var newPattern = ""
    @State private var newMerchant = ""
    @State private var newCategory = "Food & Dining"
    
    let categoryOptions = ["Food & Dining", "Transport", "Shopping", "Miscellaneous"]
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AppleTheme.mainBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Title Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Regex Rule Engine")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(AppleTheme.textPrimary)
                            Text("Custom Parsing Overrides")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(AppleTheme.textMuted)
                        }
                        Spacer()
                        
                        KharchaPaniLogoView(size: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Live Playground Regex Tester Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("LIVE REGEX TESTER")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(AppleTheme.textMuted)
                            Spacer()
                            Image(systemName: "terminal.fill")
                                .foregroundColor(AppleTheme.accentBlue)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Sample Bank SMS:")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppleTheme.textPrimary)
                            TextEditor(text: $testSMSText)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(AppleTheme.textPrimary)
                                .frame(height: 54)
                                .padding(6)
                                .background(AppleTheme.mainBackground)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppleTheme.borderLine, lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Regex Group Pattern:")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppleTheme.textPrimary)
                            TextField("Enter regex with (group)", text: $testPattern)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(AppleTheme.accentBlue)
                                .padding(12)
                                .background(AppleTheme.mainBackground)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppleTheme.borderLine, lineWidth: 1)
                                )
                        }
                        
                        Button(action: runLiveTest) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Execute Test Pattern")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(AppleTheme.tertiaryChip)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppleTheme.borderLine, lineWidth: 1)
                            )
                        }
                        
                        if let res = testResult {
                            HStack {
                                Text("Extracted Group:")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(AppleTheme.textMuted)
                                Text(res.isEmpty ? "No match found" : "\"\(res)\"")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(res.isEmpty ? AppleTheme.accentRed : AppleTheme.accentGreen)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppleTheme.mainBackground)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppleTheme.borderLine, lineWidth: 1)
                            )
                        }
                    }
                    .appleCardStyle(cornerRadius: 22)
                    .padding(.horizontal, 20)
                    
                    // Rules List Section
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Active Mapping Rules")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(AppleTheme.textPrimary)
                            Spacer()
                            Button(action: { showingAddModal = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("Add Rule")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(AppleTheme.accentBlue)
                                .cornerRadius(14)
                            }
                        }
                        
                        if regexEngine.customRules.isEmpty {
                            Text("No custom rules configured yet.")
                                .font(.system(size: 13))
                                .foregroundColor(AppleTheme.textMuted)
                                .padding(.vertical, 12)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(regexEngine.customRules) { rule in
                                    RuleRow(rule: rule, onToggle: {
                                        regexEngine.toggleRule(id: rule.id)
                                    }, onDelete: {
                                        regexEngine.deleteRule(id: rule.id)
                                    })
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
        .sheet(isPresented: $showingAddModal) {
            AddRuleModal(
                newPattern: $newPattern,
                newMerchant: $newMerchant,
                newCategory: $newCategory,
                categoryOptions: categoryOptions,
                onSave: {
                    regexEngine.addRule(pattern: newPattern, merchant: newMerchant, category: newCategory)
                    newPattern = ""
                    newMerchant = ""
                    showingAddModal = false
                }
            )
        }
        .onAppear {
            runLiveTest()
        }
    }
    
    private func runLiveTest() {
        let result = regexEngine.testPattern(testPattern, in: testSMSText)
        self.testResult = result ?? ""
    }
}

struct RuleRow: View {
    let rule: RegexRule
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rule.mappedMerchant)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppleTheme.textPrimary)
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { rule.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: AppleTheme.accentGreen))
            }
            
            Text("PATTERN: \(rule.pattern)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(AppleTheme.accentBlue)
            
            HStack {
                Text("CATEGORY: \(rule.targetCategory)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(AppleTheme.textMuted)
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(AppleTheme.accentRed)
                }
            }
        }
        .padding(14)
        .background(AppleTheme.mainBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppleTheme.borderLine, lineWidth: 1)
        )
    }
}

struct AddRuleModal: View {
    @Binding var newPattern: String
    @Binding var newMerchant: String
    @Binding var newCategory: String
    let categoryOptions: [String]
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppleTheme.secondaryCard.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Add Custom Parsing Rule")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(AppleTheme.textPrimary)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppleTheme.textMuted)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Merchant Shortcode Pattern (Regex):")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppleTheme.textPrimary)
                    TextField("e.g. (?:SWG|Swiggy)\\s*([A-Za-z0-9]+)", text: $newPattern)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(AppleTheme.textPrimary)
                        .padding(12)
                        .background(AppleTheme.mainBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppleTheme.borderLine, lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Mapped Clean Merchant Name:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppleTheme.textPrimary)
                    TextField("e.g. Swiggy Food", text: $newMerchant)
                        .font(.system(size: 14))
                        .foregroundColor(AppleTheme.textPrimary)
                        .padding(12)
                        .background(AppleTheme.mainBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppleTheme.borderLine, lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Target Category:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppleTheme.textPrimary)
                    
                    Picker("Category", selection: $newCategory) {
                        ForEach(categoryOptions, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Spacer()
                
                Button(action: onSave) {
                    Text("Save Rule")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [AppleTheme.accentBlue, Color(hex: "#0076E4")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(16)
                }
                .disabled(newPattern.isEmpty || newMerchant.isEmpty)
            }
            .padding(20)
        }
    }
}

#Preview {
    RegexCustomizerView()
        .environmentObject(RegexRuleEngine())
}
