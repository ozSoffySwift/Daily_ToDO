//
//  Mood.swift
//  DailyToDo
//
//  Created by Oz Soffy on 03/07/2025.
//
import Foundation

enum Mood: String, Codable, CaseIterable, Identifiable {
    case happy
    case neutral
    case sad
    case anxious
    case productive
    case tired

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .happy: return "😄"
        case .neutral: return "😐"
        case .sad: return "😢"
        case .anxious: return "😰"
        case .productive: return "🚀"
        case .tired: return "😴"
        }
    }

    var label: String {
        rawValue.capitalized
    }
}

