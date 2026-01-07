import Foundation

/// Registry of scanner decorators - add new decorators here (OCP compliant)
enum ScannerDecoratorRegistry {
    typealias DecoratorFactory = (ElementScanner, String) -> ElementScanner

    /// Registered decorators: (UserDefaults key, factory)
    /// To add a new decorator, just append to this array
    private static let decorators: [(key: String, factory: DecoratorFactory)] = [
        ("debug-timing", { TimedScanner($0, name: $1) }),
        ("debug-perf", { PerfScanner($0, name: $1) }),
    ]

    /// Wrap a scanner with all enabled decorators
    static func wrap(_ scanner: ElementScanner, name: String) -> ElementScanner {
        decorators
            .filter { UserDefaults.standard.bool(forKey: $0.key) }
            .reduce(scanner) { wrapped, decorator in
                decorator.factory(wrapped, name)
            }
    }
}
