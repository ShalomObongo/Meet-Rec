//
//  MemosEditorView.swift
//  MeetRec
//
//  Created by Kiro on 11/16/25.
//

import SwiftUI
import AppKit

struct MemosEditorView: View {
    @Binding var text: String
    @State private var textView: RichTextView?
    
    var body: some View {
        VStack(spacing: 0) {
            // Formatting toolbar
            HStack(spacing: 12) {
                ToolbarButton(icon: "bold", tooltip: "Bold (⌘B)") {
                    textView?.toggleBold()
                }
                
                ToolbarButton(icon: "italic", tooltip: "Italic (⌘I)") {
                    textView?.toggleItalic()
                }
                
                ToolbarButton(icon: "underline", tooltip: "Underline (⌘U)") {
                    textView?.toggleUnderline()
                }
                
                Divider()
                    .frame(height: 20)
                
                ToolbarButton(icon: "textformat.size.larger", tooltip: "Heading") {
                    textView?.makeHeading()
                }
                
                ToolbarButton(icon: "list.bullet", tooltip: "Bullet List") {
                    textView?.insertBulletList()
                }
                
                ToolbarButton(icon: "list.number", tooltip: "Numbered List") {
                    textView?.insertNumberedList()
                }
                
                Spacer()
                
                // Word count
                Text("\(wordCount) words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            .glassEffect(.regular, in: .rect(cornerRadius: 8))
            
            // Rich text editor
            RichTextEditor(text: $text, textView: $textView)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var wordCount: Int {
        let words = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
        return words.count
    }
}

struct ToolbarButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}

// MARK: - Rich Text Editor

struct RichTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var textView: RichTextView?
    
    func makeNSView(context: Context) -> NSScrollView {
        // Create scroll view manually to use our custom text view
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        // Create our custom text view
        let textView = RichTextView()
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        
        // Configure text view
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = true
        
        // Set initial text
        if !text.isEmpty {
            textView.string = text
        }
        
        // Set text view as document view
        scrollView.documentView = textView
        
        // Store reference
        DispatchQueue.main.async {
            self.textView = textView
        }
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? RichTextView else { return }
        
        // Only update if text changed externally
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            textView.setSelectedRange(selectedRange)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

// MARK: - Custom NSTextView

class RichTextView: NSTextView {
    
    func toggleBold() {
        guard let font = typingAttributes[.font] as? NSFont else { return }
        
        let newFont: NSFont
        if font.fontDescriptor.symbolicTraits.contains(.bold) {
            newFont = NSFontManager.shared.convert(font, toNotHaveTrait: .boldFontMask)
        } else {
            newFont = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
        }
        
        applyFontToSelection(newFont)
    }
    
    func toggleItalic() {
        guard let font = typingAttributes[.font] as? NSFont else { return }
        
        let newFont: NSFont
        if font.fontDescriptor.symbolicTraits.contains(.italic) {
            newFont = NSFontManager.shared.convert(font, toNotHaveTrait: .italicFontMask)
        } else {
            newFont = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
        }
        
        applyFontToSelection(newFont)
    }
    
    func toggleUnderline() {
        let range = selectedRange()
        if range.length > 0 {
            let currentUnderline = textStorage?.attribute(.underlineStyle, at: range.location, effectiveRange: nil) as? Int ?? 0
            let newUnderline = currentUnderline == 0 ? NSUnderlineStyle.single.rawValue : 0
            textStorage?.addAttribute(.underlineStyle, value: newUnderline, range: range)
        } else {
            let currentUnderline = typingAttributes[.underlineStyle] as? Int ?? 0
            let newUnderline = currentUnderline == 0 ? NSUnderlineStyle.single.rawValue : 0
            typingAttributes[.underlineStyle] = newUnderline
        }
    }
    
    func makeHeading() {
        guard let font = typingAttributes[.font] as? NSFont else { return }
        let headingFont = NSFont.systemFont(ofSize: 20, weight: .bold)
        applyFontToSelection(headingFont)
    }
    
    func insertBulletList() {
        insertText("• ", replacementRange: selectedRange())
    }
    
    func insertNumberedList() {
        insertText("1. ", replacementRange: selectedRange())
    }
    
    private func applyFontToSelection(_ font: NSFont) {
        let range = selectedRange()
        if range.length > 0 {
            textStorage?.addAttribute(.font, value: font, range: range)
        } else {
            typingAttributes[.font] = font
        }
    }
}

#Preview {
    @Previewable @State var text = "This is a sample note with rich text formatting."
    
    MemosEditorView(text: $text)
        .frame(width: 600, height: 400)
}
