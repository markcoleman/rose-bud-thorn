
//
//  View.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 6/6/25.
//


import SwiftUI
import SwiftUI
import SwiftUI
import SwiftUI
import SwiftUI
import SwiftUI
import SwiftUI

extension View {
  /// Adds an accessibility label, optional hint, and expands the touch area.
  func accessibleTouchTarget(label: String, hint: String? = nil) -> some View {
    self
      .accessibilityLabel(Text(label))
      .accessibilityHint(Text(hint ?? ""))
      .contentShape(Rectangle())
      .padding(10)
  }
}
