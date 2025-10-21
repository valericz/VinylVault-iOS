//
//  WishlistView.swift
//  VinylVault
//
//  Created by WEIHUA ZHANG on 22/10/2025.
//

import SwiftUI

struct WishlistView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var showingAddSheet = false
    @State private var showingTestAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: "1a1a1a"), Color(hex: "2d2d2d")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if dataManager.wishlistItems.isEmpty {
                    emptyStateView
                } else {
                    wishlistContent
                }
            }
            .navigationTitle("💭 Wishlist")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                
                #if DEBUG
                // 测试按钮（只在 DEBUG 模式显示）
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { testPriceAlert() }) {
                        HStack {
                            Image(systemName: "bell.badge")
                            Text("Test")
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingAddSheet) {
                AddToWishlistView()
            }
            .alert("🎉 Test Notification Sent!", isPresented: $showingTestAlert) {
                Button("OK") { }
            } message: {
                Text("Check your notification! In real use, this happens automatically when prices drop.")
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Your Wishlist is Empty")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Add albums you want to buy\nand set target prices")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Button(action: { showingAddSheet = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your First Album")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(.top)
        }
    }
    
    // MARK: - Wishlist Content
    private var wishlistContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 统计卡片
                HStack(spacing: 12) {
                    WishlistStatCard(
                        icon: "🎵",
                        title: "Watching",
                        value: "\(dataManager.wishlistItems.count)"
                    )
                    
                    WishlistStatCard(
                        icon: "🎉",
                        title: "Price Reached",
                        value: "\(dataManager.wishlistWithPriceReached.count)"
                    )
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // 心愿单列表
                ForEach(dataManager.wishlistItems) { item in
                    WishlistItemRow(item: item)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Test Price Alert (演示用)
    private func testPriceAlert() {
        guard let firstItem = dataManager.wishlistItems.first else {
            print("⚠️ No items in wishlist to test")
            return
        }
        
        // 模拟价格达到目标
        var testItem = firstItem
        testItem.currentPrice = firstItem.targetPrice - 2  // 比目标价低$2
        
        // 发送测试通知
        Task {
            await PriceMonitorService.shared.sendPriceAlert(for: testItem)
            
            // 更新数据（模拟价格变化）
            await MainActor.run {
                dataManager.updateWishlistItem(testItem)
                showingTestAlert = true
            }
        }
    }
}

// MARK: - Stat Card (小统计卡片)
struct WishlistStatCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

#Preview {
    WishlistView()
}
