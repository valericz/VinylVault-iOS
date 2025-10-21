import Foundation
import SwiftUI

// MARK: - Vinyl Album Model
struct VinylAlbum: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var artist: String
    var releaseYear: Int
    var genre: String
    var coverImageData: Data?  // Stored as Data for Core Data
    var rating: Double // 0-5 (your personal rating)
    var personalReview: String
    var dateAdded: Date
    var trackListing: [Track]
    var condition: Condition
    var purchasePrice: Double?
    var purchaseLocation: String?
    var isFavorite: Bool
    var discogsId: Int?  // Link to Discogs
    var discogsUrl: String?
    var label: String?
    var catalogNumber: String?
    var country: String?
    
    init(id: UUID = UUID(),
         title: String,
         artist: String,
         releaseYear: Int,
         genre: String,
         coverImageData: Data? = nil,
         rating: Double = 0,
         personalReview: String = "",
         dateAdded: Date = Date(),
         trackListing: [Track] = [],
         condition: Condition = .veryGood,
         purchasePrice: Double? = nil,
         purchaseLocation: String? = nil,
         isFavorite: Bool = false,
         discogsId: Int? = nil,
         discogsUrl: String? = nil,
         label: String? = nil,
         catalogNumber: String? = nil,
         country: String? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.releaseYear = releaseYear
        self.genre = genre
        self.coverImageData = coverImageData
        self.rating = rating
        self.personalReview = personalReview
        self.dateAdded = dateAdded
        self.trackListing = trackListing
        self.condition = condition
        self.purchasePrice = purchasePrice
        self.purchaseLocation = purchaseLocation
        self.isFavorite = isFavorite
        self.discogsId = discogsId
        self.discogsUrl = discogsUrl
        self.label = label
        self.catalogNumber = catalogNumber
        self.country = country
    }
    
    // Convert Data to UIImage
    var coverImage: UIImage? {
        guard let data = coverImageData else { return nil }
        return UIImage(data: data)
    }
    
    // Helper to set image from UIImage
    mutating func setCoverImage(_ image: UIImage?) {
        coverImageData = image?.jpegData(compressionQuality: 0.8)
    }
}

// MARK: - Track Model
struct Track: Identifiable, Codable, Equatable {
    let id: UUID
    var position: String  // e.g., "A1", "B2"
    var title: String
    var duration: String
    
    init(id: UUID = UUID(), position: String, title: String, duration: String) {
        self.id = id
        self.position = position
        self.title = title
        self.duration = duration
    }
    
    var side: String {
        if position.hasPrefix("A") {
            return "Side A"
        } else if position.hasPrefix("B") {
            return "Side B"
        } else if position.hasPrefix("C") {
            return "Side C"
        } else if position.hasPrefix("D") {
            return "Side D"
        }
        return "Unknown"
    }
}

// MARK: - Enums
enum Condition: String, Codable, CaseIterable {
    case mint = "Mint (M)"
    case nearMint = "Near Mint (NM)"
    case veryGoodPlus = "Very Good Plus (VG+)"
    case veryGood = "Very Good (VG)"
    case goodPlus = "Good Plus (G+)"
    case good = "Good (G)"
    case fair = "Fair (F)"
    case poor = "Poor (P)"
    
