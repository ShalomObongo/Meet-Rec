//
//  SessionView.swift
//  MeetRec
//
//  Created by Shalom .O on 11/16/25.
//

import SwiftUI
import CoreData

enum EditorTab: String, CaseIterable {
    case memos = "Memos"
    case transcript = "Transcript"
    case summary = "Summary"
}

struct SessionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var session: Session
    @State private var viewModel: SessionViewModel?
    
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
                
                HStack {
                    if let createdAt = session.createdAt {
                        Text(createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Recording controls
                    if let vm = viewModel {
                        HStack(spacing: 12) {
                            // Mic level indicator
                            if vm.audioService.isRecording {
                                HStack(spacing: 4) {
                                    Image(systemName: "mic.fill")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                    
                                    ProgressView(value: Double(vm.audioService.micLevel), total: 1.0)
                                        .progressViewStyle(.linear)
                                        .frame(width: 60)
                                        .tint(.red)
                                }
                            }
                            
                            // Record button
                            Button(action: {
                                Task {
                                    await vm.toggleRecording()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: vm.audioService.isRecording ? "stop.circle.fill" : "record.circle")
                                        .font(.system(size: 16))
                                    Text(vm.audioService.isRecording ? "Stop Recording" : "Start Recording")
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(vm.audioService.isRecording ? .red : .blue)
                        }
                    }
                }
            }
            .padding()
            .borderBottom()
            
            // Tab selector and content
            if let vm = viewModel {
                TabContentView(viewModel: vm)
            }
            
            Spacer()
        }
        .onAppear {
            if viewModel == nil {
                viewModel = SessionViewModel(session: session, viewContext: viewContext)
            }
        }
        .onDisappear {
            saveSession()
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel?.showError ?? false },
            set: { if !$0 { viewModel?.showError = false } }
        )) {
            Button("OK") {
                viewModel?.showError = false
            }
            if let error = viewModel?.errorMessage,
               error.contains("Microphone access") {
                Button("Open System Settings") {
                    openSystemSettings()
                }
            }
        } message: {
            if let error = viewModel?.errorMessage {
                Text(error)
            }
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
    
    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct TabContentView: View {
    @Bindable var viewModel: SessionViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("Editor", selection: $viewModel.selectedEditor) {
                ForEach(EditorTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Content based on selected tab
            Group {
                switch viewModel.selectedEditor {
                case .memos:
                    MemosEditorView(text: $viewModel.memosContent)
                        .padding(.horizontal)
                        .padding(.bottom)
                    
                case .transcript:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transcript")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        TranscriptView(words: viewModel.transcriptionService.words)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(6)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    
                case .summary:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Text("Summary generation coming soon...")
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
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
