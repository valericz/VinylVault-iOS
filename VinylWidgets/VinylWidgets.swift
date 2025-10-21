import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct VinylEntry: TimelineEntry {
    let date: Date
    let albums: [VinylAlbum]
}

// MARK: - Widget Provider
struct VinylProvider: TimelineProvider {
    func placeholder(in context: Context) -> VinylEntry {
        VinylEntry(date: Date(), albums: Array(VinylAlbum.sampleData.prefix(6)))
    }

    func getSnapshot(in context: Context, completion: @escaping (VinylEntry) -> Void) {
        // 🔍 添加调试信息
        print("📱 Widget getSnapshot called")
        print("📱 App Group ID: \(AppGroup.identifier)")
        
        let albums = AppGroup.loadAlbums()
        print("📱 Loaded \(albums.count) albums in widget")
        
        // 如果没有数据，使用示例数据
        let entry = VinylEntry(
            date: Date(),
            albums: albums.isEmpty ? Array(VinylAlbum.sampleData.prefix(9)) : albums
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VinylEntry>) -> ()) {
        // 🔍 添加调试信息
        print("📱 Widget getTimeline called")
        
        let albums = AppGroup.loadAlbums()
        print("📱 Timeline: Loaded \(albums.count) albums")
        
        // 如果没有数据，使用示例数据
        let finalAlbums = albums.isEmpty ? Array(VinylAlbum.sampleData.prefix(9)) : albums
        
        let entry = VinylEntry(date: Date(), albums: finalAlbums)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Album Cover with Border and Rotation
struct StyledAlbumCover: View {
    let album: VinylAlbum?
    let size: CGFloat
    let rotation: Double

    var body: some View {
        Group {
            if let album = album, let image = album.coverImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.white, lineWidth: 2.5)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
                    .rotationEffect(.degrees(rotation))
            } else if let _ = album {
                // 占位图 - 有专辑但无封面
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0.7, green: 0.7, blue: 0.75))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: size * 0.3))
                            .foregroundColor(.white.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.white, lineWidth: 2.5)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
                    .rotationEffect(.degrees(rotation))
            }
        }
    }
}

// MARK: - Wooden Shelf (Beige Style)
struct BeigeWoodenShelf: View {
    var body: some View {
        VStack(spacing: 0) {
            // 顶部边缘 - 深棕色
            Rectangle()
                .fill(Color(hex: "451a03"))
                .frame(height: 2)

            // 主体 - 琥珀棕色渐变（约 16）
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "b45309"),
                            Color(hex: "92400e"),
                            Color(hex: "78350f")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 16)

            // 底部阴影
            Rectangle()
                .fill(Color(hex: "451a03").opacity(0.5))
                .frame(height: 2)
        }
    }
}

// MARK: - Small Widget: Full Cover
struct SmallWidgetView: View {
    let album: VinylAlbum

