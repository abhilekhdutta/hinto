import ApplicationServices
import Cocoa

/// Decorator that collects performance data for statistical analysis
/// Outputs CSV format to /tmp/hinto-perf.csv
final class PerfScanner: ElementScanner {
    private let wrapped: ElementScanner
    private let name: String
    private static let perfFile = "/tmp/hinto-perf.csv"
    private static var initialized = false

    init(_ scanner: ElementScanner, name: String) {
        wrapped = scanner
        self.name = name
        Self.initializeFileIfNeeded()
    }

    func scan(context: ScanContext) -> [UIElement] {
        let start = CFAbsoluteTimeGetCurrent()
        let results = wrapped.scan(context: context)
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

        writePerf(timeMs: elapsed, elementCount: results.count)
        return results
    }

    private static func initializeFileIfNeeded() {
        guard !initialized else { return }
        initialized = true

        let header = "timestamp,scanner,time_ms,elements\n"
        guard let data = header.data(using: .utf8) else { return }
        FileManager.default.createFile(atPath: perfFile, contents: data)
    }

    private func writePerf(timeMs: Double, elementCount: Int) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "\(timestamp),\(name),\(String(format: "%.2f", timeMs)),\(elementCount)\n"

        guard let data = line.data(using: .utf8),
              let handle = FileHandle(forWritingAtPath: Self.perfFile) else { return }

        handle.seekToEndOfFile()
        handle.write(data)
        handle.closeFile()
    }
}
