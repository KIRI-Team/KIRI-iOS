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

struct HomeQuestionAnswerView: View {
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
                    Spacer()
                    Button("답변 저장") {
                        let normalized = answer.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !normalized.isEmpty, normalized.count <= 500 else { return }
                        onSave(normalized)
                    }
                    .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || answer.count > 500)
                    .font(KIRITypography.button).foregroundStyle(KIRIColor.Text.onGreen)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(KIRIColor.Primary.default).clipShape(RoundedRectangle(cornerRadius: 8))
                }.padding(18)
            }
        }
    }
}

struct HomeMissionDetailView: View {
    let onBack: () -> Void
    let onScheduleCreated: () -> Void
    @State private var isScheduleSheetPresented = false

    var body: some View {
        ZStack { KIRIColor.Background.base.ignoresSafeArea()
            VStack(spacing: 0) {
                HomeInteractionBar(title: "이번 주 미션", onBack: onBack)
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("가족과 함께 경복궁에서 사진 찍기").font(KIRITypography.title).foregroundStyle(KIRIColor.Text.strong)
                        Text("이번 주 가족 모두에게 배정된 미션이에요.").font(KIRITypography.body).foregroundStyle(KIRIColor.Text.secondary)
                        missionInfo("추천 장소", value: "경복궁 종로구")
                        missionInfo("참여 가족", value: "가족 구성원 정보를 불러오면 표시돼요")
                        missionInfo("완료 조건", value: "일정을 만들고 활동 기록을 남겨주세요")
                        Text("미션 완료는 일정과 필수 기록이 저장된 뒤에만 처리됩니다.")
                            .font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary)
                        Button("캘린더에 일정 만들기") { isScheduleSheetPresented = true }
                            .font(KIRITypography.button).foregroundStyle(KIRIColor.Text.onGreen)
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(KIRIColor.Primary.default).clipShape(RoundedRectangle(cornerRadius: 8))
                    }.padding(18)
                }
            }
        }
        .fullScreenCover(isPresented: $isScheduleSheetPresented) {
            AddScheduleSheet(title: "경복궁에서 사진 찍기", date: "이번 주 토요일", participants: "", onClose: { isScheduleSheetPresented = false }, onCancel: { isScheduleSheetPresented = false }, onConfirm: { isScheduleSheetPresented = false; onScheduleCreated() })
                .preferredColorScheme(.dark)
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
    let onBack: () -> Void
    @State private var didPoke = false
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(member.name)의 가장 좋아하는 음식은")
                        .font(KIRITypography.body)
                        .foregroundStyle(KIRIColor.Text.secondary)
                    Text(member.hasAnswered ? (member.answer ?? "답변을 확인해보세요") : "아직 답변하지 않았어요")
                        .font(KIRITypography.headingSmall)
                        .foregroundStyle(KIRIColor.Text.strong)
                }
                Rectangle()
                    .fill(KIRIColor.Border.default)
                    .frame(width: 1, height: 50)
                if !member.isMe {
                    Button(didPoke ? "콕 보냄" : "콕 찌르기") { didPoke = true }
                        .disabled(didPoke)
                        .font(KIRITypography.caption)
                        .overlay(alignment: .top) {
                            Image("figma_gesture_tap")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .offset(y: -28)
                        }
                        .foregroundStyle(didPoke ? KIRIColor.Text.tertiary : KIRIColor.Primary.default)
                        .frame(width: 55)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(KIRIColor.Background.primary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 28)
        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        .onTapGesture { onBack() }
        .accessibilityAddTraits(.isModal)
    }
}

private struct HomeInteractionBar: View {
    let title: String
    let onBack: () -> Void
    var body: some View {
        ZStack {
            Text(title).font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.strong)
            HStack { Button(action: onBack) { Image(systemName: "chevron.left").foregroundStyle(KIRIColor.Icon.primary).frame(width: 52, height: 52) }.buttonStyle(.plain); Spacer() }.padding(.horizontal, 0)
        }.frame(height: 62)
    }
}