    var shortName: String {
        switch self {
        case .mint: return "Mint"
        case .nearMint: return "Near Mint"
        case .veryGoodPlus: return "VG+"
        case .veryGood: return "VG"
        case .goodPlus: return "G+"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
}

// MARK: - Widget Display Settings
struct WidgetSettings: Codable {
    var selectedAlbumIds: [UUID] = []  // Albums to show in widget
    var widgetStyle: WidgetStyle = .grid
    var shuffleDaily: Bool = true
    var showFavoritesOnly: Bool = false
    
    enum WidgetStyle: String, Codable {
        case grid = "Grid"
        case shelf = "Shelf"
        case list = "List"
    }
}
// MARK: - Wishlist Item
struct WishlistItem: Identifiable, Codable, Equatable {
    let id: UUID
    var albumTitle: String
    var artist: String
    var targetPrice: Double
    var currentPrice: Double?
    var discogsId: Int?
    var discogsUrl: String?
    var coverImageData: Data?
    var dateAdded: Date
    var lastPriceCheck: Date?
    var priceHistory: [PricePoint]
    var notificationEnabled: Bool
    
    init(id: UUID = UUID(),
         albumTitle: String,
         artist: String,
         targetPrice: Double,
         currentPrice: Double? = nil,
         discogsId: Int? = nil,
         discogsUrl: String? = nil,
         coverImageData: Data? = nil,
         dateAdded: Date = Date(),
         lastPriceCheck: Date? = nil,
         priceHistory: [PricePoint] = [],
         notificationEnabled: Bool = true) {
        self.id = id
        self.albumTitle = albumTitle
        self.artist = artist
        self.targetPrice = targetPrice
        self.currentPrice = currentPrice
        self.discogsId = discogsId
        self.discogsUrl = discogsUrl
        self.coverImageData = coverImageData
        self.dateAdded = dateAdded
        self.lastPriceCheck = lastPriceCheck
        self.priceHistory = priceHistory
        self.notificationEnabled = notificationEnabled
    }
    
    var coverImage: UIImage? {
        guard let data = coverImageData else { return nil }
        return UIImage(data: data)
    }
    
    var isPriceReached: Bool {
        guard let current = currentPrice else { return false }
        return current <= targetPrice
    }
    
    var priceChange: Double? {
        guard let current = currentPrice,
              let lastPrice = priceHistory.last?.price else {
            return nil
        }
        return ((current - lastPrice) / lastPrice) * 100
    }
}

struct PricePoint: Codable, Equatable {
    let date: Date
    let price: Double
}

// MARK: - Sample Data
extension VinylAlbum {
    static let sampleData: [VinylAlbum] = [
        VinylAlbum(
            title: "Abbey Road",
            artist: "The Beatles",
            releaseYear: 1969,
            genre: "Rock",
            rating: 5.0,
            personalReview: "An absolute masterpiece. The medley on Side B is perfection.",
            trackListing: [
                Track(position: "A1", title: "Come Together", duration: "4:20"),
                Track(position: "A2", title: "Something", duration: "3:03"),
                Track(position: "A3", title: "Maxwell's Silver Hammer", duration: "3:27"),
                Track(position: "B1", title: "Here Comes The Sun", duration: "3:05"),
                Track(position: "B2", title: "The End", duration: "2:19")
            ],
            condition: .nearMint,
            purchasePrice: 35.00,
            isFavorite: true,
            label: "Apple Records",
            country: "UK"
        ),
        VinylAlbum(
            title: "Kind of Blue",
            artist: "Miles Davis",
            releaseYear: 1959,
            genre: "Jazz",
            rating: 4.5,
            personalReview: "The warmth of vinyl brings out the beauty of this jazz classic.",
            condition: .veryGood,
            purchasePrice: 28.00,
            isFavorite: true,
            label: "Columbia",
            country: "US"
        ),
        VinylAlbum(
            title: "The Dark Side of the Moon",
            artist: "Pink Floyd",
            releaseYear: 1973,
            genre: "Progressive Rock",
            rating: 5.0,
            personalReview: "A sonic journey. The gatefold artwork is stunning.",
            condition: .nearMint,
            purchasePrice: 42.00,
            isFavorite: true,
            label: "Harvest",
            country: "UK"
        ),
      
    ]
}

// MARK: - App Group for Widget Sharing
struct AppGroup {
    static let identifier = "group.com.valeriez.vinylvault"
    
    static var userDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
    
    // Keys for shared data
    struct Keys {
        static let albums = "shared_albums"
        static let widgetSettings = "widget_settings"
    }
    
    // Save albums for widget access
    static func saveAlbums(_ albums: [VinylAlbum]) {
        if let encoded = try? JSONEncoder().encode(albums) {
            userDefaults.set(encoded, forKey: Keys.albums)
        }
    }
    
    // Load albums for widget
    static func loadAlbums() -> [VinylAlbum] {
        guard let data = userDefaults.data(forKey: Keys.albums),
              let albums = try? JSONDecoder().decode([VinylAlbum].self, from: data) else {
            return []
        }
        return albums
    }
    
    // Save widget settings
    static func saveWidgetSettings(_ settings: WidgetSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: Keys.widgetSettings)
        }
    }
    
    // Load widget settings
    static func loadWidgetSettings() -> WidgetSettings {
        guard let data = userDefaults.data(forKey: Keys.widgetSettings),
              let settings = try? JSONDecoder().decode(WidgetSettings.self, from: data) else {
            return WidgetSettings()
        }
        return settings
    }
}
