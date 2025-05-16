import SwiftUI

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("statusCheckInterval") private var statusCheckInterval = 30
    @AppStorage("logRetentionDays") private var logRetentionDays = 7
    @AppStorage("showDockIcon") private var showDockIcon = false
    
    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                Toggle("Show in Dock", isOn: $showDockIcon)
                    .onChange(of: showDockIcon) { newValue in
                        toggleDockIcon(show: newValue)
                    }
            }
            
            Section("Notifications") {
                Toggle("Enable notifications", isOn: $notificationsEnabled)
            }
            
            Section("Monitoring") {
                Stepper("Status check interval: \(statusCheckInterval)s",
                        value: $statusCheckInterval,
                        in: 10...300,
                        step: 10)
            }
            
            Section("Logs") {
                Picker("Log retention", selection: $logRetentionDays) {
                    Text("1 day").tag(1)
                    Text("7 days").tag(7)
                    Text("30 days").tag(30)
                    Text("90 days").tag(90)
                }
                Button("Open logs folder") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "\(NSHomeDirectory())/.zscaler"))
                }
                Button("Export logs...") {
                    exportLogs()
                }
            }
        }
        .padding()
        .frame(width: 350)
    }
    
    private func toggleDockIcon(show: Bool) {
        NSApp.setActivationPolicy(show ? .regular : .accessory)
    }
    
    private func exportLogs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.zip]
        panel.nameFieldStringValue = "zscaler-logs.zip"
        
        panel.begin { response in
            guard response == .OK,
                  let url = panel.url else { return }
            
            Task {
                await LogExporter.exportLogs(to: url)
            }
        }
    }
}

#Preview {
    SettingsView()
}
