import SwiftUI

@main
struct MoodFlowApp: App {

    @StateObject private var authService = SpotifyAuthService()
    @StateObject private var playbackService = SpotifyPlaybackService()

    var body: some Scene {
        WindowGroup {
            RootView(
                authService: authService,
                playbackService: playbackService
            )
            .preferredColorScheme(.dark)
            .onOpenURL { url in
                playbackService.handleOpenURL(url)
            }
        }
    }
}

struct RootView: View {
    @ObservedObject var authService: SpotifyAuthService
    @ObservedObject var playbackService: SpotifyPlaybackService

    var body: some View {
        Group {
            if authService.isAuthenticated {
                AppContentView(
                    authService: authService,
                    playbackService: playbackService
                )
            } else {
                LoginView(authService: authService)
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
}

struct AppContentView: View {
    @StateObject private var vm: JourneyViewModel

    init(authService: SpotifyAuthService, playbackService: SpotifyPlaybackService) {
        _vm = StateObject(wrappedValue: JourneyViewModel(
            authService: authService,
            playbackService: playbackService
        ))
    }

    var body: some View {
        JourneyFlowView(vm: vm)
    }
}
