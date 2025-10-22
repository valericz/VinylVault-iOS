//
//  StoreCard.swift
//  VinylVault
//
//  Created by WEIHUA ZHANG on 22/10/2025.
//

import SwiftUI
import CoreLocation

struct StoreCard: View {
    let store: Store
    @StateObject private var locationService = LocationNotificationService.shared
    
    var isMonitored: Bool {
        locationService.monitoredStoreIds.contains(store.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            storeLogo
            
            VStack(alignment: .leading, spacing: 6) {
                Text(store.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(height: 36, alignment: .top)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue.opacity(0.8))
                    
                    Text(store.suburb)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                if !store.specialty.isEmpty {
                    Text(store.specialty.first ?? "")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack {
                    if locationService.isMonitoringEnabled {
                        Button(action: {
                            locationService.toggleStoreMonitoring(for: store)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isMonitored ? "bell.fill" : "bell.slash.fill")
                                    .font(.system(size: 10))
                                Text(isMonitored ? "ON" : "OFF")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(isMonitored ? .blue : .white.opacity(0.5))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(isMonitored ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                            )
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var storeLogo: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "2d2d2d"),
                            Color(hex: "1a1a1a")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)
            
            VStack(spacing: 8) {
                Image(systemName: "music.note.house.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.3))
                
                Text("🎵")
                    .font(.system(size: 28))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    ZStack {
        Color(hex: "1a1a1a").ignoresSafeArea()
        StoreCard(store: Store.sampleStore)
            .frame(width: 170)
            .padding()
    }
}
