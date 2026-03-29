import Foundation
import AuthenticationServices
import CryptoKit

@MainActor
class SpotifyAuthService: NSObject, ObservableObject {

    @Published var isAuthenticated = false
    @Published var accessToken: String?
    @Published var error: String?

    private var tokenExpiry: Date?
    private var refreshToken: String?
    private var codeVerifier: String?
    private var authSession: ASWebAuthenticationSession?

    private let tokenKey = "spotify_access_token"
    private let refreshKey = "spotify_refresh_token"
    private let expiryKey = "spotify_token_expiry"

    override init() {
        super.init()
        loadStoredTokens()
    }

    var isTokenValid: Bool {
        guard let token = accessToken, !token.isEmpty,
              let expiry = tokenExpiry else { return false }
        return Date() < expiry.addingTimeInterval(-60) // 60s buffer
    }

    // MARK: - Auth flow

    func authenticate() async throws {
        let verifier = generateCodeVerifier()
        self.codeVerifier = verifier
        let challenge = generateCodeChallenge(from: verifier)

        var components = URLComponents(string: Config.spotifyAuthURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Config.spotifyClientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: Config.spotifyRedirectURI),
            URLQueryItem(name: "scope", value: Config.spotifyScopes),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge)
        ]

        guard let authURL = components.url else {
            throw AppError.authError("Failed to build auth URL")
        }

        guard let callbackScheme = URL(string: Config.spotifyRedirectURI)?.scheme else {
            throw AppError.authError("Invalid redirect URI scheme")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: callbackScheme
            ) { [weak self] callbackURL, error in
                guard let self else { return }
                if let error {
                    if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                        continuation.resume(throwing: AppError.authError("Login cancelled"))
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                guard let callbackURL,
                      let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                        .queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: AppError.authError("No auth code in callback"))
                    return
                }
                Task { @MainActor in
                    do {
                        try await self.exchangeCodeForToken(code: code)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = self
            self.authSession = session
            session.start()
        }
    }

    func refreshTokenIfNeeded() async throws {
        guard !isTokenValid else { return }
        guard let refresh = refreshToken, !refresh.isEmpty else {
            throw AppError.authError("No refresh token — please log in again")
        }
        try await performTokenRefresh(refreshToken: refresh)
    }

    func logout() {
        accessToken = nil
        refreshToken = nil
        tokenExpiry = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshKey)
        UserDefaults.standard.removeObject(forKey: expiryKey)
    }

    // MARK: - Token exchange

    private func exchangeCodeForToken(code: String) async throws {
        guard let verifier = codeVerifier else {
            throw AppError.authError("Missing code verifier")
        }

        var request = URLRequest(url: URL(string: Config.spotifyTokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params = [
            "grant_type=authorization_code",
            "code=\(code)",
            "redirect_uri=\(Config.spotifyRedirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
            "client_id=\(Config.spotifyClientID)",
            "code_verifier=\(verifier)"
        ].joined(separator: "&")
        request.httpBody = params.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AppError.authError("Token exchange failed")
        }

        try parseTokenResponse(data: data)
    }

    private func performTokenRefresh(refreshToken: String) async throws {
        var request = URLRequest(url: URL(string: Config.spotifyTokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params = [
            "grant_type=refresh_token",
            "refresh_token=\(refreshToken)",
            "client_id=\(Config.spotifyClientID)"
        ].joined(separator: "&")
        request.httpBody = params.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AppError.authError("Token refresh failed")
        }

        try parseTokenResponse(data: data)
    }

    private func parseTokenResponse(data: Data) throws {
        struct TokenResponse: Decodable {
            let accessToken: String
            let tokenType: String
            let expiresIn: Int
            let refreshToken: String?
            let scope: String?

            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case tokenType = "token_type"
                case expiresIn = "expires_in"
                case refreshToken = "refresh_token"
                case scope
            }
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        accessToken = tokenResponse.accessToken
        tokenExpiry = Date().addingTimeInterval(Double(tokenResponse.expiresIn))
        if let newRefresh = tokenResponse.refreshToken {
            refreshToken = newRefresh
        }
        isAuthenticated = true
        storeTokens()
    }

    // MARK: - Storage

    private func storeTokens() {
        UserDefaults.standard.set(accessToken, forKey: tokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshKey)
        UserDefaults.standard.set(tokenExpiry, forKey: expiryKey)
    }

    private func loadStoredTokens() {
        accessToken = UserDefaults.standard.string(forKey: tokenKey)
        refreshToken = UserDefaults.standard.string(forKey: refreshKey)
        tokenExpiry = UserDefaults.standard.object(forKey: expiryKey) as? Date
        isAuthenticated = isTokenValid
    }

    // MARK: - PKCE helpers

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .prefix(128)
            .description
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

extension SpotifyAuthService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
