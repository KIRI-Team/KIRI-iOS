
import SwiftUI

struct FamilyHomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                todayQuestionSection

                familySection

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
            Text("오늘도 가족과\n조금 더 가까워져볼까요?")
                .font(KIRITypography.title)
                .foregroundStyle(KIRIColor.textPrimary)
                .lineSpacing(7)

            Text("우리 가족의 오늘을 확인해보세요.")
                .font(KIRITypography.subtitle)
                .foregroundStyle(KIRIColor.textSecondary)
        }
    }

    private var todayQuestionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("오늘의 질문")
                .font(KIRITypography.bodyMedium)
                .foregroundStyle(KIRIColor.textPrimary)

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("TODAY")
                        .font(KIRITypography.caption)
                        .foregroundStyle(KIRIColor.textSecondary)

                    Text("요즘 가장 같이 해보고 싶은 일이 있나요?")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(KIRIColor.textPrimary)
                        .lineSpacing(5)
                }

                HStack {
                    Text("아직 답변하지 않았어요")
                        .font(KIRITypography.caption)
                        .foregroundStyle(KIRIColor.textSecondary)

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
    }

    private var familySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("우리 가족")
                .font(KIRITypography.bodyMedium)
                .foregroundStyle(KIRIColor.textPrimary)

            HStack(spacing: 14) {
                familyMember(
                    name: "나",
                    role: "아들"
                )

                familyMember(
                    name: "엄마",
                    role: "엄마"
                )

                familyMember(
                    name: "아빠",
                    role: "아빠"
                )
            }
        }
    }

    private func familyMember(
        name: String,
        role: String
    ) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(KIRIColor.surface)
                    .frame(width: 54, height: 54)

                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(KIRIColor.textSecondary)
            }

            VStack(spacing: 3) {
                Text(name)
                    .font(KIRITypography.bodyMedium)
                    .foregroundStyle(KIRIColor.textPrimary)

                Text(role)
                    .font(KIRITypography.caption)
                    .foregroundStyle(KIRIColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    FamilyHomeView()
}
