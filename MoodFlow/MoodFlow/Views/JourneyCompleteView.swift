import SwiftUI

struct JourneyCompleteView: View {
    @ObservedObject var vm: JourneyViewModel
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var particlesVisible = false

    var body: some View {
        ZStack {
            // Background
            if let journey = vm.journey {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.12),
                        journey.desiredMood.color.opacity(0.2),
                        Color(red: 0.05, green: 0.05, blue: 0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            } else {
                Color(red: 0.05, green: 0.05, blue: 0.12).ignoresSafeArea()
            }

            VStack(spacing: 0) {
                Spacer()

                // Completion icon
                ZStack {
                    if let journey = vm.journey {
                        Circle()
                            .fill(journey.desiredMood.color.opacity(0.15))
                            .frame(width: 160, height: 160)
                            .blur(radius: 20)

                        Circle()
                            .fill(journey.desiredMood.color.opacity(0.2))
                            .frame(width: 120, height: 120)

                        Text(journey.desiredMood.emoji)
                            .font(.system(size: 56))
                    }
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                        scale = 1.0
                        opacity = 1.0
                    }
                }

                Spacer().frame(height: 40)

                // Title
                VStack(spacing: 12) {
                    Text("Journey Complete")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    if let journey = vm.journey {
                        Text("You've arrived at \(journey.desiredMood.displayName)")
                            .font(.system(size: 18))
                            .foregroundColor(journey.desiredMood.color)
                    }
                }
                .opacity(opacity)
                .animation(.easeIn.delay(0.5), value: opacity)

                Spacer().frame(height: 40)

                // Stats
                if let journey = vm.journey {
                    HStack(spacing: 0) {
                        CompletionStat(
                            icon: "clock.fill",
                            value: "\(journey.durationMinutes)",
                            unit: "min",
                            label: "Journey Time"
                        )
                        Divider()
                            .frame(height: 44)
                            .background(Color.white.opacity(0.15))
                        CompletionStat(
                            icon: "music.note.list",
                            value: "\(journey.totalSongs)",
                            unit: "",
                            label: "Songs Played"
                        )
                        Divider()
                            .frame(height: 44)
                            .background(Color.white.opacity(0.15))
                        CompletionStat(
                            icon: "chart.bar.fill",
                            value: "4",
                            unit: "",
                            label: "Stages"
                        )
                    }
                    .padding(.vertical, 20)
                    .background(Color.white.opacity(0.07))
                    .cornerRadius(20)
                    .padding(.horizontal, 24)
                    .opacity(opacity)
                    .animation(.easeIn.delay(0.7), value: opacity)

                    Spacer().frame(height: 28)

                    // Journey path recap
                    HStack(spacing: 12) {
                        // From
                        VStack(spacing: 4) {
                            Text(journey.currentMood.emoji).font(.title2)
                            Text(journey.currentMood.displayName)
                                .font(.system(size: 12))
                                .foregroundColor(journey.currentMood.color)
                        }

                        // Arrow with stages
                        HStack(spacing: 4) {
                            ForEach(0..<4, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 8, height: 2)
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 5, height: 5)
                            }
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(journey.desiredMood.color)
                        }

                        // To
                        VStack(spacing: 4) {
                            Text(journey.desiredMood.emoji).font(.title2)
                            Text(journey.desiredMood.displayName)
                                .font(.system(size: 12))
                                .foregroundColor(journey.desiredMood.color)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    .opacity(opacity)
                    .animation(.easeIn.delay(0.8), value: opacity)
                }

                Spacer()

                // Actions
                VStack(spacing: 14) {
                    Button {
                        vm.resetJourney()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Start a New Journey")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .cornerRadius(50)
                    }

                    if let journey = vm.journey {
                        Text("From \(journey.currentMood.displayName) to \(journey.desiredMood.displayName)")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .opacity(opacity)
                .animation(.easeIn.delay(1.0), value: opacity)
            }
        }
    }
}

struct CompletionStat: View {
    let icon: String
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.purple.opacity(0.8))
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}
