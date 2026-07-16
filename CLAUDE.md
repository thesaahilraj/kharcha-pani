# Kharcha Pani

Local-only iOS expense tracker. Parses bank SMS on-device — no backend, no third-party dependencies.

## Architecture

An iOS Shortcut automation (not app code) watches for bank SMS and appends JSON lines to `On My iPhone/KharchaPani/transactional.jsonl`, which the app's Documents directory exposes via `UIFileSharingEnabled` in `Info.plist`. The app reads/parses that file locally — see README.md for the full pipeline and line format.

## Layout

- `KharchaPani/Models/Models.swift` — `RawTransactionLine` (raw JSONL schema) and parsed transaction types.
- `KharchaPani/Services/TransactionFileManager.swift` — reads/writes `transactional.jsonl`.
- `KharchaPani/Services/TransactionParser.swift` — default regex rules (amount, merchant, payment type).
- `KharchaPani/Services/RegexRuleEngine.swift` — user-defined regex rule overrides.
- `KharchaPani/Views/` — SwiftUI screens (dashboard, analytics, ledger, regex customizer, settings).
- `web/` — dependency-free HTML/CSS/JS mirror of the parser + UI for browser testing without Xcode.

## Conventions

- No networking code and no third-party dependencies — keep it that way; this is the app's core privacy guarantee.
- Transaction de-duplication is by hash of `date + sender + body` — preserve this when touching the parsing pipeline.
- `AGENTS.md` and `DESIGN.md` are AI-tool planning artifacts, gitignored — don't treat them as source of truth over the actual code.
