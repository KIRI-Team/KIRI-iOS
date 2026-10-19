import SwiftUI
struct MissionView: View {
    private enum Category: String, CaseIterable, Hashable {
        case all = "전체"
        case exhibition = "전시·문화"
        case popup = "팝업·행사"
        case experience = "체험·놀거리"
        case outdoor = "산책·야외"
        case performance = "공연"
        case food = "맛집·카페"
    }
    private struct PlaceItem: Identifiable {
        let id = UUID()
        let title: String
        let placeName: String
        let district: String
        let rating: Double?
        let tags: [String]
        let isRecommended: Bool
        let category: Category
        let mockAssetName: String?
        let imageURL: URL?
        var isBookmarked: Bool
    }
    @StateObject private var bucketStore = MissionBucketStore.shared
    @State private var selectedPlace: PlaceItem?

    @State private var searchText = ""
    @State private var selectedCategory: Category = .all
    @State private var places: [PlaceItem] = [
        PlaceItem(
            title: "광장시장에서 시장음식 먹어보기",
            placeName: "광장시장",
            district: "종로구",
            rating: nil,
            tags: [
                "혼잡도 높음"
            ],
            isRecommended: true,
            category: .food,
            mockAssetName: "mission_gyeongbok",
            imageURL: nil,
            isBookmarked: true
        ),
        PlaceItem(
            title: "광장시장에서 시장음식 먹어보기",
            placeName: "광장시장",
            district: "종로구",
            rating: 4.6,
            tags: [
                "대중교통 편리",
                "혼잡도 높음"
            ],
            isRecommended: false,
            category: .food,
            mockAssetName: "mission_namsan",
            imageURL: nil,
            isBookmarked: true
        ),
        PlaceItem(
            title: "광장시장에서 시장음식 먹어보기",
            placeName: "광장시장",
            district: "종로구",
            rating: 4.6,
            tags: [
                "대중교통 편리",
                "혼잡도 높음"
            ],
            isRecommended: false,
            category: .food,
            mockAssetName: "mission_gyeongbok",
            imageURL: nil,
            isBookmarked: false
        ),
        PlaceItem(
            title: "한강공원에서 산책하기",
            placeName: "뚝섬한강공원",
            district: "광진구",
            rating: 4.8,
            tags: [
                "좌석충분",
                "계단 없음"
            ],
            isRecommended: false,
            category: .outdoor,
            mockAssetName: "mission_namsan",
            imageURL: nil,
            isBookmarked: false
        ),
        PlaceItem(
            title: "가족과 함께 전시 관람하기",
            placeName: "국립현대미술관",
            district: "종로구",
            rating: 4.7,
            tags: [
                "실내",
                "대중교통 편리"
            ],
            isRecommended: false,
            category: .exhibition,
            mockAssetName: "mission_gyeongbok",
            imageURL: nil,
            isBookmarked: false
        )
    ]
    private var filteredPlaces: [PlaceItem] {
        places.filter { place in
            let matchesCategory =
                selectedCategory == .all ||
                place.category == selectedCategory
            let keyword = searchText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            let matchesSearch =
                keyword.isEmpty ||
                place.title.localizedCaseInsensitiveContains(keyword) ||
                place.placeName.localizedCaseInsensitiveContains(keyword) ||
                place.district.localizedCaseInsensitiveContains(keyword)
            return matchesCategory && matchesSearch
        }
    }
    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()
            VStack(spacing: 0) {
                appBar
                ScrollView(
                    .vertical,
                    showsIndicators: false
                ) {
                    VStack(spacing: 0) {
                        searchSection
                        categorySection
                            .padding(.top, 13)
                        filterHeader
                            .padding(.horizontal, 18)
                            .padding(.top, 24)
                        placeList
                            .padding(.horizontal, 18)
                            .padding(.top, 16)
                        Color.clear
                            .frame(height: 100)
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedPlace) { place in
            MissionActivityDetailView(
                title: place.title,
                placeName: place.placeName,
                district: place.district,
                rating: place.rating,
                tags: place.tags,
                isRecommended: place.isRecommended,
                mockAssetName: place.mockAssetName,
                imageURL: place.imageURL,
                isBookmarked: bookmarkBinding(for: place.id),
                onBack: { selectedPlace = nil }
            )
        }
    }

    // MARK: - App Bar
    private var appBar: some View {
        ZStack {
            Text("미션")
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(KIRIColor.Text.strong)
        }
        .frame(height: 62)
    }
    // MARK: - Search
    private var searchSection: some View {
        KIRISearchField(
            text: $searchText
        )
        .padding(.horizontal, 18)
        .padding(.top, 6)
    }
    // MARK: - Categories
    private var categorySection: some View {
        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {
            HStack(spacing: 8) {
                ForEach(
                    Category.allCases,
                    id: \.self
                ) { category in
                    KIRIChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(
                            .easeOut(duration: 0.15)
                        ) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
        }
    }
    // MARK: - Filter
    private var filterHeader: some View {
        HStack(spacing: 0) {
            Text("활동 \(filteredPlaces.count)개")
                .font(KIRITypography.bodySmallMedium)
                .tracking(-0.56)
                .foregroundStyle(KIRIColor.Text.secondary)
            Spacer()
            HStack(spacing: 12) {
                filterButton(
                    title: "날짜·시간"
                )
                filterButton(
                    title: "지역·거리"
                )
            }
        }
        .frame(height: 20)
    }
    private func filterButton(
        title: String
    ) -> some View {
        Button {
            // TODO: 필터 화면 연결
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(KIRITypography.bodySmallMedium)
                    .tracking(-0.56)
                    .foregroundStyle(KIRIColor.Text.secondary)
                Image(systemName: "chevron.down")
                    .font(
                        .system(
                            size: 8,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(KIRIColor.Icon.disabled)
            }
        }
        .buttonStyle(.plain)
    }
    // MARK: - Places
    private var placeList: some View {
        LazyVStack(spacing: 16) {
            ForEach(filteredPlaces) { place in
                MissionPlaceCard(
                    title: place.title,
                    placeName: place.placeName,
                    district: place.district,
                    rating: place.rating,
                    tags: place.tags,
                    isRecommended: place.isRecommended,
                    mockAssetName: place.mockAssetName,
                    imageURL: place.imageURL,
                    isBookmarked: bookmarkBinding(
                        for: place.id
                    )
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedPlace = place
                }
            }
        }
    }
    // MARK: - Bookmark
    private func bookmarkBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: {
                guard let place = places.first(where: { $0.id == id }) else { return false }
                return bucketStore.contains(title: place.title, placeName: place.placeName)
            },
            set: { isSaved in
                guard let place = places.first(where: { $0.id == id }) else { return }
                bucketStore.setSaved(isSaved, title: place.title, placeName: place.placeName)
            }
        )
    }
}
// MARK: - Preview
#Preview {
    MissionView()
}
