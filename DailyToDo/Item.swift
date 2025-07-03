//
//  Item.swift
//  DailyToDo
//
//  Created by Oz Soffy on 03/07/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
