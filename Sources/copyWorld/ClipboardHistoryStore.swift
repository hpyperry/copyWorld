import Foundation

@MainActor
final class ClipboardHistoryStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []

    private let storage: ClipboardStorage
    private let maximumItems: Int

    init(storage: ClipboardStorage, maximumItems: Int = 30) {
        self.storage = storage
        self.maximumItems = maximumItems
        load()
    }

    func save(item: ClipboardItem, rtfData: Data? = nil, imageData: Data? = nil) {
        if let existingIndex = items.firstIndex(where: { $0.contentHash == item.contentHash }) {
            items.remove(at: existingIndex)
        }

        items.insert(item, at: 0)
        items = Array(items.prefix(maximumItems))
        persist(item: item, rtfData: rtfData, imageData: imageData)
    }

    func remove(itemID: UUID) {
        items.removeAll { $0.id == itemID }
        try? storage.delete(itemID: itemID)
    }

    func clear() {
        items.removeAll()
        try? storage.clearAll()
    }

    private func load() {
        items = storage.loadAllMetadata()
    }

    private func persist(item: ClipboardItem, rtfData: Data?, imageData: Data?) {
        do {
            try storage.save(item: item, rtfData: rtfData, imageData: imageData)
        } catch {
            assertionFailure("Failed to persist clipboard history: \(error)")
        }
    }
}
