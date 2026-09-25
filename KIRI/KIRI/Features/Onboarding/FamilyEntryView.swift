
import SwiftUI

struct FamilyEntryView: View {
    let onBack: () -> Void
    let onCreateFamily: () -> Void
    let onEnterFamilyCode: () -> Void
    let onBrowse: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 0) {
                Text("지금 바로 가족공간을\n만들어봐요!")
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.textPrimary)
                    .lineSpacing(7)

                Text("관심가지고 있는 분야에 대해 알려주세요!")
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(KIRIColor.textSecondary)
                    .padding(.top, 12)

                VStack(spacing: 14) {
                    entryCard(
                        title: "가족공간 만들러 가기",
                        subtitle: "지금 바로 가족들을 초대해주세요!",
                        action: onCreateFamily
                    )

                    entryCard(
                        title: "가족코드 입력하기",
                        subtitle: "전달받은 가족코드를 입력해주세요!",
                        action: onEnterFamilyCode
                    )

                    entryCard(
                        title: "먼저 둘러보러가기",
                        subtitle: "할 수 있는 미션을 먼저 살펴봐요!",
                        action: onBrowse
                    )
                }
                .padding(.horizontal, 17)
                .padding(.top, 55)

                Spacer()
            }
            .padding(.horizontal, KIRISpacing.horizontal)
        }
        .background(KIRIColor.background)
    }

    private var header: some View {
        HStack {
            KIRIBackButton(action: onBack)

            Spacer()
        }
        .padding(.horizontal, 4)
        .frame(height: 70)
    }

    private func entryCard(
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(KIRIColor.background)
                        .frame(width: 52, height: 52)

                    Image(systemName: "envelope.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(KIRIColor.textSecondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(KIRITypography.bodyMedium)
                        .foregroundStyle(KIRIColor.textPrimary)

                    Text(subtitle)
                        .font(KIRITypography.caption)
                        .foregroundStyle(KIRIColor.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(KIRIColor.textPrimary)
            }
            .padding(.horizontal, 20)
            .frame(height: 88)
            .background(KIRIColor.surface)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: KIRIRadius.large
                )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FamilyEntryView(
        onBack: {},
        onCreateFamily: {},
        onEnterFamilyCode: {},
        onBrowse: {}
    )
    .background(KIRIColor.background)
}
