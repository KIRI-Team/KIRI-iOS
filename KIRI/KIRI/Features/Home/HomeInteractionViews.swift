//
// MARK: - 파일 가이드
// 파일: Features/Home/HomeInteractionViews.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import SwiftUI

private struct HomeMemberQuestionSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 124

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeQuestionAnswerView: View {
    @Environment(\.kiriTabBarVisibility) private var tabBarVisibility
    let question: String
    let existingAnswer: String?
    let onBack: () -> Void
    let onSave: (String) -> Void
    @State private var answer: String

    init(question: String, existingAnswer: String?, onBack: @escaping () -> Void, onSave: @escaping (String) -> Void) {
        self.question = question
        self.existingAnswer = existingAnswer
        self.onBack = onBack
        self.onSave = onSave
        _answer = State(initialValue: existingAnswer ?? "")
    }

    var body: some View {
        ZStack { KIRIColor.Background.base.ignoresSafeArea()
            VStack(spacing: 0) {
                HomeInteractionBar(title: "오늘의 질문", onBack: onBack)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("오늘의 질문").font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.secondary)
                        Text(question).font(KIRITypography.title).foregroundStyle(KIRIColor.Text.strong)
                        TextEditor(text: $answer)
                            .font(KIRITypography.body).foregroundStyle(KIRIColor.Text.primary)
                            .scrollContentBackground(.hidden).padding(12).frame(height: 170)
                            .background(KIRIColor.Background.secondary).clipShape(RoundedRectangle(cornerRadius: 8))
                        HStack {
                            Text("공백 제외 \(answer.trimmingCharacters(in: .whitespacesAndNewlines).count)/500")
                            Spacer()
                        }.font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary)
                        Text("오늘의 질문은 텍스트로만 답변할 수 있으며, 저장 버튼을 눌러야 답변 상태가 변경됩니다.")
                            .font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary)
                    }
                    .padding(18)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    answerSaveButton
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                        .padding(.bottom, 10)
                        .background(KIRIColor.Background.base)
                }
            }
        }
        .onAppear { tabBarVisibility.wrappedValue = false }
        .onDisappear { tabBarVisibility.wrappedValue = true }
    }

    private var answerSaveButton: some View {
        let isEnabled = !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && answer.count <= 500
        return Button("답변 저장") {
            let normalized = answer.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty, normalized.count <= 500 else { return }
            onSave(normalized)
        }
        .disabled(!isEnabled)
        .font(KIRITypography.button)
        .foregroundStyle(isEnabled ? KIRIColor.Button.FilledAccent.contentDefault : KIRIColor.Button.FilledNeutral.contentDefault)
        .frame(maxWidth: .infinity).frame(height: 54)
        .background(isEnabled ? KIRIColor.Button.FilledAccent.backgroundDefault : KIRIColor.Button.FilledNeutral.backgroundDisabled)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .buttonStyle(.plain)
    }
}

struct HomeMissionDetailView: View {
    let mission: MissionFeedItem?
    let onBack: () -> Void
    let onScheduleCreated: () -> Void
    @State private var isScheduleSheetPresented = false

