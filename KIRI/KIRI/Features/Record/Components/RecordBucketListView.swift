//
// MARK: - 파일 가이드
// 담당 화면: 기록탭 버킷리스트. 가족 필터와 서버 목록의 로딩·빈 상태·오류를 관리합니다.
// UI 수정 위치: filterSection spacing, bucketCard(_:) padding/반경, 빈 상태 문구.
// API: GET /api/v1/bucket-items, DELETE /api/v1/bucket-items/{bucketItemId}.
// Figma: 기록탭 9898:18872의 버킷리스트 화면.
//
import SwiftUI



struct RecordBucketListView: View {



    struct InvitationData: Identifiable, Equatable {

        let id = UUID()



        let title: String

        let dateTime: String

        let participants: String

        let description: String

        let familyMessage: String

    }



    private enum FamilyFilter: String, CaseIterable, Hashable {

        case all = "전체"

        case mom = "엄마 1"

        case dad = "아빠 2"

        case daughter = "딸 1"

        case son = "아들 1"

    }



    private struct BucketItem: Identifiable {

        let id = UUID()



        let title: String

        let savedBy: String

        let owner: FamilyFilter

        let isCompleted: Bool

        let invitation: InvitationData?

    }



    let showsInvitationSentBanner: Bool

    let onSelectInvitation: (InvitationData) -> Void



    @ObservedObject private var bucketStore = MissionBucketStore.shared
    @State private var selectedFilter: FamilyFilter = .all
    @State private var serverItems: [BucketItemResult] = []
    @State private var isLoading = false
    @State private var loadError: String?



    init(

        showsInvitationSentBanner: Bool = false,

        onSelectInvitation: @escaping (InvitationData) -> Void = { _ in }

    ) {

        self.showsInvitationSentBanner = showsInvitationSentBanner

        self.onSelectInvitation = onSelectInvitation

    }



    private let items: [BucketItem] = [

        BucketItem(

            title: "광장시장에서 시장음식 먹어보기",

            savedBy: "아빠가 저장했어요!",

            owner: .dad,

            isCompleted: true,

            invitation: nil

        ),

        BucketItem(

            title: "실리카겔 콘서트 관람하기",

            savedBy: "아빠가 저장했어요!",

            owner: .dad,

            isCompleted: false,

            invitation: InvitationData(

                title: "한강 뚜벅뚜벅 축제",

                dateTime: "26.10.07·16:30분",

                participants: "엄마, 아빠, 나",

                description: """

                2026 한강 뚜벅뚜벅 축제는 잠수교를 보행교로 전환해 시민이 직접 걸으며 공연·체험·미식 등 다양한 문화·여가 프로그램을 즐기는 서울 대표 한강 축제입니다.

                """,

                familyMessage: "엄마, 아빠 나 여기 가고싶은데 우리 10월 초에 갈래요??"

            )

        ),

        BucketItem(

            title: "실리카겔 콘서트 관람하기",

            savedBy: "아빠가 저장했어요!",

            owner: .dad,

            isCompleted: false,

            invitation: InvitationData(

                title: "한강 뚜벅뚜벅 축제",

                dateTime: "26.10.07·16:30분",

                participants: "엄마, 아빠, 나",

                description: """

                2026 한강 뚜벅뚜벅 축제는 잠수교를 보행교로 전환해 시민이 직접 걸으며 공연·체험·미식 등 다양한 문화·여가 프로그램을 즐기는 서울 대표 한강 축제입니다.

                """,

                familyMessage: "엄마, 아빠 나 여기 가고싶은데 우리 10월 초에 갈래요??"

            )

        )

    ]



    private var filteredItems: [BucketItem] {
        let mapped = serverItems.map { item in
            BucketItem(title: item.mission.title,
                       savedBy: "\(item.saver.nickname)이 저장했어요!",
                       owner: familyFilter(for: item.saver.familyRole),
                       isCompleted: item.status == "COMPLETED",
                       invitation: nil)
        }
        guard selectedFilter != .all else { return mapped }
        return mapped.filter { $0.owner == selectedFilter }
    }

    private func familyFilter(for role: String?) -> FamilyFilter {
        switch role {
        case "MOTHER": return .mom
        case "FATHER": return .dad
        case "SON": return .son
        default: return .daughter
        }
    }

    var body: some View {

        ZStack(alignment: .top) {

            ScrollView(

                .vertical,

                showsIndicators: false

            ) {

                VStack(spacing: 0) {

                    filterSection

                        .padding(.top, 32)



                    Group {
                        if isLoading {
                            ProgressView().frame(maxWidth: .infinity).padding(.top, 48)
                        } else if let loadError {
                            VStack(spacing: 12) {
                                Text(loadError).font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.secondary)
                                Button("다시 시도") { Task { await loadBuckets() } }
                            }.frame(maxWidth: .infinity).padding(.top, 48)
                        } else if filteredItems.isEmpty {
                            Text("저장한 버킷리스트가 없어요.").font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.secondary).frame(maxWidth: .infinity).padding(.top, 48)
                        } else { bucketList }
                    }
                    .padding(.top, 29)



                    Color.clear

                        .frame(height: 110)

                }

            }



