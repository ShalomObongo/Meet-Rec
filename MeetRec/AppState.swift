//
//  AppState.swift
//  MeetRec
//
//  Created by Shalom .O on 11/16/25.
//

import SwiftUI
import CoreData

@MainActor
@Observable
final class AppState {
    var selectedSession: Session?
    
    init() {
        self.selectedSession = nil
    }
}
