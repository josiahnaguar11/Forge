//
//  HabitLog.swift
//  Forge
//
//  Created by Josiah Naguar on 05/08/2025.
//

import Foundation

struct HabitLog: Identifiable, Codable, Hashable {
    let id = UUID()
    let habitId: UUID
    let date: Date
    var isCompleted: Bool
    
    // For quantitative habits
    var value: Double?
    
    // For timer habits
    var duration: TimeInterval?
    
    // Metadata
    var completedAt: Date?
    var notes: String?
    
    init(
        habitId: UUID,
        date: Date = Date(),
        isCompleted: Bool = false,
        value: Double? = nil,
        duration: TimeInterval? = nil,
        notes: String? = nil
    ) {
        self.habitId = habitId
        self.date = Calendar.current.startOfDay(for: date)
        self.isCompleted = isCompleted
        self.value = value
        self.duration = duration
        self.notes = notes
        
        if isCompleted {
            self.completedAt = Date()
        }
    }
    
    mutating func markCompleted(value: Double? = nil, duration: TimeInterval? = nil, notes: String? = nil) {
        self.isCompleted = true
        self.completedAt = Date()
        self.value = value
        self.duration = duration
        if let notes = notes {
            self.notes = notes
        }
    }
    
    mutating func markIncomplete() {
        self.isCompleted = false
        self.completedAt = nil
        self.value = nil
        self.duration = nil
    }
    
    var displayValue: String {
        if let value = value {
            return String(format: "%.0f", value)
        } else if let duration = duration {
            let minutes = Int(duration / 60)
            let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
            if minutes > 0 {
                return "\(minutes)m \(seconds)s"
            } else {
                return "\(seconds)s"
            }
        }
        return ""
    }
}

struct WeeklyStats: Codable {
    let habitId: UUID
    let weekStartDate: Date
    let completionCount: Int
    let totalPossible: Int
    let averageValue: Double?
    let totalDuration: TimeInterval?
    let bestDay: Date?
    let consistency: Double // 0.0 to 1.0
    
    var completionRate: Double {
        guard totalPossible > 0 else { return 0.0 }
        return Double(completionCount) / Double(totalPossible)
    }
}

struct HabitStats: Codable {
    let habitId: UUID
    let totalCompletions: Int
    let currentStreak: Int
    let bestStreak: Int
    let averagePerWeek: Double
    let lastCompleted: Date?
    let personalBest: Double? // For quantitative habits
    let longestSession: TimeInterval? // For timer habits
    let consistency: Double // Last 30 days completion rate
    
    var momentumScore: Double {
        let streakFactor = min(Double(currentStreak) / 30.0, 1.0)
        let consistencyFactor = consistency
        return (streakFactor * 0.4 + consistencyFactor * 0.6) * 100
    }
}