//
//  AuthFlowView 2.swift
//  KIRI
//
//  Created by namhyuk on 9/28/26.
//


import SwiftUI

struct AuthFlowView: View {
    enum Step {
        case entry
        case login
        case signUp
        case terms
    }

    @State private var step: Step = .entry

    let onAuthenticated: () -> Void

    var body: some View {
        ZStack {
            KIRIColor.background
                .ignoresSafeArea()

            switch step {
            case .entry:
                AuthEntryView(
                    onLogin: {
                        step = .login
                    },
                    onSignUp: {
                        step = .signUp
                    }
                )

            case .login:
                LoginView(
                    onBack: {
                        step = .entry
                    },
                    onLogin: {
                        authenticateLogin()
                    },
                    onSignUp: {
                        step = .signUp
                    }
                )

            case .signUp:
                SignUpView(
                    onBack: {
                        step = .entry
                    },
                    onNext: {
                        step = .terms
                    }
                )

            case .terms:
                TermsAgreementView(
                    onBack: {
                        step = .signUp
                    },
                    onComplete: {
                        completeSignUp()
                    }
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: step)
    }

    private func authenticateLogin() {
        // TODO: 로그인 API 연결
        onAuthenticated()
    }

    private func completeSignUp() {
        // TODO: 회원가입 및 약관 동의 API 연결
        onAuthenticated()
    }
}

#Preview {
    AuthFlowView(
        onAuthenticated: {}
    )
}
