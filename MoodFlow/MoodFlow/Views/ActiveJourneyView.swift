import SwiftUI

struct ActiveJourneyView: View {
    @ObservedObject var vm: JourneyViewModel
    @State private var showSongList = false

    var body: some View {
        ZStack {
            // Dynamic background based on current stage
            dynamicBackground

            VStack(spacing: 0) {
                // Top bar
                topBar

                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Album art + now playing
                        nowPlayingSection

                        // Stage progress
                        stageProgressSection

                        // Overall progress bar
                        overallProgressSection

                        // Stage info
                        if let stage = vm.currentStage {
                            stageInfoCard(stage: stage)
                        }

                        // Controls
                        playbackControls

                        // Upcoming songs
                        if showSongList {
                            upcomingSection
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
            }

            // Mood check-in overlay
            if vm.moodCheckInVisible {
                MoodCheckInOverlay(vm: vm)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.5), value: vm.moodCheckInVisible)
            }

            // Re-curating indicator
            if vm.journeyState == .recuating {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        ProgressView().tint(.white).scaleEffect(0.8)
                        Text("Adjusting your journey...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.purple.opacity(0.9))
                    .cornerRadius(30)
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: vm.moodCheckInVisible)
    }

    // MARK: - Subviews

    private var dynamicBackground: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.12).ignoresSafeArea()
            if let journey = vm.journey {
                let stageColors: [Color] = [
                    journey.currentMood.color,
                    Color(red: 0.3, green: 0.3, blue: 0.8),
                    Color(red: 0.2, green: 0.6, blue: 0.7),
                    journey.desiredMood.color
                ]
                let color = stageColors[safe: vm.currentStageIndex] ?? journey.currentMood.color

                RadialGradient(
                    colors: [color.opacity(0.2), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 500
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 2.0), value: vm.currentStageIndex)
            }
        }
    }

    private var topBar: some View {
        HStack {
            if let journey = vm.journey {
                // From → To
                HStack(spacing: 8) {
                    Text(journey.currentMood.emoji)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                    Text(journey.desiredMood.emoji)
                }
                .font(.system(size: 18))
            }

            Spacer()

            // Time remaining
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                Text(vm.timeRemaining)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var nowPlayingSection: some View {
        VStack(spacing: 20) {
            // Album art
            ZStack {
                if let song = vm.currentSong {
                    AsyncImageView(urlString: song.albumArtURL, size: 220)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                        .id(song.id) // Force redraw on song change
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 220, height: 220)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.2))
                        )
                }
            }
            .animation(.spring(response: 0.4), value: vm.currentSong?.id)

            // Song info
            VStack(spacing: 6) {
                Text(vm.currentSong?.title ?? "Loading...")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .animation(.easeInOut, value: vm.currentSong?.id)

                Text(vm.currentSong?.artist ?? "")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
                    .animation(.easeInOut, value: vm.currentSong?.id)

                if let bpm = vm.currentSong?.estimatedBPM {
                    HStack(spacing: 12) {
                        Label("\(bpm) BPM", systemImage: "metronome")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        if let energy = vm.currentSong?.estimatedEnergy {
                            Label(energyLabel(energy), systemImage: "bolt.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.top, 4)
                }
            }

            // Song reason
            if let reason = vm.currentSong?.reason, !reason.isEmpty {
                Text(reason)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .italic()
            }
        }
    }

    private var stageProgressSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text(vm.currentStage?.name ?? "")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("Stage \(vm.currentStageIndex + 1) of \(vm.journey?.stages.count ?? 4)")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Stage dots
            HStack(spacing: 8) {
                ForEach(0..<(vm.journey?.stages.count ?? 4), id: \.self) { i in
                    Capsule()
                        .fill(i <= vm.currentStageIndex ? stageColor(for: i) : Color.white.opacity(0.15))
                        .frame(width: i == vm.currentStageIndex ? 32 : 10, height: 8)
                        .animation(.spring(response: 0.4), value: vm.currentStageIndex)
                }
                Spacer()
            }
        }
    }

    private var overallProgressSection: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 6)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    vm.journey?.currentMood.color ?? .purple,
                                    vm.journey?.desiredMood.color ?? .blue
                                ],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * vm.overallProgress, height: 6)
                        .animation(.linear(duration: 1.0), value: vm.overallProgress)
                }
            }
            .frame(height: 6)

            HStack {
                Text("Journey progress")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
                Text("\(Int(vm.overallProgress * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    private func stageInfoCard(stage: JourneyStage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(stage.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(stage.songs.count) songs")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            Text(stage.stageDescription)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.07))
        .cornerRadius(14)
    }

    private var playbackControls: some View {
        HStack(spacing: 36) {
            // Previous
            Button {
                vm.goToPreviousSong()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white.opacity(0.7))
            }

            // Play/Pause
            Button {
                if vm.playbackService.isPlaying {
                    vm.playbackService.pause()
                } else {
                    vm.playbackService.resume()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 68, height: 68)
                    Image(systemName: vm.playbackService.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.black)
                }
            }

            // Skip
            Button {
                vm.advanceToNextSong()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Up Next")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            if let stage = vm.currentStage {
                ForEach(Array(stage.songs.dropFirst(vm.currentSongIndex + 1).prefix(3))) { song in
                    SongRow(song: song)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Helpers

    private func stageColor(for index: Int) -> Color {
        let colors: [Color] = [.purple, .blue, .teal, .green]
        return colors[safe: index] ?? .purple
    }

    private func energyLabel(_ energy: Double) -> String {
        switch energy {
        case 0..<0.3: return "Low energy"
        case 0.3..<0.6: return "Medium energy"
        case 0.6...: return "High energy"
        default: return "Medium energy"
        }
    }
}

// MARK: - Mood Check-In Overlay

struct MoodCheckInOverlay: View {
    @ObservedObject var vm: JourneyViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture { vm.moodCheckInVisible = false }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("How are you feeling?")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        Text("Is the music moving you toward\n\(vm.journey?.desiredMood.displayName ?? "your goal")?")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }

                    if let desired = vm.journey?.desiredMood {
                        HStack(spacing: 12) {
                            Text(desired.emoji)
                                .font(.system(size: 32))
                            VStack(alignment: .leading) {
                                Text("Getting closer to")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                                Text(desired.displayName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(desired.color)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(desired.color.opacity(0.15))
                        .cornerRadius(14)
                    }

                    VStack(spacing: 12) {
                        Button {
                            vm.moodImproving()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                Text("Yes, I'm feeling the shift")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(red: 0.11, green: 0.87, blue: 0.47))
                            .cornerRadius(50)
                        }

                        Button {
                            vm.moodNotImproving()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 18))
                                Text("Not working — try different songs")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(50)
                        }

                        Button("Keep going") {
                            vm.moodCheckInVisible = false
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(red: 0.1, green: 0.1, blue: 0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
    }
}
