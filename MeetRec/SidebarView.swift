//
//  SidebarView.swift
//  MeetRec
//
//  Created by Shalom .O on 11/16/25.
//

import SwiftUI
import CoreData

struct SidebarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedSession: Session?
    
    @FetchRequest(
        entity: Session.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Session.createdAt, ascending: false)],
        animation: .default
    )
    private var sessions: FetchedResults<Session>
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Sessions")
                    .font(.headline)
                Spacer()
                Button(action: createNewSession) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .help("New Session")
            }
            .padding()
            .borderBottom()
            
            List(sessions, id: \.self, selection: $selectedSession) { session in
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title ?? "Untitled Session")
                        .font(.body)
                        .fontWeight(.medium)
                    if let createdAt = session.createdAt {
                        Text(createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tag(session)
            }
        }
    }
    
    private func createNewSession() {
        let newSession = Session(context: viewContext)
        newSession.id = UUID()
        newSession.title = "New Session"
        newSession.createdAt = Date()
        newSession.rawMarkdown = ""
        
        do {
            try viewContext.save()
            selectedSession = newSession
        } catch {
            let nsError = error as NSError
            print("Error creating session: \(nsError), \(nsError.userInfo)")
        }
    }
}

extension View {
    func borderBottom() -> some View {
        self.border(Color(nsColor: .separatorColor), width: 1)
    }
}

#Preview {
    SidebarView(selectedSession: .constant(nil))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
