//
// MARK: - 파일 가이드
// 파일: Core/DesignSystem/KIRITypography.swift
// 담당 영역: 공통 컴포넌트·디자인 시스템·네트워크·저장소
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import SwiftUI
import UIKit

struct KIRITextStyle {
    enum Weight: String {
        case regular = "Regular"
        case medium = "Medium"
        case semiBold = "SemiBold"
    }

    let font: Font
    let fontName: String
    let weight: Weight
    let fontSize: CGFloat
    let letterSpacing: CGFloat
    let lineHeight: CGFloat
    let usesExplicitLineHeight: Bool

    var lineSpacing: CGFloat {
        guard usesExplicitLineHeight else { return 0 }
        // SwiftUI's lineSpacing is added to the font's own leading. Use the
        // actual Pretendard UIFont metric instead of subtracting fontSize.
        let metricsLineHeight = UIFont(name: fontName, size: fontSize)?.lineHeight ?? fontSize
        return max(0, lineHeight - metricsLineHeight)
    }
}

enum KIRITypography {

    // MARK: - Font Family

    private static let regularName = "Pretendard-Regular"
    private static let mediumName = "Pretendard-Medium"
    private static let semiBoldName = "Pretendard-SemiBold"

    // MARK: - Display / Title

    /// 28 / 40 / Medium / -2%
    static let title = pretendard(
        name: mediumName,
        size: 28
    )

    /// 28 / 40 / Medium / -2%
    static let titleBold = pretendard(
        name: mediumName,
        size: 28
    )

    /// 24 / 32 / SemiBold / -2%
    static let headingLarge = pretendard(
        name: semiBoldName,
        size: 24
    )

    /// Figma Heading/Medium: 20 / 28 / Medium / -4%
    static let headingMedium = pretendard(
        name: mediumName,
        size: 20
    )

    /// 18 / 27 / Medium / -4%
    static let headingSmall = pretendard(
        name: mediumName,
        size: 18
    )

    // MARK: - Body

    /// 16 / 26 / Regular / -4%
    static let body = pretendard(
        name: regularName,
        size: 16
    )

    /// 16 / 24 / Medium / -4%
    static let bodyMedium = pretendard(
        name: mediumName,
        size: 16
    )

    /// 14 / 21 / Regular / -4%
    static let bodySmall = pretendard(
        name: regularName,
        size: 14
    )

    /// 14 / 20 / Medium / -4%
    static let bodySmallMedium = pretendard(
        name: mediumName,
        size: 14
    )

    // MARK: - Components

    /// KIRI/Button
    /// 16 / 24 / Medium / -4%
    static let button = pretendard(
        name: mediumName,
        size: 16
    )

    /// 14 / 20 / Medium / -4%
    static let chip = pretendard(
        name: mediumName,
        size: 14
    )

    /// 12 / 18 / Regular / -4%
    static let caption = pretendard(
        name: regularName,
        size: 12
    )

    /// 12 / 17 / Medium / -4%
    static let captionMedium = pretendard(
        name: mediumName,
        size: 12
    )

    /// Bottom Navigation
    static let navigation = pretendard(
        name: mediumName,
        size: 10
    )

    // MARK: - Figma Text Styles

    // Tracking is stored in points after converting Figma's percentage value:
    // fontSize × percent / 100. The line height is applied by kiriTextStyle().
    static let displayLarge = style(size: 28, lineHeight: 40, weight: .medium, trackingPercent: -2)
    static let displayMedium = style(size: 24, lineHeight: 36, weight: .regular, trackingPercent: -2)
    static let headingLargeStyle = style(size: 24, lineHeight: 32, weight: .semiBold, trackingPercent: -2)
    static let headingMediumStyle = style(size: 20, lineHeight: 28, weight: .medium, trackingPercent: -4)
    static let titleLarge = style(size: 18, lineHeight: 27, weight: .medium, trackingPercent: -4)
    static let titleMedium = style(size: 16, lineHeight: 24, weight: .medium, trackingPercent: -4)
    static let bodyLarge3 = style(size: 20, lineHeight: 30, weight: .medium, trackingPercent: -4)
    static let bodyLarge2 = style(size: 18, lineHeight: 27, weight: .medium, trackingPercent: -4)
    static let bodyLarge = style(size: 16, lineHeight: 26, weight: .regular, trackingPercent: -4)
    static let bodyMediumStyle = style(size: 14, lineHeight: 21, weight: .regular, trackingPercent: -4)
    static let bodySmallStyle = style(size: 12, lineHeight: 18, weight: .regular, trackingPercent: -4)
    static let labelLarge = style(size: 16, lineHeight: 23, weight: .medium, trackingPercent: -4)
    static let labelMedium = style(size: 14, lineHeight: 20, weight: .medium, trackingPercent: -4)
    static let labelSmall = style(size: 12, lineHeight: 17, weight: .medium, trackingPercent: -4)
    static let labelSmallStrong = style(size: 12, lineHeight: 17, weight: .semiBold, trackingPercent: -4)
    static let captionStyle = style(size: 11, lineHeight: 16, weight: .regular, trackingPercent: -2)
    static let micro = style(size: 10, lineHeight: 14, weight: .medium, trackingPercent: -4)
    static let toastMessage = style(size: 18, lineHeight: 22, weight: .medium, trackingPercent: -4, usesExplicitLineHeight: false)
    static let toastAction = style(size: 14, lineHeight: 17, weight: .regular, trackingPercent: -4)

    // MARK: - Role

    /// 가족 역할 한글
    static let roleKorean = pretendard(
        name: semiBoldName,
        size: 24
    )

    /// 가족 역할 영문
    static let roleEnglish = pretendard(
        name: semiBoldName,
        size: 18
    )

    // MARK: - Legacy Compatibility

    static let subtitle = bodySmall

    // MARK: - Font Factory

    private static func pretendard(
        name: String,
        size: CGFloat
    ) -> Font {
        .custom(
            name,
            fixedSize: size
        )
    }

    private static func style(
        size: CGFloat,
        lineHeight: CGFloat,
        weight: KIRITextStyle.Weight,
        trackingPercent: CGFloat,
        usesExplicitLineHeight: Bool = true
    ) -> KIRITextStyle {
        let fontName: String
        switch weight {
        case .regular: fontName = regularName
        case .medium: fontName = mediumName
        case .semiBold: fontName = semiBoldName
        }

        return KIRITextStyle(
            font: pretendard(name: fontName, size: size),
            fontName: fontName,
            weight: weight,
            fontSize: size,
            letterSpacing: size * trackingPercent / 100,
            lineHeight: lineHeight,
            usesExplicitLineHeight: usesExplicitLineHeight
        )
    }
}

extension View {
    /// Applies the complete Figma text style in one place. Callers should not
    /// add another tracking or lineSpacing modifier after this method.
    @ViewBuilder
    func kiriTextStyle(_ style: KIRITextStyle) -> some View {
        if style.usesExplicitLineHeight {
            font(style.font)
                .tracking(style.letterSpacing)
                .lineSpacing(style.lineSpacing)
        } else {
            // Figma Auto line-height: preserve the font's native metrics.
            font(style.font)
                .tracking(style.letterSpacing)
        }
    }
}
