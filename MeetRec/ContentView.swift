//
//  ContentView.swift
//  MeetRec
//
//  Created by Shalom .O on 11/15/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedSession: Session?

    var body: some View {
        HSplitView {
            SidebarView(selectedSession: $selectedSession)
                .frame(minWidth: 200, maxWidth: 300)
            
            if let session = selectedSession {
                SessionView(session: session)
            } else {
                VStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No Session Selected")
                        .font(.headline)
                    Text("Select a session from the sidebar or create a new one")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .controlBackgroundColor))
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
