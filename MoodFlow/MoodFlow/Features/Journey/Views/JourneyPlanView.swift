import SwiftUI

struct JourneyPlanView: View {
    @ObservedObject var viewModel: JourneyViewModel

    var body: some View {
        ZStack {
            Color(hex: "0F0A1E").ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Journey Ready ✓")
                    .font(.title.bold())
                    .foregroundColor(.white)
                Text("\(viewModel.stages.count) stages loaded")
                    .foregroundColor(.white.opacity(0.6))
                // We'll build this out next
                ForEach(viewModel.stages) { stage in
                    Text(stage.stageName.uppercased())
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
