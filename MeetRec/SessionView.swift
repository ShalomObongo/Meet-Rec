//
//  SessionView.swift
//  MeetRec
//
//  Created by Shalom .O on 11/16/25.
//

import SwiftUI
import CoreData

struct SessionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var session: Session
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                TextField("Session Title", text: Binding(
                    get: { session.title ?? "" },
                    set: { session.title = $0 }
                ))
                .font(.title2)
                .fontWeight(.semibold)
                .textFieldStyle(.plain)
                
                if let createdAt = session.createdAt {
                    Text(createdAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .borderBottom()
            
            // Memos Editor
            VStack(alignment: .leading, spacing: 8) {
                Text("Memos")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top)
                
                TextEditor(text: Binding(
                    get: { session.rawMarkdown ?? "" },
                    set: { session.rawMarkdown = $0 }
                ))
                .font(.body)
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
                .padding()
            }
            
            Spacer()
        }
        .onDisappear {
            saveSession()
        }
    }
    
    private func saveSession() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error saving session: \(nsError), \(nsError.userInfo)")
        }
    }
}

// Custom binding for ObservedRealmObject - using @ObservedObject instead
struct SessionView_Preview: View {
    @State private var selectedSession: Session?
    
    var body: some View {
        if let session = selectedSession {
            SessionView(session: session)
        } else {
            Text("No session selected")
        }
    }
}

#Preview {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext
    
    let fetchRequest: NSFetchRequest<Session> = Session.fetchRequest()
    let sessions = try? context.fetch(fetchRequest)
    
    if let session = sessions?.first {
        SessionView(session: session)
            .environment(\.managedObjectContext, context)
    }
}
