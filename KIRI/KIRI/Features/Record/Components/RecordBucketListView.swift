
import SwiftUI

struct RecordBucketListView: View {

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
    }

    @State private var selectedFilter: FamilyFilter = .all

    private let items: [BucketItem] = [
        BucketItem(
            title: "광장시장에서 시장음식 먹어보기",
            savedBy: "아빠가 저장했어요!",
            owner: .dad,
            isCompleted: true
        ),
        BucketItem(
            title: "광장시장에서 시장음식 먹어보기",
            savedBy: "아빠가 저장했어요!",
            owner: .dad,
            isCompleted: false
        ),
        BucketItem(
            title: "광장시장에서 시장음식 먹어보기",
            savedBy: "아빠가 저장했어요!",
            owner: .dad,
            isCompleted: false
        )
    ]

    private var filteredItems: [BucketItem] {
        guard selectedFilter != .all else {
            return items
        }

        return items.filter {
            $0.owner == selectedFilter
        }
    }

    var body: some View {
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
            // TODO: 버킷 상세 / 일정 잡기 연결
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

        RecordBucketListView()
    }
}
