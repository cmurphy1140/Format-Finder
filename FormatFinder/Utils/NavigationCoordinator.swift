import SwiftUI

// MARK: - Navigation Path
enum NavigationDestination: Hashable {
    case formatDetail(GolfFormat)
    case bookmarks
    case settings
    case about
}

// MARK: - Navigation Coordinator
class NavigationCoordinator: ObservableObject {
    @Published var navigationPath = NavigationPath()
    @Published var selectedTab = 0
    @Published var presentedSheet: NavigationDestination?
    @Published var showingOnboarding = false
    
    // History tracking
    @Published private(set) var recentlyViewed: [String] = []
    private let maxRecentItems = 10
    
    // Deep linking support
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else { return }
        
        switch host {
        case "format":
            if let formatId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                // Navigate to specific format
                navigateToFormat(withId: formatId)
            }
        case "bookmarks":
            selectedTab = 1
        default:
            break
        }
    }
    
    func navigateToFormat(withId id: String) {
        // Find format by name since id is String but GolfFormat.id is UUID
        if let format = GolfFormat.allFormats.first(where: { $0.name == id }) {
            presentedSheet = .formatDetail(format)
            addToRecentlyViewed(id)
        }
    }
    
    func navigate(to destination: NavigationDestination) {
        navigationPath.append(destination)
    }
    
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func navigateToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
    
    func presentSheet(_ destination: NavigationDestination) {
        presentedSheet = destination
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
    
    private func addToRecentlyViewed(_ formatId: String) {
        recentlyViewed.removeAll { $0 == formatId }
        recentlyViewed.insert(formatId, at: 0)
        if recentlyViewed.count > maxRecentItems {
            recentlyViewed.removeLast()
        }
    }
    
    func clearHistory() {
        recentlyViewed.removeAll()
    }
}

// MARK: - Navigation Button Styles
struct NavigationButtonStyle: ButtonStyle {
    let role: ButtonRole
    
    enum ButtonRole {
        case primary
        case secondary
        case destructive
        case dismiss
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded))
            .foregroundColor(foregroundColor(for: role))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundColor(for: role, isPressed: configuration.isPressed))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func foregroundColor(for role: ButtonRole) -> Color {
        switch role {
        case .primary:
            return .white
        case .secondary:
            return .primary
        case .destructive:
            return .white
        case .dismiss:
            return .secondary
        }
    }
    
    private func backgroundColor(for role: ButtonRole, isPressed: Bool) -> Color {
        let opacity = isPressed ? 0.8 : 1.0
        switch role {
        case .primary:
            return Color.blue.opacity(opacity)
        case .secondary:
            return Color.blue.opacity(0.1 * opacity)
        case .destructive:
            return Color.red.opacity(opacity)
        case .dismiss:
            return Color.gray.opacity(0.2 * opacity)
        }
    }
}

// MARK: - Haptic Feedback Manager
class HapticManager {
    static let shared = HapticManager()
    private init() {}
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Improved Navigation Bar
struct ImprovedNavigationBar: View {
    let title: String
    let showBackButton: Bool
    let onBack: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            if showBackButton {
                Button(action: {
                    HapticManager.shared.impact(.light)
                    onBack()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                        Text("Back")
                            .font(.system(.body, design: .rounded))
                    }
                }
                .buttonStyle(NavigationButtonStyle(role: .secondary))
            }
            
            Spacer()
            
            Text(title)
                .font(.system(.title3, design: .rounded, weight: .semibold))
            
            Spacer()
            
            Button(action: {
                HapticManager.shared.impact(.light)
                onDismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
}