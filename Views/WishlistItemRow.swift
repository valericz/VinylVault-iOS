//
//  WishlistItemRow.swift
//  VinylVault
//
//  Created by WEIHUA ZHANG on 22/10/2025.
//

import SwiftUI

struct WishlistItemRow: View {
    let item: WishlistItem
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // album cover
                if let image = item.coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.3))
                        )
                }
                
                // album info
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.albumTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(item.artist)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // pricecomparison
                    priceComparisonView
                }
                
                Spacer()
            }
            .padding()
            
            // button
            HStack(spacing: 12) {
                // notification
                Button(action: {
                    dataManager.toggleNotification(for: item)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: item.notificationEnabled ? "bell.fill" : "bell.slash")
                        Text(item.notificationEnabled ? "ON" : "OFF")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(item.notificationEnabled ? .white : .white.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(item.notificationEnabled ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                    )
                }
                
                // if price reached show button
                if item.isPriceReached {
                    Button(action: {
                        dataManager.moveToCollection(item)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Move to Collection")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.green)
                        )
                    }
                }
                
                Spacer()
                
                // delete button
                Button(action: {
                    dataManager.removeFromWishlist(item)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.8))
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
    
    // MARK: - Price Comparison View
    private var priceComparisonView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // ideal target price
            HStack(spacing: 4) {
                Text("Target:")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                Text("$\(String(format: "%.2f", item.targetPrice))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // current price
            if let currentPrice = item.currentPrice {
                HStack(spacing: 4) {
                    Text("Current:")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("$\(String(format: "%.2f", currentPrice))")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(item.isPriceReached ? .green : .orange)
                    
                    // indicator for price change
                    // indicator for price change
                    if item.isPriceReached {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Price Reached!")
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.green)
                    } else {
                        let diff = currentPrice - item.targetPrice
                        Text("+$\(String(format: "%.2f", diff))")
                            .font(.system(size: 10))
                            .foregroundColor(.orange.opacity(0.8))
                    }
                }
            } else {
                Text("Checking price...")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .italic()
            }
        }
    }
}

#Preview {
    let sampleItem = WishlistItem(
        albumTitle: "Dark Side of the Moon",
        artist: "Pink Floyd",
        targetPrice: 30.0,
        currentPrice: 28.0
    )
    
    return ZStack {
        Color(hex: "1a1a1a").ignoresSafeArea()
        WishlistItemRow(item: sampleItem)
            .padding()
    }
}
