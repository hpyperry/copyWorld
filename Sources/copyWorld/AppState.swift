import Foundation

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    let historyStore: ClipboardHistoryStore
    let monitor: ClipboardMonitor
    let launchAtLoginManager: LaunchAtLoginManager

    private init() {
        let historyStore = ClipboardHistoryStore(maximumItems: 30)
        self.historyStore = historyStore
        self.monitor = ClipboardMonitor(historyStore: historyStore)
        self.launchAtLoginManager = LaunchAtLoginManager()
        self.monitor.start()
    }
}
