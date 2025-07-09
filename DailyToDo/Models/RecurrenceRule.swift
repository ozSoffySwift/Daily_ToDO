//
//  RecurrenceRule.swift
//  DailyToDo
//
//  Created by Oz Soffy on 03/07/2025.
//
import Foundation

// Enum to define task repetition frequency
enum RecurrenceRule: String, Codable, CaseIterable, Identifiable {
    case none      // One-time task (default)
    case daily     // Repeats every day
    case weekly    // Repeats every week
    case monthly   // Repeats every month
    case yearly    // Repeats every year

    var id: String { rawValue } // Conform to Identifiable for SwiftUI use
}

