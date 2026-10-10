import SwiftUI

/// 둘러보기 전용 홈.
/// 가족공간에 연결되지 않은 사용자는 공개 장소 추천만 볼 수 있다.
struct BrowseHomeView: View {
    let onFamilyCreated: (String, String) -> Void
    private let places = [
        BrowsePlace(imageName: "browse_place_a", title: "경복궁에서 사진찍기", location: "경복궁 종로구"),
        BrowsePlace(imageName: "browse_place_b", title: "경복궁에서 사진찍기", location: "경복궁 종로구")
    ]

    @State private var isFamilyCreationPresented = false

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        familyActionCard
                            .padding(.top, 18)

                        recommendationSection(title: "엄마와 함께라면 여기!")
                            .padding(.top, 36)

                        recommendationSection(title: "오늘 가을분위기를 느끼고 싶다면")
                            .padding(.top, 36)

                        Spacer()
                            .frame(height: 140)
                    }
                    .padding(.leading, 18)
                }
            }
            .fullScreenCover(isPresented: $isFamilyCreationPresented) {
                BrowseFamilyCreationFlow(
                    onDismiss: { isFamilyCreationPresented = false },
                    onFamilyCreated: onFamilyCreated
                )
            }
        }
    }

    private var navigationBar: some View {
        Text("끼리네 가족")
            .font(KIRITypography.headingSmall)
            .tracking(-0.72)
            .foregroundStyle(KIRIColor.Text.strong)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
    }

    private var familyActionCard: some View {
        Button {
            isFamilyCreationPresented = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    KIRIColor.Background.secondary

                    Image("browse_action_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("아직 가족 공간이 없군요!")
                        .font(KIRITypography.caption)
                        .foregroundStyle(KIRIColor.Text.tertiary)

                    Text("가족공간 만들러 가기")
                        .font(KIRITypography.headingSmall)
                        .foregroundStyle(KIRIColor.Text.strong)
                }

                Spacer()

                Image("browse_arrow")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 18)
            .frame(width: 354, height: 96)
            .background(KIRIColor.Background.primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("가족공간 만들러 가기")
    }

    private func recommendationSection(title: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(KIRIColor.Text.strong)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(places) { place in
                        PlaceCard(
                            title: place.title,
                            location: place.location,
                            rating: 4.6,
                            description: "대중교통이 편리하고, 부모님이랑 가기 좋아요! 추천합니다",
                            imageName: place.imageName
                        )
                    }
                }
                .padding(.trailing, 18)
            }
        }
    }
}

private struct BrowseFamilyCreationFlow: View {
    private enum Step {
        case entry
        case familyName
        case loading
        case code
    }

    @State private var step: Step = .entry
    @State private var familyName = ""
    @State private var familyCode = ""

    let onDismiss: () -> Void
    let onFamilyCreated: (String, String) -> Void

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            switch step {
            case .entry:
                FamilyEntryView(
                    mode: .creationOnly,
                    onBack: onDismiss,
                    onCreateFamily: {
                        step = .familyName
                    },
                    onEnterFamilyCode: {},
                    onBrowse: {}
                )

            case .familyName:
                FamilyNameView(
                    familyName: $familyName,
                    onBack: {
                        step = .entry
                    },
                    onNext: {
                        step = .loading
                        createFamilyCode()
                    }
                )

            case .loading:
                FamilyCodeLoadingView()

            case .code:
                FamilyCodeView(
                    familyName: familyName,
                    familyCode: familyCode,
                    onBack: {
                        step = .familyName
                    },
                    onComplete: { onFamilyCreated(familyName, familyCode) }
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    private func createFamilyCode() {
        // 서버 연동 전에는 Figma 플로우를 확인할 수 있는 로컬 코드만 사용한다.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            familyCode = "NWTKYJ"
            step = .code
        }
    }
}

private struct BrowsePlace: Identifiable {
    let imageName: String
    let title: String
    let location: String

    var id: String { imageName }
}

#Preview {
    BrowseHomeView(onFamilyCreated: { _, _ in })
}
