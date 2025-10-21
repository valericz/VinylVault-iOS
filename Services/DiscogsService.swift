import Foundation
import SwiftUI
import Combine
import UIKit
// MARK: - Discogs API Service
class DiscogsService: ObservableObject {
    // this is where we got token https://www.discogs.com/settings/developers
    // signin → Settings → Developers → Generate new token
    private let apiToken = "PdlbmGBlAztIlkXYXJBnQPFmvtWOFCURZuLAROiC"
    private let baseURL = "https://api.discogs.com"
    
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    // MARK: - Search Albums
    func searchAlbums(query: String) async throws -> [DiscogsSearchResult] {
        // 🔍 Debug 1: 检查token
        print("🔑 API Token: \(apiToken.prefix(10))...")  // 只显示前10个字符
        
        guard !apiToken.contains("YOUR_") else {
            print("❌ Error: Token not configured")
            throw DiscogsError.noToken
        }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/database/search?q=\(encodedQuery)&type=release&format=vinyl&token=\(apiToken)"
        
        // 🔍 Debug 2: 打印完整URL (不含token)
        print("🌐 Request URL: \(baseURL)/database/search?q=\(encodedQuery)&type=release&format=vinyl&token=***")
        
        guard let url = URL(string: urlString) else {
            print("❌ Error: Invalid URL")
            throw DiscogsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("VinylVault/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        
        // 🔍 Debug 3: 开始请求
        print("📡 Sending request...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 🔍 Debug 4: 检查响应
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ Response Status: \(httpResponse.statusCode)")
                
                // 打印响应头（看rate limit信息）
                if let rateLimit = httpResponse.value(forHTTPHeaderField: "X-Discogs-Ratelimit") {
                    print("📊 Rate Limit: \(rateLimit)")
                }
                if let remaining = httpResponse.value(forHTTPHeaderField: "X-Discogs-Ratelimit-Remaining") {
                    print("📊 Remaining: \(remaining)")
                }
                
                // 处理不同状态码
                switch httpResponse.statusCode {
                case 200:
                    print("✅ Success! Parsing data...")
                    
                    // 🔍 Debug 5: 打印部分响应数据
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📦 Response (first 200 chars): \(jsonString.prefix(200))...")
                    }
                    
                    let searchResponse = try JSONDecoder().decode(DiscogsSearchResponse.self, from: data)
                    print("✅ Found \(searchResponse.results.count) results")
                    return searchResponse.results
                    
                case 401:
                    print("❌ 401 Unauthorized - Token is invalid")
                    throw DiscogsError.noToken
                    
                case 429:
                    print("❌ 429 Rate Limited - Too many requests")
                    throw DiscogsError.rateLimited
                    
                default:
                    print("❌ Unexpected status code: \(httpResponse.statusCode)")
                    
                    // 打印错误响应内容
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("❌ Error response: \(errorString)")
                    }
                    
                    throw DiscogsError.badResponse
                }
            } else {
                print("❌ Response is not HTTPURLResponse")
                throw DiscogsError.badResponse
            }
            
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding Error: \(decodingError)")
            throw DiscogsError.decodingError
            
        } catch let urlError as URLError {
            print("❌ URL Error: \(urlError.localizedDescription)")
            print("   Error Code: \(urlError.code.rawValue)")
            
            // 具体的网络错误
            switch urlError.code {
            case .notConnectedToInternet:
                print("   → Not connected to internet")
            case .timedOut:
                print("   → Request timed out")
            case .cannotConnectToHost:
                print("   → Cannot connect to host")
            case .networkConnectionLost:
                print("   → Network connection lost")
            default:
                print("   → Other network error")
            }
            
            throw urlError
            
        } catch {
            print("❌ Unknown Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Get Album Details
    func getAlbumDetails(releaseId: Int) async throws -> DiscogsRelease {
        guard !apiToken.contains("YOUR_") else {
            throw DiscogsError.noToken
        }
        
        let urlString = "\(baseURL)/releases/\(releaseId)?token=\(apiToken)"
        
        guard let url = URL(string: urlString) else {
            throw DiscogsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("VinylVaultApp/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DiscogsError.badResponse
        }
        
        let release = try JSONDecoder().decode(DiscogsRelease.self, from: data)
        return release
    }
    
    // MARK: - Download Image
    func downloadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw DiscogsError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw DiscogsError.invalidImageData
        }
        
        return image
    }
    
    // MARK: - Convert Discogs Result to VinylAlbum
    func convertToVinylAlbum(from release: DiscogsRelease, coverImage: UIImage? = nil) -> VinylAlbum {
        var album = VinylAlbum(
            title: release.albumTitle,
            artist: release.artistName,
            releaseYear: release.year ?? 0,
            genre: release.primaryGenre,
            rating: 0,
            discogsId: release.id,
            discogsUrl: "https://www.discogs.com/release/\(release.id)",
            label: release.labels?.first?.name,
            catalogNumber: release.labels?.first?.catno,
            country: release.country
        )
        
        // Convert tracks
        if let tracks = release.tracklist {
            album.trackListing = tracks.map { track in
                Track(
                    position: track.position,
                    title: track.title,
                    duration: track.duration
                )
            }
        }
        
        // Set cover image
        if let image = coverImage {
            album.setCoverImage(image)
        }
        
        return album
    }
}

// MARK: - Discogs Error
enum DiscogsError: Error, LocalizedError {
    case noToken
    case invalidURL
    case badResponse
    case rateLimited
    case invalidImageData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .noToken:
            return "Please add your Discogs API token"
        case .invalidURL:
            return "Invalid URL"
        case .badResponse:
            return "Bad response from Discogs server"
        case .rateLimited:
            return "Rate limited. Please wait a minute and try again."
        case .invalidImageData:
            return "Could not load image"
        case .decodingError:
            return "Could not decode data"
        }
    }
}

