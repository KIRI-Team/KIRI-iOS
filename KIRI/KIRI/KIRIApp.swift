import SwiftUI
import FirebaseCore // firebase 연결
import KakaoSDKCommon
import KakaoSDKAuth
import GoogleSignIn

// AppDelegate 추가
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    if let appKey = Bundle.main.object(
        forInfoDictionaryKey: "KAKAO_NATIVE_APP_KEY"
    ) as? String,
       !appKey.isEmpty {
      KakaoSDK.initSDK(
        appKey: appKey,
        customScheme: "kakao\(appKey)"
      )
    }
    return true
  }

  func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    if AuthController.handleOpenUrl(url: url, options: options) {
      return true
    }

    return GIDSignIn.sharedInstance.handle(url)
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
