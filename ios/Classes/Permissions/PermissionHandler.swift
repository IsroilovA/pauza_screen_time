/// Handles permission checking and requesting for iOS Screen Time API.
///
/// This class manages Family Controls authorization which is required for:
/// - App restriction functionality (ManagedSettings)
/// - Usage statistics access (DeviceActivity)
/// - FamilyActivityPicker for app selection

import Foundation
import FamilyControls

/// Handler for iOS permission operations related to Screen Time API.
///
/// Uses FamilyControls.AuthorizationCenter to manage Screen Time permissions.
/// Note: The Screen Time API requires iOS 16.0+ for individual authorization
/// or iOS 15.0+ for family-based authorization.
@available(iOS 16.0, *)
class PermissionHandler {
    
    // MARK: - Permission Keys
    
    /// Permission key for Family Controls (matches Flutter IOSPermission enum).
    static let familyControlsKey = "ios.familyControls"
    
    /// Permission key for Screen Time (maps to same underlying authorization).
    static let screenTimeKey = "ios.screenTime"
    
    // MARK: - Permission Status Strings
    
    /// Status string for granted permission (matches Flutter PermissionStatus enum).
    static let statusGranted = "granted"
    
    /// Status string for denied permission.
    static let statusDenied = "denied"
    
    /// Status string for not determined permission (user hasn't been prompted yet).
    static let statusNotDetermined = "notDetermined"
    
    // MARK: - Singleton
    
    /// Shared instance of PermissionHandler.
    static let shared = PermissionHandler()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Checks the status of a specific iOS permission.
    ///
    /// - Parameter permissionKey: The permission key from IOSPermission enum
    ///   (e.g., "ios.familyControls" or "ios.screenTime").
    /// - Returns: String status: "granted", "denied", or "notDetermined".
    func checkPermission(permissionKey: String) -> String {
        switch permissionKey {
        case PermissionHandler.familyControlsKey, PermissionHandler.screenTimeKey:
            return checkFamilyControlsAuthorization()
        default:
            return PermissionHandler.statusDenied
        }
    }
    
    /// Requests a specific iOS permission from the user.
    ///
    /// - Parameter permissionKey: The permission key from IOSPermission enum.
    /// - Parameter completion: Callback with Boolean indicating if permission was granted.
    func requestPermission(permissionKey: String, completion: @escaping (Bool) -> Void) {
        switch permissionKey {
        case PermissionHandler.familyControlsKey, PermissionHandler.screenTimeKey:
            requestFamilyControlsAuthorization(completion: completion)
        default:
            completion(false)
        }
    }
    
    // MARK: - Private Methods
    
    /// Checks the current Family Controls authorization status.
    ///
    /// - Returns: Permission status string.
    private func checkFamilyControlsAuthorization() -> String {
        let status = AuthorizationCenter.shared.authorizationStatus
        return mapAuthorizationStatus(status)
    }
    
    /// Requests Family Controls authorization from the user.
    ///
    /// This will present a system dialog asking for Screen Time access.
    /// The user's Apple ID must have Screen Time enabled on the device.
    ///
    /// - Parameter completion: Callback with Boolean indicating if authorization was granted.
    private func requestFamilyControlsAuthorization(completion: @escaping (Bool) -> Void) {
        Task {
            do {
                // Request authorization for individual (non-child) use
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                
                // Check if authorization was granted
                let isGranted = AuthorizationCenter.shared.authorizationStatus == .approved
                await MainActor.run {
                    completion(isGranted)
                }
            } catch {
                // Authorization failed or was denied
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }
    
    /// Maps FamilyControls.AuthorizationStatus to Flutter PermissionStatus string.
    ///
    /// - Parameter status: The native authorization status.
    /// - Returns: String representation for Flutter.
    private func mapAuthorizationStatus(_ status: AuthorizationStatus) -> String {
        switch status {
        case .approved:
            return PermissionHandler.statusGranted
        case .denied:
            return PermissionHandler.statusDenied
        case .notDetermined:
            return PermissionHandler.statusNotDetermined
        @unknown default:
            return PermissionHandler.statusDenied
        }
    }
}

// MARK: - Fallback for iOS 15.x

/// Fallback permission handler for iOS versions below 16.0.
///
/// On iOS 15.x, FamilyControls is only available for child accounts
/// in a Family Sharing group. Individual authorization requires iOS 16.0+.
class LegacyPermissionHandler {
    
    /// Shared instance of LegacyPermissionHandler.
    static let shared = LegacyPermissionHandler()
    
    private init() {}
    
    /// Always returns "denied" for iOS 15.x since individual authorization
    /// is not supported.
    func checkPermission(permissionKey: String) -> String {
        return "denied"
    }
    
    /// Always returns false for iOS 15.x since individual authorization
    /// is not supported.
    func requestPermission(permissionKey: String, completion: @escaping (Bool) -> Void) {
        completion(false)
    }
}
