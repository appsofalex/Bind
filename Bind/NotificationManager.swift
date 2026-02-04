import Foundation
import UserNotifications
import SwiftUI
internal import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    print("Notification permission granted.")
                } else if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func scheduleExpiryNotifications(for documents: [TravelDocument]) {
        // Only schedule if Pro
        guard SubscriptionManager.shared.isPro else { return }
        
        // Clear existing to avoid duplicates/stale alerts
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        for doc in documents {
            guard let expiryDate = doc.expiryDate else { continue }
            
            // Check if document is still valid
            if expiryDate > Date() {
                scheduleNotification(for: doc, monthsBefore: 6)
                scheduleNotification(for: doc, monthsBefore: 3)
                scheduleNotification(for: doc, monthsBefore: 1)
            }
        }
    }
    
    private func scheduleNotification(for doc: TravelDocument, monthsBefore: Int) {
        guard let alertDate = Calendar.current.date(byAdding: .month, value: -monthsBefore, to: doc.expiryDate!) else { return }
        
        // Don't schedule if the alert date is in the past
        if alertDate < Date() { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Document Expiry Alert"
        content.body = "Your \(doc.type.displayName.lowercased()) expires in \(monthsBefore) month\(monthsBefore > 1 ? "s" : ""). Time to renew!"
        content.sound = .default
        
        // Create trigger
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let id = "\(doc.id.uuidString)-\(monthsBefore)m"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Scheduled alert for \(doc.title) on \(alertDate)")
            }
        }
    }
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
