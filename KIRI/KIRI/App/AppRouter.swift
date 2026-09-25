import SwiftUI

@Observable
final class AppRouter {
    enum AppState {
        case main
    }

    var appState: AppState = .main
}
