import Foundation
import SwiftUI
import Combine
import UIKit

struct CollectionView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var showingAddMenu = false
    @State private var showingSearch = false
    @State private var showingManualAdd = false
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case favorites = "Favorites"
        case recent = "Recent"
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var filteredAlbums: [VinylAlbum] {
        var result = dataManager.albums
        
        // Apply text search
        if !searchText.isEmpty {
            result = dataManager.searchAlbums(query: searchText)
        }
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .recent:
            result = result.sorted { $0.dateAdded > $1.dateAdded }
        }
        
        return result
    }
    
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
                
                VStack(spacing: 0) {
                    // Stats Cards
                    HStack(spacing: 16) {
                        StatCard(
                            icon: "📀",
                            title: "Total",
                            value: "\(dataManager.totalAlbums)"
                        )
                        
                        StatCard(
                            icon: "⭐️",
                            title: "Avg Rating",
                            value: String(format: "%.1f", dataManager.averageRating)
                        )
                        
                        StatCard(
                            icon: "❤️",
                            title: "Favorites",
                            value: "\(dataManager.favoriteAlbums.count)"
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(FilterOption.allCases, id: \.self) { option in
                                FilterChip(
                                    title: option.rawValue,
                                    isSelected: selectedFilter == option
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedFilter = option
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    
                    // Albums Grid
                    if filteredAlbums.isEmpty {
                        EmptyStateView()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(filteredAlbums) { album in
                                    NavigationLink(destination: AlbumDetailView(album: album)) {
                                        AlbumGridItem(album: album)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("My Collection")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingSearch = true }) {
                            Label("Search Discogs", systemImage: "magnifyingglass")
                        }
                        
                        Button(action: { showingManualAdd = true }) {
                            Label("Add Manually", systemImage: "plus.circle")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search albums or artists")
            .sheet(isPresented: $showingSearch) {
                DiscogsSearchView()
            }
            .sheet(isPresented: $showingManualAdd) {
                ManualAddAlbumView()
            }
        }
    }
}

// MARK: - Album Grid Item
struct AlbumGridItem: View {
    let album: VinylAlbum
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Album Cover
            ZStack(alignment: .topTrailing) {
                if let image = album.coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 110, height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.3))
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                // Favorite Badge
                if album.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(6)
                        .background(Circle().fill(Color.black.opacity(0.6)))
                        .padding(6)
                }
            }
            
            // Album Info
            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(album.artist)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                
                // Rating
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(album.rating) ? "star.fill" : "star")
                            .font(.system(size: 8))
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .frame(width: 110)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white : Color.white.opacity(0.2))
                )
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No Albums Yet")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Start building your vinyl collection\nby searching Discogs or adding manually")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    CollectionView()
}
