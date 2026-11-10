import SwiftUI

/// 버킷 항목에서 실제 일정 생성 API를 호출하는 화면입니다.
/// API: POST /api/v1/bucket-items/{bucketItemId}/schedules
struct ScheduleCreationSheet: View {
    let bucket: BucketItemResult
    let onCreated: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var time = Date()
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("활동") {
                    Text(bucket.mission.title)
                    Text("저장자: \(bucket.saver.nickname)")
                        .foregroundStyle(.secondary)
                }
                Section("약속 시간") {
                    DatePicker("날짜", selection: $date, in: Date()..., displayedComponents: .date)
                    DatePicker("시간", selection: $time, displayedComponents: .hourAndMinute)
                }
                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSubmitting { ProgressView() }
                            else { Text("일정 만들기") }
                            Spacer()
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
            .navigationTitle("일정 만들기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
        }
    }

    private func submit() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            _ = try await AuthService.shared.createSchedule(
                bucketItemId: bucket.bucketItemId,
                request: CreateScheduleRequest(
                    scheduleDate: dateString,
                    scheduleTime: timeString,
                    participantMemberIds: [],
                    requestMessage: nil
                )
            )
            onCreated()
            dismiss()
        } catch {
            errorMessage = "일정을 만들지 못했어요. 다시 시도해 주세요."
        }
    }
}
