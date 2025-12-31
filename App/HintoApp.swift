import Cocoa

// Use traditional AppKit app lifecycle for menu bar apps
@main
struct HintoApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