    var body: some View {
        ZStack { KIRIColor.Background.base.ignoresSafeArea()
            VStack(spacing: 0) {
                HomeInteractionBar(title: "이번 주 미션", onBack: onBack)
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(mission?.title ?? "이번 주 미션").font(KIRITypography.title).foregroundStyle(KIRIColor.Text.strong)
                        Text("이번 주 가족 모두에게 배정된 미션이에요.").font(KIRITypography.body).foregroundStyle(KIRIColor.Text.secondary)
                        if let mission {
                            missionInfo("추천 장소", value: mission.placeName)
                        }
                        missionInfo("참여 가족", value: "가족 구성원을 선택해 주세요")
                        missionInfo("완료 조건", value: "일정을 만들고 활동 기록을 남겨주세요")
                        Text("미션 완료는 일정과 필수 기록이 저장된 뒤에만 처리됩니다.")
                            .font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary)
                        Button("캘린더에 일정 만들기") { isScheduleSheetPresented = true }
                            .font(KIRITypography.button).foregroundStyle(KIRIColor.Button.FilledAccent.contentDefault)
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(KIRIColor.Button.FilledAccent.backgroundDefault).clipShape(RoundedRectangle(cornerRadius: 8))
                            .buttonStyle(.plain)
                    }.padding(18)
                }
            }
        }
        .fullScreenCover(isPresented: $isScheduleSheetPresented) {
            if let mission {
                ScheduleCreationSheet(missionId: mission.missionId, missionTitle: mission.title) {
                    isScheduleSheetPresented = false
                    onScheduleCreated()
                }
            }
        }
    }

    private func missionInfo(_ label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.secondary).frame(width: 72, alignment: .leading)
            Text(value).font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.primary)
            Spacer()
        }.padding(16).background(KIRIColor.Background.secondary).clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct HomeMemberQuestionView: View {
    let member: HomeMember
    let question: String
    let anchorFrame: CGRect?
    let initiallyPoked: Bool
    let onBack: () -> Void
    let onPoke: (Int) async -> Bool
    let onAlreadyPoked: () -> Void
    @State private var didPoke: Bool
    @State private var isPoking = false
    @State private var measuredCardHeight: CGFloat = 124

    init(
        member: HomeMember,
        question: String,
        anchorFrame: CGRect?,
        initiallyPoked: Bool,
        onBack: @escaping () -> Void,
        onPoke: @escaping (Int) async -> Bool,
        onAlreadyPoked: @escaping () -> Void
    ) {
        self.member = member
        self.question = question
        self.anchorFrame = anchorFrame
        self.initiallyPoked = initiallyPoked
        self.onBack = onBack
        self.onPoke = onPoke
        self.onAlreadyPoked = onAlreadyPoked
        _didPoke = State(initialValue: initiallyPoked)
    }

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = min(303, max(280, proxy.size.width - 36))
            let cardHeight = max(124, measuredCardHeight)
            let containerFrame = proxy.frame(in: .global)
            let targetX = anchorFrame.map { $0.midX - containerFrame.minX } ?? proxy.size.width / 2
            let cardX = min(
                max(targetX, cardWidth / 2 + 18),
                proxy.size.width - cardWidth / 2 - 18
            )
            let targetTop = min(
                (anchorFrame.map { $0.maxY - containerFrame.minY } ?? proxy.size.height * 0.35) + 10,
                proxy.size.height - cardHeight - 24
            )
            let cardY = max(cardHeight / 2 + 16, targetTop + cardHeight / 2)

            card
                .frame(width: cardWidth)
                .frame(minHeight: cardHeight)
                .overlay(alignment: .top) {
                    SpeechTail()
                        .fill(KIRIColor.Background.primary)
                        .frame(width: 22, height: 12)
                        .offset(
                            x: min(
                                max(targetX - cardX, -cardWidth / 2 + 22),
                                cardWidth / 2 - 22
                            ),
                            y: -8
                        )
                }
                .position(x: cardX, y: cardY)
                .onPreferenceChange(HomeMemberQuestionSizePreferenceKey.self) { height in
                    guard height > 0, abs(measuredCardHeight - height) > 0.5 else { return }
                    measuredCardHeight = max(124, height)
                }
        }
        .ignoresSafeArea()
        .accessibilityAddTraits(.isModal)
    }

    private var card: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(question)
                    .font(KIRITypography.body)
                    .foregroundStyle(KIRIColor.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(member.hasAnswered ? (member.answer ?? "답변을 확인해보세요") : "아직 답변하지 않았어요")
                    .font(KIRITypography.headingSmall)
                    .foregroundStyle(KIRIColor.Text.strong)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(KIRIColor.Border.default)
                .frame(width: 1, height: 50)

            if !member.isMe {
                Button {
                    guard !isPoking else { return }
                    if didPoke {
                        onAlreadyPoked()
                        return
                    }
                    guard let memberId = member.memberId else { return }
                    isPoking = true
                    Task { @MainActor in
                        let success = await onPoke(memberId)
                        didPoke = success
                        isPoking = false
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image("figma_gesture_tap")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        Text("콕 찌르기")
                            .font(KIRITypography.caption)
                            // 답변 여부와 콕 전송 여부는 독립적입니다. 전송 이력이 있어도 재탭 안내를 제공합니다.
                            .foregroundStyle(KIRIColor.Primary.default)
                            .lineLimit(1)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .frame(width: 55)
                    .contentShape(Rectangle())
                }
                .disabled(isPoking || member.memberId == nil)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 21)
        .padding(.vertical, 20)
        .background(KIRIColor.Background.primary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: HomeMemberQuestionSizePreferenceKey.self,
                    value: proxy.size.height
                )
            }
        )
    }
}

private struct SpeechTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct HomeInteractionBar: View {
    let title: String
    let onBack: () -> Void
    var body: some View {
        ZStack {
            Text(title).font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.strong)
            HStack { KIRIBackButton(action: onBack); Spacer() }.padding(.horizontal, 0)
        }.frame(height: 62)
    }
}
