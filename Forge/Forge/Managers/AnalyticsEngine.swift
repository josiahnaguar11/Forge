//
//  AnalyticsEngine.swift
//  Forge
//
//  Created by Josiah Naguar on 05/08/2025.
//

import Foundation

struct CorrelationInsight {
    let id = UUID()
    let title: String
    let description: String
    let strength: Double // 0.0 to 1.0
    let type: CorrelationType
    let habitIds: [UUID]
    
    enum CorrelationType {
        case positive
        case negative
        case temporal
    }
    
    var strengthDescription: String {
        switch strength {
        case 0.8...1.0:
            return "Very Strong"
        case 0.6..<0.8:
            return "Strong"
        case 0.4..<0.6:
            return "Moderate"
        case 0.2..<0.4:
            return "Weak"
        default:
            return "Very Weak"
        }
    }
    
    var emoji: String {
        switch type {
        case .positive:
            return "🔗"
        case .negative:
            return "⚠️"
        case .temporal:
            return "⏰"
        }
    }
}

struct PillarPerformance {
    let pillar: Pillar
    let completionRate: Double
    let averageStreak: Double
    let momentum: Double
    let habitCount: Int
    let trend: Trend
    
    enum Trend {
        case improving
        case stable
        case declining
        
        var emoji: String {
            switch self {
            case .improving: return "📈"
            case .stable: return "➡️"
            case .declining: return "📉"
            }
        }
    }
}

@MainActor
class AnalyticsEngine: ObservableObject {
    @Published var correlationInsights: [CorrelationInsight] = []
    @Published var pillarPerformances: [PillarPerformance] = []
    @Published var personalRecords: [PersonalRecord] = []
    
    private let habitManager: HabitManager
    
    init(habitManager: HabitManager) {
        self.habitManager = habitManager
        calculateAnalytics()
    }
    
    func calculateAnalytics() {
        calculateCorrelations()
        calculatePillarPerformances()
        calculatePersonalRecords()
    }
    
    // MARK: - Correlation Analysis
    
    private func calculateCorrelations() {
        var insights: [CorrelationInsight] = []
        let habits = habitManager.habits.filter { $0.isActive }
        
        // Analyze habit-to-habit correlations
        for i in 0..<habits.count {
            for j in (i+1)..<habits.count {
                let habit1 = habits[i]
                let habit2 = habits[j]
                
                if let correlation = calculateHabitCorrelation(habit1, habit2) {
                    insights.append(correlation)
                }
            }
        }
        
        // Analyze temporal patterns
        for habit in habits {
            if let temporalInsight = analyzeTemporalPattern(habit) {
                insights.append(temporalInsight)
            }
        }
        
        // Sort by strength and take top insights
        correlationInsights = insights
            .sorted { $0.strength > $1.strength }
            .prefix(5)
            .map { $0 }
    }
    
    private func calculateHabitCorrelation(_ habit1: Habit, _ habit2: Habit) -> CorrelationInsight? {
        let calendar = Calendar.current
        let last30Days = (0..<30).compactMap { i in
            calendar.date(byAdding: .day, value: -i, to: Date())
        }
        
        var completionPairs: [(Bool, Bool)] = []
        
        for date in last30Days {
            let completed1 = habitManager.habitLogs.first { 
                $0.habitId == habit1.id && calendar.isDate($0.date, inSameDayAs: date) 
            }?.isCompleted ?? false
            
            let completed2 = habitManager.habitLogs.first { 
                $0.habitId == habit2.id && calendar.isDate($0.date, inSameDayAs: date) 
            }?.isCompleted ?? false
            
            completionPairs.append((completed1, completed2))
        }
        
        guard completionPairs.count >= 10 else { return nil }
        
        let correlation = calculatePearsonCorrelation(completionPairs)
        let absCorrelation = abs(correlation)
        
        guard absCorrelation > 0.3 else { return nil }
        
        let isPositive = correlation > 0
        let percentage = Int(absCorrelation * 100)
        
        let title: String
        let description: String
        let type: CorrelationInsight.CorrelationType
        
        if isPositive {
            title = "Synergy Detected"
            description = "You are \(percentage)% more likely to complete '\(habit2.name)' on days you complete '\(habit1.name)'"
            type = .positive
        } else {
            title = "Conflict Pattern"
            description = "Your '\(habit2.name)' success rate drops by \(percentage)% on days you complete '\(habit1.name)'"
            type = .negative
        }
        
        return CorrelationInsight(
            title: title,
            description: description,
            strength: absCorrelation,
            type: type,
            habitIds: [habit1.id, habit2.id]
        )
    }
    
