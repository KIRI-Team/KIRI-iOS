import SwiftUI
import FirebaseCore // firebase 연결

// AppDelegate 추가
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}
// 여기까지 AppDelegate

@main
struct KIRIApp: App {
    // 앱 델리게이트 등록 코드 추가
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootView() // 기존에 쓰시던 RootView 그대로 유지
        }
    }
}
