//
//  MeetRecApp.swift
//  MeetRec
//
//  Created by Shalom .O on 11/15/25.
//

import SwiftUI
import CoreData

@main
struct MeetRecApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
