import SwiftUI

enum KIRIColor {

    // MARK: - Primitive Colors
    //
    // Figma:
    // 02 Primitive Colors
    //
    // Feature/View에서는 Primitive를 직접 사용하는 것을 지양하고,
    // 아래 Semantic 또는 Component Color를 사용한다.

    enum Primitive {

        // MARK: Neutral

        static let neutral0 = Color(
            red: 1.00,
            green: 1.00,
            blue: 1.00
        )

        static let neutral50 = Color(
            red: 0.97,
            green: 0.97,
            blue: 0.97
        )

        static let neutral100 = Color(
            red: 0.93,
            green: 0.93,
            blue: 0.93
        )

        static let neutral200 = Color(
            red: 0.82,
            green: 0.82,
            blue: 0.82
        )

        static let neutral300 = Color(
            red: 0.70,
            green: 0.70,
            blue: 0.70
        )

        static let neutral400 = Color(
            red: 0.58,
            green: 0.58,
            blue: 0.58
        )

        static let neutral500 = Color(
            red: 0.48,
            green: 0.48,
            blue: 0.48
        )

        static let neutral600 = Color(
            red: 0.38,
            green: 0.38,
            blue: 0.38
        )

        static let neutral700 = Color(
            red: 0.29,
            green: 0.29,
            blue: 0.29
        )

        static let neutral800 = Color(
            red: 0.21,
            green: 0.21,
            blue: 0.21
        )

        static let neutral850 = Color(
            red: 0.17,
            green: 0.17,
            blue: 0.17
        )

        static let neutral900 = Color(
            red: 0.14,
            green: 0.14,
            blue: 0.14
        )

        static let neutral950 = Color(
            red: 0.10,
            green: 0.10,
            blue: 0.10
        )

        static let neutral1000 = Color(
            red: 0.00,
            green: 0.00,
            blue: 0.00
        )

        // MARK: Green

        static let green50 = Color(
            red: 0.95,
            green: 0.99,
            blue: 0.91
        )

        static let green100 = Color(
            red: 0.88,
            green: 0.98,
            blue: 0.78
        )

        static let green200 = Color(
            red: 0.77,
            green: 0.95,
            blue: 0.59
        )

        static let green300 = Color(
            red: 0.67,
            green: 0.92,
            blue: 0.42
        )

        static let green400 = Color(
            red: 0.58,
            green: 0.91,
            blue: 0.28
        )

        static let green500 = Color(
            red: 0.54,
            green: 0.91,
            blue: 0.25
        )

        static let green600 = Color(
            red: 0.47,
            green: 0.82,
            blue: 0.20
        )

        static let green700 = Color(
            red: 0.38,
            green: 0.69,
            blue: 0.16
        )

        static let green800 = Color(
            red: 0.30,
            green: 0.56,
            blue: 0.13
        )

        static let green900 = Color(
            red: 0.20,
            green: 0.40,
            blue: 0.09
        )

        // MARK: Blue

        static let blue500 = Color(
            red: 0.40,
            green: 0.65,
            blue: 0.90
        )

        static let blue900 = Color(
            red: 0.13,
            green: 0.26,
            blue: 0.38
        )

        // MARK: Red

        static let red500 = Color(
            red: 0.95,
            green: 0.39,
            blue: 0.40
        )

        static let red900 = Color(
            red: 0.34,
            green: 0.14,
            blue: 0.14
        )

        // MARK: Yellow

        static let yellow500 = Color(
            red: 0.96,
            green: 0.78,
            blue: 0.35
        )

        static let yellow900 = Color(
            red: 0.31,
            green: 0.25,
            blue: 0.10
        )

        // MARK: Alpha

        static let alphaBlack60 = Color.black.opacity(0.60)

        static let alphaGreen10 = green500.opacity(0.10)

        static let alphaGreen16 = green500.opacity(0.16)

        static let alphaTransparent = Color.clear

        static let alphaWhite05 = Color.white.opacity(0.05)

        static let alphaWhite08 = Color.white.opacity(0.08)

        static let alphaWhite12 = Color.white.opacity(0.12)
    }

    // MARK: - Semantic Colors
    //
    // Figma:
    // 03 Semantic Colors

    enum Background {

        static let base = Primitive.neutral950

        static let elevated = Primitive.neutral700

        static let green = Primitive.green900

        static let greenSoft = Primitive.alphaGreen10

        static let primary = Primitive.neutral900

        static let secondary = Primitive.neutral850

        static let tertiary = Primitive.neutral800

        static let transparent = Primitive.alphaTransparent
    }

    enum Border {

        static let `default` = Primitive.neutral700

        static let strong = Primitive.neutral500

        static let subtle = Primitive.neutral800

        static let transparent = Primitive.alphaTransparent
    }

    enum Divider {

        static let `default` = Primitive.neutral700
    }

    enum Focus {

        static let ring = Primitive.green300
    }

    enum Icon {

        static let accent = Primitive.green500

        static let disabled = Primitive.neutral500

        static let onGreen = Primitive.neutral950

        static let primary = Primitive.neutral200

        static let secondary = Primitive.neutral400

        static let strong = Primitive.neutral50
    }

    enum Primary {

        static let container = Primitive.green900

        static let `default` = Primitive.green400

        static let disabled = Primitive.green800

        static let pressed = Primitive.green600
    }

    enum State {

        static let greenPressed = Primitive.green900

        static let overlay = Primitive.alphaBlack60

        static let pressed = Primitive.neutral700

        static let selected = Primitive.neutral600
    }

    enum Status {

        static let error = Primitive.red500

        static let errorBackground = Primitive.red900

        static let info = Primitive.blue500

        static let infoBackground = Primitive.blue900

        static let success = Primitive.green400

        static let successBackground = Primitive.green900

        static let warning = Primitive.yellow500

        static let warningBackground = Primitive.yellow900
    }

    enum Text {

        static let accent = Primitive.green400

        static let disabled = Primitive.neutral500

        static let inverse = Primitive.neutral950

        static let onGreen = Primitive.neutral950

        static let primary = Primitive.neutral200

        static let secondary = Primitive.neutral300

        static let strong = Primitive.neutral50

        static let tertiary = Primitive.neutral400
    }

    // MARK: - Component Colors
    //
    // Figma:
    // 04 Component Colors

    enum Button {

        enum FilledAccent {

            static let backgroundDefault = Primary.default

            static let backgroundDisabled = Primitive.neutral800

            static let backgroundPressed = Primary.pressed

            static let contentDefault = Text.onGreen

            static let contentDisabled = Text.disabled

            static let contentPressed = Text.onGreen
        }

        enum FilledNeutral {

            static let backgroundDefault = Primitive.neutral700

            static let backgroundDisabled = Primitive.neutral850

            static let backgroundPressed = Primitive.neutral600

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

        static let backgroundDefault = Background.secondary

        static let backgroundDisabled = Background.primary

        static let backgroundPressed = State.pressed

        static let backgroundSelected = Primary.container

        static let borderDefault = Border.default

        static let borderDisabled = Border.subtle

        static let borderPressed = Border.strong

        static let borderSelected = Primary.default

        static let contentDefault = Text.primary

        static let contentDisabled = Text.disabled

        static let contentPressed = Text.strong

        static let contentSelected = Text.accent
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

        static let borderFocus = Focus.ring

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

        static let placeholderDefault = Text.tertiary

        static let placeholderDisabled = Text.disabled

        static let placeholderError = Text.tertiary

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
    // 기존 화면들이 한 번에 깨지지 않도록 유지한다.
    // 신규 코드에서는 위 Semantic / Component Token 사용을 우선한다.

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
