import SwiftUI
import CoreLocation

struct StoresView: View {
    @StateObject private var locationService = LocationNotificationService.shared
    @State private var searchText = ""
    @State private var showingPermissionAlert = false
    @State private var selectedStore: Store?
    
    var storeManager = StoreDataManager.shared
    
    var filteredStores: [Store] {
        if searchText.isEmpty {
            return storeManager.stores
        }
        return storeManager.stores.filter { store in
            store.name.localizedCaseInsensitiveContains(searchText) ||
            store.suburb.localizedCaseInsensitiveContains(searchText) ||
            store.specialty.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "1a1a1a"), Color(hex: "2d2d2d")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    monitoringToggleSection
                    
                    if !filteredStores.isEmpty {
                        storesGrid
                    } else {
                        emptyStateView
                    }
                }
            }
            .navigationTitle("🎵 Record Stores")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search stores or suburbs")
            .alert("Enable Location Services", isPresented: $showingPermissionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("To receive notifications when you're near record stores, please enable location services in Settings.")
            }
            .sheet(item: $selectedStore) { store in
                StoreDetailView(store: store)
            }
        }
    }
    
    private var monitoringToggleSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: locationService.isMonitoringEnabled ? "bell.fill" : "bell.slash.fill")
                            .font(.system(size: 20))
                            .foregroundColor(locationService.isMonitoringEnabled ? .blue : .white.opacity(0.5))
                        
                        Text("Nearby Alerts")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text(locationService.isMonitoringEnabled ? "You'll be notified when near stores" : "Enable to get notified near stores")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { locationService.isMonitoringEnabled },
                    set: { newValue in
                        if newValue {
                            enableMonitoring()
                        } else {
                            locationService.disableMonitoring()
                        }
                    }
                ))
                .labelsHidden()
                .tint(.blue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
            
            
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
    
    private var storesGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredStores) { store in
                    StoreCard(store: store)
                        .onTapGesture {
                            selectedStore = store
                        }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No Stores Found")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Try a different search term")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxHeight: .infinity)
    }
    
    private func enableMonitoring() {
        let status = locationService.authorizationStatus
        
        if status == .denied || status == .restricted {
            showingPermissionAlert = true
            return
        }
        
        if status == .notDetermined || status == .authorizedWhenInUse {
            locationService.requestPermissions { granted in
                if granted {
                    locationService.enableMonitoring()
                } else {
                    showingPermissionAlert = true
                }
            }
        } else {
            locationService.enableMonitoring()
        }
    }
}

struct StoreStatCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

#Preview {
    StoresView()
}
