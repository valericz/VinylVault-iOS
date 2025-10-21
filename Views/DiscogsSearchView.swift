import SwiftUI
import Foundation
import Combine
import UIKit

struct DiscogsSearchView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var service = DiscogsService()
    @StateObject private var dataManager = DataManager.shared
    
    @State private var searchText = ""
    @State private var searchResults: [DiscogsSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var selectedAlbum: DiscogsSearchResult?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1a1a1a").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.6))
                        
                        TextField("Search vinyl on Discogs...", text: $searchText)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .onSubmit {
                                performSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchResults = []
                                errorMessage = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding()
                    
                    // Search Button
                    if !searchText.isEmpty && !isSearching {
                        Button(action: performSearch) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Search Discogs Database")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    
                    // Content
                    if isSearching {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error)
                    } else if !searchResults.isEmpty {
                        resultsList
                    } else {
                        emptyView
                    }
                }
            }
            .navigationTitle("Search Discogs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(item: $selectedAlbum) { album in
                AlbumImportView(discogsResult: album)
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Searching Discogs...")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
            
            Text("Finding the best vinyl records")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red.opacity(0.8))
            
            Text("Oops!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(error)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                errorMessage = nil
                performSearch()
            }) {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Search Discogs")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                Text("Search from the world's largest")
                    .foregroundColor(.white.opacity(0.6))
                Text("vinyl and music database")
                    .foregroundColor(.white.opacity(0.6))
            }
            .font(.system(size: 15))
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureBullet(icon: "music.note", text: "Millions of vinyl records")
                FeatureBullet(icon: "star.fill", text: "Community ratings & reviews")
                FeatureBullet(icon: "photo", text: "High-quality cover art")
                FeatureBullet(icon: "list.bullet", text: "Complete track listings")
            }
            .padding(.top)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Results List
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(searchResults) { result in
                    SearchResultRow(result: result) {
                        selectedAlbum = result
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Search Action
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        searchResults = []
        
        Task {
            do {
                let results = try await service.searchAlbums(query: searchText)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                    
                    if results.isEmpty {
                        errorMessage = "No results found. Try a different search term."
                    }
                }
            } catch let error as DiscogsError {
                await MainActor.run {
                    errorMessage = error.errorDescription ?? "Unknown error occurred"
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Could not connect to Discogs. Please check your internet connection."
                    isSearching = false
                }
            }
        }
    }
}

// MARK: - Feature Bullet
struct FeatureBullet: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let result: DiscogsSearchResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Album Cover
                if let thumbUrl = result.thumb, !thumbUrl.isEmpty, thumbUrl != "" {
                    AsyncImage(url: URL(string: thumbUrl)) { phase in
                        switch phase {
                        case .empty:
                            placeholderImage
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            placeholderImage
                        @unknown default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }
                
                // Album Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.albumTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(result.artistName)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        if let year = result.year {
                            Text(year)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        if let year = result.year, !result.primaryGenre.isEmpty {
                            Text("•")
                                .foregroundColor(.white.opacity(0.3))
                        }
                        
                        if !result.primaryGenre.isEmpty && result.primaryGenre != "Unknown" {
                            Text(result.primaryGenre)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                    }
                    
                    // Rating if available
                    if let rating = result.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.2))
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.3))
            )
    }
}

#Preview {
    DiscogsSearchView()
}
