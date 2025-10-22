//
//  LocationNotificationService.swift
//  VinylVault
//
//  Created by WEIHUA ZHANG on 22/10/2025.
//

import Foundation
import CoreLocation
import UserNotifications
import Combine

class LocationNotificationService: NSObject, ObservableObject {
    static let shared = LocationNotificationService()
    
    private let locationManager = CLLocationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    @Published var isMonitoringEnabled = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var monitoredStoreIds: Set<String> = []
    
    private let monitoringRadius: CLLocationDistance = 200
    private let maxMonitoredRegions = 15
    
    private override init() {
        super.init()
        locationManager.delegate = self
        checkAuthorizationStatus()
        loadMonitoredStores()
    }
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { notifGranted, error in
            if let error = error {
                print("❌ Notification permission error: \(error)")
            }
            
            DispatchQueue.main.async {
                if notifGranted {
                    self.requestLocationPermission(completion: completion)
                } else {
                    print("❌ Notification permission denied")
                    completion(false)
                }
            }
        }
    }
    
    private func requestLocationPermission(completion: @escaping (Bool) -> Void) {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completion(self.locationManager.authorizationStatus == .authorizedWhenInUse ||
                          self.locationManager.authorizationStatus == .authorizedAlways)
            }
            
        case .authorizedWhenInUse:
            self.locationManager.requestAlwaysAuthorization()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completion(true)
            }
            
        case .authorizedAlways:
            completion(true)
            
        case .denied, .restricted:
            completion(false)
            
        @unknown default:
            completion(false)
        }
    }
    
    func enableMonitoring() {
        guard locationManager.authorizationStatus == .authorizedAlways ||
              locationManager.authorizationStatus == .authorizedWhenInUse else {
            print("⚠️ Location permission not granted")
            return
        }
        
        isMonitoringEnabled = true
        startMonitoringAllStores()
        saveMonitoringState()
        print("✅ Store monitoring enabled")
    }
    
    func disableMonitoring() {
        isMonitoringEnabled = false
        stopMonitoringAllStores()
        saveMonitoringState()
        print("🛑 Store monitoring disabled")
    }
    
    func toggleStoreMonitoring(for store: Store) {
        if monitoredStoreIds.contains(store.id) {
            stopMonitoring(store: store)
            monitoredStoreIds.remove(store.id)
        } else {
            startMonitoring(store: store)
            monitoredStoreIds.insert(store.id)
        }
        saveMonitoredStores()
    }
    
    private func startMonitoringAllStores() {
        let stores = StoreDataManager.shared.stores
        
        let storesToMonitor = Array(stores.prefix(maxMonitoredRegions))
        
        for store in storesToMonitor {
            startMonitoring(store: store)
            monitoredStoreIds.insert(store.id)
        }
        
        saveMonitoredStores()
    }
    
    private func stopMonitoringAllStores() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        monitoredStoreIds.removeAll()
        saveMonitoredStores()
    }
    
    private func startMonitoring(store: Store) {
        let region = CLCircularRegion(
            center: store.coordinate,
            radius: monitoringRadius,
            identifier: store.id
        )
        
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        locationManager.startMonitoring(for: region)
        
        print("📍 Started monitoring: \(store.name)")
    }
    
    private func stopMonitoring(store: Store) {
        if let region = locationManager.monitoredRegions.first(where: { $0.identifier == store.id }) {
            locationManager.stopMonitoring(for: region)
            print("🛑 Stopped monitoring: \(store.name)")
        }
    }
    
    private func sendNotification(for store: Store) {
        let notificationId = "store-entry-\(store.id)-\(Date().timeIntervalSince1970)"
        
        if hasRecentNotification(for: store.id) {
            print("⏭️ Skipping notification for \(store.name) (already sent recently)")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🎵 Near \(store.name)!"
        content.body = "\(store.description.prefix(80))..."
        content.sound = .default
        content.badge = 1
        content.userInfo = ["storeId": store.id]
        
        if let specialty = store.specialty.first {
            content.subtitle = "Specializing in \(specialty)"
        }
        
        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to send notification: \(error)")
            } else {
                print("✅ Notification sent for: \(store.name)")
                self.saveNotificationTimestamp(for: store.id)
            }
        }
    }
    
    private func hasRecentNotification(for storeId: String) -> Bool {
        let key = "lastNotification-\(storeId)"
        
        if let lastTime = UserDefaults.standard.object(forKey: key) as? Date {
            let hoursSince = Date().timeIntervalSince(lastTime) / 3600
            return hoursSince < 24
        }
        
        return false
    }
    
    private func saveNotificationTimestamp(for storeId: String) {
        let key = "lastNotification-\(storeId)"
        UserDefaults.standard.set(Date(), forKey: key)
    }
    
    private func checkAuthorizationStatus() {
        authorizationStatus = locationManager.authorizationStatus
    }
    
    private func saveMonitoringState() {
        UserDefaults.standard.set(isMonitoringEnabled, forKey: "storeMonitoringEnabled")
    }
    
    private func loadMonitoringState() {
        isMonitoringEnabled = UserDefaults.standard.bool(forKey: "storeMonitoringEnabled")
    }
    
    private func saveMonitoredStores() {
        let array = Array(monitoredStoreIds)
        UserDefaults.standard.set(array, forKey: "monitoredStoreIds")
    }
    
    private func loadMonitoredStores() {
        if let array = UserDefaults.standard.array(forKey: "monitoredStoreIds") as? [String] {
            monitoredStoreIds = Set(array)
        }
    }
}

extension LocationNotificationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        print("📍 Location authorization changed: \(authorizationStatus.rawValue)")
        
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            if isMonitoringEnabled {
                startMonitoringAllStores()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let storeId = region.identifier as String?,
              let store = StoreDataManager.shared.store(withId: storeId) else {
            return
        }
        
        print("🎯 Entered region: \(store.name)")
        
        Task { @MainActor in
            sendNotification(for: store)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let storeId = region.identifier as String?,
           let store = StoreDataManager.shared.store(withId: storeId) {
            print("👋 Exited region: \(store.name)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("❌ Monitoring failed for region: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if let storeId = region.identifier as String?,
           let store = StoreDataManager.shared.store(withId: storeId) {
            print("✅ Started monitoring region: \(store.name)")
        }
    }
}

extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When In Use"
        @unknown default: return "Unknown"
        }
    }
}
