//
//  ViewExtensions.swift
//  MeetRec
//
//  Created by Kiro on 11/16/25.
//

import SwiftUI

extension View {
    func borderBottom(color: Color = Color(nsColor: .separatorColor), width: CGFloat = 1) -> some View {
        self.overlay(
            Rectangle()
                .frame(height: width)
                .foregroundColor(color),
            alignment: .bottom
        )
    }
}
