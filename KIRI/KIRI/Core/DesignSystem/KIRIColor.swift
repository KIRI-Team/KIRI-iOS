
import SwiftUI

enum KIRIColor {
    // MARK: - Background

    /// 앱 전체 기본 배경
    static let background = Color(
        red: 36 / 255,
        green: 36 / 255,
        blue: 38 / 255
    )

    /// 입력창 및 기본 카드
    static let surface = Color(
        red: 68 / 255,
        green: 68 / 255,
        blue: 69 / 255
    )

    /// 비활성 버튼
    static let disabled = Color(
        red: 45 / 255,
        green: 45 / 255,
        blue: 46 / 255
    )

    // MARK: - Text

    static let textPrimary = Color(
        red: 232 / 255,
        green: 232 / 255,
        blue: 234 / 255
    )

    static let textSecondary = Color(
        red: 126 / 255,
        green: 126 / 255,
        blue: 130 / 255
    )

    static let textTertiary = Color(
        red: 91 / 255,
        green: 91 / 255,
        blue: 94 / 255
    )

    // MARK: - Selection

    static let selectedBackground = Color(
        red: 245 / 255,
        green: 245 / 255,
        blue: 247 / 255
    )

    static let selectedText = Color(
        red: 63 / 255,
        green: 63 / 255,
        blue: 65 / 255
    )

    // MARK: - Common

    static let white = Color.white
    static let black = Color.black
}
