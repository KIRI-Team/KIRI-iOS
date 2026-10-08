
import SwiftUI

struct ActivityReviewCompleteView: View {

    let schedule: RecordCalendarView.ScheduleDetailData
    let review: ActivityReviewWriteView.Draft
    let onBack: () -> Void
    let onEdit: () -> Void

    var userName: String = "김주연"
    var familyRole: String = "나"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            reviewSection

            familySection
                .padding(.top, 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - My Review

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("끼리네가족 님의 한 줄")
                .font(KIRITypography.headingSmall)
                .foregroundStyle(KIRIColor.Text.strong)

            reviewCard
        }
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: 19) {
            HStack(spacing: 14) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(KIRIColor.Text.secondary)

                Text("\(userName) | \(familyRole)")
                    .font(KIRITypography.body)
                    .foregroundStyle(KIRIColor.Text.primary)

                Spacer()

                Button(action: onEdit) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 20))

                        Text("수정하기")
                            .font(KIRITypography.bodySmall)
                    }
                    .foregroundStyle(KIRIColor.Text.secondary)
                }
                .buttonStyle(.plain)
            }

            photoContent

            Text(review.comment)
                .font(KIRITypography.body)
                .foregroundStyle(KIRIColor.Text.primary)
                .fixedSize(horizontal: false, vertical: true)

            reviewMetadata
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KIRIColor.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Photos

    @ViewBuilder
    private var photoContent: some View {
        if let firstImage = review.images.first {
            Image(uiImage: firstImage)
                .resizable()
                .scaledToFill()
                .frame(height: 185)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if review.images.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(
                            1..<review.images.count,
                            id: \.self
                        ) { index in
                            Image(uiImage: review.images[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 88, height: 88)
                                .clipped()
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 8)
                                )
                        }
                    }
                }
            }
        } else {
            Text("등록된 사진이 없어요.")
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 185)
                .background(KIRIColor.Background.tertiary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Metadata

    private var reviewMetadata: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { value in
                    Image(
                        systemName: value <= review.rating
                            ? "star.fill"
                            : "star"
                    )
                    .font(.system(size: 17))
                    .foregroundStyle(
                        value <= review.rating
                            ? KIRIColor.Primary.default
                            : KIRIColor.Text.tertiary
                    )
                }
            }

            HStack(spacing: 8) {
                Text("다시 참여하고 싶나요?")

                Text(review.wantsToRepeat ? "예" : "아니오")
                    .foregroundStyle(KIRIColor.Primary.default)
            }
            .font(KIRITypography.bodySmall)
            .foregroundStyle(KIRIColor.Text.secondary)
        }
    }

    // MARK: - Family Reviews

    private var familySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("다른 가족의 기록")
                .font(KIRITypography.headingSmall)
                .foregroundStyle(KIRIColor.Text.strong)

            VStack(spacing: 12) {
                Image(systemName: "person.2")
                    .font(.system(size: 28))
                    .foregroundStyle(KIRIColor.Text.tertiary)

                Text("아직 다른 가족이 남긴 기록이 없어요.")
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 150)
            .background(KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
