
import SwiftUI

struct BrowseHomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                familyEntryCard

                previewSection

                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, KIRISpacing.horizontal)
            .padding(.top, 20)
        }
        .background(KIRIColor.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("KIRI를\n먼저 둘러보세요.")
                .font(KIRITypography.title)
                .foregroundStyle(KIRIColor.textPrimary)
                .lineSpacing(7)

            Text("가족공간에 참여하면 함께 질문하고 기록할 수 있어요.")
                .font(KIRITypography.subtitle)
                .foregroundStyle(KIRIColor.textSecondary)
        }
    }

    private var familyEntryCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            ZStack {
                Circle()
                    .fill(KIRIColor.background)
                    .frame(width: 52, height: 52)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(KIRIColor.textPrimary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("가족과 함께 시작해보세요")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(KIRIColor.textPrimary)

                Text("가족공간을 만들거나 초대받은 가족공간에 참여할 수 있어요.")
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(KIRIColor.textSecondary)
                    .lineSpacing(4)
            }

            HStack {
                Text("가족공간 시작하기")
                    .font(KIRITypography.bodyMedium)
                    .foregroundStyle(KIRIColor.textPrimary)

                Spacer()

                Image(systemName: "arrow.right")
                    .foregroundStyle(KIRIColor.textPrimary)
            }
        }
        .padding(22)
        .background(KIRIColor.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: KIRIRadius.xLarge
            )
        )
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("KIRI에서는")
                .font(KIRITypography.bodyMedium)
                .foregroundStyle(KIRIColor.textPrimary)

            VStack(spacing: 12) {
                previewRow(
                    icon: "questionmark.bubble.fill",
                    title: "서로를 알아가는 질문",
                    description: "매일 하나의 질문으로 가족의 생각을 알아가요."
                )

                previewRow(
                    icon: "sparkles",
                    title: "함께하는 미션",
                    description: "가족과 같이 해볼 활동을 발견해요."
                )

                previewRow(
                    icon: "calendar",
                    title: "우리 가족의 기록",
                    description: "함께한 시간을 가족 캘린더에 남겨요."
                )
            }
        }
    }

    private func previewRow(
        icon: String,
        title: String,
        description: String
    ) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: KIRIRadius.large
                )
                .fill(KIRIColor.surface)
                .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 19))
                    .foregroundStyle(KIRIColor.textPrimary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(KIRITypography.bodyMedium)
                    .foregroundStyle(KIRIColor.textPrimary)

                Text(description)
                    .font(KIRITypography.caption)
                    .foregroundStyle(KIRIColor.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
    }
}

#Preview {
    BrowseHomeView()
}
