//
//  StoreDetailView.swift
//  VinylVault
//
//  Created by WEIHUA ZHANG on 22/10/2025.
//

import SwiftUI
import MapKit

struct StoreDetailView: View {
    @Environment(\.dismiss) var dismiss
    let store: Store
    
    @StateObject private var locationService = LocationNotificationService.shared
    @State private var region: MKCoordinateRegion
    
    init(store: Store) {
        self.store = store
        _region = State(initialValue: MKCoordinateRegion(
            center: store.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var isMonitored: Bool {
        locationService.monitoredStoreIds.contains(store.id)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1a1a1a").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        mapSection
                        
                        VStack(spacing: 24) {
                            headerSection
                            infoSection
                            specialtySection
                            contactSection
                            actionButtons
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(store.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private var mapSection: some View {
        Map(coordinateRegion: .constant(region), annotationItems: [store]) { store in
            MapMarker(coordinate: store.coordinate, tint: .blue)
        }
        .frame(height: 250)
        .allowsHitTesting(false)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(store.suburb)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "music.note.house.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue.opacity(0.6))
            }
            
            Text(store.description)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
        }
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            InfoRow(icon: "mappin.circle.fill", title: "Address", value: store.fullAddress)
            
            if let phone = store.phone {
                InfoRow(icon: "phone.fill", title: "Phone", value: phone)
            }
            
            InfoRow(icon: "clock.fill", title: "Hours", value: store.hours)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
    
    private var specialtySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "music.note.list")
                    .foregroundColor(.blue)
                Text("Specialties")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(store.specialty, id: \.self) { genre in
                    Text(genre)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.2))
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
    
    private var contactSection: some View {
        VStack(spacing: 12) {
            if let website = store.website {
                Link(destination: URL(string: website)!) {
                    HStack {
                        Image(systemName: "globe")
                        Text("Visit Website")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
            
            if let instagram = store.instagram {
                Link(destination: URL(string: "https://instagram.com/\(instagram.replacingOccurrences(of: "@", with: ""))")!) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Follow on Instagram")
                        Spacer()
                        Text(instagram)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if locationService.isMonitoringEnabled {
                Button(action: {
                    locationService.toggleStoreMonitoring(for: store)
                }) {
                    HStack {
                        Image(systemName: isMonitored ? "bell.fill" : "bell.badge")
                        Text(isMonitored ? "Disable Alerts" : "Enable Alerts")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isMonitored ? Color.red.opacity(0.6) : Color.blue)
                    )
                }
            }
            
            Button(action: openMaps) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Get Directions")
                }
                .font(.system(size: 16, weight: .semibold))
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
            
            if let phone = store.phone {
                Button(action: { callStore(phone) }) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Call Store")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
        }
    }
    
    private func openMaps() {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: store.coordinate))
        mapItem.name = store.name
        mapItem.openInMaps(launchOptions: nil)
    }
    
    private func callStore(_ phone: String) {
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(value)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width, x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
                
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: width, height: y + lineHeight)
        }
    }
}

#Preview {
    StoreDetailView(store: Store.sampleStore)
}
