import SwiftData
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        // Las fotos de los ejercicios se guardan en disco tras verlas la primera vez.
        URLCache.shared = URLCache(memoryCapacity: 30_000_000, diskCapacity: 300_000_000)
        Task { @MainActor in NotificationManager.registerCategories() }
        return true
    }

    /// Muestra el aviso aunque la app esté abierta.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    /// Botón "Ya lo tomé" desde la notificación.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        guard response.actionIdentifier == NotificationManager.takenActionID,
              let raw = response.notification.request.content.userInfo[NotificationManager.supplementKey] as? String,
              let uid = UUID(uuidString: raw) else { return }
        await Self.markTaken(uid)
    }

    @MainActor
    private static func markTaken(_ uid: UUID) async {
        let context = Persistence.container.mainContext
        let descriptor = FetchDescriptor<Supplement>(predicate: #Predicate<Supplement> { $0.uid == uid })
        guard let supplement = try? context.fetch(descriptor).first, !supplement.isTakenToday else { return }
        supplement.logs.append(SupplementLog())
        try? context.save()
        await NotificationManager.rescheduleAll(in: context)
    }
}
