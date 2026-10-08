
import SwiftUI
import PhotosUI

struct ActivityReviewWriteView: View {

    struct Draft {
        let rating: Int
        let images: [UIImage]
        let comment: String
        let wantsToRepeat: Bool
    }

    let onBack: () -> Void
    let onSubmit: (Draft) -> Void

    var initialDraft: Draft? = nil
    var userName: String = "김주연"
    var familyRole: String = "나"

    @State private var rating = 0
    @State private var comment = ""
    @State private var wantsToRepeat: Bool?

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State private var isLoadingPhotos = false
    @State private var hasLoadedInitialDraft = false

    private let maxCommentLength = 500
    private let maxPhotoCount = 10

    private var canSubmit: Bool {
        rating >= 1 &&
        rating <= 5 &&
        !images.isEmpty &&
        !comment.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty &&
        wantsToRepeat != nil &&
        !isLoadingPhotos
    }

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    userSection
                        .padding(.top, 18)

                    ratingSection
                        .padding(.top, 42)

                    photoSection
                        .padding(.top, 48)

                    commentSection
                        .padding(.top, 52)

                    repeatSection
                        .padding(.top, 52)

                    Color.clear.frame(height: 80)
                }
                .padding(.horizontal, 18)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(
            KIRIColor.Background.base.ignoresSafeArea()
        )
        .onAppear {
            loadInitialDraftIfNeeded()
        }
        .onChange(of: selectedPhotos) { _, newItems in
            guard !newItems.isEmpty else {
                return
            }

            Task {
                await loadPhotos(newItems)
            }
        }
    }

    // MARK: - Initial Data

    private func loadInitialDraftIfNeeded() {
        guard !hasLoadedInitialDraft else {
            return
        }

        hasLoadedInitialDraft = true

        guard let initialDraft else {
            return
        }

        rating = initialDraft.rating
        comment = String(
            initialDraft.comment.prefix(maxCommentLength)
        )
        wantsToRepeat = initialDraft.wantsToRepeat
        images = Array(
            initialDraft.images.prefix(maxPhotoCount)
        )
    }

    // MARK: - Navigation

    private var navigationBar: some View {
        HStack {
            KIRIBackButton(action: onBack)

            Spacer()

            Button {
                submitReview()
            } label: {
                Text(
                    initialDraft == nil
                        ? "등록하기"
                        : "수정완료"
                )
                .font(KIRITypography.headingSmall)
                .foregroundStyle(
                    canSubmit
                        ? KIRIColor.Text.strong
                        : KIRIColor.Text.disabled
                )
                .frame(minWidth: 80, minHeight: 44)
            }
            .disabled(!canSubmit)
            .buttonStyle(.plain)
        }
        .frame(height: 62)
    }

    private func submitReview() {
        guard canSubmit,
              let wantsToRepeat else {
            return
        }

        onSubmit(
            Draft(
                rating: rating,
                images: images,
                comment: comment.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
                wantsToRepeat: wantsToRepeat
            )
        )
    }

    // MARK: - User

    private var userSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(
                    KIRIColor.Text.secondary
                )

            Text("\(userName) | \(familyRole)")
                .font(KIRITypography.body)
                .foregroundStyle(
                    KIRIColor.Text.primary
                )
        }
    }

    // MARK: - Rating

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("끼리 추천은 어떠셨나요?")

            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        rating = value
                    } label: {
                        Image(
                            systemName: value <= rating
                                ? "star.fill"
                                : "star"
                        )
                        .font(.system(size: 30))
                        .foregroundStyle(
                            value <= rating
                                ? KIRIColor.Primary.default
                                : KIRIColor.Text.tertiary
                        )
                        .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(value)점")
                    .accessibilityAddTraits(
                        rating == value ? .isSelected : []
                    )
                }
            }
        }
    }

    // MARK: - Photos

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(
                alignment: .firstTextBaseline,
                spacing: 4
            ) {
                sectionTitle("오늘의 사진")

                Text("(최소 1장)")
                    .font(KIRITypography.caption)
                    .foregroundStyle(
                        KIRIColor.Text.tertiary
                    )
            }

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                HStack(spacing: 12) {
                    ForEach(
                        images.indices,
                        id: \.self
                    ) { index in
                        photoThumbnail(at: index)
                    }

                    if images.count < maxPhotoCount {
                        photoPicker
                    }
                }
            }

            Text(
                "\(images.count)/\(maxPhotoCount)장"
            )
            .font(KIRITypography.caption)
            .foregroundStyle(
                KIRIColor.Text.tertiary
            )
        }
    }

    private var photoPicker: some View {
        PhotosPicker(
            selection: $selectedPhotos,
            maxSelectionCount: maxPhotoCount - images.count,
            matching: .images
        ) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        KIRIColor.Background.secondary
                    )

                if isLoadingPhotos {
                    ProgressView()
                        .tint(
                            KIRIColor.Primary.default
                        )
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            KIRIColor.Text.primary
                        )
                }
            }
            .frame(width: 137, height: 137)
        }
        .disabled(isLoadingPhotos)
    }

    private func photoThumbnail(
        at index: Int
    ) -> some View {
        Image(uiImage: images[index])
            .resizable()
            .scaledToFill()
            .frame(width: 137, height: 137)
            .clipped()
            .clipShape(
                RoundedRectangle(cornerRadius: 8)
            )
            .overlay(alignment: .topTrailing) {
                Button {
                    images.remove(at: index)
                } label: {
                    Image(
                        systemName: "xmark.circle.fill"
                    )
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .padding(6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("사진 삭제")
            }
    }

    @MainActor
    private func loadPhotos(
        _ items: [PhotosPickerItem]
    ) async {
        guard !items.isEmpty else {
            return
        }

        isLoadingPhotos = true
        defer {
            isLoadingPhotos = false
            selectedPhotos = []
        }

        let availableSlots = maxPhotoCount - images.count

        guard availableSlots > 0 else {
            return
        }

        for item in items.prefix(availableSlots) {
            guard let data = try? await item.loadTransferable(
                type: Data.self
            ),
            let image = UIImage(data: data) else {
                continue
            }

            images.append(image)
        }
    }

    // MARK: - Comment

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(
                "오늘의 하루를 돌아봐요!"
            )

            ZStack(alignment: .topLeading) {
                if comment.isEmpty {
                    Text(
                        "끼리네 가족한테 공유하고 싶은 오늘의 감정을 알려주세요"
                    )
                    .font(KIRITypography.body)
                    .foregroundStyle(
                        KIRIColor.Text.tertiary
                    )
                    .padding(.horizontal, 23)
                    .padding(.top, 25)
                    .allowsHitTesting(false)
                }

                TextEditor(text: $comment)
                    .font(KIRITypography.body)
                    .foregroundStyle(
                        KIRIColor.Text.primary
                    )
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                    .onChange(of: comment) {
                        _, newValue in

                        if newValue.count > maxCommentLength {
                            comment = String(
                                newValue.prefix(
                                    maxCommentLength
                                )
                            )
                        }
                    }
            }
            .frame(height: 149)
            .background(
                KIRIColor.Background.secondary
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 8)
            )
            .overlay(alignment: .bottomTrailing) {
                Text(
                    "\(comment.count)/\(maxCommentLength)"
                )
                .font(KIRITypography.bodySmall)
                .foregroundStyle(
                    KIRIColor.Text.tertiary
                )
                .padding(.trailing, 23)
                .padding(.bottom, 18)
            }
        }
    }

    // MARK: - Repeat

    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                sectionTitle(
                    "이 활동을 다시 참여하고 싶으신가요?"
                )

                Text(
                    "추후 AI 미션 추천에 반영됩니다"
                )
                .font(KIRITypography.bodySmall)
                .foregroundStyle(
                    KIRIColor.Text.secondary
                )
            }

            HStack(spacing: 8) {
                repeatButton(
                    title: "예",
                    value: true
                )

                repeatButton(
                    title: "아니오",
                    value: false
                )
            }
        }
    }

    private func repeatButton(
        title: String,
        value: Bool
    ) -> some View {
        let isSelected = wantsToRepeat == value

        return Button {
            wantsToRepeat = value
        } label: {
            Text(title)
                .font(KIRITypography.button)
                .foregroundStyle(
                    isSelected
                        ? KIRIColor.Text.onGreen
                        : KIRIColor.Text.disabled
                )
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    isSelected
                        ? KIRIColor.Primary.default
                        : KIRIColor.Background.secondary
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 8)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            isSelected ? .isSelected : []
        )
    }

    private func sectionTitle(
        _ title: String
    ) -> some View {
        Text(title)
            .font(KIRITypography.headingSmall)
            .foregroundStyle(
                KIRIColor.Text.strong
            )
    }
}

#Preview("기록 작성") {
    ActivityReviewWriteView(
        onBack: {},
        onSubmit: { _ in }
    )
}
