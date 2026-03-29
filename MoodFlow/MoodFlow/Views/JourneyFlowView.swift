import SwiftUI

/// Top-level flow controller — switches between setup, preview, active, complete
struct JourneyFlowView: View {
    @ObservedObject var vm: JourneyViewModel

    var body: some View {
        ZStack {
            switch vm.journeyState {
            case .idle:
                MoodSetupView(vm: vm)
                    .transition(.opacity)
            case .generating, .resolvingSpotify:
                LoadingView(message: vm.loadingMessage)
                    .transition(.opacity)
            case .preview:
                JourneyPreviewView(vm: vm)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .active, .recuating:
                ActiveJourneyView(vm: vm)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .complete:
                JourneyCompleteView(vm: vm)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .error(let msg):
                ErrorView(message: msg) {
                    vm.resetJourney()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: vm.journeyState)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let message: String
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.12).ignoresSafeArea()

            VStack(spacing: 32) {
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.purple.opacity(0.6), .blue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: CGFloat(60 + i * 30), height: CGFloat(60 + i * 30))
                            .scaleEffect(pulse ? 1.1 : 0.95)
                            .animation(
                                .easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(Double(i) * 0.2),
                                value: pulse
                            )
                    }
                    Image(systemName: "waveform.path")
                        .font(.system(size: 32))
                        .foregroundColor(.purple)
                }
                .onAppear { pulse = true }

                VStack(spacing: 8) {
                    Text(message)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Text("Powered by Gemini AI")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.12).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)

                Text("Something went wrong")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button("Try Again") {
                    onRetry()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 48)
                .padding(.vertical, 16)
                .background(.white)
                .cornerRadius(50)
            }
        }
    }
}
