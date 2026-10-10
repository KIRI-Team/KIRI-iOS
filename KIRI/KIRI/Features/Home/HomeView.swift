import SwiftUI

struct HomeView: View {
    let userMode: AppRouter.UserMode
    let familyName: String?
    let familyInviteCode: String?
    let onFamilyCreated: (String, String) -> Void

    var body: some View {
        switch userMode {
        case .family:
            FamilyHomeView(
                familyName: familyName ?? "끼리네 가족",
                familyInviteCode: familyInviteCode
            )

        case .browse:
            BrowseHomeView(onFamilyCreated: onFamilyCreated)
        }
    }
}

#Preview("Family") {
    HomeView(
        userMode: .family,
        familyName: "끼리네 가족",
        familyInviteCode: "KIRI24",
        onFamilyCreated: { _, _ in }
    )
}

#Preview("Browse") {
    HomeView(
        userMode: .browse,
        familyName: nil,
        familyInviteCode: nil,
        onFamilyCreated: { _, _ in }
    )
}
