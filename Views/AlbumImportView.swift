import SwiftUI

struct AlbumImportView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var service = DiscogsService()
    @StateObject private var dataManager = DataManager.shared
    
    let discogsResult: DiscogsSearchResult
    
    @State private var isLoading = true
    @State private var albumDetails: DiscogsRelease?
    @State private var coverImage: UIImage?
    @State private var errorMessage: String?
    
    // User inputs
    @State private var personalRating: Double = 0
    @State private var personalReview: String = ""
    @State private var condition: Condition = .veryGood
    @State private var purchasePrice: String = ""
    @State private var purchaseLocation: String = ""
    @State private var isFavorite: Bool = false
    
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1a1a1a").ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if let details = albumDetails {
                    contentView(details)
                }
            }
            .navigationTitle("Import Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("Album Added!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("\(discogsResult.albumTitle) has been added to your collection!")
            }
        }
        .onAppear {
            loadAlbumDetails()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Loading album details...")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
            
            Text("Getting info from Discogs")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
    }
    
    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red.opacity(0.8))
            
            Text("Error")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(error)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Try Again") {
                errorMessage = nil
                loadAlbumDetails()
            }
            .foregroundColor(.blue)
        }
    }
    
    // MARK: - Content View
    private func contentView(_ details: DiscogsRelease) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Album Cover
                if let image = coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 280, maxHeight: 280)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.3), radius: 10)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 280, height: 280)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.3))
                        )
                }
                
                // Album Info
                VStack(spacing: 8) {
                    Text(details.albumTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(details.artistName)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 8) {
                        if let year = details.year {
                            Text("\(year)")
                        }
                        if details.year != nil && !details.primaryGenre.isEmpty {
                            Text("•")
                        }
                        if !details.primaryGenre.isEmpty {
                            Text(details.primaryGenre)
                        }
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    
                    
                    
                }
                .padding()
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.horizontal)
                
                // Personal Details Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your Details")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Personal Rating
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Rating")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { index in
                                Button(action: {
                                    personalRating = Double(index)
                                }) {
                                    Image(systemName: Double(index) <= personalRating ? "star.fill" : "star")
                                        .font(.system(size: 28))
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        
                        if personalRating > 0 {
                            Text(String(format: "%.0f / 5 stars", personalRating))
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                    )
                    
                    // Personal Review
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Review (Optional)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextEditor(text: $personalReview)
                            .frame(height: 100)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    // Condition
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Condition")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Picker("Condition", selection: $condition) {
                            ForEach(Condition.allCases, id: \.self) { cond in
                                Text(cond.shortName).tag(cond)
                            }
                        }
                        .pickerStyle(.menu)
                        .accentColor(.white)
                    }
                    
                    // Purchase Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Purchase Details (Optional)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack {
                            Text("$")
                                .foregroundColor(.white.opacity(0.7))
                            TextField("Price", text: $purchasePrice)
                                .keyboardType(.decimalPad)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        
                        TextField("Where did you buy it?", text: $purchaseLocation)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Favorite Toggle
                    Toggle(isOn: $isFavorite) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(isFavorite ? .red : .white.opacity(0.5))
                            Text("Add to Favorites")
                                .foregroundColor(.white)
                        }
                    }
                    .tint(.red)
                }
                .padding()
                
                // Add to Collection Button
                Button(action: addToCollection) {
                    Text("Add to My Collection")
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
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Actions
    private func loadAlbumDetails() {
        Task {
            do {
                let details = try await service.getAlbumDetails(releaseId: discogsResult.id)
                
                // Download cover image if available
                if let imageUrl = details.primaryImage {
                    do {
                        let image = try await service.downloadImage(from: imageUrl)
                        await MainActor.run {
                            self.coverImage = image
                        }
                    } catch {
                        // Continue without image
                        print("Could not load image: \(error)")
                    }
                }
                
                await MainActor.run {
                    self.albumDetails = details
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Could not load album details. Please try again."
                    self.isLoading = false
                }
            }
        }
    }
    
    private func addToCollection() {
        guard let details = albumDetails else { return }
        
        var album = service.convertToVinylAlbum(from: details, coverImage: coverImage)
        
        // Add user inputs
        album.rating = personalRating
        album.personalReview = personalReview
        album.condition = condition
        album.purchasePrice = Double(purchasePrice)
        album.purchaseLocation = purchaseLocation.isEmpty ? nil : purchaseLocation
        album.isFavorite = isFavorite
        
        // Save to collection
        dataManager.addAlbum(album)
        
        showingSuccess = true
    }
}

#Preview {
    let sampleResult = DiscogsSearchResult(
        id: 123456,
        title: "Pink Floyd - The Dark Side of the Moon",
        year: "1973",
        thumb: nil,
        coverImage: nil,
        genre: ["Rock"],
        style: ["Progressive Rock"],
        format: ["Vinyl", "LP"],
        country: "UK",
        label: ["Harvest"],

    )
    
    return AlbumImportView(discogsResult: sampleResult)
}
