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

/// API 이미지가 있으면 우선 표시하고, 없거나 실패하면 콘텐츠별 목 에셋을 사용한다.
struct KIRIContentImage<Placeholder: View>: View {
    let imageURL: URL?
    let mockAssetName: String?
    let contentMode: ContentMode
    let placeholder: () -> Placeholder

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
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image): image.resizable().aspectRatio(contentMode: contentMode)
                    case .empty, .failure: fallback
                    @unknown default: fallback
                    }
                }
            } else {
                fallback
            }
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
