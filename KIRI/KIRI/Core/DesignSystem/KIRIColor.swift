import SwiftUI

enum KIRIColor {

    // MARK: - Primitive Colors
    //
    // Source of Truth:
    // Figma → KIRI / Foundations → KIRI / Primitive
    //
    // Feature/View에서는 Primitive를 직접 사용하지 않고
    // Semantic 또는 Component Token을 사용한다.

    enum Primitive {

        // MARK: Neutral

        static let neutral0 = Color(hex: 0xFFFFFF)
        static let neutral50 = Color(hex: 0xF7F7F7)
        static let neutral100 = Color(hex: 0xEEEEEE)
        static let neutral200 = Color(hex: 0xD9D9D9)
        static let neutral300 = Color(hex: 0xB3B3B3)
        static let neutral400 = Color(hex: 0x8C8C8C)
        static let neutral500 = Color(hex: 0x737373)
        static let neutral600 = Color(hex: 0x595959)
        static let neutral700 = Color(hex: 0x404040)
        static let neutral800 = Color(hex: 0x333333)
        static let neutral850 = Color(hex: 0x2B2B2B)
        static let neutral900 = Color(hex: 0x242424)
        static let neutral950 = Color(hex: 0x1A1A1A)
        static let neutral1000 = Color(hex: 0x000000)

        // MARK: Green

        static let green50 = Color(hex: 0xF3FDE9)
        static let green100 = Color(hex: 0xE4FACB)
        static let green200 = Color(hex: 0xCDF6A5)
        static let green300 = Color(hex: 0xB6F17C)
        static let green400 = Color(hex: 0xA6ED62)
        static let green500 = Color(hex: 0x9BEA51)
        static let green600 = Color(hex: 0x85D641)
        static let green700 = Color(hex: 0x6DB530)
        static let green800 = Color(hex: 0x568F27)
        static let green900 = Color(hex: 0x3C641C)

        // MARK: Blue

        static let blue500 = Color(hex: 0x6BAAF2)
        static let blue900 = Color(hex: 0x20364F)

        // MARK: Red

        static let red500 = Color(hex: 0xF36B6B)
        static let red900 = Color(hex: 0x4A2424)

        // MARK: Yellow

        static let yellow500 = Color(hex: 0xF1C75B)
        static let yellow900 = Color(hex: 0x463A1D)

        // MARK: Alpha

        // Figma alpha/black-60의 실제 opacity는 0.70
        static let alphaBlack60 = neutral1000.opacity(0.70)

        // Figma 변수 이름은 white-05지만 실제 값은 10%
        static let alphaWhite05 = neutral0.opacity(0.10)

        static let alphaWhite08 = neutral0.opacity(0.08)
        static let alphaWhite12 = neutral0.opacity(0.12)

        static let alphaGreen10 = green500.opacity(0.10)

        // Figma 변수 이름은 green-16이지만 실제 값은 20%
        static let alphaGreen16 = green500.opacity(0.20)

        // Figma alpha/transparent 실제 값
        static let alphaTransparent = neutral1000.opacity(0.10)
    }

    // MARK: - Semantic Colors
    //
    // Source of Truth:
    // Figma → KIRI / Semantic → Dark

    enum Background {
        static let base = Primitive.neutral950
        static let primary = Primitive.neutral900
        static let secondary = Primitive.neutral850
        static let tertiary = Primitive.neutral800
        static let elevated = Primitive.neutral700

        static let green = Primitive.green900
        static let greenSoft = Primitive.alphaGreen10

        static let transparent = Primitive.alphaTransparent
    }

    enum Border {
        static let subtle = Primitive.neutral800
        static let `default` = Primitive.neutral700
        static let strong = Primitive.neutral600
        static let transparent = Primitive.alphaTransparent
    }

    enum Divider {
        static let `default` = Primitive.neutral800
    }

    enum Focus {
        static let ring = Primitive.green300
    }

    enum Icon {
        static let primary = Primitive.neutral200
        static let secondary = Primitive.neutral400
        static let disabled = Primitive.neutral500

        static let accent = Primitive.green500
        static let strong = Primitive.neutral50
        static let onGreen = Primitive.neutral950
    }

    enum Primary {
        static let `default` = Primitive.green500
        static let pressed = Primitive.green600
        static let disabled = Primitive.green800
        static let container = Primitive.alphaGreen16
    }

    enum State {
        static let overlay = Primitive.alphaBlack60
        static let pressed = Primitive.alphaWhite08
        static let selected = Primitive.alphaWhite12
        static let greenPressed = Primitive.alphaGreen16
    }

    enum Status {
        static let success = Primitive.green500
        static let successBackground = Primitive.alphaGreen10

        static let warning = Primitive.yellow500
        static let warningBackground = Primitive.yellow900

        static let error = Primitive.red500
        static let errorBackground = Primitive.red900

