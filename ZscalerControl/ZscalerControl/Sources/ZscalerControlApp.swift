import SwiftUI

@main
struct ZscalerControlApp: App {
    var body: some Scene {
        MenuBarExtra("Zscaler Control", systemImage: "network") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
