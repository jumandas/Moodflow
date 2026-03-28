import SwiftUI

struct CheckInView: View {
    @StateObject private var viewModel = JourneyViewModel()
    @State private var selectedEmotion: Emotion? = nil
    @State private var selectedGoal: Goal? = nil
    @State private var duration: Int = 12
    @State private var navigateToJourney = false

    var canProceed: Bool {
        selectedEmotion != nil && selectedGoal != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "0F0A1E"), Color(hex: "1A0F3C")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {

                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How are you feeling?")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                            Text("We'll build a journey from here.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 16)

                        // Emotion Picker
                        SectionLabel(text: "RIGHT NOW I FEEL")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(Emotion.allCases) { emotion in
                                EmotionCard(
                                    emotion: emotion,
                                    isSelected: selectedEmotion == emotion
                                ) {
                                    selectedEmotion = emotion
                                }
                            }
                        }

                        // Goal Picker
                        SectionLabel(text: "I WANT TO")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(Goal.allCases) { goal in
                                GoalCard(
                                    goal: goal,
                                    isSelected: selectedGoal == goal
                                ) {
                                    selectedGoal = goal
                                }
                            }
                        }

                        // Duration
                        SectionLabel(text: "SESSION LENGTH")
                        HStack(spacing: 12) {
                            ForEach([10, 15, 20, 30], id: \.self) { mins in
                                DurationChip(
                                    minutes: mins,
                                    isSelected: duration == mins
                                ) {
                                    duration = mins
                                }
                            }
                        }

                        // CTA Button
                        Button {
                            guard let emotion = selectedEmotion,
                                  let goal = selectedGoal else { return }
                            Task {
                                await viewModel.buildJourney(
                                    emotion: emotion,
                                    goal: goal,
                                    duration: duration
                                )
                                navigateToJourney = true
                            }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Building your journey...")
                                } else {
                                    Text("Build My Journey")
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                canProceed
                                ? LinearGradient(colors: [Color(hex: "4F46E5"), Color(hex: "7C3AED")], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(!canProceed || viewModel.isLoading)
                        .padding(.top, 8)
                        .padding(.bottom, 32)

                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationDestination(isPresented: $navigateToJourney) {
                JourneyPlanView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Subcomponents

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.bold())
            .foregroundColor(.white.opacity(0.5))
            .kerning(1.5)
    }
}

struct EmotionCard: View {
    let emotion: Emotion
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emotion.emoji).font(.largeTitle)
                Text(emotion.label)
                    .font(.subheadline.bold())
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(hex: "4F46E5").opacity(0.5) : Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color(hex: "7C3AED") : Color.clear, lineWidth: 1.5)
                    )
            )
        }
    }
}

struct GoalCard: View {
    let goal: Goal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(goal.emoji).font(.largeTitle)
                Text(goal.label)
                    .font(.subheadline.bold())
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(hex: "7C3AED").opacity(0.5) : Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color(hex: "4F46E5") : Color.clear, lineWidth: 1.5)
                    )
            )
        }
    }
}

struct DurationChip: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(minutes) min")
                .font(.subheadline.bold())
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color(hex: "4F46E5") : Color.white.opacity(0.07))
                )
        }
    }
}
