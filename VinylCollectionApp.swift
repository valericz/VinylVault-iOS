import SwiftUI


@main
struct VinylVaultApp: App {
    init() {
        print("🚀 App launching...")
        print("🚀 App Group ID: \(AppGroup.identifier)")
        
        let albums = DataManager.shared.albums
        print("🚀 App has \(albums.count) albums")
        
        AppGroup.saveAlbums(albums)
        
        let loaded = AppGroup.loadAlbums()
        print("🚀 Verified: \(loaded.count) albums saved to App Group")
        
        requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied")
            }
            
            if let error = error {
                print("❌ Notification error: \(error)")
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "square.grid.2x2")
                }
            
            WishlistView()
                .tabItem {
                    Label("Wishlist", systemImage: "heart.text.square")
                }
            
            StatisticsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .accentColor(.white)
    }
}

// MARK: - Statistics View
struct StatisticsView: View {
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1a1a1a").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Overview Cards
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            OverviewCard(
                                icon: "music.note.list",
                                title: "Total Albums",
                                value: "\(dataManager.totalAlbums)",
                                color: .blue
                            )
                            
                            OverviewCard(
                                icon: "star.fill",
                                title: "Avg Rating",
                                value: String(format: "%.1f", dataManager.averageRating),
                                color: .yellow
                            )
                            
                            OverviewCard(
                                icon: "dollarsign.circle.fill",
                                title: "Total Value",
                                value: "$\(Int(dataManager.totalValue))",
                                color: .green
                            )
                            
                            OverviewCard(
                                icon: "heart.fill",
                                title: "Favorites",
                                value: "\(dataManager.favoriteAlbums.count)",
                                color: .red
                            )
                        }
                        .padding(.horizontal)
                        
                        // Genre Distribution
                        if !dataManager.genreBreakdown.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "guitars")
                                    Text("By Genre")
                                        .font(.system(size: 20, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    ForEach(dataManager.genreBreakdown.prefix(5), id: \.genre) { item in
                                        GenreBar(
                                            genre: item.genre,
                                            count: item.count,
                                            total: dataManager.totalAlbums
                                        )
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                )
                                .padding(.horizontal)
                            }
                        }
                        
                        // Top Rated Albums
                        if !dataManager.topRated.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "trophy.fill")
                                    Text("Top Rated")
                                        .font(.system(size: 20, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    ForEach(dataManager.topRated.prefix(5)) { album in
                                        NavigationLink(destination: AlbumDetailView(album: album)) {
                                            TopRatedRow(album: album)
                                        }
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Overview Card
struct OverviewCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Genre Bar
struct GenreBar: View {
    let genre: String
    let count: Int
    let total: Int
    
    var percentage: Double {
        Double(count) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(genre)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("(\(Int(percentage * 100))%)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * percentage, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Top Rated Row
struct TopRatedRow: View {
    let album: VinylAlbum
    
    var body: some View {
        HStack(spacing: 12) {
            if let image = album.coverImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.5))
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(album.artist)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                Text(String(format: "%.1f", album.rating))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var showingExportSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1a1a1a").ignoresSafeArea()
                
                Form {
                    // App Info
                    Section {
                        VStack(alignment: .center, spacing: 12) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Vinyl Collection Manager")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Version 1.0.0")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                        .listRowBackground(Color.white.opacity(0.08))
                    }
                    
                    // Collection Stats
                    Section("Collection") {
                        HStack {
                            Text("Total Albums")
                            Spacer()
                            Text("\(dataManager.totalAlbums)")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        HStack {
                            Text("Favorites")
                            Spacer()
                            Text("\(dataManager.favoriteAlbums.count)")
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                    
                    // Data Management
                    Section("Data") {
                        Button(action: exportCollection) {
                            Label("Export Collection", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: {}) {
                            Label("Import Collection", systemImage: "square.and.arrow.down")
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                    
                    // About
                    Section("About") {
                        Link(destination: URL(string: "https://www.discogs.com")!) {
                            HStack {
                                Label("Powered by Discogs", systemImage: "link")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                }
                .scrollContentBackground(.hidden)
                .foregroundColor(.white)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Export Successful", isPresented: $showingExportSuccess) {
                Button("OK") { }
            } message: {
                Text("Your collection has been exported successfully!")
            }
        }
    }
    
    private func exportCollection() {
        guard let data = dataManager.exportAlbums() else {
            print("❌ Failed to export")
            return
        }
        
        // 创建文件
        let fileName = "VinylVault_Backup_\(Date().formatted(date: .numeric, time: .omitted)).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            
            // 显示分享菜单
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            // 获取当前window scene
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                
                // iPad需要设置popover
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = window
                    popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                rootVC.present(activityVC, animated: true)
            }
            
            showingExportSuccess = true
            
        } catch {
            print("❌ Error saving file: \(error)")
        }
    }
}
#Preview {
    MainTabView()
}
