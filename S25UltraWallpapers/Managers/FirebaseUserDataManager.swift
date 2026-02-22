import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

// MARK: - Firebase User Data Manager
@MainActor
class FirebaseUserDataManager: ObservableObject {
    static let shared = FirebaseUserDataManager()
    
    private let db = Firestore.firestore()
    @Published var isLoading = false
    @Published var syncError: String?
    
    private init() {}
    
    // MARK: - User Data Structure
    struct UserData {
        let uid: String
        let displayName: String
        let email: String
        let photoUrl: String?
        let favorites: [String]
        let premium: Bool
        let premiumType: String?
        let premiumSince: Date?
        let premiumExpiry: Date?
        
        var dictionary: [String: Any] {
            var dict: [String: Any] = [
                "displayName": displayName,
                "email": email,
                "favorites": favorites,
                "premium": premium
            ]
            
            if let photoUrl = photoUrl {
                dict["photoUrl"] = photoUrl
            }
            
            if let premiumType = premiumType {
                dict["premiumType"] = premiumType
            } else {
                dict["premiumType"] = NSNull()
            }
            
            if let premiumSince = premiumSince {
                dict["premiumSince"] = Timestamp(date: premiumSince)
            } else {
                dict["premiumSince"] = NSNull()
            }
            
            if let premiumExpiry = premiumExpiry {
                dict["premiumExpiry"] = Timestamp(date: premiumExpiry)
            } else {
                dict["premiumExpiry"] = NSNull()
            }
            
            return dict
        }
        
        init(uid: String, data: [String: Any]) {
            self.uid = uid
            self.displayName = data["displayName"] as? String ?? "User"
            self.email = data["email"] as? String ?? ""
            self.photoUrl = data["photoUrl"] as? String
            self.favorites = data["favorites"] as? [String] ?? []
            self.premium = data["premium"] as? Bool ?? false
            self.premiumType = data["premiumType"] as? String
            
            if let timestamp = data["premiumSince"] as? Timestamp {
                self.premiumSince = timestamp.dateValue()
            } else {
                self.premiumSince = nil
            }
            
            if let timestamp = data["premiumExpiry"] as? Timestamp {
                self.premiumExpiry = timestamp.dateValue()
            } else {
                self.premiumExpiry = nil
            }
        }
    }
    
    // MARK: - Firebase Collection Path
    private func userDocumentPath(for uid: String) -> DocumentReference {
        return db.collection("Users")
            .document("SamsungWallpapers")
            .collection("S25UltraIOSUsers")
            .document(uid)
    }
    
    // MARK: - User Data Sync
    func syncUserDataOnSignIn() async {
        guard let user = Auth.auth().currentUser else {
            print("❌ No authenticated user found")
            return
        }
        
        isLoading = true
        syncError = nil
        
        do {
            let userRef = userDocumentPath(for: user.uid)
            let document = try await userRef.getDocument()
            
            if document.exists {
                // User exists, fetch and update local data
                try await fetchAndUpdateUserData(for: user.uid)
                print("✅ Existing user data fetched and synced")
            } else {
                // New user, create initial document
                try await createInitialUserDocument(user: user)
                print("✅ New user document created")
            }
        } catch {
            syncError = "Failed to sync user data: \(error.localizedDescription)"
            print("❌ Firebase sync error: \(error)")
        }
        
        isLoading = false
    }
    
    private func createInitialUserDocument(user: User) async throws {
        let initialData: [String: Any] = [
            "displayName": user.displayName ?? "User",
            "email": user.email ?? "",
            "photoUrl": user.photoURL?.absoluteString ?? NSNull(),
            "favorites": [],
            "premium": false,
            "premiumType": NSNull(),
            "premiumSince": NSNull(),
            "premiumExpiry": NSNull()
        ]
        
        let userData = UserData(uid: user.uid, data: initialData)
        
        let userRef = userDocumentPath(for: user.uid)
        try await userRef.setData(userData.dictionary)
        
        // Update local UserManager
        await updateLocalUserManager(with: userData)
    }
    
