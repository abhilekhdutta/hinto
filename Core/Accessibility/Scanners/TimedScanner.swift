import ApplicationServices
import Cocoa

/// Decorator that measures scan execution time (AOP-style)
final class TimedScanner: ElementScanner {
    private let wrapped: ElementScanner
    private let name: String

    init(_ scanner: ElementScanner, name: String) {
        wrapped = scanner
        self.name = name
    }

    func scan(context: ScanContext) -> [UIElement] {
        let start = CFAbsoluteTimeGetCurrent()
        let results = wrapped.scan(context: context)
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

        log("⏱ \(name): \(String(format: "%.1f", elapsed))ms (\(results.count) elements)")
        return results
    }
}
