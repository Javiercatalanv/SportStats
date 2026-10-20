import Charts
import SwiftData
import SwiftUI

/// "Progreso": constancia con suplementos y entrenamientos.
/// (Se llama ProgressScreen para no chocar con `SwiftUI.ProgressView`.)
struct ProgressScreen: View {
    @Query private var supplements: [Supplement]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @State private var selectedDay: Date?

    private struct DayStat: Identifiable {
        let date: Date
        let taken: Int
        let total: Int
        var id: Date { date }
        var ratio: Double { total == 0 ? 0 : Double(taken) / Double(total) }
    }

    private var lastSevenDays: [DayStat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            // Solo cuentan los suplementos que ya existían ese día.
            let existing = supplements.filter { calendar.startOfDay(for: $0.createdAt) <= day }
            return DayStat(date: day, taken: existing.filter { $0.wasTaken(on: day) }.count, total: existing.count)
        }
    }

    private var weeklyAdherence: Int {
        let stats = lastSevenDays.filter { $0.total > 0 }
        let taken = stats.reduce(0) { $0 + $1.taken }
        let total = stats.reduce(0) { $0 + $1.total }
        return total == 0 ? 0 : Int((Double(taken) / Double(total) * 100).rounded())
    }

    /// Días seguidos (hasta ayer, más hoy si ya está completo) con todos los suplementos tomados.
    private var streak: Int {
        guard !supplements.isEmpty else { return 0 }
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: .now)
        var count = 0
        if supplements.allSatisfy({ $0.wasTaken(on: day) }) { count += 1 }
        for _ in 0..<365 {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
            let existing = supplements.filter { calendar.startOfDay(for: $0.createdAt) <= day }
            guard !existing.isEmpty, existing.allSatisfy({ $0.wasTaken(on: day) }) else { break }
            count += 1
        }
        return count
    }

    private var sessionsThisWeek: Int {
        let calendar = Calendar.current
        return sessions.filter { calendar.isDate($0.date, equalTo: .now, toGranularity: .weekOfYear) }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BackHeader(title: "Progreso")

                HStack(spacing: 12) {
                    StatTile(label: "Entrenos", value: "\(sessionsThisWeek)", caption: "esta semana")
                    StatTile(label: "Racha", value: "\(streak)", caption: streak == 1 ? "día" : "días")
                    StatTile(label: "Suplementos", value: "\(weeklyAdherence)%", caption: "7 días")
                }

                SectionTitle(text: "Suplementos tomados")
                adherenceChart

                SectionTitle(text: "Últimos entrenos")
                if sessions.isEmpty {
                    EmptyStateCard(systemImage: "figure.volleyball",
                                   title: "Aún no hay entrenos",
                                   message: "Completa una rutina en Entrenar y aparecerá aquí.")
                } else {
                    VStack(spacing: 12) {
                        ForEach(sessions.prefix(10)) { session in
                            SessionRow(session: session)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .screenBackground()
    }

    @ViewBuilder
    private var adherenceChart: some View {
        let stats = lastSevenDays
        let selected = selectedDay.flatMap { day in stats.first { Calendar.current.isDate($0.date, inSameDayAs: day) } }

        VStack(alignment: .leading, spacing: 12) {
            if supplements.isEmpty {
                Text("Añade suplementos para ver tu constancia diaria.")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.inkSecondary)
            } else {
                Text(selected.map { "\($0.date.formatted(.dateTime.weekday(.wide).day().locale(Locale(identifier: "es_CL")))): \($0.taken) de \($0.total)" }
                     ?? "Últimos 7 días · toca una barra")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)

                Chart(stats) { stat in
                    BarMark(
                        x: .value("Día", stat.date, unit: .day),
                        y: .value("Tomados", stat.ratio * 100),
                        width: .ratio(0.45)
                    )
                    .cornerRadius(4)
                    .foregroundStyle(selected == nil || selected?.id == stat.id ? Theme.ink : Theme.inkMuted)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 50, 100]) { value in
                        AxisGridLine().foregroundStyle(Theme.stroke)
                        AxisValueLabel { Text("\(value.as(Int.self) ?? 0)%").foregroundStyle(Theme.inkMuted) }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(Weekday.from(date).initial).foregroundStyle(Theme.inkSecondary)
                            }
                        }
                    }
                }
                .chartXSelection(value: $selectedDay)
                .frame(height: 180)
                .accessibilityLabel("Porcentaje de suplementos tomados en los últimos 7 días")
            }
        }
        .card(padding: 20)
    }
}

private struct StatTile: View {
    let label: String
    let value: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.inkSecondary)
            Text(value).font(.system(size: 28, weight: .bold).monospacedDigit()).foregroundStyle(Theme.ink)
            Text(caption).font(.system(size: 13)).foregroundStyle(Theme.inkMuted)
        }
        .card(corner: Theme.cornerMedium, padding: 16)
    }
}

private struct SessionRow: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: session.goal?.systemImage ?? "dumbbell")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 46, height: 46)
                .background(Circle().fill(Theme.cardRaised))
            VStack(alignment: .leading, spacing: 2) {
                Text(session.goal?.title ?? "Entreno").font(.system(size: 17, weight: .semibold))
                Text("\(session.setsCompleted) series · \(WorkoutSessionView.clock(session.durationSeconds))")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
            Text(session.date.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "es_CL"))))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
        }
        .foregroundStyle(Theme.ink)
        .card(corner: Theme.cornerMedium, padding: 14)
    }
}
