//
//  TranscribedWord.swift
//  MeetRec
//
//  Created by Kiro on 11/16/25.
//

import Foundation

struct TranscribedWord: Identifiable {
    let id: UUID
    let text: String
    let startMs: Int64
    let endMs: Int64
    let channel: String?
    var confidence: Double  // var instead of let so we can update it
    var isFinal: Bool       // Track whether this came from a final result

    init(id: UUID = UUID(), text: String, startMs: Int64, endMs: Int64, channel: String? = nil, confidence: Double = 1.0, isFinal: Bool = false) {
        self.id = id
        self.text = text
        self.startMs = startMs
        self.endMs = endMs
        self.channel = channel
        self.confidence = confidence
        self.isFinal = isFinal
    }
}
