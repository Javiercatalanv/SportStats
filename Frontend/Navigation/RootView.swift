import SwiftData
import SwiftUI

enum AppTab: CaseIterable {
    case train, home, profile

    var title: String {
        switch self {
        case .train: "Entrenar"
        case .home: "Inicio"
        case .profile: "Perfil"
        }
    }

    var systemImage: String {
        switch self {
        case .train: "dumbbell"
        case .home: "house"
        case .profile: "person"
        }
    }
}

/// Destinos de navegación compartidos por las tres pestañas.
enum Route: Hashable {
    case supplements
    case progress
    case settings
    case editProfile
    case privacy
    case routine(TrainingGoal)
    case allRoutines
    case muscleGroup(MuscleGroup)
    case exercise(Exercise, TrainingGoal?)
    case search
}

struct RootView: View {
    @State private var tab: AppTab = .home
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            tabStack(.train) { TrainView() }
            tabStack(.home) { HomeView() }
            tabStack(.profile) { ProfileView() }
        }
        .overlay(alignment: .bottom) {
            FloatingTabBar(selection: $tab)
                .padding(.horizontal, 16)
                .padding(.bottom, FloatingTabBar.bottomPadding)
        }
        .tint(Theme.ink)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await NotificationManager.rescheduleAll(in: modelContext) }
            }
        }
    }

    private func tabStack<Content: View>(_ item: AppTab, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content()
                .tabBarInset()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Route.self) { route in
                    RouteDestination(route: route)
                        .tabBarInset()
                        .toolbar(.hidden, for: .navigationBar)
                }
        }
        .opacity(tab == item ? 1 : 0)
        .allowsHitTesting(tab == item)
        .accessibilityHidden(tab != item)
    }
}

struct RouteDestination: View {
    let route: Route

    var body: some View {
        switch route {
        case .supplements: SupplementsView()
        case .progress: ProgressScreen()
        case .settings: SettingsView()
        case .editProfile: EditProfileView()
        case .privacy: PrivacyView()
        case .routine(let goal): RoutineDetailView(goal: goal)
        case .allRoutines: AllRoutinesView()
        case .muscleGroup(let group): MuscleGroupView(group: group)
        case .exercise(let exercise, let goal): ExerciseDetailView(exercise: exercise, goal: goal)
        case .search: ExerciseSearchView()
        }
    }
}

extension View {
    /// Reserva espacio al final de cada pantalla para que la barra flotante no tape el contenido.
    /// Va dentro del NavigationStack porque un safeAreaInset puesto afuera no llega a sus pantallas.
    func tabBarInset() -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: FloatingTabBar.reservedHeight)
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selection: AppTab
    @Namespace private var namespace

    static let itemHeight: CGFloat = 54
    static let inset: CGFloat = 6
    static let bottomPadding: CGFloat = 4
    /// Alto total que ocupa la barra sobre el borde inferior.
    static let reservedHeight = itemHeight + inset * 2 + bottomPadding

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { item in
                let selected = item == selection
                Button {
                    if !selected { Feedback.tap() }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selection = item }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 20, weight: selected ? .semibold : .regular))
                        Text(item.title)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(selected ? Theme.ink : Theme.inkSecondary)
                    .frame(maxWidth: .infinity, minHeight: Self.itemHeight)
                    .background {
                        if selected {
                            Capsule()
                                .fill(Theme.selection)
                                .matchedGeometryEffect(id: "tab", in: namespace)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(Self.inset)
        .background(
            Capsule()
                .fill(Theme.card)
                .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 8)
        )
    }
}
