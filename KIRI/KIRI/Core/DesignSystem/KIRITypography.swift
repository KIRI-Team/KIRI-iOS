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
