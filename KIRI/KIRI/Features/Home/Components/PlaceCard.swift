import SwiftUI

struct PlaceCard: View {
    let title: String
    let location: String
    let rating: Double?
    let description: String
    var imageName: String? = nil
    var imageURL: URL? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imagePlaceholder

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(KIRITypography.headingSmall)
                            .foregroundStyle(KIRIColor.Text.strong)
                            .lineLimit(1)

                        Spacer()

                        if let rating {
                            HStack(spacing: 4) {
                                Image("browse_rating_star")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 12, height: 12)

                                Text(rating.formatted(.number.precision(.fractionLength(1))))
                                    .font(KIRITypography.captionMedium)
                            }
                            .foregroundStyle(KIRIColor.Text.tertiary)
                            .padding(.horizontal, 6)
                            .frame(height: 25)
                            .background(KIRIColor.Background.tertiary)
                            .clipShape(Capsule())
                        }
                    }

                    Text(location)
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Text.secondary)
                }

                HStack(alignment: .top, spacing: 5) {
                    Image("browse_quote")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)

                    Text(description)
                        .font(KIRITypography.caption)
                        .lineSpacing(2)
                        .lineLimit(2)
                }
                .foregroundStyle(KIRIColor.Text.tertiary)
            }
            .padding(.horizontal, 19)
            .padding(.top, 18)
            .padding(.bottom, 16)
        }
        .frame(width: 251, height: 284)
        .background(KIRIColor.Background.primary)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    private var imagePlaceholder: some View {
        ZStack {
            KIRIContentImage(imageURL: imageURL, mockAssetName: imageName) {
                Rectangle().fill(KIRIColor.Background.tertiary)
            }
        }
        .frame(height: 144)
        .clipped()
    }
}

#Preview {
    PlaceCard(
        title: "경복궁에서 사진찍기",
        location: "경복궁 종로구",
        rating: 4.6,
        description: "대중교통이 편리하고, 부모님이랑 가기 좋아요! 추천합니다."
    )
    .padding()
    .background(KIRIColor.background)
}
