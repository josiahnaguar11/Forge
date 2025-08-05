//
//  Habit.swift
//  Forge
//
//  Created by Josiah Naguar on 05/08/2025.
//

import Foundation

enum HabitType: String, CaseIterable, Codable {
    case binary = "Binary"
    case quantitative = "Quantitative"
    case timer = "Timer"
    
    var description: String {
        switch self {
        case .binary:
            return "Simple yes/no completion"
        case .quantitative:
            return "Track a specific number or amount"
        case .timer:
            return "Track time spent on activity"
        }
    }
}

enum HabitCategory: String, CaseIterable, Codable {
    case build = "Build"
    case break = "Break"
    
    var description: String {
        switch self {
        case .build:
            return "Building a positive habit"
        case .break:
            return "Breaking a negative habit"
        }
    }
}

enum HabitFrequency: Codable, Equatable {
    case daily
    case specificDays([Int]) // 0 = Sunday, 1 = Monday, etc.
    case xTimesPerWeek(Int)
    
    var description: String {
        switch self {
        case .daily:
            return "Daily"
        case .specificDays(let days):
            let dayNames = days.map { Calendar.current.weekdaySymbols[$0] }.joined(separator = ", ")
            return dayNames
        case .xTimesPerWeek(let times):
            return "\(times) times per week"
        }
    }
}

struct Habit: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var pillar: Pillar
    var type: HabitType
    var category: HabitCategory
    var frequency: HabitFrequency
    var difficulty: Int // 1x, 2x, 3x multiplier for momentum score
    var isActive: Bool
    
    // Optional fields for behavior science
    var trigger: String?
    var recipe: String?
    
    // Type-specific properties
    var targetValue: Double? // For quantitative habits
    var unit: String? // e.g., "pages", "pushups", "minutes"
    var targetDuration: TimeInterval? // For timer habits in seconds
    
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String,
        pillar: Pillar,
        type: HabitType,
        category: HabitCategory = .build,
        frequency: HabitFrequency = .daily,
        difficulty: Int = 1,
        trigger: String? = nil,
        recipe: String? = nil,
        targetValue: Double? = nil,
        unit: String? = nil,
        targetDuration: TimeInterval? = nil
    ) {
        self.name = name
        self.pillar = pillar
        self.type = type
        self.category = category
        self.frequency = frequency
        self.difficulty = max(1, min(3, difficulty)) // Clamp between 1 and 3
        self.isActive = true
        self.trigger = trigger
        self.recipe = recipe
        self.targetValue = targetValue
        self.unit = unit
        self.targetDuration = targetDuration
        
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }
    
    // Helper methods
    var difficultyMultiplier: Double {
        return Double(difficulty)
    }
    
    var displayName: String {
        return name
    }
    
    var fullDescription: String {
        var desc = name
        if let targetValue = targetValue, let unit = unit {
            desc += " (\(Int(targetValue)) \(unit))"
        } else if let targetDuration = targetDuration {
            let minutes = Int(targetDuration / 60)
            desc += " (\(minutes) min)"
        }
        return desc
    }
    
    func shouldShowToday() -> Bool {
        guard isActive else { return false }
        
        let today = Calendar.current.component(.weekday, from: Date()) - 1 // 0-based
        
        switch frequency {
        case .daily:
            return true
        case .specificDays(let days):
            return days.contains(today)
        case .xTimesPerWeek(_):
            return true // Show daily, but track completion count
        }
    }
}