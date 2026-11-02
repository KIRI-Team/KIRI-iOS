//
// MARK: - 파일 가이드
// 파일: Features/Record/Components/FamilyReviewCard.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//


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
