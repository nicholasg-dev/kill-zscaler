import SwiftUI

struct LogViewer: View {
    @StateObject private var logMonitor = LogMonitor()
    @State private var searchText = ""
    @State private var selectedLogLevel: LogLevel = .all
    @State private var autoScroll = true
    
    var filteredLogs: [LogEntry] {
        logMonitor.logs.filter { log in
            let matchesSearch = searchText.isEmpty || 
                log.message.localizedCaseInsensitiveContains(searchText)
            let matchesLevel = selectedLogLevel == .all || 
                log.level == selectedLogLevel
            return matchesSearch && matchesLevel
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                Picker("Log Level", selection: $selectedLogLevel) {
                    ForEach(LogLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .frame(width: 120)
                
                Toggle("Auto-scroll", isOn: $autoScroll)
                    .toggleStyle(.switch)
                
                Button(action: logMonitor.clearLogs) {
                    Label("Clear", systemImage: "trash")
                }
            }
            .padding(.horizontal)
            
            ScrollViewReader { proxy in
                List(filteredLogs) { log in
                    LogEntryView(log: log)
                        .id(log.id)
                }
                .onChange(of: filteredLogs.count) { _ in
                    if autoScroll, let lastLog = filteredLogs.last {
                        proxy.scrollTo(lastLog.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct LogEntryView: View {
    let log: LogEntry
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(log.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(log.level.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(log.level.color)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            
            Text(log.message)
                .font(.system(.body, design: .monospaced))
        }
        .padding(.vertical, 2)
    }
}

class LogMonitor: ObservableObject {
    @Published private(set) var logs: [LogEntry] = []
    private var fileHandle: FileHandle?
    private let maxLogs = 1000
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        guard let logPath = ZscalerConfig.load().logDir else { return }
        let logFile = "\(logPath)/zscaler-control.log"
        
        guard let handle = try? FileHandle(forReadingFrom: URL(fileURLWithPath: logFile)) else {
            return
        }
        
        fileHandle = handle
        
        Task {
            for await line in handle.bytes.lines {
                await processLogLine(line)
            }
        }
    }
    
    @MainActor
    private func processLogLine(_ line: String) {
        guard let entry = LogEntry(from: line) else { return }
        logs.append(entry)
        
        if logs.count > maxLogs {
            logs.removeFirst(logs.count - maxLogs)
        }
    }
    
    func clearLogs() {
        logs.removeAll()
    }
}

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String
    
    init?(from line: String) {
        let components = line.split(separator: " ")
        guard components.count >= 4,
              let date = DateFormatter.logDate.date(from: String(components[0])) else {
            return nil
        }
        
        self.timestamp = date
        self.level = LogLevel(rawValue: String(components[2])) ?? .info
        self.message = components[3...].joined(separator: " ")
    }
}

enum LogLevel: String, CaseIterable, Identifiable {
    case all = "All"
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .all: return .gray
        case .debug: return .blue
        case .info: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}

extension DateFormatter {
    static let logDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
