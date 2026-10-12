import AVFoundation
import Combine
import SwiftUI
import UIKit

/// 앱 시작 시 재생되는 Figma 스플래시 영상.
/// 세션 분기와 다음 화면 전환은 RootView가 담당한다.
struct SplashView: View {
    let onFinished: () -> Void

    @StateObject private var coordinator = SplashVideoCoordinator()

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            if let player = coordinator.player {
                SplashVideoPlayer(player: player)
                    .aspectRatio(390.0 / 844.0, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            coordinator.start(onFinished: onFinished)
        }
    }
}

private final class SplashVideoCoordinator: NSObject, ObservableObject {
    private let transitionTime = CMTime(seconds: 2.0, preferredTimescale: 600)

    let player: AVPlayer?

    private var finish: (() -> Void)?
    private var didFinish = false
    private var statusObservation: NSKeyValueObservation?
    private var timeObserver: Any?

    override init() {
        if let url = Bundle.main.url(forResource: "최종스플래시", withExtension: "mp4") {
            let item = AVPlayerItem(url: url)
            let avPlayer = AVPlayer(playerItem: item)
            avPlayer.isMuted = true
            avPlayer.actionAtItemEnd = .pause
            player = avPlayer

            super.init()

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerDidFinish(_:)),
                name: .AVPlayerItemDidPlayToEndTime,
                object: item
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerDidFail(_:)),
                name: .AVPlayerItemFailedToPlayToEndTime,
                object: item
            )

            statusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
                guard item.status == .failed else { return }
                self?.finishOnce()
            }
        } else {
            player = nil
            super.init()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        statusObservation?.invalidate()
        removeTimeObserver()
    }

    func start(onFinished: @escaping () -> Void) {
        guard !didFinish else { return }
        finish = onFinished

        guard let player else {
            finishOnce()
            return
        }

        timeObserver = player.addBoundaryTimeObserver(
            forTimes: [NSValue(time: transitionTime)],
            queue: .main
        ) { [weak self] in
            self?.finishOnce()
        }

        player.seek(to: .zero)
        player.play()
    }

    @objc private func playerDidFinish(_ notification: Notification) {
        finishOnce()
    }

    @objc private func playerDidFail(_ notification: Notification) {
        finishOnce()
    }

    private func finishOnce() {
        guard !didFinish else { return }
        didFinish = true
        player?.pause()
        removeTimeObserver()

        DispatchQueue.main.async { [finish] in
            finish?()
        }
    }

    private func removeTimeObserver() {
        guard let timeObserver, let player else { return }
        player.removeTimeObserver(timeObserver)
        self.timeObserver = nil
    }
}

private struct SplashVideoPlayer: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.playerLayer.player = player
        uiView.playerLayer.videoGravity = .resizeAspect
    }
}

private final class PlayerView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        guard let layer = layer as? AVPlayerLayer else {
            return AVPlayerLayer()
        }
        return layer
    }
}
