import SwiftUI
import FirebaseAuth

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
        
        // TODO: Add GoogleSignIn SDK dependency to project first
        // For now, show instructions to user
        
        /*
        // With GoogleSignIn SDK, the implementation would be:
        
        import GoogleSignIn
        
        guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
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
                }
            }
        }
        */
        
        // Temporary implementation - simulate sign in for demo
        simulateGoogleSignIn()
    }
    
    // Temporary method for demo purposes
    private func simulateGoogleSignIn() {
        // Simulate a successful Google sign-in for demo
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            // Create a simulated user state
            self?.isSignedIn = true
            self?.displayName = "Demo User"
            self?.email = "demo@example.com"
            self?.profileImageURL = nil
            
            print("✅ Demo Google Sign-In completed")
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
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
}