import Foundation

struct ZscalerConfig: Codable {
    let appPath: String
    let launchAgentsPath: String
    let launchDaemonsPath: String
    let logDir: String
    let maxRetries: Int
    let retryDelay: Int
    let statusCheckInterval: Int
    let notificationsEnabled: Bool
    let scriptsPath: String
    
    static func load() -> ZscalerConfig {
        let defaultConfig = ZscalerConfig(
            appPath: "/Applications/Zscaler/Zscaler.app",
            launchAgentsPath: "/Library/LaunchAgents",
            launchDaemonsPath: "/Library/LaunchDaemons",
            logDir: "\(NSHomeDirectory())/.zscaler",
            maxRetries: 3,
            retryDelay: 2,
            statusCheckInterval: 30,
            notificationsEnabled: true,
            scriptsPath: "\(Bundle.main.bundlePath)/Contents/Resources/scripts"
        )
        
        guard let configUrl = Bundle.main.url(forResource: "config", withExtension: "json"),
              let configData = try? Data(contentsOf: configUrl),
              let config = try? JSONDecoder().decode(ZscalerConfig.self, from: configData)
        else {
            return defaultConfig
        }
        
        return config
    }
}