    var body: some View {
        ZStack {
            if let image = album.coverImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "music.note")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(.gray.opacity(0.4))

                    Text("No Album")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - Medium Widget: Single Shelf (3 Albums)
struct MediumShelfWidgetView: View {
    let albums: [VinylAlbum]

    // 获取前3张专辑，不足则用nil补位
    var displayAlbums: [VinylAlbum?] {
        var result: [VinylAlbum?] = []
        for i in 0..<3 {
            if i < albums.count {
                result.append(albums[i])
            } else {
                result.append(nil)
            }
        }
        return result
    }

    // 随机旋转角度（保持你原逻辑）
    let rotations: [Double] = [
        Double.random(in: -3...3),
        Double.random(in: -3...3),
        Double.random(in: -3...3)
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // 专辑区域
            HStack(spacing: 16) {
                Spacer()

                ForEach(0..<3, id: \.self) { index in
                    StyledAlbumCover(
                        album: displayAlbums[index],
                        size: 100,
                        rotation: rotations[index]
                    )
                }

                Spacer()
            }
            .padding(.bottom, 4)

            // 木质书架
            BeigeWoodenShelf()
                .padding(.horizontal, 24)
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Large Widget: size-aware layout
struct LargeWidgetView: View {
    let albums: [VinylAlbum]

    var topShelf: [VinylAlbum?]    { slice(0) }
    var middleShelf: [VinylAlbum?] { slice(3) }
    var bottomShelf: [VinylAlbum?] { slice(6) }

    private func slice(_ start: Int) -> [VinylAlbum?] {
        (0..<3).map { i in
            let idx = start + i
            return idx < albums.count ? albums[idx] : nil
        }
    }

    // Use small, deterministic rotations so they don't unexpectedly reflow
    private func rotationsForRow(_ row: Int) -> [Double] {
        // Seeded-ish tiny tilts to keep “polaroid” vibe without clipping
        switch row {
        case 0: return [-1.6, 0.8, -0.9]
        case 1: return [ 1.2, -1.0,  0.6]
        default: return [-0.7, 1.1, -1.3]
        }
    }

    var body: some View {
        GeometryReader { geo in
            // Tunables
            let horizontalPadding: CGFloat = 24
            let interItemSpacing: CGFloat = 16
            let shelfThickness: CGFloat = 20     // BeigeWoodenShelf: 2 + 16 + 2
            let rowGap: CGFloat = 12
            let topPadding: CGFloat = 10
            let bottomPadding: CGFloat = 10

            // Compute album size so 3x rows + shelves fit vertically
            // Vertical budget = H - paddings - two row gaps - 3 shelves
            let verticalBudget = geo.size.height - topPadding - bottomPadding
                                  - (2 * rowGap) - (3 * shelfThickness) - 1 // safety pixel
            let albumSizeFromHeight = verticalBudget / 3.0

            // Horizontal budget for 3 squares + 2 spacings
            let horizontalBudget = geo.size.width - (2 * horizontalPadding) - (2 * interItemSpacing)
            let albumSizeFromWidth = horizontalBudget / 3.0

            // Final album size is the limiting factor, with a tiny reduction for rotation
            let albumSize = max(0, min(albumSizeFromHeight, albumSizeFromWidth)) * 0.96

            VStack(spacing: 0) {
                Spacer(minLength: topPadding)

                ShelfRow(
                    albums: topShelf,
                    rotations: rotationsForRow(0),
                    albumSize: albumSize,
                    interItemSpacing: interItemSpacing,
                    horizontalPadding: horizontalPadding,
                    shelfThickness: shelfThickness
                )

                Spacer(minLength: rowGap)

                ShelfRow(
                    albums: middleShelf,
                    rotations: rotationsForRow(1),
                    albumSize: albumSize,
                    interItemSpacing: interItemSpacing,
                    horizontalPadding: horizontalPadding,
                    shelfThickness: shelfThickness
                )

                Spacer(minLength: rowGap)

                ShelfRow(
                    albums: bottomShelf,
                    rotations: rotationsForRow(2),
                    albumSize: albumSize,
                    interItemSpacing: interItemSpacing,
                    horizontalPadding: horizontalPadding,
                    shelfThickness: shelfThickness
                )

                Spacer(minLength: bottomPadding)
            }
        }
    }
}

// MARK: - Shelf Row with size-aware album area
struct ShelfRow: View {
    let albums: [VinylAlbum?]
    let rotations: [Double]
    let albumSize: CGFloat
    let interItemSpacing: CGFloat
    let horizontalPadding: CGFloat
    let shelfThickness: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            // Album area: give enough height so rotation won’t clip
            ZStack(alignment: .bottom) {
                Color.clear
                    .frame(height: albumSize * 1.1) // little headroom for rotation

                HStack(spacing: interItemSpacing) {
                    Spacer(minLength: horizontalPadding)
                    ForEach(0..<3, id: \.self) { i in
                        if let album = albums[i] {
                            StyledAlbumCover(
                                album: album,
                                size: albumSize,
                                rotation: rotations[i]
                            )
                            .compositingGroup() // better shadow/clipping behavior when rotated
                        } else {
                            Color.clear.frame(width: albumSize, height: albumSize)
                        }
                    }
                    Spacer(minLength: horizontalPadding)
                }
            }
            .padding(.bottom, 4)

            // Shelf (fixed thickness)
            BeigeWoodenShelf()
                .frame(height: shelfThickness)
                .padding(.horizontal, horizontalPadding)
        }
    }
}

// MARK: - Empty State
struct EmptyStateWidgetView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.gray.opacity(0.4))

            Text("No Albums Yet")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray.opacity(0.7))

            Text("Add vinyl to your collection")
                .font(.system(size: 11))
                .foregroundColor(.gray.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Widget Configuration
struct VinylWidget: Widget {
    let kind: String = "VinylWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VinylProvider()) { entry in
            VinylWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [
                            Color(hex: "e7e5e4"),
                            Color(hex: "d6d3d1")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .configurationDisplayName("Vinyl Collection")
        .description("Display your vinyl collection on your home screen")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Entry View
struct VinylWidgetEntryView: View {
    var entry: VinylEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        if entry.albums.isEmpty {
            EmptyStateWidgetView()
        } else {
            switch widgetFamily {
            case .systemSmall:
                SmallWidgetView(album: entry.albums[0])
            case .systemMedium:
                MediumShelfWidgetView(albums: entry.albums)
            case .systemLarge:
                LargeWidgetView(albums: entry.albums)
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Widget Bundle
@main
struct VinylWidgets: WidgetBundle {
    var body: some Widget {
        VinylWidget()
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    VinylWidget()
} timeline: {
    VinylEntry(date: .now, albums: VinylAlbum.sampleData)
}

#Preview(as: .systemMedium) {
    VinylWidget()
} timeline: {
    VinylEntry(date: .now, albums: VinylAlbum.sampleData)
}

#Preview(as: .systemLarge) {
    VinylWidget()
} timeline: {
    VinylEntry(date: .now, albums: VinylAlbum.sampleData)
}
