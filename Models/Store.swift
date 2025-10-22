import Foundation
import CoreLocation
import Combine

struct Store: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
    let suburb: String
    let postcode: String
    let lat: Double
    let lng: Double
    let phone: String?
    let hours: String
    let description: String
    let website: String?
    let instagram: String?
    let specialty: [String]
    let logoFileName: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    var fullAddress: String {
        "\(address), \(suburb) NSW \(postcode)"
    }
    
    var specialtyText: String {
        specialty.joined(separator: " • ")
    }
}

class StoreDataManager: ObservableObject {
    static let shared = StoreDataManager()
    
    @Published var stores: [Store] = []
    
    private init() {
        loadStores()
    }
    
    private func loadStores() {
        if let url = Bundle.main.url(forResource: "stores_sydney", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Store].self, from: data) {
            stores = decoded
            print("✅ Loaded \(stores.count) record stores")
        } else {
            stores = Store.defaultStores
            print("⚠️ Using default stores")
        }
    }
    
    func store(withId id: String) -> Store? {
        stores.first { $0.id == id }
    }
}

extension Store {
    static let defaultStores: [Store] = [
        Store(
            id: "red-eye-records",
            name: "Red Eye Records",
            address: "66 King St",
            suburb: "Sydney",
            postcode: "2000",
            lat: -33.8688,
            lng: 151.2093,
            phone: "(02) 9233 8828",
            hours: "Mon-Sat 10am-6pm, Sun 11am-5pm",
            description: "Sydney's iconic independent record store since 2003. Specializing in new and second-hand vinyl across all genres.",
            website: "https://redeyerecords.com.au",
            instagram: "@redeyerecords",
            specialty: ["Indie", "Rock", "Electronic", "Jazz"],
            logoFileName: nil
        ),
        Store(
            id: "basement-discs",
            name: "Basement Discs",
            address: "ShopE04/377 Sussex St",
            suburb: "Sydney",
            postcode: "2000",
            lat: -33.8731,
            lng: 151.2042,
            phone: "(02) 9283 1088",
            hours: "Mon-Fri 11am-6pm, Sat 11am-5pm",
            description: "Underground vinyl paradise in the CBD. Extensive collection of rare and collectible records.",
            website: nil,
            instagram: "@basementdiscs",
            specialty: ["Rare Vinyl", "Collectibles", "Rock", "Soul"],
            logoFileName: nil
        ),
        Store(
            id: "berkelouw-paddington",
            name: "Berkelouw Books",
            address: "19 Oxford St",
            suburb: "Paddington",
            postcode: "2021",
            lat: -33.8848,
            lng: 151.2265,
            phone: "(02) 9360 3200",
            hours: "Daily 10am-6pm",
            description: "Beautiful bookstore with a curated selection of vinyl records. Perfect for a Sunday afternoon browse.",
            website: "https://berkelouw.com.au",
            instagram: "@berkelouwbooks",
            specialty: ["Classical", "Jazz", "Soundtrack", "World"],
            logoFileName: nil
        ),
        Store(
            id: "egg-records",
            name: "Egg Records Newtown",
            address: "3/166 King St",
            suburb: "Newtown",
            postcode: "2042",
            lat: -33.8964,
            lng: 151.1814,
            phone: "(02) 9550 3301",
            hours: "Daily 11am-7pm",
            description: "Newtown's legendary vinyl destination. Massive selection of new releases and second-hand gems.",
            website: "https://eggrecords.com",
            instagram: "@eggrecordsnewtown",
            specialty: ["Punk", "Metal", "Alternative", "Hip-Hop"],
            logoFileName: nil
        ),
        Store(
            id: "sonic-sherpa",
            name: "Sonic Sherpa",
            address: "34 Oxford St",
            suburb: "Darlinghurst",
            postcode: "2010",
            lat: -33.8774,
            lng: 151.2187,
            phone: "(02) 9331 3222",
            hours: "Daily 11am-7pm",
            description: "Electronic and dance music specialists. DJ equipment and rare imports.",
            website: "https://sonicsherpa.com",
            instagram: "@sonicsherpa",
            specialty: ["Electronic", "House", "Techno", "Ambient"],
            logoFileName: nil
        ),
        Store(
            id: "repressed-records",
            name: "Repressed Records",
            address: "401 King St",
            suburb: "Newtown",
            postcode: "2042",
            lat: -33.8982,
            lng: 151.1803,
            phone: nil,
            hours: "Tue-Sun 11am-6pm",
            description: "Newtown's newest vinyl haven. Focus on Australian artists and limited editions.",
            website: nil,
            instagram: "@repressedrecords",
            specialty: ["Australian", "Indie", "Limited Editions"],
            logoFileName: nil
        ),
        Store(
            id: "folkways-music",
            name: "Folkways Music",
            address: "282 Oxford St",
            suburb: "Paddington",
            postcode: "2021",
            lat: -33.8863,
            lng: 151.2289,
            phone: "(02) 9361 3980",
            hours: "Mon-Sat 10am-6pm, Sun 12pm-5pm",
            description: "Folk, acoustic, and world music specialists since 1976. Knowledgeable staff and listening stations.",
            website: "https://folkways.com.au",
            instagram: "@folkwaysmusic",
            specialty: ["Folk", "Acoustic", "World", "Blues"],
            logoFileName: nil
        )
    ]
}

extension Store {
    static let sampleStore = Store.defaultStores[0]
}