// MARK: - Discogs Models
struct DiscogsSearchResponse: Codable {
    let results: [DiscogsSearchResult]
}

struct DiscogsSearchResult: Codable, Identifiable {
    let id: Int
    let title: String
    let year: String?
    let thumb: String?
    let coverImage: String?
    let genre: [String]?
    let style: [String]?
    let format: [String]?
    let country: String?
    let label: [String]?

    
    enum CodingKeys: String, CodingKey {
        case id, title, year, thumb, genre, style, format, country, label
        case coverImage = "cover_image"
        
    }
    
    var artistName: String {
        let components = title.components(separatedBy: " - ")
        return components.first?.trimmingCharacters(in: .whitespaces) ?? "Unknown Artist"
    }
    
    var albumTitle: String {
        let components = title.components(separatedBy: " - ")
        if components.count > 1 {
            return components.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespaces)
        }
        return title
    }
    
    var primaryGenre: String {
        genre?.first ?? style?.first ?? "Unknown"
    }
    
    var formatString: String {
        format?.joined(separator: ", ") ?? "Vinyl"
    }
    
    var rating: Double? {
        return nil
    }
}



struct DiscogsRelease: Codable {
    let id: Int
    let title: String
    let artists: [DiscogsArtist]?
    let year: Int?
    let genres: [String]?
    let styles: [String]?
    let images: [DiscogsImage]?
    let tracklist: [DiscogsTrack]?
    let labels: [DiscogsLabel]?
    let country: String?
    let released: String?
   
    
    enum CodingKeys: String, CodingKey {
        case id, title, artists, year, genres, styles, images, tracklist, labels, country, released
        
    }
    
    var primaryImage: String? {
        images?.first(where: { $0.type == "primary" })?.uri ?? images?.first?.uri
    }
    
    var artistName: String {
        artists?.first?.name ?? "Unknown Artist"
    }
    
    var albumTitle: String {
        let components = title.components(separatedBy: " - ")
        if components.count > 1 {
            return components.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespaces)
        }
        return title
    }
    
    var primaryGenre: String {
        genres?.first ?? styles?.first ?? "Unknown"
    }
}

struct DiscogsArtist: Codable {
    let name: String
    let id: Int
}

struct DiscogsImage: Codable {
    let type: String
    let uri: String
    let uri150: String?
    let width: Int
    let height: Int
}

struct DiscogsTrack: Codable {
    let position: String
    let title: String
    let duration: String
}

struct DiscogsLabel: Codable {
    let name: String
    let catno: String?
}
