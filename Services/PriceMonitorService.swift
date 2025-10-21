//
//  PriceMonitorService.swift
//  VinylVault
//
//  Created by WEIHUA ZHANG on 22/10/2025.
//

import Foundation
import UserNotifications

class PriceMonitorService {
    static let shared = PriceMonitorService()
    
    private let discogsService = DiscogsService()
    
    func checkPrices() async {
        let items = DataManager.shared.wishlistItems
        
        for item in items where item.notificationEnabled {
            await checkPrice(for: item)
        }
    }
    
    private func checkPrice(for item: WishlistItem) async {
        guard let discogsId = item.discogsId else { return }
        
        do {
            // 获取当前价格（简化版，实际需要调用 Discogs Marketplace API）
            let currentPrice = try await fetchCurrentPrice(discogsId: discogsId)
            
            // 更新价格
            var updatedItem = item
            updatedItem.currentPrice = currentPrice
            updatedItem.lastPriceCheck = Date()
            
            // 添加到历史
            let pricePoint = PricePoint(date: Date(), price: currentPrice)
            updatedItem.priceHistory.append(pricePoint)
            
            DataManager.shared.updateWishlistItem(updatedItem)
            
            // 检查是否达到目标价格
            if currentPrice <= item.targetPrice {
                await sendPriceAlert(for: updatedItem)
            }
            
        } catch {
            print("❌ Failed to check price for \(item.albumTitle): \(error)")
        }
    }
    
    private func fetchCurrentPrice(discogsId: Int) async throws -> Double {
        // 简化版 - 实际需要调用 Discogs Marketplace API
        // 这里返回模拟价格
        return Double.random(in: 20...50)
    }
    
    private func sendPriceAlert(for item: WishlistItem) async {
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
        
        try? await UNUserNotificationCenter.current().add(request)
    }
}
