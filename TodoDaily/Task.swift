//
//  Task.swift
//  TodoDaily
//
//  Created by Oz Soffy on 28/04/2025.
//

import Foundation

struct Task: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isDone: Bool = false
}
