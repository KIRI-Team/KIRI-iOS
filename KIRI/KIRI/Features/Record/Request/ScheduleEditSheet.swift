import SwiftUI

/// 기존 일정의 날짜·시간·초대 대상자를 수정합니다.
/// API: PATCH /api/v1/schedules/{scheduleId}
struct ScheduleEditSheet: View {
    let scheduleId: Int
    let initialDate: String
    let initialTime: String
    let onUpdated: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var date: Date
    @State private var time: Date
    @State private var members: [FamilyAnswer] = []
    @State private var selectedMemberIds: Set<Int> = []
    @State private var isLoadingMembers = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    init(scheduleId: Int, initialDate: String, initialTime: String, onUpdated: @escaping () -> Void) {
        self.scheduleId = scheduleId
        self.initialDate = initialDate
        self.initialTime = initialTime
        self.onUpdated = onUpdated
        let dateFormatter = DateFormatter(); dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter(); timeFormatter.dateFormat = "HH:mm"
        _date = State(initialValue: dateFormatter.date(from: initialDate) ?? Date())
        _time = State(initialValue: timeFormatter.date(from: initialTime) ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("약속 시간") {
                    DatePicker("날짜", selection: $date, in: Date()..., displayedComponents: .date)
                    DatePicker("시간", selection: $time, displayedComponents: .hourAndMinute)
                }
                Section("초대할 가족") {
                    if isLoadingMembers { ProgressView("가족 구성원을 불러오는 중") }
                    else {
                        ForEach(members) { member in
                            Button {
                                if selectedMemberIds.contains(member.memberId) { selectedMemberIds.remove(member.memberId) }
                                else { selectedMemberIds.insert(member.memberId) }
                            } label: {
                                HStack {
                                    Text(member.nickname)
                                    if let role = member.familyRole { Text(role).foregroundStyle(.secondary) }
                                    Spacer()
                                    Image(systemName: selectedMemberIds.contains(member.memberId) ? "checkmark.circle.fill" : "circle")
                                }
                            }.foregroundStyle(.primary)
                        }
                    }
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
                Section {
                    Button { Task { await submit() } } label: {
                        HStack { Spacer(); if isSubmitting { ProgressView() } else { Text("수정 저장") }; Spacer() }
                    }.disabled(isSubmitting || isLoadingMembers)
                }
            }
            .navigationTitle("일정 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } } }
        }
        .task { await loadMembers() }
    }

    private func loadMembers() async {
        guard !isLoadingMembers else { return }
        isLoadingMembers = true; defer { isLoadingMembers = false }
        do {
            let today = try await AuthService.shared.todayQuestion()
            if let questionId = today.questionId {
                let result = try await AuthService.shared.familyAnswers(questionId: questionId)
                members = result.answers.filter { !$0.isMe }
            }
        } catch { errorMessage = "가족 구성원을 불러오지 못했어요." }
    }

    private func submit() async {
        guard !isSubmitting else { return }
        isSubmitting = true; errorMessage = nil; defer { isSubmitting = false }
        let dateFormatter = DateFormatter(); dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter(); timeFormatter.dateFormat = "HH:mm"
        do {
            _ = try await AuthService.shared.updateSchedule(
                scheduleId: scheduleId,
                request: UpdateScheduleRequest(
                    scheduleDate: dateFormatter.string(from: date),
                    scheduleTime: timeFormatter.string(from: time),
                    participantMemberIds: selectedMemberIds.sorted(),
                    requestMessage: nil
                )
            )
            onUpdated(); dismiss()
        } catch { errorMessage = "일정을 수정하지 못했어요. 다시 시도해 주세요." }
    }
}
