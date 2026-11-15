import SwiftUI

/// 버킷리스트에서 가족에게 일정 요청서를 작성하고 발송하는 화면입니다.
/// Figma 요청서 흐름(9898:19097, 9898:19129, 9898:19196, 9898:18832)을
/// 단계 상태로 표현하며, 마지막 발송 버튼에서만 일정 생성 API를 호출합니다.
/// API: POST /api/v1/bucket-items/{bucketItemId}/schedules
struct ScheduleCreationSheet: View {
    let bucket: BucketItemResult?
    let missionId: Int?
    let missionTitle: String
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
    @State private var isMemberPickerPresented = false
    @State private var isDateTimePickerPresented = false
    @State private var displayedMonth = Date()
    @State private var errorMessage: String?
    @State private var memberLoadError: String?
    @State private var isLoadingMembers = false
    @State private var missionDescription: String?

    private enum Step { case form, dateTime, members, preview }
    private var canPreview: Bool { membersLoaded && !selectedMemberIds.isEmpty }
    private var dateString: String { Self.format(date, format: "yyyy-MM-dd", locale: "en_US_POSIX") }
    private var timeString: String { Self.format(time, format: "HH:mm", locale: "en_US_POSIX") }
    private var displayDateTime: String { Self.format(date, format: "yy.MM.dd(E) · HH:mm", locale: "ko_KR") }
    private static func format(_ date: Date, format: String, locale: String) -> String {
        let formatter = DateFormatter(); formatter.dateFormat = format; formatter.locale = Locale(identifier: locale); return formatter.string(from: date)
    }
    private var selectedMembers: [FamilyMemberInfoResult] { familyMembers.filter { selectedMemberIds.contains($0.memberId) } }

    init(bucket: BucketItemResult, onCreated: @escaping () -> Void) {
        self.bucket = bucket
        self.missionId = nil
        self.missionTitle = bucket.mission.title
        self.onCreated = onCreated
    }

    init(missionId: Int, missionTitle: String, onCreated: @escaping () -> Void) {
        self.bucket = nil
        self.missionId = missionId
        self.missionTitle = missionTitle
        self.onCreated = onCreated
    }

