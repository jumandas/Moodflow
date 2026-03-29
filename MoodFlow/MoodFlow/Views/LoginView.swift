import SwiftUI

struct LoginView: View {
    @ObservedObject var authService: SpotifyAuthService
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(red: 0.4, green: 0.2, blue: 0.9).opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -80, y: -200)

            Circle()
                .fill(Color(red: 0.1, green: 0.6, blue: 0.9).opacity(0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .offset(x: 100, y: 200)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.5, green: 0.2, blue: 1.0), Color(red: 0.2, green: 0.5, blue: 1.0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "waveform.path")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundColor(.white)
                    }

                    Text("MoodFlow")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Your AI-powered music journey\nto emotional balance")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Spacer()

                VStack(spacing: 14) {
                    FeatureRow(icon: "brain.head.profile", text: "AI curates your perfect song sequence")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "4-stage journey from your mood to your goal")
                    FeatureRow(icon: "music.note.list", text: "Plays live on Spotify — songs chosen in real-time")
                }
                .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 16) {
                    Button {
                        login()
                    } label: {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .tint(.black)
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "music.note")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            Text(isLoading ? "Connecting..." : "Continue with Spotify")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(red: 0.11, green: 0.87, blue: 0.47))
                        .cornerRadius(50)
                    }
                    .disabled(isLoading)

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    Text("Spotify Premium required for full playback")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.35))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }

    private func login() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.authenticate()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 1.0))
                .frame(width: 28)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.75))

            Spacer()
        }
    }
}
