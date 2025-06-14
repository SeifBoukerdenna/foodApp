//
//  ViewExtension.swift
//  FoodMap
//
//  Extension methods for View
//

import SwiftUI

// MARK: - Hide keyboard helper
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
#endif
