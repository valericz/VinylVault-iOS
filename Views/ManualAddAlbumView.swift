import SwiftUI
import PhotosUI

struct ManualAddAlbumView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var dataManager = DataManager.shared
    
    // States
    @State private var title = ""
    @State private var artist = ""
    @State private var releaseYear = ""
    @State private var genre = ""
    @State private var label = ""
    @State private var catalogNumber = ""
    @State private var country = ""
    @State private var personalRating: Double = 0
    @State private var personalReview = ""
    @State private var condition: Condition = .veryGood
    @State private var purchasePrice = ""
    @State private var purchaseLocation = ""
    @State private var isFavorite = false
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showingSuccess = false
    
    // MARK: - Main Body
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1a1a1a").ignoresSafeArea()
                mainContent
            }
            .navigationTitle("Add Album Manually")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .alert("Album Added!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("\(title) has been added to your collection!")
            }
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                coverPhotoSection
                basicInformationSection
                personalDetailsSection
                addButton
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Cover Photo Section
    private var coverPhotoSection: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            coverPhotoDisplay
        }
        .onChange(of: selectedPhoto) { _, newItem in
            loadPhoto(from: newItem)
        }
        .padding(.top)
    }
    
    private var coverPhotoDisplay: some View {
        Group {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                placeholderCover
            }
        }
    }
    
    private var placeholderCover: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.5))
            Text("Add Cover Photo")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(width: 180, height: 180)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Basic Information Section
    private var basicInformationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Basic Information")
            
            CustomTextField(
                icon: "music.note",
                placeholder: "Album Title",
                text: $title
            )
            
            CustomTextField(
                icon: "person",
                placeholder: "Artist Name",
                text: $artist
            )
            
            CustomTextField(
                icon: "calendar",
                placeholder: "Release Year",
                text: $releaseYear
            )
            .keyboardType(.numberPad)
            
            CustomTextField(
                icon: "guitars",
                placeholder: "Genre",
                text: $genre
            )
            
            CustomTextField(
                icon: "building.2",
                placeholder: "Label (Optional)",
                text: $label
            )
            
            CustomTextField(
                icon: "number",
                placeholder: "Catalog Number (Optional)",
                text: $catalogNumber
            )
            
            CustomTextField(
                icon: "flag",
                placeholder: "Country (Optional)",
                text: $country
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Personal Details Section
    private var personalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Your Details")
            
            ratingSection
            reviewSection
            conditionSection
            purchaseDetailsSection
            favoriteToggle
        }
        .padding(.horizontal)
    }
    
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Rating")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { index in
                    starButton(for: index)
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
    }
    
    private func starButton(for index: Int) -> some View {
        Button(action: {
            personalRating = Double(index)
        }) {
            Image(systemName: Double(index) <= personalRating ? "star.fill" : "star")
                .font(.system(size: 28))
                .foregroundColor(.yellow)
        }
    }
    
    private var reviewSection: some View {
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
    }
    
    private var conditionSection: some View {
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
    }
    
    private var purchaseDetailsSection: some View {
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
    }
    
    private var favoriteToggle: some View {
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
    
    // MARK: - Add Button
    private var addButton: some View {
        Button(action: addAlbum) {
            Text("Add to Collection")
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
    }
    
    // MARK: - Toolbar
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.white)
        }
    }
    
    // MARK: - Actions
    private func loadPhoto(from item: PhotosPickerItem?) {
        Task {
            if let data = try? await item?.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                }
            }
        }
    }
    
    private func addAlbum() {
        // Validation
        guard !title.isEmpty, !artist.isEmpty else {
            return
        }
        
        var album = VinylAlbum(
            title: title,
            artist: artist,
            releaseYear: Int(releaseYear) ?? 0,
            genre: genre.isEmpty ? "Unknown" : genre,
            rating: personalRating,
            discogsId: nil,
            discogsUrl: nil,
            label: label.isEmpty ? nil : label,
            catalogNumber: catalogNumber.isEmpty ? nil : catalogNumber,
            country: country.isEmpty ? nil : country
        )
        
        // Add user inputs
        album.personalReview = personalReview
        album.condition = condition
        album.purchasePrice = Double(purchasePrice)
        album.purchaseLocation = purchaseLocation.isEmpty ? nil : purchaseLocation
        album.isFavorite = isFavorite
        
        // Set cover image
        if let image = selectedImage {
            album.setCoverImage(image)
        }
        
        // Save
        dataManager.addAlbum(album)
        
        showingSuccess = true
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
    }
}

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview
#Preview {
    ManualAddAlbumView()
}
