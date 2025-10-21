import Foundation
import SwiftUI
import Combine
import UIKit

struct AlbumDetailView: View {
    let album: VinylAlbum
    @StateObject private var dataManager = DataManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) { // 统一的竖直间距
                // Header with Album Cover
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "1a1a1a"), Color(hex: "2d2d2d").opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 420)
                    
                    VStack(spacing: 16) {
                        // Album Art
                        if let image = album.coverImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 280, height: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                        } else {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 280, height: 280)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 80))
                                        .foregroundColor(.white.opacity(0.3))
                                )
                                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                        }
                        
                        // Album Info
                        VStack(spacing: 4) {
                            Text(album.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(album.artist)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("\(album.releaseYear) • \(album.genre)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.top, 40)
                }
                .padding(.bottom, 20) // 让 header 和下方内容有呼吸感
                
                // Details Section - Rating
                VStack(spacing: 12) {
                    Text("My Rating")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 8) {
                        ForEach(0..<5) { index in
                            Image(systemName: Double(index) < album.rating ? "star.fill" : "star")
                                .font(.system(size: 24))
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(String(format: "%.1f / 5.0", album.rating))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 16) // 横向内边距避免贴边
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
                
                // Quick Info Cards
                HStack(spacing: 12) {
                    InfoCard(icon: "record.circle", title: "Condition", value: album.condition.shortName)
                    InfoCard(icon: "calendar", title: "Added", value: album.dateAdded.formatted(.dateTime.month().day()))
                }
                .padding(.horizontal, 16)
                
                // Personal Review
                if !album.personalReview.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("My Review", systemImage: "quote.bubble")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(album.personalReview)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(6)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.08))
                            )
                    }
                    .padding(.horizontal, 16)
                }
                
                // Track Listing
                if !album.trackListing.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Track Listing", systemImage: "list.bullet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 0) {
                            ForEach(album.trackListing) { track in
                                TrackRow(track: track)
                                if track.id != album.trackListing.last?.id {
                                    Divider().overlay(Color.white.opacity(0.06))
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.08))
                        )
                    }
                    .padding(.horizontal, 16)
                }
                
                // Additional Details
                if album.label != nil || album.country != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Details", systemImage: "info.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            if let label = album.label {
                                DetailRow(label: "Label", value: label)
                            }
                            if let country = album.country {
                                DetailRow(label: "Country", value: country)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.08))
                        )
                    }
                    .padding(.horizontal, 16)
                }
                
                // Purchase Info
                if album.purchasePrice != nil || album.purchaseLocation != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Purchase Details", systemImage: "cart")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            if let price = album.purchasePrice {
                                DetailRow(label: "Price", value: "$\(String(format: "%.2f", price))")
                            }
                            if let location = album.purchaseLocation {
                                DetailRow(label: "Location", value: location)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.08))
                        )
                    }
                    .padding(.horizontal, 16)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: { showingEditSheet = true }) {
                        Label("Edit Album", systemImage: "pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    ShareLink(item: "Check out \(album.title) by \(album.artist)!") {
                        Label("Share Album", systemImage: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: { showingDeleteAlert = true }) {
                        Label("Delete Album", systemImage: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 20)
        }
        // iOS 17+ 可用：统一内容边距（有它可以删掉上面很多 .padding(.horizontal, 16)）
        .applyContentMarginsIfAvailable()
        
        .background(Color(hex: "1a1a1a"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    dataManager.toggleFavorite(album)
                }) {
                    Image(systemName: album.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(album.isFavorite ? .red : .white)
                }
            }
        }
        .alert("Delete Album?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                dataManager.deleteAlbum(album)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \(album.title)?")
        }
    }
    
    // MARK: - Info Card
    struct InfoCard: View {
        let icon: String
        let title: String
        let value: String
        
        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
            )
        }
    }
    
    // MARK: - Track Row
    struct TrackRow: View {
        let track: Track
        
        // 从 position 推断 Side（如 "A1" -> "Side A"）
        private var sideText: String {
            guard let first = track.position.first else { return "" }
            return "Side \(first)"
        }
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("\(track.position) • \(sideText)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Text(track.duration)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .background(
                Rectangle()
                    .fill(Color.white.opacity(0.02))
            )
        }
    }
    
    // MARK: - Detail Row
    struct DetailRow: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
}

// iOS 17+ 的统一内容边距封装（可选）
private extension View {
    @ViewBuilder
    func applyContentMarginsIfAvailable() -> some View {
        if #available(iOS 17.0, *) {
            self.contentMargins(.horizontal, 16, for: .scrollContent)
        } else {
            self
        }
    }
}

#Preview {
    NavigationView {
        AlbumDetailView(album: VinylAlbum.sampleData[0])
    }
}