            if showsInvitationSentBanner {

                invitationSentBanner

                    .padding(.horizontal, 18)

                    .padding(.top, 21)

                    .transition(

                        .move(edge: .top)

                            .combined(with: .opacity)

                    )

                    .zIndex(10)

            }

        }
        .task { await loadBuckets() }

    }



    private func loadBuckets() async {
        guard !isLoading else { return }
        isLoading = true
        loadError = nil
        do {
            serverItems = try await AuthService.shared.bucketItems().bucketItems
        } catch {
            serverItems = []
            loadError = "버킷리스트를 불러오지 못했어요."
            #if DEBUG
            print("[KIRI][Record] bucket load failed: \(error)")
            #endif
        }
        isLoading = false
    }

    // MARK: - Invitation Sent Banner



    private var invitationSentBanner: some View {

        HStack(spacing: 12) {

            Image(systemName: "paperplane.fill")

                .font(.system(size: 18, weight: .medium))

                .foregroundStyle(KIRIColor.Icon.primary)

                .frame(width: 24, height: 24)



            Text("초대를 발송했습니다!")

                .font(KIRITypography.headingSmall)

                .tracking(-0.72)

                .foregroundStyle(KIRIColor.Text.strong)



            Spacer(minLength: 0)

        }

        .padding(.horizontal, 16)

        .frame(height: 59)

        .background(KIRIColor.Background.tertiary)

        .clipShape(

            RoundedRectangle(

                cornerRadius: 12

            )

        )

    }



    // MARK: - Filter



    private var filterSection: some View {

        ScrollView(

            .horizontal,

            showsIndicators: false

        ) {

            HStack(spacing: 8) {

                ForEach(

                    FamilyFilter.allCases,

                    id: \.self

                ) { filter in

                    KIRIChip(

                        title: filter.rawValue,

                        isSelected: selectedFilter == filter

                    ) {

                        withAnimation(

                            .easeOut(duration: 0.15)

                        ) {

                            selectedFilter = filter

                        }

                    }

                }

            }

            .padding(.horizontal, 18)

        }

    }



    // MARK: - List



    private var bucketList: some View {

        LazyVStack(spacing: 18) {

            ForEach(filteredItems) { item in

                bucketCard(item)

            }

        }

        .padding(.horizontal, 18)

    }



    // MARK: - Card



    private func bucketCard(

        _ item: BucketItem

    ) -> some View {

        Button {

            guard !item.isCompleted else {

                return

            }



            guard let invitation = item.invitation else {

                return

            }



            onSelectInvitation(invitation)

        } label: {

            VStack(

                alignment: .leading,

                spacing: 8

            ) {

                HStack(spacing: 10) {

                    if item.isCompleted {

                        tag(

                            title: "종료된 일정",

                            isAccent: false

                        )

                    }



                    tag(

                        title: item.savedBy,

                        isAccent: false

                    )

                }



                Text(item.title)

                    .font(KIRITypography.headingMedium)

                    .tracking(-0.8)

                    .foregroundStyle(KIRIColor.Text.strong)

                    .lineLimit(1)

                    .frame(

                        maxWidth: .infinity,

                        alignment: .leading

                    )

            }

            .padding(.horizontal, 18)

            .padding(.vertical, 16)

            .frame(

                maxWidth: .infinity,

                alignment: .leading

            )

            .background(

                KIRIColor.Background.tertiary

            )

            .clipShape(

                RoundedRectangle(

                    cornerRadius: 16

                )

            )

        }

        .buttonStyle(.plain)

    }



    // MARK: - Tag



    private func tag(

        title: String,

        isAccent: Bool

    ) -> some View {

        Text(title)

            .font(KIRITypography.bodySmallMedium)

            .tracking(-0.56)

            .foregroundStyle(

                isAccent

                    ? KIRIColor.Text.accent

                    : KIRIColor.Text.secondary

            )

            .padding(.horizontal, 8)

            .padding(.vertical, 6)

            .background(

                isAccent

                    ? KIRIColor.Background.greenSoft

                    : KIRIColor.Background.elevated

            )

            .clipShape(

                RoundedRectangle(

                    cornerRadius: 5

                )

            )

    }

}



#Preview {
    
    ZStack {
        
        KIRIColor.Background.base
        
            .ignoresSafeArea()
        
        
        
        RecordBucketListView(
            
            showsInvitationSentBanner: true
            
        )
        
    }
    
}
