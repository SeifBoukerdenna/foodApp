//
//  Item.swift
//  foodMap
//
//  Created by Malik Macbook on 2025-05-10.
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
