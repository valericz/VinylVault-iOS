import Foundation
import UserNotifications

class PriceMonitorService {
    static let shared = PriceMonitorService()
    
    private init() {}
    
    func checkPrices() async {
        let items = DataManager.shared.wishlistItems
        
        for item in items where item.notificationEnabled {
            await checkPrice(for: item)
        }
    }
    
    private func checkPrice(for item: WishlistItem) async {
        guard let discogsId = item.discogsId else { return }
        
        do {
            let currentPrice = try await fetchCurrentPrice(discogsId: discogsId)
            
            var updatedItem = item
            updatedItem.currentPrice = currentPrice
            updatedItem.lastPriceCheck = Date()
            
            let pricePoint = PricePoint(date: Date(), price: currentPrice)
            updatedItem.priceHistory.append(pricePoint)
            
            DataManager.shared.updateWishlistItem(updatedItem)
            
            if currentPrice <= item.targetPrice {
                await sendPriceAlert(for: updatedItem)
            }
            
        } catch {
            print("❌ Failed to check price for \(item.albumTitle): \(error)")
        }
    }
    
    private func fetchCurrentPrice(discogsId: Int) async throws -> Double {
        #if DEBUG
        return Double.random(in: 20...50)
        #else
        return Double.random(in: 20...50)
        #endif
    }
    
    func sendPriceAlert(for item: WishlistItem) async {
        print("🔔 Sending notification for: \(item.albumTitle)")
        
        let content = UNMutableNotificationContent()
        content.title = "🎉 Price Alert!"
        content.subtitle = "\(item.albumTitle) - \(item.artist)"
        content.body = String(format: "Now $%.2f (Target: $%.2f)\nTime to grab it! 🎵",
                             item.currentPrice ?? 0,
                             item.targetPrice)
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: item.id.uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Notification added successfully")
        } catch {
            print("❌ Failed to add notification: \(error)")
        }
    }
}
