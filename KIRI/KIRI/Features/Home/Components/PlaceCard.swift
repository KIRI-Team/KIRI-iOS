import SwiftUI

struct PlaceCard: View {
    let title: String
    let location: String
    let rating: Double
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imagePlaceholder

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(KIRIColor.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))

                        Text(
                            rating.formatted(
                                .number.precision(
                                    .fractionLength(1)
                                )
                            )
                        )
                        .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(KIRIColor.textPrimary)
                    .padding(.horizontal, 8)
                    .frame(height: 24)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
                }

                Text(location)
                    .font(.system(size: 12))
                    .foregroundStyle(KIRIColor.textSecondary)

                HStack(alignment: .top, spacing: 5) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 10))

                    Text(description)
                        .font(.system(size: 11))
                        .lineSpacing(3)
                        .lineLimit(2)
                }
                .foregroundStyle(KIRIColor.textSecondary)
            }
            .padding(16)
        }
        .frame(width: 250)
        .background(KIRIColor.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14
            )
        )
    }

    private var imagePlaceholder: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.08))

            Image(systemName: "photo")
                .font(.system(size: 30))
                .foregroundStyle(KIRIColor.textSecondary)
        }
        .frame(height: 160)
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
