import Foundation
import SwiftData
import UserNotifications

/// Recordatorios diarios de suplementos.
///
/// En vez de un único aviso repetitivo, se programan avisos sueltos para los
/// próximos días. Así, si ya marcaste el suplemento hoy, no te llega el aviso
/// de hoy. La lista se rehace cada vez que abres la app o marcas una toma.
@MainActor
enum NotificationManager {
    static let categoryID = "SUPPLEMENT_REMINDER"
    static let takenActionID = "MARK_TAKEN"
    static let supplementKey = "supplementUID"

    /// iOS permite como máximo 64 avisos pendientes por app.
    private static let pendingBudget = 60
    private static let maxDaysAhead = 14

    static func registerCategories() {
        let taken = UNNotificationAction(identifier: takenActionID, title: "Ya lo tomé ✓", options: [])
        let category = UNNotificationCategory(identifier: categoryID, actions: [taken], intentIdentifiers: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    @discardableResult
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    /// Borra y vuelve a programar todos los recordatorios.
    static func reschedule(_ supplements: [Supplement]) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let enabled = UserDefaults.standard.object(forKey: SettingsKey.notificationsEnabled) as? Bool ?? true
        let active = supplements.filter(\.remindersEnabled)
        guard enabled, !active.isEmpty, await requestAuthorization() else { return }

        let daysAhead = max(2, min(maxDaysAhead, pendingBudget / active.count))
        let calendar = Calendar.current
        let now = Date.now

        for supplement in active {
            for offset in 0..<daysAhead {
                guard let day = calendar.date(byAdding: .day, value: offset, to: now),
                      let fireDate = calendar.date(bySettingHour: supplement.reminderHour,
                                                   minute: supplement.reminderMinute,
                                                   second: 0, of: day),
                      fireDate > now,
                      !supplement.wasTaken(on: day) else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Hora de tu \(supplement.name)"
                content.body = supplement.dose.isEmpty
                    ? "Recuerda tomarlo hoy."
                    : "Toca tu dosis de \(supplement.dose)."
                content.sound = .default
                content.categoryIdentifier = categoryID
                content.userInfo = [supplementKey: supplement.uid.uuidString]

                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let id = "\(supplement.uid.uuidString)-\(offset)"
                try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }
        }
    }

    /// Reprograma leyendo directamente de la base de datos.
    static func rescheduleAll(in context: ModelContext) async {
        let supplements = (try? context.fetch(FetchDescriptor<Supplement>())) ?? []
        await reschedule(supplements)
    }
}
