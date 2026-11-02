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

    /// 20 / 30 / Medium / -4%
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
}
