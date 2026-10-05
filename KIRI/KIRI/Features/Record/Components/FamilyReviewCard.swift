
import SwiftUI

struct FamilyReviewCard: View {

    let nickname: String
    let review: String
    let likeCount: Int
    let isLiked: Bool

    var onLike: () -> Void = {}

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            userHeader

            reviewContent

            likeButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 23)
        .frame(
            maxWidth: .infinity,
            minHeight: 398,
            alignment: .topLeading
        )
        .background(
            KIRIColor.Background.secondary
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    // MARK: - User

    private var userHeader: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(KIRIColor.Background.elevated)
                .frame(
                    width: 36,
                    height: 36
                )

            Text(nickname)
                .font(KIRITypography.body)
                .tracking(-0.64)
                .foregroundStyle(KIRIColor.Text.primary)
        }
    }

    // MARK: - Review

    private var reviewContent: some View {
        VStack(
            alignment: .leading,
            spacing: 18
        ) {
            reviewImage

            Text(review)
                .font(KIRITypography.body)
                .tracking(-0.64)
                .foregroundStyle(KIRIColor.Text.primary)
                .lineSpacing(4)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
    }

    private var reviewImage: some View {
        ZStack {
            KIRIColor.Background.elevated

            Image(systemName: "photo")
                .font(
                    .system(
                        size: 25,
                        weight: .regular
                    )
                )
                .foregroundStyle(KIRIColor.Icon.disabled)
        }
        .frame(
            maxWidth: .infinity
        )
        .frame(height: 185)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 4
            )
        )
    }

    // MARK: - Like

    private var likeButton: some View {
        Button {
            onLike()
        } label: {
            HStack(spacing: 4) {
                Image(
                    systemName: isLiked
                        ? "heart.fill"
                        : "heart"
                )
                .font(
                    .system(
                        size: 22,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    isLiked
                        ? KIRIColor.Primary.default
                        : KIRIColor.Icon.secondary
                )

                Text("\(likeCount)")
                    .font(KIRITypography.body)
                    .tracking(-0.64)
                    .foregroundStyle(
                        KIRIColor.Text.secondary
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            isLiked
                ? "좋아요 취소"
                : "좋아요"
        )
    }
}

#Preview {
    ZStack {
        KIRIColor.Background.base
            .ignoresSafeArea()

        FamilyReviewCard(
            nickname: "USER)@#@#@",
            review: "아빠가 자주 가는 식당에 처음 가봤다. 좋아하는 메뉴를 같이 먹으니 아빠를 조금 더 알게 된 기분이었다.",
            likeCount: 10,
            isLiked: true
        )
        .padding(.horizontal, 18)
    }
}
