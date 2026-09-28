//
//  FamilyCodeLoadingView 2.swift
//  KIRI
//
//  Created by namhyuk on 9/26/26.
//


import SwiftUI

struct FamilyCodeLoadingView: View {
    var body: some View {
        ZStack {
            KIRIColor.background
                .ignoresSafeArea()

            VStack(spacing: 28) {
                ProgressView()
                    .controlSize(.large)
                    .tint(KIRIColor.textPrimary)

                VStack(spacing: 10) {
                    Text("가족코드를 생성하고 있어요")
                        .font(KIRITypography.bodyMedium)
                        .foregroundStyle(KIRIColor.textPrimary)

                    Text("잠시만 기다려주세요!")
                        .font(KIRITypography.subtitle)
                        .foregroundStyle(KIRIColor.textSecondary)
                }
            }
        }
    }
}

#Preview {
    FamilyCodeLoadingView()
}
