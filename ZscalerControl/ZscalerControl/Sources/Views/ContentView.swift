import SwiftUI

struct ContentView: View {
    @StateObject private var zscalerState: ZscalerState
    @State private var showError = false
    @State private var errorMessage = ""
    
    init() {
        let config = ZscalerConfig.load()
        _zscalerState = StateObject(wrappedValue: ZscalerState(config: config))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            StatusView(status: zscalerState.status)
            
            if zscalerState.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                HStack(spacing: 20) {
                    Button(action: startZscaler) {
                        Label("Start", systemImage: "play.fill")
                            .frame(width: 100)
                    }
                    .disabled(zscalerState.status == .running)
                    
                    Button(action: stopZscaler) {
                        Label("Stop", systemImage: "stop.fill")
                            .frame(width: 100)
                    }
                    .disabled(zscalerState.status == .stopped)
                }
            }
            
            Text("Last updated: \(formattedLastUpdate)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 300, height: 200)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var formattedLastUpdate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: zscalerState.lastUpdated)
    }
    
    private func startZscaler() {
        Task {
            do {
                try await zscalerState.startZscaler()
            } catch {
                showError(error.localizedDescription)
            }
        }
    }
    
    private func stopZscaler() {
        Task {
            do {
                try await zscalerState.stopZscaler()
            } catch {
                showError(error.localizedDescription)
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

struct StatusView: View {
    let status: ZscalerStatus
    
    var body: some View {
        VStack {
            Circle()
                .fill(Color(status.color))
                .frame(width: 20, height: 20)
            
            Text(status.rawValue)
                .font(.headline)
        }
    }
}

#Preview {
    ContentView()
}
