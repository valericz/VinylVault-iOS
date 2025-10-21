import Foundation
import Combine
import UIKit
import SwiftUI
import WidgetKit

// MARK: - Data Manager
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var albums: [VinylAlbum] = []
    @Published var widgetSettings: WidgetSettings = WidgetSettings()
    @Published var wishlistItems: [WishlistItem] = []
    
    private init() {
        loadAlbums()
        loadWidgetSettings()
        loadWishlist()
    }
    
    // MARK: - Album Management
    func addAlbum(_ album: VinylAlbum) {
        albums.append(album)
        saveAlbums()
    }
    
    func updateAlbum(_ album: VinylAlbum) {
        if let index = albums.firstIndex(where: { $0.id == album.id }) {
            albums[index] = album
            saveAlbums()
        }
    }
    
    func deleteAlbum(_ album: VinylAlbum) {
        albums.removeAll { $0.id == album.id }
        saveAlbums()
    }
    
    func deleteAlbums(at offsets: IndexSet) {
        albums.remove(atOffsets: offsets)
        saveAlbums()
    }
    
    func toggleFavorite(_ album: VinylAlbum) {
        if let index = albums.firstIndex(where: { $0.id == album.id }) {
            albums[index].isFavorite.toggle()
            saveAlbums()
        }
    }
    
    // MARK: - Persistence
    private func saveAlbums() {
        if let encoded = try? JSONEncoder().encode(albums) {
            UserDefaults.standard.set(encoded, forKey: "albums")
        }
        
        AppGroup.saveAlbums(albums)
        print("💾 Saved \(albums.count) albums to App Group")
        print("💾 App Group ID: \(AppGroup.identifier)")
            
        let loadedAlbums = AppGroup.loadAlbums()
        print("✅ Loaded back \(loadedAlbums.count) albums from App Group")
            
        WidgetCenter.shared.reloadAllTimelines()
        print("🔄 Widget timeline reloaded")
    }
    
    private func loadAlbums() {
        if let data = UserDefaults.standard.data(forKey: "albums"),
           let decoded = try? JSONDecoder().decode([VinylAlbum].self, from: data) {
            albums = decoded
        } else {
            albums = VinylAlbum.sampleData
            saveAlbums()
        }
    }
    
    // MARK: - Widget Settings
    func updateWidgetSettings(_ settings: WidgetSettings) {
        widgetSettings = settings
        AppGroup.saveWidgetSettings(settings)
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func loadWidgetSettings() {
        widgetSettings = AppGroup.loadWidgetSettings()
    }
    
    // MARK: - Wishlist Management
    func addToWishlist(_ item: WishlistItem) {
        wishlistItems.append(item)
        saveWishlist()
        print("✅ Added to wishlist: \(item.albumTitle)")
    }
    
    func removeFromWishlist(_ item: WishlistItem) {
        wishlistItems.removeAll { $0.id == item.id }
        saveWishlist()
        print("🗑️ Removed from wishlist: \(item.albumTitle)")
    }
    
    func updateWishlistItem(_ item: WishlistItem) {
        if let index = wishlistItems.firstIndex(where: { $0.id == item.id }) {
            wishlistItems[index] = item
            saveWishlist()
            print("📝 Updated wishlist item: \(item.albumTitle)")
        }
    }
    
    func toggleNotification(for item: WishlistItem) {
        if let index = wishlistItems.firstIndex(where: { $0.id == item.id }) {
            wishlistItems[index].notificationEnabled.toggle()
            saveWishlist()
            print("🔔 Notification toggled for: \(item.albumTitle) -> \(wishlistItems[index].notificationEnabled)")
        }
    }
    
    func moveToCollection(_ item: WishlistItem) {
        var album = VinylAlbum(
            title: item.albumTitle,
            artist: item.artist,
            releaseYear: 0,
            genre: "Unknown",
            coverImageData: item.coverImageData,
            purchasePrice: item.currentPrice,
            discogsId: item.discogsId,
            discogsUrl: item.discogsUrl
        )
        
        addAlbum(album)
        removeFromWishlist(item)
        print("🎉 Moved to collection: \(item.albumTitle)")
    }
    
    // MARK: - Wishlist Persistence
    private func saveWishlist() {
        if let encoded = try? JSONEncoder().encode(wishlistItems) {
            UserDefaults.standard.set(encoded, forKey: "wishlist")
            AppGroup.userDefaults.set(encoded, forKey: "wishlist")
            AppGroup.userDefaults.synchronize()
        }
    }
    
    private func loadWishlist() {
        if let data = UserDefaults.standard.data(forKey: "wishlist"),
           let decoded = try? JSONDecoder().decode([WishlistItem].self, from: data) {
            wishlistItems = decoded
            print("📋 Loaded \(wishlistItems.count) wishlist items")
        } else {
            wishlistItems = []
            print("📋 No wishlist items found, starting fresh")
        }
    }
    
    // MARK: - Wishlist Queries
    var wishlistWithPriceReached: [WishlistItem] {
        wishlistItems.filter { $0.isPriceReached }
    }
    
    var wishlistPendingPrice: [WishlistItem] {
        wishlistItems.filter { !$0.isPriceReached }
    }
    
    // MARK: - Statistics
    var totalAlbums: Int {
        albums.count
    }
    
    var averageRating: Double {
        guard !albums.isEmpty else { return 0 }
        let sum = albums.map { $0.rating }.reduce(0, +)
        return sum / Double(albums.count)
    }
    
    var totalValue: Double {
        albums.compactMap { $0.purchasePrice }.reduce(0, +)
    }
    
    var favoriteAlbums: [VinylAlbum] {
        albums.filter { $0.isFavorite }
    }
    
    var recentlyAdded: [VinylAlbum] {
        albums.sorted { $0.dateAdded > $1.dateAdded }
    }
    
    var topRated: [VinylAlbum] {
        albums.sorted { $0.rating > $1.rating }
    }
    
    var genreBreakdown: [(genre: String, count: Int)] {
        let grouped = Dictionary(grouping: albums, by: { $0.genre })
        return grouped.map { (genre: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
    
    var decadeBreakdown: [(decade: String, count: Int)] {
        let grouped = Dictionary(grouping: albums) { album -> String in
            let decade = (album.releaseYear / 10) * 10
            return "\(decade)s"
        }
        return grouped.map { (decade: $0.key, count: $0.value.count) }
            .sorted { $0.decade < $1.decade }
    }
    
    // MARK: - Search and Filter
    func searchAlbums(query: String) -> [VinylAlbum] {
        guard !query.isEmpty else { return albums }
        
        let lowercased = query.lowercased()
        return albums.filter { album in
            album.title.lowercased().contains(lowercased) ||
            album.artist.lowercased().contains(lowercased) ||
            album.genre.lowercased().contains(lowercased)
        }
    }
    
    func filterByGenre(_ genre: String) -> [VinylAlbum] {
        albums.filter { $0.genre == genre }
    }
    
    func filterByCondition(_ condition: Condition) -> [VinylAlbum] {
        albums.filter { $0.condition == condition }
    }
    
    // MARK: - Export/Import
    func exportAlbums() -> Data? {
        try? JSONEncoder().encode(albums)
    }
    
    func importAlbums(from data: Data) throws {
        let importedAlbums = try JSONDecoder().decode([VinylAlbum].self, from: data)
        
        for album in importedAlbums {
            if !albums.contains(where: { $0.id == album.id }) {
                albums.append(album)
            }
        }
        
        saveAlbums()
    }
}

// MARK: - Image Cache Manager
class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    
    func removeImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
