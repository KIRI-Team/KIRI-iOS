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
