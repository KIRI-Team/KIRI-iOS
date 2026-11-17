//
// MARK: - 파일 가이드
// 파일: Core/Components/KIRIContentImage.swift
// 담당 영역: 공통 컴포넌트·디자인 시스템·네트워크·저장소
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import SwiftUI
import UIKit
import ImageIO
import UniformTypeIdentifiers

private actor KIRIImagePipeline {
    static let shared = KIRIImagePipeline()

    private var cache: [URL: Data] = [:]
    private var inFlight: [URL: Task<Data?, Never>] = [:]

    func data(for url: URL) async -> Data? {
        let startedAt = Date()
        if let cached = cache[url] {
            #if DEBUG
            print("[KIRI][ImagePerf] cache hit elapsedMs=\(Int(Date().timeIntervalSince(startedAt) * 1000))")
            #endif
            return cached
        }
        if let task = inFlight[url] { return await task.value }

        let task = Task<Data?, Never> {
            guard let raw = try? await URLSession.shared.data(from: url).0 else { return nil }
            return Self.downsample(raw, maxPixelSize: 1200)
        }
        inFlight[url] = task
        let result = await task.value
        inFlight[url] = nil
        if let result { cache[url] = result }
        #if DEBUG
        print("[KIRI][ImagePerf] fetch complete elapsedMs=\(Int(Date().timeIntervalSince(startedAt) * 1000)) success=\(result != nil)")
        #endif
        return result
    }

    private static func downsample(_ data: Data, maxPixelSize: Int) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return data }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return data
        }
        let output = NSMutableData()
        let type = CGImageSourceGetType(source) ?? UTType.jpeg.identifier as CFString
        guard let destination = CGImageDestinationCreateWithData(output, type, 1, nil) else { return data }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return data }
        return output as Data
    }
}

/// API 이미지가 있으면 우선 표시하고, 없거나 실패하면 콘텐츠별 목 에셋을 사용한다.
struct KIRIContentImage<Placeholder: View>: View {
    let imageURL: URL?
    let mockAssetName: String?
    let contentMode: ContentMode
    let placeholder: () -> Placeholder
    @State private var imageData: Data?

    init(imageURL: URL? = nil, mockAssetName: String? = nil,
         contentMode: ContentMode = .fill,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.imageURL = imageURL
        self.mockAssetName = mockAssetName
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                fallback
            }
        }
        .task(id: imageURL) {
            imageData = nil
            guard let imageURL else { return }
            imageData = await KIRIImagePipeline.shared.data(for: imageURL)
        }
    }

    @ViewBuilder
    private var fallback: some View {
        if let mockAssetName {
            Image(mockAssetName).resizable().aspectRatio(contentMode: contentMode)
        } else {
            placeholder()
        }
    }
}
