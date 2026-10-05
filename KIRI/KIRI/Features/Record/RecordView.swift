import SwiftUI

struct RecordView: View {

    enum RecordTab: Hashable {
        case calendar
        case bucket

        var title: String {
            switch self {
            case .calendar:
                return "캘린더"
            case .bucket:
                return "버킷리스트"
            }
        }
    }

    @State private var selectedTab: RecordTab = .calendar

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            VStack(spacing: 0) {
                KIRITopTab(
                    items: [
                        RecordTab.calendar,
                        RecordTab.bucket
                    ],
                    selection: $selectedTab
                ) { tab in
                    tab.title
                }
                .padding(.horizontal, 18)
                .padding(.top, 40)

                Group {
                    switch selectedTab {
                    case .calendar:
                        RecordCalendarView()

                    case .bucket:
                        RecordBucketListView()
                    }
                }
            }
        }
    }
}

#Preview {
    RecordView()
}
