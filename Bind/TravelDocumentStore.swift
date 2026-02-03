import Foundation

// Manages saving and loading from the Documents directory
class TravelDocumentStore {
    static let shared = TravelDocumentStore()
    private let fileName = "travel_docs_v1.json"
    
    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    }
    
    func load() -> [TravelDocument] {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([TravelDocument].self, from: data)
            return decoded
        } catch {
            return []
        }
    }
    
    func save(_ docs: [TravelDocument]) {
        do {
            let data = try JSONEncoder().encode(docs)
            try data.write(to: fileURL)
            
            // Trigger Cloud Sync if Pro
            if SubscriptionManager.shared.isPro {
                syncToCloud(data)
            }
        } catch {
            print("Error saving documents: \(error)")
        }
    }
    
    private func syncToCloud(_ data: Data) {
        // TODO: Implement CloudKit or iCloud Drive sync here
        // This is where you would push the updated JSON to the user's private CloudKit database
        print("Pro Feature: Syncing \(data.count) bytes to iCloud...")
    }
}