        static let info = Primitive.blue500
        static let infoBackground = Primitive.blue900
    }

    enum Text {
        static let strong = Primitive.neutral50
        static let primary = Primitive.neutral200
        static let secondary = Primitive.neutral300
        static let tertiary = Primitive.neutral400
        static let disabled = Primitive.neutral500

        static let accent = Primitive.green500

        static let onGreen = Primitive.neutral950
        static let inverse = Primitive.neutral950
    }

    // MARK: - Component Colors
    //
    // Source of Truth:
    // Figma → KIRI / Component → Dark

    enum Button {

        enum FilledAccent {
            static let backgroundDefault = Primary.default
            static let backgroundDisabled = Primary.disabled
            static let backgroundPressed = Primary.pressed

            static let contentDefault = Text.onGreen
            static let contentDisabled = Text.disabled
            static let contentPressed = Text.onGreen
        }

        enum FilledNeutral {
            static let backgroundDefault = Background.elevated
            static let backgroundDisabled = Background.secondary
            static let backgroundPressed = State.pressed

            static let contentDefault = Text.primary
            static let contentDisabled = Text.disabled
            static let contentPressed = Text.strong
        }

        enum Ghost {
            static let backgroundDefault = Background.transparent
            static let backgroundDisabled = Background.transparent
            static let backgroundPressed = State.greenPressed

            static let contentDefault = Text.accent
            static let contentDisabled = Text.disabled
            static let contentPressed = Text.accent
        }
    }

    enum Card {
        static let backgroundDefault = Background.secondary
        static let backgroundDisabled = Background.primary
        static let backgroundPressed = State.pressed
        static let backgroundSelected = Primary.container

        static let borderDefault = Border.default
        static let borderDisabled = Border.subtle
        static let borderPressed = Border.strong
        static let borderSelected = Primary.default
    }

    enum Chip {
        static let backgroundDefault = Background.tertiary
        static let backgroundDisabled = Background.primary
        static let backgroundPressed = State.pressed
        static let backgroundSelected = Primary.container

        static let borderDefault = Border.default
        static let borderDisabled = Border.subtle
        static let borderPressed = Border.strong
        static let borderSelected = Primary.default

        static let contentDefault = Text.secondary
        static let contentDisabled = Text.disabled
        static let contentPressed = Text.strong
        static let contentSelected = Primary.default
    }

    enum Input {
        static let backgroundDefault = Background.secondary
        static let backgroundDisabled = Background.primary
        static let backgroundError = Background.secondary
        static let backgroundFilled = Background.secondary
        static let backgroundFocus = Background.secondary

        static let borderDefault = Border.default
        static let borderDisabled = Border.subtle
        static let borderError = Status.error
        static let borderFilled = Border.default
        static let borderFocus = Primary.default

        static let contentDefault = Text.primary
        static let contentDisabled = Text.disabled
        static let contentError = Text.primary
        static let contentFilled = Text.primary
        static let contentFocus = Text.primary

        static let helperDefault = Text.tertiary
        static let helperDisabled = Text.disabled
        static let helperError = Status.error
        static let helperFilled = Text.tertiary
        static let helperFocus = Text.tertiary

        static let placeholderDefault = Text.secondary
        static let placeholderDisabled = Text.disabled
        static let placeholderError = Text.secondary
        static let placeholderFocus = Text.secondary
    }

    enum Navigation {

        enum Bar {
            static let background = Background.secondary
            static let border = Border.strong
        }

        enum Item {
            static let backgroundActive = Background.primary
            static let backgroundDefault = Background.transparent
            static let backgroundDisabled = Background.transparent
            static let backgroundPressed = State.pressed

            static let contentActive = Text.strong
            static let contentDefault = Text.tertiary
            static let contentDisabled = Text.disabled
            static let contentPressed = Text.primary
        }
    }

    enum Tab {
        static let contentActive = Text.strong
        static let contentDefault = Text.tertiary
        static let contentDisabled = Text.disabled
        static let contentPressed = Text.primary

        static let indicatorActive = Text.strong
        static let indicatorDefault = Background.transparent
        static let indicatorDisabled = Background.transparent
        static let indicatorPressed = State.pressed
    }

    // MARK: - Legacy Compatibility
    //
    // 기존 화면 마이그레이션용.
    // 신규 화면에서는 Semantic / Component Token을 사용한다.

    static let background = Background.base
    static let surface = Input.backgroundDefault
    static let disabled = Button.FilledNeutral.backgroundDisabled

    static let textPrimary = Text.primary
    static let textSecondary = Text.secondary
    static let textTertiary = Text.tertiary

    static let selectedBackground = Primitive.neutral50
    static let selectedText = Primitive.neutral900

    static let white = Primitive.neutral0
    static let black = Primitive.neutral1000
}

// MARK: - Hex Color

private extension Color {

    init(hex: UInt32, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
