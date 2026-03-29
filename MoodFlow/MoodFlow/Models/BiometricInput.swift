import Foundation

struct BiometricInput {
    var restingHeartRate: Double?
    var walkingHeartRate: Double?
    var respiratoryRate: Double?

    var hasAnyInput: Bool {
        restingHeartRate != nil || walkingHeartRate != nil || respiratoryRate != nil
    }

    /// Computed energy level from biometrics (0.0 = very low, 1.0 = very high)
    var energyLevel: Double {
        var factors: [Double] = []
        if let rhr = restingHeartRate {
            factors.append(min(max((rhr - 45) / 65.0, 0), 1))
        }
        if let whr = walkingHeartRate {
            factors.append(min(max((whr - 80) / 90.0, 0), 1))
        }
        if let rr = respiratoryRate {
            factors.append(min(max((rr - 10) / 20.0, 0), 1))
        }
        guard !factors.isEmpty else { return 0.5 }
        return factors.reduce(0, +) / Double(factors.count)
    }

    /// Computed stress level from biometrics (0.0 = very relaxed, 1.0 = very stressed)
    var stressLevel: Double {
        var factors: [Double] = []
        if let rhr = restingHeartRate {
            factors.append(min(max((rhr - 55) / 50.0, 0), 1))
        }
        if let rr = respiratoryRate {
            factors.append(min(max((rr - 12) / 16.0, 0), 1))
        }
        if let whr = walkingHeartRate {
            factors.append(min(max((whr - 100) / 60.0, 0), 1))
        }
        guard !factors.isEmpty else { return 0.5 }
        return factors.reduce(0, +) / Double(factors.count)
    }

    /// Human-readable summary for LLM context
    var summary: String {
        var parts: [String] = []
        if let rhr = restingHeartRate { parts.append("Resting HR: \(Int(rhr)) BPM") }
        if let whr = walkingHeartRate { parts.append("Walking HR: \(Int(whr)) BPM") }
        if let rr = respiratoryRate { parts.append("Respiratory Rate: \(Int(rr)) breaths/min") }
        if parts.isEmpty { return "No biometric data provided" }
        parts.append("Stress level: \(String(format: "%.0f", stressLevel * 100))%")
        parts.append("Energy level: \(String(format: "%.0f", energyLevel * 100))%")
        return parts.joined(separator: ", ")
    }
}
