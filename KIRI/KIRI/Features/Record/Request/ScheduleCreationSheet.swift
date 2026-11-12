import SwiftUI

/// 버킷리스트에서 가족에게 일정 요청서를 작성하고 발송하는 화면입니다.
/// Figma 요청서 흐름(9898:19097, 9898:19129, 9898:19196, 9898:18832)을
/// 단계 상태로 표현하며, 마지막 발송 버튼에서만 일정 생성 API를 호출합니다.
/// API: POST /api/v1/bucket-items/{bucketItemId}/schedules
struct ScheduleCreationSheet: View {
    let bucket: BucketItemResult
    let onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var step: Step = .form
    @State private var date = Date()
    @State private var time = Date()
    @State private var message = ""
    @State private var familyMembers: [FamilyMemberInfoResult] = []
    @State private var selectedMemberIds: Set<Int> = []
    @State private var membersLoaded = false
    @State private var isSubmitting = false
    @State private var isSendMethodVisible = false
    @State private var errorMessage: String?
    @State private var memberLoadError: String?

    private enum Step { case form, dateTime, members, preview }
    private var canPreview: Bool { membersLoaded && !selectedMemberIds.isEmpty }
    private var dateString: String { Self.format(date, format: "yyyy-MM-dd", locale: "en_US_POSIX") }
    private var timeString: String { Self.format(time, format: "HH:mm", locale: "en_US_POSIX") }
    private var displayDateTime: String { Self.format(date, format: "yy.MM.dd(E) · HH:mm", locale: "ko_KR") }
    private static func format(_ date: Date, format: String, locale: String) -> String {
        let formatter = DateFormatter(); formatter.dateFormat = format; formatter.locale = Locale(identifier: locale); return formatter.string(from: date)
    }
    private var selectedMembers: [FamilyMemberInfoResult] { familyMembers.filter { selectedMemberIds.contains($0.memberId) } }

    var body: some View {
        ZStack {
            KIRIColor.Background.base.ignoresSafeArea()
            switch step { case .form: formView; case .dateTime: dateTimeView; case .members: membersView; case .preview: previewView }
        }
        .task { await loadFamilyMembers() }
    }

