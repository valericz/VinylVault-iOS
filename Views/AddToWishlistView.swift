//
//  AddToWishlistView.swift
//  VinylVault
//
//  Created by WEIHUA ZHANG on 22/10/2025.
//

import SwiftUI

struct AddToWishlistView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var service = DiscogsService()
    @StateObject private var dataManager = DataManager.shared
    
    @State private var searchText = ""
    @State private var searchResults: [DiscogsSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var selectedAlbum: DiscogsSearchResult?
    @State private var showingPriceSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1a1a1a").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    searchBar
                    
                    if !searchText.isEmpty && !isSearching {
                        searchButton
                    }
                    
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
            .navigationTitle("Add to Wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showingPriceSheet) {
                if let album = selectedAlbum {
                    SetTargetPriceView(album: album) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.6))
            
            TextField("Search for albums on Discogs...", text: $searchText)
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
    }
    
    private var searchButton: some View {
        Button(action: performSearch) {
            HStack {
                Image(systemName: "sparkles")
                Text("Search Discogs")
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
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Searching Discogs...")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxHeight: .infinity)
    }
    
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
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 70))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Find Albums to Watch")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                Text("Search for vinyl you want to buy")
                    .foregroundColor(.white.opacity(0.6))
                Text("Set a target price")
                    .foregroundColor(.white.opacity(0.6))
                Text("Get notified when price drops!")
                    .foregroundColor(.white.opacity(0.6))
            }
            .font(.system(size: 15))
        }
        .frame(maxHeight: .infinity)
    }
    
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(searchResults) { result in
                    WishlistSearchResultRow(result: result) {
                        selectedAlbum = result
                        showingPriceSheet = true
                    }
                }
            }
            .padding()
        }
    }
    
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

struct WishlistSearchResultRow: View {
    let result: DiscogsSearchResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if let thumbUrl = result.thumb, !thumbUrl.isEmpty, thumbUrl != "" {
                    AsyncImage(url: URL(string: thumbUrl)) { phase in
                        switch phase {
                        case .empty:
                            placeholderImage
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.albumTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(result.artistName)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        if let year = result.year {
                            Text(year)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        if let year = result.year, !result.primaryGenre.isEmpty {
                            Text("•")
                                .foregroundColor(.white.opacity(0.3))
                        }
                        
                        if !result.primaryGenre.isEmpty && result.primaryGenre != "Unknown" {
                            Text(result.primaryGenre)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
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
            .frame(width: 60, height: 60)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.3))
            )
    }
}

struct SetTargetPriceView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var service = DiscogsService()
    @StateObject private var dataManager = DataManager.shared
    
    let album: DiscogsSearchResult
    let onComplete: () -> Void
    
    @State private var targetPrice: String = ""
    @State private var coverImage: UIImage?
    @State private var isLoading = true
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1a1a1a").ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                } else {
                    contentView
                }
            }
            .navigationTitle("Set Target Price")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("Added to Wishlist!", isPresented: $showingSuccess) {
                Button("OK") {
                    onComplete()
                }
            } message: {
                Text("\(album.albumTitle) is now in your wishlist!")
            }
        }
        .onAppear {
            loadCoverImage()
        }
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let image = coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.3), radius: 10)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.3))
                        )
                }
                
                VStack(spacing: 8) {
                    Text(album.albumTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(album.artistName)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal)
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Set Your Target Price")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("You'll get notified when the price drops to or below your target.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack {
                        Text("$")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        TextField("30.00", text: $targetPrice)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                }
                .padding(.horizontal)
                
                Button(action: addToWishlist) {
                    Text("Add to Wishlist")
                        .font(.system(size: 18, weight: .bold))
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
                .padding(.top)
                .disabled(targetPrice.isEmpty)
                .opacity(targetPrice.isEmpty ? 0.5 : 1.0)
            }
            .padding(.vertical, 24)
        }
    }
    
    private func loadCoverImage() {
        Task {
            if let imageUrl = album.coverImage ?? album.thumb {
                do {
                    let image = try await service.downloadImage(from: imageUrl)
                    await MainActor.run {
                        self.coverImage = image
                        self.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func addToWishlist() {
        guard let price = Double(targetPrice), price > 0 else {
            return
        }
        
        let wishlistItem = WishlistItem(
            albumTitle: album.albumTitle,
            artist: album.artistName,
            targetPrice: price,
            currentPrice: Double.random(in: (price - 10)...(price + 20)),
            discogsId: album.id,
            discogsUrl: "https://www.discogs.com/release/\(album.id)",
            coverImageData: coverImage?.jpegData(compressionQuality: 0.8),
            notificationEnabled: true
        )
        
        dataManager.addToWishlist(wishlistItem)
        showingSuccess = true
    }
}

#Preview {
    AddToWishlistView()
}
