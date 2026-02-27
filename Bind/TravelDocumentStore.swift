import Foundation

// Manages saving and loading from the Documents directory (and iCloud when Pro)
class TravelDocumentStore {
    static let shared = TravelDocumentStore()
    private let fileName = "travel_docs_v1.json"
    
    /// Must match the iCloud container in Signing & Capabilities.
    private let iCloudContainerID = "iCloud.com.AlexCo.Bind"
    
    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    }
    
    /// URL for the same file in the iCloud ubiquity container (nil if iCloud unavailable).
    private var cloudFileURL: URL? {
        guard let base = FileManager.default.url(forUbiquityContainerIdentifier: iCloudContainerID) else { return nil }
        return base.appendingPathComponent("Documents").appendingPathComponent(fileName)
    }
    
    func load() -> [TravelDocument] {
        if SubscriptionManager.shared.isPro, let cloudURL = cloudFileURL, FileManager.default.fileExists(atPath: cloudURL.path) {
            return load(from: cloudURL) ?? load(from: fileURL) ?? []
        }
        return load(from: fileURL) ?? []
    }
    
    private func load(from url: URL) -> [TravelDocument]? {
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([TravelDocument].self, from: data)
            return decoded
        } catch {
            return nil
        }
    }
    
    func save(_ docs: [TravelDocument]) {
        do {
            let data = try JSONEncoder().encode(docs)
            try data.write(to: fileURL)
            
            if SubscriptionManager.shared.isPro {
                syncToCloud(data)
                NotificationManager.shared.scheduleExpiryNotifications(for: docs)
            }
        } catch {
            print("Error saving documents: \(error)")
        }
    }
    
    private func syncToCloud(_ data: Data) {
        guard let url = cloudFileURL else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let dir = url.deletingLastPathComponent()
                if !FileManager.default.fileExists(atPath: dir.path) {
                    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                }
                try data.write(to: url)
            } catch {
                print("Cloud sync failed: \(error)")
            }
        }
    }
}
