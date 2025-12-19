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
            // Return empty array on first launch (no file exists)
            return []
        }
    }
    
    func save(_ docs: [TravelDocument]) {
        do {
            let data = try JSONEncoder().encode(docs)
            try data.write(to: fileURL)
        } catch {
            print("Error saving documents: \(error)")
        }
    }
}
