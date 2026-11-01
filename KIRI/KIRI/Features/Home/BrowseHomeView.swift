import SwiftUI

/// 둘러보기 전용 홈.
/// 가족공간에 연결되지 않은 사용자는 공개 장소 추천만 볼 수 있다.
struct BrowseHomeView: View {
    let familyState: AppRouter.FamilyState
    let onFamilyCreated: (String, String) -> Void
    let onRetryFamilyState: () -> Void
    private let places = [
        BrowsePlace(imageName: "browse_place_a", title: "경복궁에서 사진찍기", location: "경복궁 종로구"),
        BrowsePlace(imageName: "browse_place_b", title: "경복궁에서 사진찍기", location: "경복궁 종로구")
    ]

    @State private var isFamilyCreationPresented = false

    init(
        familyState: AppRouter.FamilyState = .noFamily,
        onFamilyCreated: @escaping (String, String) -> Void,
        onRetryFamilyState: @escaping () -> Void = {}
    ) {
        self.familyState = familyState
        self.onFamilyCreated = onFamilyCreated
        self.onRetryFamilyState = onRetryFamilyState
    }

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        familyStateCard
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

    @ViewBuilder
    private var familyStateCard: some View {
        switch familyState {
        case .noFamily:
            familyActionCard
        case .loading:
            familyStatusCard(title: "가족공간을 확인하고 있어요", actionTitle: nil, action: {})
        case .unknown:
            familyStatusCard(title: "가족공간 정보를 확인하지 못했어요", actionTitle: "다시 시도", action: onRetryFamilyState)
        case .hasFamily:
            familyStatusCard(title: "가족공간 정보를 불러오고 있어요", actionTitle: nil, action: {})
        }
    }

    private func familyStatusCard(
        title: String,
        actionTitle: String?,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(KIRITypography.headingSmall)
                .foregroundStyle(KIRIColor.Text.strong)
            if let actionTitle {
                Button(actionTitle, action: action)
                    .font(KIRITypography.caption)
                    .foregroundStyle(KIRIColor.Primary.default)
            }
        }
        .padding(.horizontal, 18)
        .frame(width: 354, height: 96, alignment: .leading)
        .background(KIRIColor.Background.primary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
    @State private var errorMessage: String?

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
        .alert("가족공간을 만들 수 없어요", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) { Button("확인", role: .cancel) {} } message: {
            Text(errorMessage ?? "잠시 후 다시 시도해주세요.")
        }
        .preferredColorScheme(.dark)
    }

    private func createFamilyCode() {
        Task { @MainActor in
            do {
                let result = try await AuthService.shared.createFamily(name: familyName)
                familyCode = result.inviteCode
                AppSessionStore().saveFamily(
                    name: result.name,
                    inviteCode: result.inviteCode,
                    familyId: result.familyId
                )
                step = .code
            } catch {
                errorMessage = error.localizedDescription
                step = .familyName
            }
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
    BrowseHomeView(onFamilyCreated: { _, _ in }, onRetryFamilyState: {})
}
