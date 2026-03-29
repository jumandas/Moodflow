import SwiftUI

struct MoodSetupView: View {
    @ObservedObject var vm: JourneyViewModel

    @State private var currentMood: Mood?
    @State private var desiredMood: Mood?
    @State private var durationMinutes: Double = 30
    @State private var step: SetupStep = .currentMood

    // Biometric inputs
    @State private var restingHR: String = ""
    @State private var walkingHR: String = ""
    @State private var respiratoryRateInput: String = ""
    @State private var inferredMood: Mood?

    enum SetupStep { case currentMood, biometrics, desiredMood, duration }

    private let durations: [Int] = [15, 20, 30, 45, 60]

    private var biometricInput: BiometricInput {
        BiometricInput(
            restingHeartRate: Double(restingHR),
            walkingHeartRate: Double(walkingHR),
            respiratoryRate: Double(respiratoryRateInput)
        )
    }

    private var detectedMood: Mood {
        guard let base = currentMood else { return .neutral }
        let bio = biometricInput
        guard bio.hasAnyInput else { return base }
        return Mood.inferMood(selfReported: base, biometrics: bio)
    }

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        switch step {
                        case .currentMood:
                            moodGrid(
                                title: "How are you feeling?",
                                subtitle: "Be honest — we'll meet you here",
                                selected: $currentMood
                            )
                        case .biometrics:
                            biometricsInputView
                        case .desiredMood:
                            moodGrid(
                                title: "Where do you want to be?",
                                subtitle: "Your destination mood",
                                selected: $desiredMood
                            )
                        case .duration:
                            durationPicker
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
            }

