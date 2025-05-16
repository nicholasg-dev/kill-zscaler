import Foundation

enum ZscalerStatus: String {
    case running = "Running"
    case partiallyRunning = "Partially Running"
    case stopped = "Stopped"
    case unknown = "Unknown"
    
    var color: String {
        switch self {
        case .running: return "green"
        case .partiallyRunning: return "yellow"
        case .stopped: return "red"
        case .unknown: return "gray"
        }
    }
}

class ZscalerState: ObservableObject {
    @Published var status: ZscalerStatus = .unknown
    @Published var lastUpdated: Date = Date()
    @Published var isLoading: Bool = false
    @Published var lastError: String?
    
    private var statusCheckTimer: Timer?
    private let config: ZscalerConfig
    
    init(config: ZscalerConfig) {
        self.config = config
        startStatusCheck()
    }
    
    func startStatusCheck() {
        checkStatus()
        statusCheckTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(config.statusCheckInterval), repeats: true) { [weak self] _ in
            self?.checkStatus()
        }
    }
    
    func stopStatusCheck() {
        statusCheckTimer?.invalidate()
        statusCheckTimer = nil
    }
    
    private func checkStatus() {
        isLoading = true
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["\(config.scriptsPath)/status-check.sh"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.updateStatus(from: output)
                    self.lastUpdated = Date()
                    self.isLoading = false
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.status = .unknown
                self.lastError = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func updateStatus(from output: String) {
        if output.contains("Fully running") {
            status = .running
        } else if output.contains("Partially running") {
            status = .partiallyRunning
        } else if output.contains("Not running") {
            status = .stopped
        } else {
            status = .unknown
        }
    }
    
    func startZscaler() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["\(config.scriptsPath)/start-zscaler.sh"]
        
        try task.run()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            throw ZscalerError.startFailed
        }
        
        checkStatus()
    }
    
    func stopZscaler() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["\(config.scriptsPath)/kill-zscaler.sh"]
        
        try task.run()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            throw ZscalerError.stopFailed
        }
        
        checkStatus()
    }
}

enum ZscalerError: LocalizedError {
    case startFailed
    case stopFailed
    
    var errorDescription: String? {
        switch self {
        case .startFailed: return "Failed to start Zscaler"
        case .stopFailed: return "Failed to stop Zscaler"
        }
    }
}
