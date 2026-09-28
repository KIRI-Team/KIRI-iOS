//
//  KIRIShareSheet 2.swift
//  KIRI
//
//  Created by namhyuk on 9/28/26.
//


import SwiftUI
import UIKit

struct KIRIShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(
        context: Context
    ) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {
    }
}
