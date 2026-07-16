<div align="center">

# Kharcha Pani (खर्चा पानी)

**A local-only iOS expense tracker that reads bank SMS on-device — no servers, no accounts, no analytics.**

[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-lightgrey)](#building)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](#building)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

</div>

---

iOS doesn't let third-party apps read the SMS inbox. Kharcha Pani works around that with a native iOS Shortcut instead of a background service: a Personal Automation fires on incoming bank SMS and appends each message as a JSON line to a file shared with the app through the Files app. The app watches that file and parses everything locally — nothing ever leaves the device.

```
Bank SMS -> iOS Shortcuts Automation -> transactional.jsonl (Files app) -> Kharcha Pani parses locally
```

## Features

- **On-device only** — no networking code, no analytics, no third-party dependencies.
- **Automated capture** — an iOS Shortcut logs bank SMS without you lifting a finger.
- **Regex-based parsing** — extracts merchant, amount, and payment method (UPI, debit, credit) from raw SMS text.
- **Custom rules** — teach it your own merchants (e.g. map `*SWG*` to Swiggy) from inside the app.
- **Dashboard & analytics** — spending totals, category breakdown, and daily trends.
- **Web simulator** — a dependency-free HTML/JS build of the parser and UI for testing without Xcode.

## How it works

1. An iOS Shortcut automation fires on incoming SMS matching bank keywords (`debited`, `spent`, `UPI`, etc.) and appends a JSON line to `On My iPhone/KharchaPani/transactional.jsonl`.
2. The app reads that file, de-duplicates entries by a hash of date/sender/body, and runs them through a regex parser to extract merchant, amount, and payment method.
3. Parsed transactions populate the dashboard, analytics, and ledger views.
4. You can add your own regex rules for merchants the default patterns miss.

## Line format

Each line in `transactional.jsonl` is a standalone JSON object:

```json
{"date": "ISO8601 timestamp", "sender": "string", "body": "string"}
```

Examples:

```json
{"date":"2026-07-15T10:15:30Z","sender":"DZ-HDFCBK","body":"Alert: Spent Rs.500.00 via UPI to Swiggy@HDFC on 15-07-26. Not you? Call bank."}
{"date":"2026-07-15T14:30:00Z","sender":"AX-AxisBk","body":"Txn: Rs.1200.00 debited from card ending 4321 at Petrol Pump Patna."}
{"date":"2026-07-15T18:45:00Z","sender":"IM-ICICIB","body":"Spent Rs 350.00 via UPI to Blinkit on 15-07-26."}
```

## App screens

| Screen | Purpose |
| --- | --- |
| Splash & Setup | First-run onboarding, initializes the local directory structure. |
| Shortcuts Guide | Walks through setting up the iOS Shortcut automation. |
| Dashboard | Total outflow, category breakdown, recent activity. |
| Analytics | Daily spending trend and top merchants. |
| Ledger | Searchable transaction history with payment-method filters. |
| Regex Customizer | Add or test custom parsing rules for specific merchants. |
| Settings | File diagnostics, data export, storage stats. |

## Getting started

### iOS app

Requires Xcode 15+ and iOS 17+.

```bash
git clone https://github.com/thesaahilraj/kharcha-pani.git
cd kharcha-pani
open KharchaPani.xcodeproj
```

Build and run the `KharchaPani` target (`Cmd+R`). The app declares `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` in `Info.plist` so its Documents directory is visible in the Files app.

### iOS Shortcut

1. Open **Shortcuts** → **Automation** → **New Automation**.
2. Choose **Message** as the trigger, with criteria matching bank SMS content (`debited`, `spent`, `UPI`).
3. Enable **Run Immediately** and disable **Ask Before Running**.
4. Build the action pipeline:
   - Get **Current Date**, format as ISO8601.
   - Create a **Text** block: `{"date":"[Formatted Date]","sender":"[Sender]","body":"[Message Body]"}`
   - **Append to File** → `On My iPhone/KharchaPani/transactional.jsonl`.

### Web simulator

Try the parser and UI in a browser, no Xcode required:

```bash
npx -y http-server web -o
```

Or just open `web/index.html` directly.

## Project structure

```
KharchaPani/
├── KharchaPaniApp.swift          # App entry point, tab navigation
├── Info.plist                    # File sharing configuration
├── Models/
│   └── Models.swift               # Transaction data models
├── Services/
│   ├── TransactionFileManager.swift  # JSONL reading/watching
│   ├── TransactionParser.swift       # Default regex parsing rules
│   └── RegexRuleEngine.swift         # User-defined regex rules
└── Views/
    ├── SplashView.swift
    ├── ShortcutOnboardingView.swift
    ├── ExpenseDashboardView.swift
    ├── AnalyticsView.swift
    ├── TransactionLedgerView.swift
    ├── RegexCustomizerView.swift
    ├── SettingsView.swift
    ├── Theme.swift
    └── Components/
        └── KharchaPaniLogoView.swift

web/
├── index.html
├── styles.css
└── app.js
```

## Privacy

No networking code, no analytics, no third-party dependencies — just Swift/SwiftUI and Foundation. All parsing happens on-device. Delete `transactional.jsonl` from the Files app at any time to remove all data.

## Contributing

1. Fork the repo and create a feature branch.
2. Make your changes with clear, focused commits.
3. Open a pull request describing what changed and why.

## License

MIT — see [LICENSE](LICENSE).