    private func analyzeTemporalPattern(_ habit: Habit) -> CorrelationInsight? {
        let calendar = Calendar.current
        let last30Days = (0..<30).compactMap { i in
            calendar.date(byAdding: .day, value: -i, to: Date())
        }
        
        var weekdayCompletions = Array(repeating: 0, count: 7)
        var weekdayTotals = Array(repeating: 0, count: 7)
        
        for date in last30Days {
            let weekday = calendar.component(.weekday, from: date) - 1 // 0-based
            weekdayTotals[weekday] += 1
            
            let isCompleted = habitManager.habitLogs.first { 
                $0.habitId == habit.id && calendar.isDate($0.date, inSameDayAs: date) 
            }?.isCompleted ?? false
            
            if isCompleted {
                weekdayCompletions[weekday] += 1
            }
        }
        
        let completionRates = zip(weekdayCompletions, weekdayTotals).map { completed, total in
            total > 0 ? Double(completed) / Double(total) : 0.0
        }
        
        let maxRate = completionRates.max() ?? 0
        let minRate = completionRates.min() ?? 0
        let difference = maxRate - minRate
        
        guard difference > 0.3 else { return nil }
        
        let bestDayIndex = completionRates.firstIndex(of: maxRate) ?? 0
        let worstDayIndex = completionRates.firstIndex(of: minRate) ?? 0
        
        let dayNames = Calendar.current.weekdaySymbols
        let bestDay = dayNames[bestDayIndex]
        let worstDay = dayNames[worstDayIndex]
        
        let percentage = Int(difference * 100)
        
        return CorrelationInsight(
            title: "Weekly Pattern",
            description: "Your '\(habit.name)' success rate is \(percentage)% higher on \(bestDay)s than \(worstDay)s",
            strength: difference,
            type: .temporal,
            habitIds: [habit.id]
        )
    }
    
    private func calculatePearsonCorrelation(_ pairs: [(Bool, Bool)]) -> Double {
        let n = Double(pairs.count)
        let x = pairs.map { $0.0 ? 1.0 : 0.0 }
        let y = pairs.map { $0.1 ? 1.0 : 0.0 }
        
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        
        guard denominator != 0 else { return 0 }
        return numerator / denominator
    }
    
    // MARK: - Pillar Performance Analysis
    
    private func calculatePillarPerformances() {
        var performances: [PillarPerformance] = []
        
        for pillar in Pillar.allCases {
            let pillarHabits = habitManager.habits.filter { $0.pillar == pillar && $0.isActive }
            guard !pillarHabits.isEmpty else { continue }
            
            var totalCompletionRate = 0.0
            var totalStreak = 0.0
            var totalMomentum = 0.0
            
            for habit in pillarHabits {
                let stats = habitManager.getHabitStats(for: habit)
                totalCompletionRate += stats.consistency
                totalStreak += Double(stats.currentStreak)
                totalMomentum += stats.momentumScore
            }
            
            let habitCount = pillarHabits.count
            let avgCompletionRate = totalCompletionRate / Double(habitCount)
            let avgStreak = totalStreak / Double(habitCount)
            let avgMomentum = totalMomentum / Double(habitCount)
            
            // Calculate trend (simplified)
            let trend: PillarPerformance.Trend = avgMomentum > 70 ? .improving : 
                                                avgMomentum > 40 ? .stable : .declining
            
            performances.append(PillarPerformance(
                pillar: pillar,
                completionRate: avgCompletionRate,
                averageStreak: avgStreak,
                momentum: avgMomentum,
                habitCount: habitCount,
                trend: trend
            ))
        }
        
        pillarPerformances = performances.sorted { $0.momentum > $1.momentum }
    }
    
    // MARK: - Personal Records
    
    private func calculatePersonalRecords() {
        var records: [PersonalRecord] = []
        
        for habit in habitManager.habits {
            let stats = habitManager.getHabitStats(for: habit)
            
            // Best streak
            if stats.bestStreak > 0 {
                records.append(PersonalRecord(
                    id: UUID(),
                    habitId: habit.id,
                    habitName: habit.name,
                    type: .longestStreak,
                    value: Double(stats.bestStreak),
                    unit: "days",
                    achievedAt: stats.lastCompleted ?? Date()
                ))
            }
            
            // Personal best for quantitative habits
            if let personalBest = stats.personalBest, habit.type == .quantitative {
                records.append(PersonalRecord(
                    id: UUID(),
                    habitId: habit.id,
                    habitName: habit.name,
                    type: .personalBest,
                    value: personalBest,
                    unit: habit.unit ?? "",
                    achievedAt: Date() // Would need to track actual date
                ))
            }
            
            // Longest session for timer habits
            if let longestSession = stats.longestSession, habit.type == .timer {
                records.append(PersonalRecord(
                    id: UUID(),
                    habitId: habit.id,
                    habitName: habit.name,
                    type: .longestSession,
                    value: longestSession / 60, // Convert to minutes
                    unit: "minutes",
                    achievedAt: Date()
                ))
            }
        }
        
        personalRecords = records.sorted { $0.value > $1.value }
    }
}

struct PersonalRecord: Identifiable {
    let id: UUID
    let habitId: UUID
    let habitName: String
    let type: RecordType
    let value: Double
    let unit: String
    let achievedAt: Date
    
    enum RecordType {
        case longestStreak
        case personalBest
        case longestSession
        
        var title: String {
            switch self {
            case .longestStreak:
                return "Longest Streak"
            case .personalBest:
                return "Personal Best"
            case .longestSession:
                return "Longest Session"
            }
        }
        
        var icon: String {
            switch self {
            case .longestStreak:
                return "flame.fill"
            case .personalBest:
                return "star.fill"
            case .longestSession:
                return "timer"
            }
        }
    }
    
    var displayValue: String {
        let formattedValue = value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(format: "%.1f", value)
        return "\(formattedValue) \(unit)"
    }
}