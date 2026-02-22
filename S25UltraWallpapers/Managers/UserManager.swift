import SwiftUI
import FirebaseAuth
import GoogleSignIn
import Firebase

@MainActor
class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var isSignedIn: Bool = false
    @Published var user: User? = nil
    @Published var displayName: String = "Guest User"
    @Published var email: String = ""
    @Published var profileImageURL: String? = nil
    @Published var isPremium: Bool = false
    @Published var premiumType: PremiumType = .none
    @Published var premiumActiveSince: Date? = nil
    @Published var premiumExpiryDate: Date? = nil
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    enum PremiumType: String, CaseIterable {
        case none = "None"
        case monthly = "Monthly"
        case yearly = "Yearly"
        case lifetime = "Lifetime"
    }
    
    private init() {
        checkAuthenticationState()
        setupAuthStateListener()
        loadPremiumStatus()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.updateUserState(user: user)
            }
        }
    }
    
    private func updateUserState(user: User?) {
        self.user = user
        self.isSignedIn = user != nil
        
        if let user = user {
            self.displayName = user.displayName ?? "User"
            self.email = user.email ?? ""
            self.profileImageURL = user.photoURL?.absoluteString
        } else {
            self.displayName = "Guest User"
            self.email = ""
            self.profileImageURL = nil
            // Clear premium status when user signs out
            clearPremiumStatusOnSignOut()
        }
    }
    
    private func checkAuthenticationState() {
        updateUserState(user: Auth.auth().currentUser)
    }
    
    private func loadPremiumStatus() {
        // Load from UserDefaults (in real app, this would sync with server)
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        
        if let premiumTypeString = UserDefaults.standard.string(forKey: "premiumType") {
            premiumType = PremiumType(rawValue: premiumTypeString) ?? .none
        }
        
        if let activeSinceData = UserDefaults.standard.data(forKey: "premiumActiveSince") {
            premiumActiveSince = try? JSONDecoder().decode(Date.self, from: activeSinceData)
        }
        
        if let expiryData = UserDefaults.standard.data(forKey: "premiumExpiryDate") {
            premiumExpiryDate = try? JSONDecoder().decode(Date.self, from: expiryData)
        }
    }
    
    func signInWithGoogle() {
        print("📱 Initiating Google Sign-In...")
        
        guard let presentingViewController = getRootViewController() else {
            print("❌ No presenting view controller found")
            return
        }
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("❌ No Firebase client ID found")
            return
        }
        
        // Configure Google Sign-In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start sign-in flow
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            if let error = error {
                print("❌ Google Sign-In error: \(error.localizedDescription)")
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("❌ Failed to get Google Sign-In credentials")
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            // Sign in to Firebase
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                if let error = error {
                    print("❌ Firebase sign-in error: \(error.localizedDescription)")
                    return
                }
                
                print("✅ Successfully signed in with Google")
                Task { @MainActor in
                    self?.updateUserState(user: authResult?.user)
                    // Sync user data with Firebase
                    await FirebaseUserDataManager.shared.syncUserDataOnSignIn()
                }
            }
        }
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
    
    func signOut() {
        do {
            // Sign out from Firebase
            try Auth.auth().signOut()
            
            // Sign out from Google
            GIDSignIn.sharedInstance.signOut()
            
            // Clear premium status when signing out
            clearPremiumStatusOnSignOut()
            
            print("📱 User signed out successfully")
        } catch {
            print("📱 Error signing out: \(error.localizedDescription)")
        }
    }
    
    func updatePremiumStatus(type: PremiumType, activeSince: Date? = nil, expiryDate: Date? = nil) {
        isPremium = type != .none
        premiumType = type
        premiumActiveSince = activeSince ?? Date()
        premiumExpiryDate = expiryDate
        
        // Save to UserDefaults
        UserDefaults.standard.set(isPremium, forKey: "isPremium")
        UserDefaults.standard.set(type.rawValue, forKey: "premiumType")
        
        if let activeSince = premiumActiveSince,
           let data = try? JSONEncoder().encode(activeSince) {
            UserDefaults.standard.set(data, forKey: "premiumActiveSince")
        }
        
        if let expiryDate = premiumExpiryDate,
           let data = try? JSONEncoder().encode(expiryDate) {
            UserDefaults.standard.set(data, forKey: "premiumExpiryDate")
        }
    }
    
    var premiumStatusText: String {
        guard isPremium else { return "Not Active" }
        
        switch premiumType {
        case .none:
            return "Not Active"
        case .monthly:
            return "Monthly Subscription"
        case .yearly:
            return "Yearly Subscription"
        case .lifetime:
            return "Lifetime Premium"
        }
    }
    
    var premiumExpiryText: String? {
        guard isPremium, premiumType != .lifetime, let expiry = premiumExpiryDate else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Expires: \(formatter.string(from: expiry))"
    }
    
    var premiumActiveSinceText: String? {
        guard isPremium, let activeSince = premiumActiveSince else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Active since: \(formatter.string(from: activeSince))"
    }
    
    // MARK: - Premium Management for Firebase Pricing System
    
    func setPremiumStatus(_ isPremium: Bool, plan: PremiumPlan) {
        let premiumType: PremiumType
        var expiryDate: Date?
        
        switch plan {
        case .monthly:
            premiumType = .monthly
            expiryDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        case .yearly:
            premiumType = .yearly
            expiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        case .lifetime:
            premiumType = .lifetime
            expiryDate = nil // Lifetime doesn't expire
        }
        
        updatePremiumStatus(type: premiumType, activeSince: Date(), expiryDate: expiryDate)
        print("✅ Premium status updated: \(premiumType.rawValue)")
    }
    
    func resetPremiumStatus() {
        updatePremiumStatus(type: .none, activeSince: nil, expiryDate: nil)
        
        // Clear test data
        UserDefaults.standard.removeObject(forKey: "simulate_had_premium")
        UserDefaults.standard.removeObject(forKey: "premium_plan_type")
        
        print("🔄 Premium status reset to free")
    }
    
    // MARK: - Firebase Integration
    
    func updateFromFirebase(displayName: String, email: String, profileImageURL: String?) {
        self.displayName = displayName
        self.email = email
        self.profileImageURL = profileImageURL
    }
    
    func setPremiumStatusWithFirebaseSync(_ isPremium: Bool, plan: PremiumPlan) {
        let premiumType: PremiumType
        var expiryDate: Date?
        
        switch plan {
        case .monthly:
            premiumType = .monthly
            expiryDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        case .yearly:
            premiumType = .yearly
            expiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        case .lifetime:
            premiumType = .lifetime
            expiryDate = nil // Lifetime doesn't expire
        }
        
        let activeSince = Date()
        
        // Update local status first
        updatePremiumStatus(type: premiumType, activeSince: activeSince, expiryDate: expiryDate)
        
        // Sync with Firebase
        Task {
            await FirebaseUserDataManager.shared.updatePremiumStatus(
                premium: isPremium,
                premiumType: premiumType.rawValue,
                premiumSince: activeSince,
                premiumExpiry: expiryDate
            )
        }
        
        print("✅ Premium status updated locally and synced to Firebase: \(premiumType.rawValue)")
    }
    
    // MARK: - Sign Out Premium Handling
    
    private func clearPremiumStatusOnSignOut() {
        // Reset premium status to free when user signs out
        updatePremiumStatus(type: .none, activeSince: nil, expiryDate: nil)
        
        // Clear test data used for simulation
        UserDefaults.standard.removeObject(forKey: "simulate_had_premium")
        UserDefaults.standard.removeObject(forKey: "premium_plan_type")
        
        print("🔄 Premium status cleared due to sign out")
    }
}
