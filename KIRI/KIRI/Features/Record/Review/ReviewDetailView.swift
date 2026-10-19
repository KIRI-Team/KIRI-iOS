import SwiftUI



struct ReviewDetailView: View {



    let review: RecordCalendarView.ReviewDetailData



    var localDraft: ActivityReviewWriteView.Draft? = nil

    let onBack: () -> Void

    let onEdit: () -> Void

    let onDelete: () -> Void



    @State private var isMenuVisible = false



    var body: some View {

        ZStack {

            KIRIColor.Background.base

                .ignoresSafeArea()



            ScrollView(

                .vertical,

                showsIndicators: false

            ) {

                VStack(

                    alignment: .leading,

                    spacing: 0

                ) {

                    navigationBar



                    completedBadge

                        .padding(.top, 21)



                    titleSection

                        .padding(.top, 12)



                    sectionTitle

                        .padding(.top, 47)



                    reviewCard

                        .padding(.top, 14)



                    privacyNotice

                        .padding(.top, 19)



                    Color.clear

                        .frame(height: 110)

                }

                .padding(.horizontal, 18)

            }

        }

        .onTapGesture {

            if isMenuVisible {

                isMenuVisible = false

            }

        }

    }



    // MARK: - Navigation



    private var navigationBar: some View {

        ZStack {

            Text("\(review.familyName) 기록")

                .font(KIRITypography.headingSmall)

                .tracking(-0.72)

                .foregroundStyle(

                    KIRIColor.Text.strong

                )



            HStack {

                KIRIBackButton {

                    onBack()

                }



                Spacer()

            }

        }

        .frame(height: 62)

    }



    // MARK: - Badge



    private var completedBadge: some View {

        Text("약속 완료")

            .font(KIRITypography.bodySmall)

            .tracking(-0.56)

            .foregroundStyle(

                KIRIColor.Text.primary

            )

            .padding(.horizontal, 8)

            .padding(.vertical, 6)

            .background(

                KIRIColor.Background.elevated

            )

            .clipShape(

                RoundedRectangle(

                    cornerRadius: 5

                )

            )

    }



    // MARK: - Title



    private var titleSection: some View {

        VStack(

            alignment: .leading,

            spacing: 12

        ) {

            Text(review.title)

                .font(KIRITypography.title)

                .tracking(-1.12)

                .foregroundStyle(

                    KIRIColor.Text.strong

                )



            HStack(spacing: 6) {

                Button {

                    // TODO: 참여자 확인 연결

                } label: {

                    Text("인원확인")

                        .font(KIRITypography.body)

                        .tracking(-0.64)

                        .foregroundStyle(

                            KIRIColor.Text.primary

                        )

                        .underline()

                }

                .buttonStyle(.plain)



                Text("I")

                    .font(KIRITypography.body)

                    .foregroundStyle(

                        KIRIColor.Text.primary

                    )



                Text(review.date)

                    .font(KIRITypography.body)

                    .tracking(-0.64)

                    .foregroundStyle(

                        KIRIColor.Text.primary

                    )

            }

        }

    }



    // MARK: - Section



    private var sectionTitle: some View {

        Text("\(review.familyName) 님의 한 줄")

            .font(KIRITypography.headingSmall)

            .tracking(-0.72)

            .foregroundStyle(

                KIRIColor.Text.strong

            )

    }



    // MARK: - Review Card



    private var reviewCard: some View {

        ZStack(

            alignment: .topTrailing

        ) {

            VStack(

                alignment: .leading,

                spacing: 0

            ) {

                authorHeader



                reviewImage

                    .padding(.top, 19)



                Text((localDraft ?? review.draft)?.comment ?? review.review)

                    .font(KIRITypography.body)

                    .tracking(-0.64)

                    .foregroundStyle(

                        KIRIColor.Text.primary

                    )

                    .lineSpacing(9.6)

                    .fixedSize(

                        horizontal: false,

                        vertical: true

                    )

                    .padding(.top, 18)



                Text("\(review.writtenDate) 작성")

                    .font(KIRITypography.bodySmall)

                    .tracking(-0.56)

                    .foregroundStyle(

                        KIRIColor.Text.secondary

                    )

                    .frame(

                        maxWidth: .infinity,

                        alignment: .trailing

                    )

                    .padding(.top, 22)

            }

            .padding(.horizontal, 16)

            .padding(.top, 13)

            .padding(.bottom, 14)

            .frame(

                maxWidth: .infinity,

                minHeight: 386,

                alignment: .topLeading

            )

            .background(

                KIRIColor.Background.secondary

            )

            .clipShape(

                RoundedRectangle(

                    cornerRadius: 16

                )

            )



            if review.isCurrentUser && (localDraft ?? review.draft) != nil {

                menuArea

                    .padding(.top, 18)

                    .padding(.trailing, 14)

            }

        }

    }



    // MARK: - Author



