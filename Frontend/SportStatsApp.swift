import SwiftUI

@main
struct SportStatsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(SettingsKey.theme) private var theme = AppTheme.light.rawValue

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(AppTheme(rawValue: theme)?.colorScheme)
        }
        .modelContainer(Persistence.container)
    }
}