    private var formView: some View {
        VStack(spacing: 0) {
            appBar(title: "일정 등록하기", onBack: { dismiss() })
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    missionSummary
                    formRow(title: "일정 선택", value: displayDateTime, icon: "calendar") { step = .dateTime }
                    formRow(title: "가족 구성원 선택", value: selectedMembers.isEmpty ? "가족 구성원을 선택해 주세요" : "인원 \(selectedMembers.count)명", icon: "person.2") { step = .members }
                    messageEditor
                    if let errorMessage { errorText(errorMessage) }
                }
                .padding(.horizontal, 18).padding(.top, 24).padding(.bottom, 110)
            }
            bottomButton(title: "초대장 만들기", enabled: canPreview && !isSubmitting) { step = .preview }
        }
    }

    private var dateTimeView: some View {
        VStack(spacing: 0) {
            appBar(title: "일정 선택", onBack: { step = .form })
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("날짜와 시간을 선택해 주세요").font(KIRITypography.headingMedium).foregroundStyle(KIRIColor.Text.strong)
                    DatePicker("날짜", selection: $date, in: Date()..., displayedComponents: .date).datePickerStyle(.graphical).tint(KIRIColor.Primary.default)
                    DatePicker("시간", selection: $time, displayedComponents: .hourAndMinute).datePickerStyle(.wheel).frame(height: 150)
                }.padding(18)
            }
            bottomButton(title: "선택 완료", enabled: true) { step = .form }
        }
    }

    private var membersView: some View {
        VStack(spacing: 0) {
            appBar(title: "가족 구성원 선택", onBack: { step = .form })
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("함께하고 싶은 가족을 선택해 주세요").font(KIRITypography.headingMedium).foregroundStyle(KIRIColor.Text.strong).padding(.bottom, 8)
                    if !membersLoaded {
                        ProgressView("가족 구성원을 불러오는 중")
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else if let memberLoadError {
                        VStack(spacing: 10) {
                            Text(memberLoadError)
                                .font(KIRITypography.bodyMedium)
                                .foregroundStyle(KIRIColor.Text.secondary)
                                .multilineTextAlignment(.center)
                            Button("다시 시도") {
                                Task { await loadFamilyMembers(force: true) }
                            }
                            .font(KIRITypography.button)
                            .foregroundStyle(KIRIColor.Primary.default)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                    } else if familyMembers.isEmpty {
                        Text("함께 초대할 가족 구성원이 없어요.")
                            .font(KIRITypography.bodyMedium)
                            .foregroundStyle(KIRIColor.Text.secondary)
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(familyMembers) { member in memberRow(member) }
                        }
                    }
                    if let errorMessage { errorText(errorMessage) }
                }.padding(18)
            }
            bottomButton(title: "선택 완료", enabled: !selectedMemberIds.isEmpty) { step = .form }
        }
    }

    private var previewView: some View {
        VStack(spacing: 0) {
            appBar(title: "초대장 미리보기", onBack: { step = .form })
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("가족에게 보낼 요청서를 확인해 주세요").font(KIRITypography.headingMedium).foregroundStyle(KIRIColor.Text.strong)
                    missionSummary
                    detailLine(label: "일정", value: displayDateTime)
                    detailLine(label: "초대할 가족", value: selectedMembers.map(\.nickname).joined(separator: ", "))
                    if !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { detailLine(label: "가족에게 한 줄", value: message) }
                    if let errorMessage { errorText(errorMessage) }
                }.padding(18).padding(.bottom, 110)
            }
            bottomButton(title: "초대장 보내기", enabled: !isSubmitting) { isSendMethodVisible = true }
        }
        .overlay {
            if isSendMethodVisible {
                InvitationSendMethodSheet(onClose: { isSendMethodVisible = false }, onSendInApp: { isSendMethodVisible = false; Task { await submit() } }, onSendKakao: { isSendMethodVisible = false; errorMessage = "카카오톡 발송은 일정 생성 후 제공되는 초대 링크로 진행해 주세요." }).zIndex(10)
            }
        }
    }

    private var missionSummary: some View {
        HStack(spacing: 12) {
            missionImage
            VStack(alignment: .leading, spacing: 5) {
                if !bucket.saver.nickname.isEmpty { Text("\(bucket.saver.nickname)이 저장했어요!").font(KIRITypography.captionMedium).foregroundStyle(KIRIColor.Primary.default) }
                Text(bucket.mission.title).font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.strong).lineLimit(2)
            }
            Spacer(minLength: 0)
        }.padding(16).background(KIRIColor.Background.tertiary).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder private var missionImage: some View {
        if let url = bucket.mission.imageUrl {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase { image.resizable().scaledToFill() } else { Color.gray.opacity(0.25) }
            }.frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 8))
        } else { Color.gray.opacity(0.25).frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 8)) }
    }

    private var messageEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("가족에게 한 줄").font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.strong)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12).fill(KIRIColor.Background.tertiary)
                if message.isEmpty { Text("같이 가고싶은 가족들에게 한 줄 적어주세요!").foregroundStyle(KIRIColor.Text.tertiary).padding(14) }
                TextEditor(text: $message).scrollContentBackground(.hidden).padding(10).foregroundStyle(KIRIColor.Text.strong).onChange(of: message) { _, value in if value.count > 100 { message = String(value.prefix(100)) } }
                Text("\(message.count)/100").font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary).padding(12).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing).allowsHitTesting(false)
            }.frame(height: 104)
        }
    }

    private func memberRow(_ member: FamilyMemberInfoResult) -> some View {
        Button {
            if selectedMemberIds.contains(member.memberId) { selectedMemberIds.remove(member.memberId) } else { selectedMemberIds.insert(member.memberId) }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    memberImage(member)
                        .frame(height: 72)
                        .frame(maxWidth: .infinity)
                    Image(systemName: selectedMemberIds.contains(member.memberId) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selectedMemberIds.contains(member.memberId) ? KIRIColor.Primary.default : KIRIColor.Text.tertiary)
                        .font(.system(size: 22))
                }
                Text(member.nickname)
                    .font(KIRITypography.bodyMedium)
                    .foregroundStyle(KIRIColor.Text.strong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(selectedMemberIds.contains(member.memberId) ? KIRIColor.Primary.default.opacity(0.18) : KIRIColor.Background.tertiary)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedMemberIds.contains(member.memberId) ? KIRIColor.Primary.default : .clear, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain)
    }

    @ViewBuilder
    private func memberImage(_ member: FamilyMemberInfoResult) -> some View {
        if let url = member.characterImageUrl {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase { image.resizable().scaledToFit() }
                else { roleImage(for: member.familyRole) }
            }
        } else {
            roleImage(for: member.familyRole)
        }
    }

    private func roleImage(for role: String?) -> some View {
        let asset: String
        switch role?.uppercased() {
        case "FATHER": asset = "role_dad"
        case "MOTHER": asset = "role_mom"
        case "SON": asset = "role_son"
        case "DAUGHTER": asset = "role_daughter"
        default: asset = "family-member"
        }
        return Image(asset).resizable().scaledToFit()
    }

    private func detailLine(label: String, value: String) -> some View { VStack(alignment: .leading, spacing: 5) { Text(label).font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary); Text(value).font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.strong) } }
    private func errorText(_ text: String) -> some View { Text(text).font(KIRITypography.caption).foregroundStyle(KIRIColor.Status.error) }
    private func appBar(title: String, onBack: @escaping () -> Void) -> some View { ZStack { Text(title).font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.strong); HStack { KIRIBackButton(action: onBack); Spacer() } }.padding(.horizontal, 6).frame(height: 62) }
    private func formRow(title: String, value: String, icon: String, action: @escaping () -> Void) -> some View { Button(action: action) { HStack(spacing: 12) { Image(systemName: icon).foregroundStyle(KIRIColor.Icon.secondary).frame(width: 22); VStack(alignment: .leading, spacing: 4) { Text(title).font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary); Text(value).font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.strong) }; Spacer(); Image(systemName: "chevron.right").foregroundStyle(KIRIColor.Icon.secondary) }.padding(.horizontal, 16).frame(minHeight: 85).background(KIRIColor.Background.tertiary).clipShape(RoundedRectangle(cornerRadius: 16)) }.buttonStyle(.plain) }
    private func bottomButton(title: String, enabled: Bool, action: @escaping () -> Void) -> some View { Button(action: action) { HStack { Spacer(); if isSubmitting { ProgressView().tint(KIRIColor.Text.onGreen) } else { Text(title) }; Spacer() }.font(KIRITypography.button).foregroundStyle(enabled ? KIRIColor.Text.onGreen : KIRIColor.Text.secondary).frame(height: 54).background(enabled ? KIRIColor.Primary.default : KIRIColor.Background.elevated).clipShape(RoundedRectangle(cornerRadius: 8)) }.buttonStyle(.plain).disabled(!enabled).padding(.horizontal, 18).padding(.bottom, 12) }

    private func submit() async {
        guard !isSubmitting else { return }
        let ids = selectedMemberIds.sorted()
        guard !ids.isEmpty else { errorMessage = "초대할 가족 구성원을 한 명 이상 선택해 주세요."; return }
        guard message.count <= 100 else { errorMessage = "메시지는 100자 이하로 입력해 주세요."; return }
        isSubmitting = true; errorMessage = nil; defer { isSubmitting = false }
        do {
            _ = try await AuthService.shared.createSchedule(bucketItemId: bucket.bucketItemId, request: CreateScheduleRequest(scheduleDate: dateString, scheduleTime: timeString, participantMemberIds: ids, requestMessage: message.isEmpty ? nil : message))
            onCreated(); dismiss()
        } catch { errorMessage = "일정 요청을 보내지 못했어요. 다시 시도해 주세요." }
    }

    private func loadFamilyMembers(force: Bool = false) async {
        guard force || !membersLoaded else { return }
        membersLoaded = false
        memberLoadError = nil
        do {
            guard let familyId = AppSessionStore().familyId else { throw AuthServiceError.missingStoredSession }
            let result = try await AuthService.shared.scheduleParticipantMembers(familyId: familyId)
            let current = try? AuthService.shared.currentMemberId()
            familyMembers = result.filter { $0.memberId != current }
            membersLoaded = true
        } catch {
            memberLoadError = "가족 구성원을 불러오지 못했어요. 다시 시도해 주세요."
            membersLoaded = true
        }
    }
}

#Preview { Text("인증된 버킷 데이터가 필요합니다") }
