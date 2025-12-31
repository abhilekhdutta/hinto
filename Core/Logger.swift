import Foundation
import os

/// Unified logger for Hinto using Apple's os.Logger
/// Optionally writes to /tmp/hinto.log when enabled via hidden setting
public enum Log {
    private static let logger = Logger(subsystem: "dev.yhao3.hinto", category: "general")
    private static let logFile = "/tmp/hinto.log"

    /// Hidden setting key for file logging (enable via: defaults write dev.yhao3.hinto debug-file-logging -bool true)
    private static let fileLoggingKey = "debug-file-logging"

    /// Check if file logging is enabled (cached for performance)
    private static var isFileLoggingEnabled: Bool = UserDefaults.standard.bool(forKey: fileLoggingKey)

    public static func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
        writeToFileIfEnabled(message, level: "DEBUG")
    }

    public static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
        writeToFileIfEnabled(message, level: "INFO")
    }

    public static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
        writeToFileIfEnabled(message, level: "ERROR")
    }

    private static func writeToFileIfEnabled(_ message: String, level: String) {
        guard isFileLoggingEnabled else { return }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] [\(level)] \(message)\n"

        guard let data = line.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: logFile) {
            if let handle = FileHandle(forWritingAtPath: logFile) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        } else {
            FileManager.default.createFile(atPath: logFile, contents: data)
        }
    }

    /// Reload file logging setting (call after changing the setting)
    public static func reloadSettings() {
        isFileLoggingEnabled = UserDefaults.standard.bool(forKey: fileLoggingKey)
    }
}

/// Legacy log function for compatibility
/// Wraps os.Logger for unified logging
public func log(_ message: String) {
    Log.debug(message)
}