            VStack {
                Spacer()
                bottomBar
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.12).ignoresSafeArea()
            if let mood = inferredMood ?? currentMood {
                RadialGradient(
                    colors: [mood.color.opacity(0.15), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: mood)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.path")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.purple)
                    Text("MoodFlow")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                Button {
                    vm.authService.logout()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            HStack(spacing: 8) {
                ForEach(0..<4) { i in
                    Capsule()
                        .fill(stepIndex >= i ? Color.purple : Color.white.opacity(0.2))
                        .frame(width: stepIndex == i ? 24 : 8, height: 5)
                        .animation(.spring(response: 0.3), value: stepIndex)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 4)
        }
    }

    private var stepIndex: Int {
        switch step {
        case .currentMood: return 0
        case .biometrics: return 1
        case .desiredMood: return 2
        case .duration: return 3
        }
    }

    // MARK: - Mood Grid

    private func moodGrid(title: String, subtitle: String, selected: Binding<Mood?>) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 24)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Mood.allCases) { mood in
                    MoodCard(mood: mood, isSelected: selected.wrappedValue == mood) {
                        withAnimation(.spring(response: 0.3)) {
                            selected.wrappedValue = mood
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Biometrics Input

    private var biometricsInputView: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Vitals")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("Help us understand your body's state")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 24)

            HStack(spacing: 10) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 16))
                    .foregroundColor(.pink.opacity(0.7))
                Text("Check Apple Health or your wearable for these values")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.45))
            }
            .padding(.horizontal, 28)

            VStack(spacing: 20) {
                BiometricField(icon: "heart.fill", iconColor: .red,
                               label: "Resting Heart Rate", value: $restingHR,
                               unit: "BPM", hint: "Normal: 60–100 BPM")

                BiometricField(icon: "figure.walk", iconColor: .orange,
                               label: "Walking Heart Rate", value: $walkingHR,
                               unit: "BPM", hint: "Normal: 100–130 BPM")

                BiometricField(icon: "wind", iconColor: .cyan,
                               label: "Respiratory Rate", value: $respiratoryRateInput,
                               unit: "breaths/min", hint: "Normal: 12–20 breaths/min")
            }
            .padding(.horizontal, 24)

            // Detected mood card
            if currentMood != nil {
                detectedMoodCard
            }
        }
    }

    private var detectedMoodCard: some View {
        let mood = detectedMood
        return VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundColor(.purple)
                Text("AI-Detected Mood")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(mood.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    Text(mood.emoji)
                        .font(.system(size: 32))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(mood.displayName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(mood.color)
                    Text(mood.description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(mood.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(mood.color.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 24)
        .animation(.easeInOut(duration: 0.4), value: mood)
    }

    // MARK: - Duration Picker

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("How long is your journey?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("Songs will play for this duration")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 24)

            if let from = inferredMood ?? currentMood, let to = desiredMood {
                JourneySummaryCard(from: from, to: to, minutes: Int(durationMinutes))
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 12) {
                ForEach(durations, id: \.self) { mins in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            durationMinutes = Double(mins)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "clock")
                                .font(.system(size: 18))
                                .foregroundColor(Int(durationMinutes) == mins ? .purple : .white.opacity(0.4))
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(mins) minutes")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(durationLabel(mins))
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.5))
                            }

                            Spacer()

                            if Int(durationMinutes) == mins {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Int(durationMinutes) == mins
                                      ? Color.purple.opacity(0.2)
                                      : Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Int(durationMinutes) == mins
                                                ? Color.purple.opacity(0.5)
                                                : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    private func durationLabel(_ mins: Int) -> String {
        switch mins {
        case 15: return "Quick reset"
        case 20: return "Short session"
        case 30: return "Standard journey"
        case 45: return "Deep transition"
        case 60: return "Full immersion"
        default: return ""
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.12).opacity(0), Color(red: 0.05, green: 0.05, blue: 0.12)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 32)

            HStack(spacing: 16) {
                if step != .currentMood {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            switch step {
                            case .biometrics: step = .currentMood
                            case .desiredMood: step = .biometrics
                            case .duration: step = .desiredMood
                            case .currentMood: break
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 54, height: 54)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(27)
                    }
                }

                Button {
                    handleNext()
                } label: {
                    Text(step == .duration ? "Generate My Journey" : "Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(isNextEnabled
                                    ? LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(50)
                }
                .disabled(!isNextEnabled)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .background(Color(red: 0.05, green: 0.05, blue: 0.12))
        }
    }

    private var isNextEnabled: Bool {
        switch step {
        case .currentMood: return currentMood != nil
        case .biometrics: return true
        case .desiredMood: return desiredMood != nil
        case .duration: return true
        }
    }

    private func handleNext() {
        switch step {
        case .currentMood:
            withAnimation(.spring(response: 0.4)) { step = .biometrics }
        case .biometrics:
            inferredMood = detectedMood
            withAnimation(.spring(response: 0.4)) { step = .desiredMood }
        case .desiredMood:
            withAnimation(.spring(response: 0.4)) { step = .duration }
        case .duration:
            guard let from = inferredMood ?? currentMood, let to = desiredMood else { return }
            let bio = biometricInput
            let bioContext = bio.hasAnyInput ? bio.summary : nil
            Task {
                await vm.generateJourney(
                    currentMood: from,
                    desiredMood: to,
                    durationMinutes: Int(durationMinutes),
                    biometricContext: bioContext
                )
            }
        }
    }
}

// MARK: - Biometric Field

struct BiometricField: View {
    let icon: String
    let iconColor: Color
    let label: String
    @Binding var value: String
    let unit: String
    let hint: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                }
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            HStack(spacing: 0) {
                TextField("—", text: $value)
                    .keyboardType(.numberPad)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .focused($isFocused)
                    .padding(.leading, 16)
                    .padding(.vertical, 16)

                Spacer()

                Text(unit)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.trailing, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(isFocused ? 0.12 : 0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isFocused ? iconColor.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)

            Text(hint)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.3))
                .padding(.leading, 4)
        }
    }
}

// MARK: - Mood Card

struct MoodCard: View {
    let mood: Mood
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(mood.emoji)
                    .font(.system(size: 32))
                Text(mood.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? mood.color : .white.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? mood.color.opacity(0.2) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? mood.color.opacity(0.8) : Color.clear, lineWidth: 1.5)
                    )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
    }
}

// MARK: - Journey Summary Card

struct JourneySummaryCard: View {
    let from: Mood
    let to: Mood
    let minutes: Int

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(from.emoji).font(.title)
                Text(from.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(from.color)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(0.3 + Double(i) * 0.15))
                            .frame(width: 6, height: 6)
                    }
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                Text("\(minutes) min")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 4) {
                Text(to.emoji).font(.title)
                Text(to.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(to.color)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
    }
}
