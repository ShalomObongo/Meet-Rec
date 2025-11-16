//
//  SummaryView.swift
//  MeetRec
//
//  Created by Kiro on 11/17/25.
//

import SwiftUI

struct SummaryView: View {
    @Bindable var viewModel: SessionViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with controls
            HStack {
                Text("Summary")
                    .font(.headline)
                
                Spacer()
                
                // Autonomy level picker
                Picker("Autonomy", selection: $viewModel.autonomyLevel) {
                    ForEach(AutonomyLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .help(viewModel.autonomyLevel.description)
                
                // Generate button
                Button(action: {
                    Task {
                        await viewModel.generateSummary()
                    }
                }) {
                    HStack(spacing: 6) {
                        if viewModel.isGeneratingSummary {
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 12, height: 12)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(viewModel.isGeneratingSummary ? "Generating..." : "Generate Summary")
                    }
                }
                .disabled(viewModel.isGeneratingSummary)
            }
            
            Divider()
            
            // Content area
            ScrollView {
                if viewModel.isGeneratingSummary {
                    // Streaming content
                    VStack(alignment: .leading, spacing: 12) {
                        if !viewModel.streamingSummary.isEmpty {
                            Text(viewModel.streamingSummary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            // Skeleton loader
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(0..<5) { _ in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 16)
                                        .frame(maxWidth: .infinity)
                                        .shimmer()
                                }
                            }
                        }
                    }
                    .padding()
                } else if let error = viewModel.summaryError {
                    // Error state
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)
                        
                        Text("Failed to Generate Summary")
                            .font(.headline)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            Task {
                                await viewModel.generateSummary()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else if let summary = viewModel.session.enhancedMarkdown, !summary.isEmpty {
                    // Display saved summary
                    Text(summary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        
                        Text("No Summary Yet")
                            .font(.headline)
                        
                        Text("Click 'Generate Summary' to create an AI-powered summary from your memos\(viewModel.autonomyLevel == .creative ? " and transcript" : "").")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
        }
        .padding()
    }
}

// Shimmer effect for skeleton loader
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

#Preview {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext
    
    let fetchRequest: NSFetchRequest<Session> = Session.fetchRequest()
    let sessions = try? context.fetch(fetchRequest)
    
    if let session = sessions?.first {
        let viewModel = SessionViewModel(session: session, viewContext: context)
        SummaryView(viewModel: viewModel)
    }
}
