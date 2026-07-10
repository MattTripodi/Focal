//
//  ProBadge.swift
//  Focal
//
//  Created by Matthew Tripodi on 7/6/26.
//

import SwiftUI

struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(Capsule().stroke(Color.secondary.opacity(0.4)))
    }
}
