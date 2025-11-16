//
//  AudioSource.swift
//  MeetRec
//
//  Created by Kiro on 11/16/25.
//

import Foundation

enum AudioSource: String, Codable, CaseIterable {
    case micAndSystem = "Mic + System"
    case micOnly = "Mic Only"
    case systemOnly = "System Only"
    
    var displayName: String {
        return self.rawValue
    }
}
