//
// MARK: - 파일 가이드
// 파일: Features/Record/Components/RecordBucketListView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
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
        let savedItems = bucketStore.activities.map { activity in
            BucketItem(
                title: activity.title,
                savedBy: "내가 저장했어요!",
                owner: .daughter,
                isCompleted: false,
                invitation: nil
            )
        }
        let combined = savedItems + items
        guard selectedFilter != .all else { return combined }
        return combined.filter { $0.owner == selectedFilter }
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



                    bucketList

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