    private var authorHeader: some View {

        HStack(spacing: 14) {

            Circle()

                .fill(

                    KIRIColor.Background.elevated

                )

                .frame(

                    width: 36,

                    height: 36

                )



            HStack(spacing: 5) {

                Text(review.authorName)



                if review.isCurrentUser {

                    Text("I")



                    Text("나")

                }

            }

            .font(KIRITypography.body)

            .tracking(-0.64)

            .foregroundStyle(

                KIRIColor.Text.primary

            )

        }

    }



    // MARK: - Image



    private var reviewImage: some View {

        Group {

            if let first = (localDraft ?? review.draft)?.images.first {
                Image(uiImage: first).resizable().scaledToFill()
            } else if let url = review.representativePhotoURL {

                AsyncImage(url: url) { phase in

                    switch phase {

                    case .success(let image):

                        image

                            .resizable()

                            .scaledToFill()



                    case .empty:

                        photoPlaceholder



                    case .failure:

                        photoPlaceholder



                    @unknown default:

                        photoPlaceholder

                    }

                }



            } else {

                photoPlaceholder

            }

        }

        .frame(

            maxWidth: .infinity

        )

        .frame(height: 185)

        .clipShape(

            RoundedRectangle(

                cornerRadius: 4

            )

        )

        .clipped()

    }



    private var photoPlaceholder: some View {

        ZStack {

            KIRIColor.Background.tertiary



            Image(systemName: "photo")

                .font(

                    .system(

                        size: 25,

                        weight: .regular

                    )

                )

                .foregroundStyle(

                    KIRIColor.Icon.disabled

                )

        }

    }



    // MARK: - Menu



    private var menuArea: some View {

        VStack(

            alignment: .trailing,

            spacing: 5

        ) {

            Button {

                withAnimation(

                    .easeOut(duration: 0.15)

                ) {

                    isMenuVisible.toggle()

                }

            } label: {

                Image(systemName: "ellipsis")

                    .font(

                        .system(

                            size: 16,

                            weight: .medium

                        )

                    )

                    .foregroundStyle(

                        KIRIColor.Icon.secondary

                    )

                    .frame(

                        width: 32,

                        height: 28

                    )

                    .contentShape(Rectangle())

            }

            .buttonStyle(.plain)



            if isMenuVisible {

                actionMenu

                    .transition(

                        .opacity.combined(

                            with: .scale(

                                scale: 0.96,

                                anchor: .topTrailing

                            )

                        )

                    )

            }

        }

    }



    private var actionMenu: some View {

        VStack(spacing: 0) {

            menuButton(

                title: "수정하기",

                systemName: "pencil.tip"

            ) {

                isMenuVisible = false

                onEdit()

            }



            Rectangle()

                .fill(KIRIColor.Border.default)

                .frame(height: 1)



            menuButton(

                title: "삭제하기",

                systemName: "trash.fill"

            ) {

                isMenuVisible = false

                onDelete()

            }

        }

        .frame(width: 100)

        .background(

            KIRIColor.Background.tertiary

        )

        .overlay {

            RoundedRectangle(

                cornerRadius: 16

            )

            .stroke(

                KIRIColor.Border.default,

                lineWidth: 1

            )

        }

        .clipShape(

            RoundedRectangle(

                cornerRadius: 16

            )

        )

    }



    private func menuButton(

        title: String,

        systemName: String,

        action: @escaping () -> Void

    ) -> some View {

        Button(action: action) {

            HStack(spacing: 4) {

                Image(systemName: systemName)

                    .font(

                        .system(

                            size: 14,

                            weight: .regular

                        )

                    )

                    .frame(

                        width: 16,

                        height: 16

                    )



                Text(title)

                    .font(KIRITypography.bodySmall)

                    .tracking(-0.56)



                Spacer(minLength: 0)

            }

            .foregroundStyle(

                KIRIColor.Text.secondary

            )

            .padding(.horizontal, 16)

            .frame(height: 41)

        }

        .buttonStyle(.plain)

    }



    // MARK: - Privacy



    private var privacyNotice: some View {

        Text("연결된 가족만 볼 수 있는 기록이에요")

            .font(KIRITypography.bodySmall)

            .tracking(-0.56)

            .foregroundStyle(

                KIRIColor.Text.tertiary

            )

            .frame(

                maxWidth: .infinity,

                alignment: .center

            )

    }

}



#Preview {

    ReviewDetailView(

        review: .init(

            title: "한강 뚜벅뚜벅 축제 방문",

            date: "2026.06.13",

            familyName: "끼리네가족",

            authorName: "김주연",

            isCurrentUser: true,

            review: "아빠가 자주 가는 식당에 처음 가봤다. 좋아하는 메뉴를 같이 먹으니 아빠를 조금 더 알게 된 기분이었다.",

            writtenDate: "12월 3일",

            representativePhotoURL: nil

        ),

        onBack: {},

        onEdit: {},

        onDelete: {}

    )

}

