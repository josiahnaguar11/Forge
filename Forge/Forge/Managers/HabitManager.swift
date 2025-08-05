//
//  HabitManager.swift
//  Forge
//
//  Created by Josiah Naguar on 05/08/2025.
//

import Foundation
import SwiftUI

@MainActor
class HabitManager: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var habitLogs: [HabitLog] = []
    @Published var currentMomentumScore: Double = 0.0
    
    private let habitsKey = "forge_habits"
    private let logsKey = "forge_logs"
    
    init() {
        loadData()
        calculateMomentumScore()
    }
    
    // MARK: - Data Persistence
    
    private func loadData() {
        loadHabits()
        loadLogs()
    }
    
    private func loadHabits() {
        if let data = UserDefaults.standard.data(forKey: habitsKey),
           let decodedHabits = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decodedHabits
        } else {
            // Load sample data for development
            habits = createSampleHabits()
            saveHabits()
        }
    }
    
    private func loadLogs() {
        if let data = UserDefaults.standard.data(forKey: logsKey),
           let decodedLogs = try? JSONDecoder().decode([HabitLog].self, from: data) {
            habitLogs = decodedLogs
        }
    }
    
    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: habitsKey)
        }
    }
    
    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(habitLogs) {
            UserDefaults.standard.set(encoded, forKey: logsKey)
        }
    }
    
    // MARK: - Habit Operations
    
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveHabits()
        calculateMomentumScore()
    }
    
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            var updatedHabit = habit
            updatedHabit.updatedAt = Date()
            habits[index] = updatedHabit
            saveHabits()
            calculateMomentumScore()
        }
    }
    
    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        habitLogs.removeAll { $0.habitId == habit.id }
        saveHabits()
        saveLogs()
        calculateMomentumScore()
    }
    
    func toggleHabitActive(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index].isActive.toggle()
            habits[index].updatedAt = Date()
            saveHabits()
            calculateMomentumScore()
        }
    }
    
    // MARK: - Habit Logging
    
    func logHabit(_ habit: Habit, value: Double? = nil, duration: TimeInterval? = nil, notes: String? = nil) {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let existingLogIndex = habitLogs.firstIndex(where: { $0.habitId == habit.id && Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            // Update existing log
            habitLogs[existingLogIndex].markCompleted(value: value, duration: duration, notes: notes)
        } else {
            // Create new log
            var newLog = HabitLog(habitId: habit.id, date: today)
            newLog.markCompleted(value: value, duration: duration, notes: notes)
            habitLogs.append(newLog)
        }
        
        saveLogs()
        calculateMomentumScore()
        
        // Trigger haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func unlogHabit(_ habit: Habit) {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let existingLogIndex = habitLogs.firstIndex(where: { $0.habitId == habit.id && Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            habitLogs[existingLogIndex].markIncomplete()
            saveLogs()
            calculateMomentumScore()
        }
    }
    
    func isHabitCompletedToday(_ habit: Habit) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return habitLogs.first { $0.habitId == habit.id && Calendar.current.isDate($0.date, inSameDayAs: today) }?.isCompleted ?? false
    }
    
    func getTodaysLog(for habit: Habit) -> HabitLog? {
        let today = Calendar.current.startOfDay(for: Date())
        return habitLogs.first { $0.habitId == habit.id && Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    // MARK: - Analytics
    
    func getTodaysHabits() -> [Habit] {
        return habits.filter { $0.shouldShowToday() }
    }
    
    func getHabitStats(for habit: Habit) -> HabitStats {
        let logs = habitLogs.filter { $0.habitId == habit.id && $0.isCompleted }
        
        let totalCompletions = logs.count
        let currentStreak = calculateCurrentStreak(for: habit)
        let bestStreak = calculateBestStreak(for: habit)
        
        // Calculate average per week
        let calendar = Calendar.current
        let now = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let recentLogs = logs.filter { $0.date >= thirtyDaysAgo }
        let averagePerWeek = Double(recentLogs.count) * 7.0 / 30.0
        
        let lastCompleted = logs.sorted { $0.date > $1.date }.first?.date
        
        // Personal best for quantitative habits
        let personalBest = logs.compactMap { $0.value }.max()
        
        // Longest session for timer habits
        let longestSession = logs.compactMap { $0.duration }.max()
        
        // Consistency (last 30 days)
        let consistency = calculateConsistency(for: habit, days: 30)
        
        return HabitStats(
            habitId: habit.id,
            totalCompletions: totalCompletions,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            averagePerWeek: averagePerWeek,
            lastCompleted: lastCompleted,
            personalBest: personalBest,
            longestSession: longestSession,
            consistency: consistency
        )
    }
    
    func calculateCurrentStreak(for habit: Habit) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        // Check if today is completed first
        if !isHabitCompletedToday(habit) {
            return 0
        }
        
        while true {
            let isCompleted = habitLogs.first { $0.habitId == habit.id && calendar.isDate($0.date, inSameDayAs: currentDate) }?.isCompleted ?? false
            
            if isCompleted && habit.shouldShowOnDate(currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if habit.shouldShowOnDate(currentDate) {
                break
            } else {
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            }
        }
        
        return streak
    }
    
    func calculateBestStreak(for habit: Habit) -> Int {
        let calendar = Calendar.current
        let sortedLogs = habitLogs
            .filter { $0.habitId == habit.id && $0.isCompleted }
            .sorted { $0.date < $1.date }
        
        var bestStreak = 0
        var currentStreak = 0
        var lastDate: Date?
        
        for log in sortedLogs {
            if let last = lastDate {
                let daysBetween = calendar.dateComponents([.day], from: last, to: log.date).day ?? 0
                if daysBetween == 1 {
                    currentStreak += 1
                } else {
                    bestStreak = max(bestStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            lastDate = log.date
        }
        
        return max(bestStreak, currentStreak)
    }
    
    func calculateConsistency(for habit: Habit, days: Int) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: now) ?? now
        
        var completedDays = 0
        var requiredDays = 0
        
        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            
            if habit.shouldShowOnDate(date) {
                requiredDays += 1
                let isCompleted = habitLogs.first { $0.habitId == habit.id && calendar.isDate($0.date, inSameDayAs: date) }?.isCompleted ?? false
                if isCompleted {
                    completedDays += 1
                }
            }
        }
        
        guard requiredDays > 0 else { return 0.0 }
        return Double(completedDays) / Double(requiredDays)
    }
    
    // MARK: - Momentum Score Calculation
    
    func calculateMomentumScore() {
        let activeHabits = habits.filter { $0.isActive }
        guard !activeHabits.isEmpty else {
            currentMomentumScore = 0.0
            return
        }
        
        var totalWeightedScore = 0.0
        var totalWeight = 0.0
        
        for habit in activeHabits {
            let consistency = calculateConsistency(for: habit, days: 7) // Last week
            let streak = Double(calculateCurrentStreak(for: habit))
            let weight = habit.difficultyMultiplier
            
            // Momentum formula: weighted average of consistency and streak factor
            let streakFactor = min(streak / 7.0, 1.0) // Normalize streak to max of 7 days
            let habitScore = (consistency * 0.7 + streakFactor * 0.3) * 100
            
            totalWeightedScore += habitScore * weight
            totalWeight += weight
        }
        
        currentMomentumScore = totalWeight > 0 ? totalWeightedScore / totalWeight : 0.0
    }
    
    // MARK: - Helper Methods
    
    private func createSampleHabits() -> [Habit] {
        return [
            Habit(name: "Morning Workout", pillar: .health, type: .timer, difficulty: 3, targetDuration: 3600),
            Habit(name: "Read 20 Pages", pillar: .knowledge, type: .quantitative, difficulty: 2, targetValue: 20, unit: "pages"),
            Habit(name: "Meditate", pillar: .discipline, type: .timer, difficulty: 2, targetDuration: 600),
            Habit(name: "No Social Media After 10 PM", pillar: .discipline, type: .binary, category: .break, difficulty: 2),
            Habit(name: "Track Expenses", pillar: .wealth, type: .binary, difficulty: 1)
        ]
    }
}

// Extension for date checking
private extension Habit {
    func shouldShowOnDate(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date) - 1 // 0-based
        
        switch frequency {
        case .daily:
            return true
        case .specificDays(let days):
            return days.contains(weekday)
        case .xTimesPerWeek(_):
            return true
        }
    }
}