    var body: some View {
        ZStack {
            KIRIColor.Background.base.ignoresSafeArea()
            switch step { case .form: formView; case .dateTime: dateTimeView; case .members: membersView; case .preview: previewView }
        }
        .task { await loadFamilyMembers() }
        .task { await loadMissionDescription() }
        .sheet(isPresented: $isMemberPickerPresented) {
            membersView
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .task { await loadFamilyMembers() }
        }
        .sheet(isPresented: $isDateTimePickerPresented) {
            dateTimePickerSheet
                .presentationDetents([.height(560)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
        }
    }

    private var formView: some View {
        VStack(spacing: 0) {
            appBar(title: "일정 등록하기", onBack: { dismiss() })
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    missionSummary
                    formRow(title: "일정 선택", value: displayDateTime, icon: "calendar") {
                        displayedMonth = monthStart(for: date)
                        isDateTimePickerPresented = true
                    }
                    formRow(title: "가족 구성원 선택", value: selectedMembers.isEmpty ? "가족 구성원을 선택해 주세요" : "인원 \(selectedMembers.count)명", icon: "person.2") {
                        isMemberPickerPresented = true
                        // 일정 등록 화면에 들어올 때 구성원 조회가 실패했거나
                        // 세션 복원이 늦어진 경우에도 행을 누르면 즉시 재조회합니다.
                        Task { await loadFamilyMembers(force: true) }
                    }
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

    private var dateTimePickerSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("날짜선택")
                .font(KIRITypography.headingMedium)
                .foregroundStyle(KIRIColor.Text.strong)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 18)

            HStack {
                Button {
                    displayedMonth = monthStart(for: calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(monthStart(for: displayedMonth) <= monthStart(for: Date()))
                Spacer()
                Text(monthLabel(displayedMonth))
                    .font(KIRITypography.bodySmallMedium)
                    .foregroundStyle(KIRIColor.Text.strong)
                Spacer()
                Button {
                    displayedMonth = monthStart(for: calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth)
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(KIRIColor.Text.strong)
            .padding(.bottom, 14)

            HStack(spacing: 0) {
                ForEach(["월", "화", "수", "목", "금", "토", "일"], id: \.self) { weekday in
                    Text(weekday)
                        .font(KIRITypography.caption)
                        .foregroundStyle(KIRIColor.Text.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        Button {
                            date = day
                        } label: {
                            Text(String(calendar.component(.day, from: day)))
                                .font(KIRITypography.bodySmall)
                                .foregroundStyle(calendar.isDate(day, inSameDayAs: date) ? KIRIColor.Text.onGreen : KIRIColor.Text.strong)
                                .frame(width: 34, height: 34)
                                .background(calendar.isDate(day, inSameDayAs: date) ? KIRIColor.Primary.default : .clear)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(height: 34)
                    }
                }
            }

            Text("시간선택")
                .font(KIRITypography.bodySmallMedium)
                .foregroundStyle(KIRIColor.Text.strong)
                .padding(.top, 18)
                .padding(.bottom, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(timeOptions, id: \.self) { option in
                        Button(option) {
                            setTime(option)
                        }
                        .font(KIRITypography.bodySmallMedium)
                        .foregroundStyle(isTimeSelected(option) ? KIRIColor.Text.onGreen : KIRIColor.Text.secondary)
                        .padding(.horizontal, 15)
                        .frame(height: 38)
                        .background(isTimeSelected(option) ? KIRIColor.Primary.default : KIRIColor.Background.tertiary)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer(minLength: 16)
            bottomButton(title: "다음", enabled: true) { isDateTimePickerPresented = false }
        }
        .padding(.horizontal, 18)
        .padding(.top, 24)
        .padding(.bottom, 12)
        .background(KIRIColor.Background.base.ignoresSafeArea())
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.firstWeekday = 2 // 월요일 시작
        calendar.timeZone = .current
        return calendar
    }

    private var monthDays: [Date?] {
        let start = monthStart(for: displayedMonth)
        guard let range = calendar.range(of: .day, in: .month, for: start) else { return [] }
        let weekday = calendar.component(.weekday, from: start)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        var days = Array(repeating: Optional<Date>.none, count: leading)
        days += range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: start) }
        return days
    }

    private var timeOptions: [String] {
        stride(from: 9 * 60, through: 21 * 60, by: 30).map { minutes in
            String(format: "%02d:%02d", minutes / 60, minutes % 60)
        }
    }

    private func monthStart(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private func monthLabel(_ date: Date) -> String {
        Self.format(date, format: "yyyy년 M월", locale: "ko_KR")
    }

    private func isTimeSelected(_ value: String) -> Bool {
        Self.format(time, format: "HH:mm", locale: "en_US_POSIX") == value
    }

    private func setTime(_ value: String) {
        let components = value.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return }
        time = calendar.date(bySettingHour: components[0], minute: components[1], second: 0, of: time) ?? time
    }

    private var membersView: some View {
        VStack(spacing: 0) {
            appBar(title: "가족 구성원 선택", onBack: { isMemberPickerPresented = false })
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
            bottomButton(title: "선택 완료", enabled: !selectedMemberIds.isEmpty) { isMemberPickerPresented = false }
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
                if let bucket, !bucket.saver.nickname.isEmpty {
                    Text("\(bucket.saver.nickname)이 저장했어요!")
                        .font(KIRITypography.captionMedium)
                        .foregroundStyle(KIRIColor.Primary.default)
                }
                Text(missionTitle).font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.strong).lineLimit(2)
                if let missionDescription, !missionDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(missionDescription)
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Text.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }.padding(16).background(KIRIColor.Background.tertiary).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder private var missionImage: some View {
        if let url = bucket?.mission.imageUrl {
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
        // 구성원 선택 상태는 캐릭터 자체의 Figma 원본으로 구분합니다.
        // 서버 URL이 있더라도 역할별 선택/미선택 에셋을 우선해 상태가
        // 카드 배경에만 반영되는 문제를 막습니다.
        if let asset = roleAsset(for: member.familyRole, selected: selectedMemberIds.contains(member.memberId)) {
            Image(asset)
                .resizable()
                .scaledToFit()
        } else if let url = member.characterImageUrl {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase { image.resizable().scaledToFit() }
                else { Image("figma_family_member_default").resizable().scaledToFit() }
            }
        } else {
            Image("figma_family_member_default").resizable().scaledToFit()
        }
    }

    private func roleAsset(for role: String?, selected: Bool) -> String? {
        let normalizedRole = role?.uppercased()
        if selected {
            switch normalizedRole {
            case "FATHER": return "figma_family_member_active"
            case "MOTHER": return "figma_family_member_active_mom"
            case "SON": return "figma_family_member_active_son"
            case "DAUGHTER": return "figma_family_member_active_daughter"
            default: return "figma_family_member_active"
            }
        }
        switch role?.uppercased() {
        case "FATHER": return "role_dad"
        case "MOTHER": return "role_mom"
        case "SON": return "role_son"
        case "DAUGHTER": return "role_daughter"
        default: return "figma_family_member_default"
        }
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
            let request = CreateScheduleRequest(scheduleDate: dateString, scheduleTime: timeString, participantMemberIds: ids, requestMessage: message.isEmpty ? nil : message)
            if let bucket {
                _ = try await AuthService.shared.createSchedule(bucketItemId: bucket.bucketItemId, request: request)
            } else if let missionId {
                _ = try await AuthService.shared.createSchedule(missionId: missionId, request: request)
            } else {
                throw APIError.decodingFailed
            }
            onCreated(); dismiss()
        } catch { errorMessage = "일정 요청을 보내지 못했어요. 다시 시도해 주세요." }
    }

    private func loadFamilyMembers(force: Bool = false) async {
        guard force || !membersLoaded else { return }
        guard !isLoadingMembers else { return }
        isLoadingMembers = true
        membersLoaded = false
        memberLoadError = nil
        defer { isLoadingMembers = false }

        do {
            // 오늘 질문의 답변 목록은 미답변 구성원을 누락시킬 수 있습니다.
            // 일정 참여자 선택은 질문 배정 여부와 무관한 가족 전체를 사용하므로
            // 가족 상세 계약을 기준으로 조회합니다. 저장된 세션이 아직 갱신되지
            // 않은 경우에도 서버의 현재 사용자 가족 ID를 한 번 더 확인합니다.
            let session = AppSessionStore()
            let familyId: Int
            if let storedFamilyId = session.familyId {
                familyId = storedFamilyId
            } else {
                familyId = try await AuthService.shared.familyIdForCurrentMember().familyId
            }
            let result = try await AuthService.shared.familyInfo(familyId: familyId)
            let currentMemberId = try? AuthService.shared.currentMemberId()
            familyMembers = result.members.filter { $0.memberId != currentMemberId }
            membersLoaded = true
        } catch is CancellationError {
            // 시트가 닫힌 경우 입력 상태를 유지하고 다음 진입에서 다시 조회합니다.
        } catch {
            memberLoadError = "가족 구성원을 불러오지 못했어요. 다시 시도해 주세요."
            membersLoaded = true
        }
    }

    private func loadMissionDescription() async {
        let bucketDescription = bucket?.mission.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let bucketDescription, !bucketDescription.isEmpty {
            missionDescription = bucketDescription
            return
        }

        let detailMissionId = bucket?.mission.missionId ?? missionId
        guard let detailMissionId else { return }
        do {
            let detail = try await AuthService.shared.missionDetail(missionId: detailMissionId)
            let description = detail.description?.trimmingCharacters(in: .whitespacesAndNewlines)
            missionDescription = description?.isEmpty == false ? description : nil
        } catch is CancellationError {
            // 화면이 닫힌 경우에는 설명을 갱신하지 않습니다.
        } catch {
            // 설명 조회 실패는 일정 선택·구성원 선택을 막지 않습니다.
            missionDescription = nil
        }
    }
}

#Preview { Text("인증된 버킷 데이터가 필요합니다") }