    private func fetchAndUpdateUserData(for uid: String) async throws {
        let userRef = userDocumentPath(for: uid)
        let document = try await userRef.getDocument()
        
        guard document.exists, let data = document.data() else {
            throw FirebaseError.userDataNotFound
        }
        
        let userData = UserData(uid: uid, data: data)
        await updateLocalUserManager(with: userData)
    }
    
    private func updateLocalUserManager(with userData: UserData) async {
        // Update UserManager with Firebase data
        UserManager.shared.updateFromFirebase(
            displayName: userData.displayName,
            email: userData.email,
            profileImageURL: userData.photoUrl
        )
        
        // Update premium status
        if userData.premium {
            let premiumType: UserManager.PremiumType
            switch userData.premiumType {
            case "Monthly":
                premiumType = .monthly
            case "Yearly":
                premiumType = .yearly
            case "Lifetime":
                premiumType = .lifetime
            default:
                premiumType = .none
            }
            
            UserManager.shared.updatePremiumStatus(
                type: premiumType,
                activeSince: userData.premiumSince,
                expiryDate: userData.premiumExpiry
            )
        } else {
            UserManager.shared.updatePremiumStatus(type: .none)
        }
        
        print("✅ UserManager updated with Firebase data")
    }
    
    // MARK: - Premium Status Update
    func updatePremiumStatus(
        premium: Bool,
        premiumType: String?,
        premiumSince: Date?,
        premiumExpiry: Date?
    ) async {
        guard let user = Auth.auth().currentUser else {
            print("❌ No authenticated user for premium update")
            return
        }
        
        isLoading = true
        
        do {
            let userRef = userDocumentPath(for: user.uid)
            
            var updateData: [String: Any] = [
                "premium": premium
            ]
            
            if let premiumType = premiumType {
                updateData["premiumType"] = premiumType
            } else {
                updateData["premiumType"] = NSNull()
            }
            
            if let premiumSince = premiumSince {
                updateData["premiumSince"] = Timestamp(date: premiumSince)
            } else {
                updateData["premiumSince"] = NSNull()
            }
            
            if let premiumExpiry = premiumExpiry {
                updateData["premiumExpiry"] = Timestamp(date: premiumExpiry)
            } else {
                updateData["premiumExpiry"] = NSNull()
            }
            
            try await userRef.updateData(updateData)
            print("✅ Premium status updated in Firebase")
            
            // Also update local UserManager
            let userManagerPremiumType: UserManager.PremiumType
            switch premiumType {
            case "Monthly":
                userManagerPremiumType = .monthly
            case "Yearly":
                userManagerPremiumType = .yearly
            case "Lifetime":
                userManagerPremiumType = .lifetime
            default:
                userManagerPremiumType = .none
            }
            
            UserManager.shared.updatePremiumStatus(
                type: userManagerPremiumType,
                activeSince: premiumSince,
                expiryDate: premiumExpiry
            )
            
        } catch {
            syncError = "Failed to update premium status: \(error.localizedDescription)"
            print("❌ Premium update error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Favorites Sync
    func updateFavorites(_ favorites: [String]) async {
        guard let user = Auth.auth().currentUser else {
            print("❌ No authenticated user for favorites update")
            return
        }
        
        do {
            let userRef = userDocumentPath(for: user.uid)
            try await userRef.updateData(["favorites": favorites])
            print("✅ Favorites updated in Firebase")
        } catch {
            print("❌ Favorites update error: \(error)")
        }
    }
    
    // MARK: - Profile Updates
    func updateProfile(displayName: String, photoUrl: String?) async {
        guard let user = Auth.auth().currentUser else {
            print("❌ No authenticated user for profile update")
            return
        }
        
        do {
            let userRef = userDocumentPath(for: user.uid)
            var updateData: [String: Any] = ["displayName": displayName]
            
            if let photoUrl = photoUrl {
                updateData["photoUrl"] = photoUrl
            }
            
            try await userRef.updateData(updateData)
            print("✅ Profile updated in Firebase")
        } catch {
            print("❌ Profile update error: \(error)")
        }
    }
}

// MARK: - Firebase Error Types
enum FirebaseError: Error, LocalizedError {
    case userDataNotFound
    case syncFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .userDataNotFound:
            return "User data not found in Firebase"
        case .syncFailed(let message):
            return "Firebase sync failed: \(message)"
        }
    }
}