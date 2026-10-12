import SwiftUI

/// Figma 9173:12284 / 8095:62668. 세션 분기는 Root/AppRouter가 담당한다.
struct SplashView: View {
    let onFinished: () -> Void
    var body: some View {
        ZStack {
            KIRIColor.Background.base.ignoresSafeArea()
            VStack(spacing: 18) {
                Image("kiri_character").resizable().scaledToFit().frame(width: 86, height: 86)
                Image("kiri_logo").resizable().scaledToFit().frame(width: 226, height: 82)
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 650_000_000)
            onFinished()
        }
    }
}
