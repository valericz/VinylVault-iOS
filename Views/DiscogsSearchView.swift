import SwiftUI
import Foundation
import Combine

struct DiscogsSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = DiscogsService()

    // 单例不要用 StateObject（避免重复创建持有），改为 ObservedObject / EnvironmentObject
    @ObservedObject private var dataManager = DataManager.shared

    @State private var searchText = ""
    @State private var searchResults: [DiscogsSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var selectedAlbum: DiscogsSearchResult?
    @FocusState private var searchFocused: Bool

    // 用来取消上一次搜索，避免结果乱序覆盖
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    content
                        .navigationTitle("Search Discogs")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Cancel") {
                                    dismissKeyboard()
                                    dismiss()
                                }
                                .foregroundColor(.white)
                            }
                        }
                        // 顶部固定区域：搜索条 + 大按钮（不随内容滚动/不叠）
                        .safeAreaInset(edge: .top) {
                            VStack(spacing: 10) {
                                searchBar
                                primarySearchButton
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 10)
                            .background(Color(hex: "1a1a1a").opacity(0.98))
                            .overlay(Divider().background(Color.white.opacity(0.08)), alignment: .bottom)
                        }
                }
            } else {
                // 旧系统兜底
                NavigationView {
                    content
                        .navigationTitle("Search Discogs")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Cancel") {
                                    dismissKeyboard()
                                    dismiss()
                                }
                                .foregroundColor(.white)
                            }
                        }
                        .overlay(alignment: .top) {
                            // iOS 15- 的近似实现：固定在顶部（会盖住内容顶部一小段）
                            VStack(spacing: 10) {
                                searchBar
                                primarySearchButton
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 10)
                            .background(Color(hex: "1a1a1a").opacity(0.98))
                            .overlay(Divider().background(Color.white.opacity(0.08)), alignment: .bottom)
                        }
                        .padding(.top, 110) // 留出给 overlay 的高度
                }
            }
        }
        .sheet(item: $selectedAlbum) { album in
            AlbumImportView(discogsResult: album)
        }
    }

    // MARK: - 顶部搜索条（固定）
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.6))

            TextField("Search vinyl on Discogs...", text: $searchText)
                .foregroundColor(.white)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .focused($searchFocused)
                .submitLabel(.search)
                .onSubmit { performSearch() }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                    errorMessage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }

    // MARK: - 顶部主按钮（固定）
    private var primarySearchButton: some View {
        Button(action: performSearch) {
            HStack(spacing: 8) {
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(isSearching ? "Searching Discogs..." : "Search Discogs Database")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(colors: [Color.blue, Color.purple],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(searchText.isEmpty ? 0.5 : 1)
        }
        .disabled(searchText.isEmpty || isSearching)
    }

    // MARK: - 主内容（滚动区域）
    private var content: some View {
        ZStack {
            Color(hex: "1a1a1a").ignoresSafeArea()
            Group {
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
            .animation(.easeInOut(duration: 0.2), value: isSearching)
            .animation(.easeInOut(duration: 0.2), value: errorMessage)
           
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(.white)

            Text("Searching Discogs...")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.75))

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
                .foregroundColor(.red.opacity(0.85))

            Text("Oops!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Text(error)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                errorMessage = nil
                performSearch()
            } label: {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
                Text("vinyl and music database")
            }
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.6))

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
            .padding(16)
        }
    }

    // MARK: - Search Action（带取消上一次任务）
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        dismissKeyboard()
        isSearching = true
        errorMessage = nil
        searchResults = []

        // 取消之前的搜索，避免竞态
        searchTask?.cancel()

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        searchTask = Task {
            do {
                let results = try await service.searchAlbums(query: query)
                if Task.isCancelled { return }
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                    if results.isEmpty {
                        errorMessage = "No results found. Try a different search term."
                    }
                }
            } catch let error as DiscogsError {
                if Task.isCancelled { return }
                await MainActor.run {
                    errorMessage = error.errorDescription ?? "Unknown error occurred"
                    isSearching = false
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    errorMessage = "Could not connect to Discogs. Please check your internet connection."
                    isSearching = false
                }
            }
        }
    }

    private func dismissKeyboard() {
        searchFocused = false
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
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
                // Cover
                if let thumbUrl = result.thumb, !thumbUrl.isEmpty {
                    AsyncImage(url: URL(string: thumbUrl)) { phase in
                        switch phase {
                        case .empty:
                            placeholderImage
                        case .success(let image):
                            image.resizable()
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

                // Info
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
                                .foregroundColor(.white.opacity(0.55))
                        }
                        if let year = result.year, !result.primaryGenre.isEmpty {
                            Text("•").foregroundColor(.white.opacity(0.3))
                        }
                        if !result.primaryGenre.isEmpty && result.primaryGenre != "Unknown" {
                            Text(result.primaryGenre)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.55))
                                .lineLimit(1)
                        }
                    }

                    if let rating = result.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.75))
                        }
                    }
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
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
