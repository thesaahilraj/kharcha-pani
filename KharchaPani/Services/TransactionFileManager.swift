import Foundation
import Combine

public class TransactionFileManager: ObservableObject {
    @Published public var rawLines: [RawTransactionLine] = []
    @Published public var metrics: FileSystemMetrics = FileSystemMetrics(path: "", exists: false, sizeInBytes: 0, lineCount: 0, lastModified: nil)
    
    public var fileURL: URL? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent("transactional.jsonl")
    }
    
    public init() {
        initializeFilePlaceholderIfMissing()
        refreshMetrics()
    }
    
    /// Initializes placeholder file under Documents directory if it does not already exist
    public func initializeFilePlaceholderIfMissing() {
        guard let url = fileURL else { return }
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try "".write(to: url, atomically: true, encoding: .utf8)
                print("[FileSys] Initialized transactional.jsonl successfully at \(url.path)")
            } catch {
                print("[FileSys] Error creating layout structure: \(error)")
            }
        }
        refreshMetrics()
    }
    
    /// Reads and parses all line-delimited JSON entries from transactional.jsonl
    public func readJSONLines() -> [RawTransactionLine] {
        guard let url = fileURL else { return [] }
        var entries: [RawTransactionLine] = []
        
        do {
            let fileContent = try String(contentsOf: url, encoding: .utf8)
            let lines = fileContent.components(separatedBy: .newlines)
            let decoder = JSONDecoder()
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty { continue }
                if let data = trimmed.data(using: .utf8),
                   let entry = try? decoder.decode(RawTransactionLine.self, from: data) {
                    entries.append(entry)
                }
            }
            self.rawLines = entries
            refreshMetrics()
        } catch {
            print("[FileSys] Read failure: \(error.localizedDescription)")
        }
        
        return entries
    }
    
    /// Appends a new RawTransactionLine to the transactional.jsonl file
    public func appendTransaction(line: RawTransactionLine) -> Bool {
        guard let url = fileURL else { return false }
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(line),
              let jsonString = String(data: data, encoding: .utf8) else {
            return false
        }
        
        let appendLine = jsonString + "\n"
        if let fileHandle = try? FileHandle(forWritingTo: url) {
            fileHandle.seekToEndOfFile()
            if let dataToAppend = appendLine.data(using: .utf8) {
                fileHandle.write(dataToAppend)
            }
            fileHandle.closeFile()
            refreshMetrics()
            return true
        } else {
            // If file doesn't exist, create it with content
            do {
                try appendLine.write(to: url, atomically: true, encoding: .utf8)
                refreshMetrics()
                return true
            } catch {
                print("[FileSys] Write error: \(error)")
                return false
            }
        }
    }
    
    /// Seeds realistic initial bank transaction samples for first launch / demo mode
    public func seedSampleDataIfEmpty() {
        guard let url = fileURL else { return }
        let currentLines = readJSONLines()
        if !currentLines.isEmpty { return }
        
        let now = Date()
        let formatter = ISO8601DateFormatter()
        
        let samples: [RawTransactionLine] = [
            RawTransactionLine(
                date: formatter.string(from: now.addingTimeInterval(-3600 * 2)),
                sender: "DZ-HDFCBK",
                body: "Alert: Spent Rs.450.00 via UPI to Swiggy@HDFC on 16-07-26. Not you? Call bank."
            ),
            RawTransactionLine(
                date: formatter.string(from: now.addingTimeInterval(-3600 * 14)),
                sender: "AX-AxisBk",
                body: "Txn: Rs.2100.00 debited from card ending 4321 at Petrol Pump Patna."
            ),
            RawTransactionLine(
                date: formatter.string(from: now.addingTimeInterval(-3600 * 28)),
                sender: "VK-ICICIB",
                body: "Debit: INR 1299.00 paid for Swiggy Order via UPI VPA swiggy@icici."
            ),
            RawTransactionLine(
                date: formatter.string(from: now.addingTimeInterval(-3600 * 48)),
                sender: "AD-SBIINB",
                body: "Dear Customer, your A/C XXXXX1234 has been debited by Rs 3499.00 on 14-Jul-26 info: Flipkart Internet."
            ),
            RawTransactionLine(
                date: formatter.string(from: now.addingTimeInterval(-3600 * 72)),
                sender: "DZ-HDFCBK",
                body: "Alert: Spent Rs.380.00 via UPI to Uber Rides on 13-07-26."
            ),
            RawTransactionLine(
                date: formatter.string(from: now.addingTimeInterval(-3600 * 96)),
                sender: "AX-AxisBk",
                body: "Txn: Rs.650.00 debited from Credit Card ending 8812 at Blinkit Commerce."
            ),
            RawTransactionLine(
                date: formatter.string(from: now.addingTimeInterval(-3600 * 120)),
                sender: "VK-ICICIB",
                body: "Spent Rs.6800.00 on ICICI Bank Credit Card ending 9011 at Myntra Fashion."
            )
        ]
        
        for sample in samples {
            _ = appendTransaction(line: sample)
        }
        _ = readJSONLines()
    }
    
    /// Reads complete content of transactional.jsonl as raw text for export
    public func exportRawJSONL() -> String {
        guard let url = fileURL else { return "" }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }
    
    /// Updates storage metrics
    public func refreshMetrics() {
        guard let url = fileURL else { return }
        let path = url.path
        let exists = FileManager.default.fileExists(atPath: path)
        var size: Int64 = 0
        var linesCount = 0
        var modDate: Date? = nil
        
        if exists {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: path) {
                size = attrs[.size] as? Int64 ?? 0
                modDate = attrs[.modificationDate] as? Date
            }
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                linesCount = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
            }
        }
        
        DispatchQueue.main.async {
            self.metrics = FileSystemMetrics(
                path: path,
                exists: exists,
                sizeInBytes: size,
                lineCount: linesCount,
                lastModified: modDate
            )
        }
    }
}
