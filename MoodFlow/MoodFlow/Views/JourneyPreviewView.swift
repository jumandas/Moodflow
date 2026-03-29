import SwiftUI

struct JourneyPreviewView: View {
    @ObservedObject var vm: JourneyViewModel
    @State private var expandedStage: UUID?

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.12).ignoresSafeArea()

            if let journey = vm.journey {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            Button {
                                vm.resetJourney()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                            Text("Your Journey")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Color.clear.frame(width: 28, height: 28)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                        // Mood arc
                        JourneyArcView(journey: journey)
                            .padding(.horizontal, 24)
                    }

                    // Stages list
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(Array(journey.stages.enumerated()), id: \.element.id) { index, stage in
                                StageExpandableCard(
                                    stage: stage,
                                    stageNumber: index + 1,
                                    isExpanded: expandedStage == stage.id
                                ) {
                                    withAnimation(.spring(response: 0.4)) {
                                        expandedStage = expandedStage == stage.id ? nil : stage.id
                                    }
                                }
                            }

                            // Stats
                            JourneyStatsRow(journey: journey)
                                .padding(.top, 8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 120)
                    }
                }

                // Start button
                VStack {
                    Spacer()
                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [.clear, Color(red: 0.05, green: 0.05, blue: 0.12)],
                            startPoint: .top, endPoint: .bottom
                        ).frame(height: 32)

                        Button {
                            vm.startJourney()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 18))
                                Text("Start Journey")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                LinearGradient(
                                    colors: [journey.currentMood.color, journey.desiredMood.color],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .cornerRadius(50)
                            .padding(.horizontal, 24)
                        }
                        .padding(.bottom, 40)
                        .background(Color(red: 0.05, green: 0.05, blue: 0.12))
                    }
                }
            }
        }
    }
}

// MARK: - Journey Arc

struct JourneyArcView: View {
    let journey: Journey

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(journey.currentMood.color.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Text(journey.currentMood.emoji)
                        .font(.system(size: 28))
                }
                Text(journey.currentMood.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(journey.currentMood.color)
            }

            Spacer()

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { i in
                        VStack(spacing: 2) {
                            Circle()
                                .fill(Color.white.opacity(0.15 + Double(i) * 0.2))
                                .frame(width: 8 + CGFloat(i) * 2, height: 8 + CGFloat(i) * 2)
                            Text("\(i + 1)")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                Text("\(journey.durationMinutes) min · 4 stages")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(journey.desiredMood.color.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Text(journey.desiredMood.emoji)
                        .font(.system(size: 28))
                }
                Text(journey.desiredMood.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(journey.desiredMood.color)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Stage Card

struct StageExpandableCard: View {
    let stage: JourneyStage
    let stageNumber: Int
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Stage header
            Button(action: onToggle) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(stageColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Text("\(stageNumber)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(stageColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(stage.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("\(stage.songs.count) songs · ~\(stage.totalDurationFormatted)")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    // Stage description
                    Text(stage.stageDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                    Divider().background(Color.white.opacity(0.1))

                    // Song list
                    ForEach(stage.songs) { song in
                        SongRow(song: song)
                        if song.id != stage.songs.last?.id {
                            Divider()
                                .background(Color.white.opacity(0.06))
                                .padding(.leading, 60)
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isExpanded ? stageColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }

    private var stageColor: Color {
        let colors: [Color] = [.purple, .blue, .teal, .green]
        return colors[safe: stageNumber - 1] ?? .purple
    }
}

struct SongRow: View {
    let song: Song

    var body: some View {
        HStack(spacing: 12) {
            // Album art or placeholder
            AsyncImageView(urlString: song.albumArtURL, size: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(song.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(song.artist)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                if let bpm = song.estimatedBPM {
                    Text("\(bpm) BPM")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.purple.opacity(0.8))
                }
                if let dur = song.durationMs {
                    Text(formatDuration(dur))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.35))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func formatDuration(_ ms: Int) -> String {
        let total = ms / 1000
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

struct AsyncImageView: View {
    let urlString: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(6)
    }

    private var placeholder: some View {
        ZStack {
            Color.white.opacity(0.1)
            Image(systemName: "music.note")
                .font(.system(size: size * 0.35))
                .foregroundColor(.white.opacity(0.3))
        }
    }
}

// MARK: - Journey Stats

struct JourneyStatsRow: View {
    let journey: Journey

    var body: some View {
        HStack(spacing: 12) {
            StatBadge(icon: "music.note.list", value: "\(journey.totalSongs)", label: "Songs")
            StatBadge(icon: "clock", value: "\(journey.durationMinutes)m", label: "Duration")
            StatBadge(icon: "chart.bar.fill", value: "4", label: "Stages")
        }
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.purple.opacity(0.8))
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
    }
}

