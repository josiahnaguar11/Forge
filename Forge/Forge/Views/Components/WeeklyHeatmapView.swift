//
//  WeeklyHeatmapView.swift
//  Forge
//
//  Created by Josiah Naguar on 05/08/2025.
//

import SwiftUI

struct WeeklyHeatmapView: View {
    @ObservedObject var habitManager: HabitManager
    
    private let days = Calendar.current.shortWeekdaySymbols
    private var weekData: [(Date, Double)] {
        let calendar = Calendar.current
        let today = Date()
        
        return (0..<7).compactMap { i in
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { return nil }
            let activity = calculateActivityScore(for: date)
            return (date, activity)
        }.reversed()
    }
    
    var body: some View {
        VStack(spacing: ForgeDesign.Spacing.sm) {
            HStack {
                ForEach(Array(weekData.enumerated()), id: \.offset) { index, data in
                    VStack(spacing: ForgeDesign.Spacing.xs) {
                        Text(days[index])
                            .font(ForgeDesign.Typography.caption1)
                            .foregroundColor(ForgeDesign.Colors.textTertiary)
                        
                        RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.sm)
                            .fill(activityColor(for: data.1))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text("\(Calendar.current.component(.day, from: data.0))")
                                    .font(ForgeDesign.Typography.caption2)
                                    .foregroundColor(data.1 > 0.3 ? .white : ForgeDesign.Colors.textSecondary)
                            )
                            .animation(ForgeDesign.Animation.fast.delay(Double(index) * 0.1), value: data.1)
                    }
                    
                    if index < weekData.count - 1 {
                        Spacer()
                    }
                }
            }
            
            HStack {
                Text("Less")
                    .font(ForgeDesign.Typography.caption2)
                    .foregroundColor(ForgeDesign.Colors.textTertiary)
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(activityColor(for: Double(level) / 4.0))
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text("More")
                    .font(ForgeDesign.Typography.caption2)
                    .foregroundColor(ForgeDesign.Colors.textTertiary)
                
                Spacer()
            }
        }
    }
    
    private func calculateActivityScore(for date: Date) -> Double {
        let calendar = Calendar.current
        let habitsForDay = habitManager.habits.filter { habit in
            habit.shouldShowToday() // This would need modification to check specific dates
        }
        
        guard !habitsForDay.isEmpty else { return 0.0 }
        
        let completedCount = habitsForDay.filter { habit in
            habitManager.habitLogs.contains { log in
                log.habitId == habit.id && 
                calendar.isDate(log.date, inSameDayAs: date) && 
                log.isCompleted
            }
        }.count
        
        return Double(completedCount) / Double(habitsForDay.count)
    }
    
    private func activityColor(for score: Double) -> Color {
        switch score {
        case 0:
            return ForgeDesign.Colors.surface
        case 0.01..<0.25:
            return ForgeDesign.Colors.accent.opacity(0.3)
        case 0.25..<0.5:
            return ForgeDesign.Colors.accent.opacity(0.5)
        case 0.5..<0.75:
            return ForgeDesign.Colors.accent.opacity(0.7)
        default:
            return ForgeDesign.Colors.accent
        }
    }
}

#Preview {
    WeeklyHeatmapView(habitManager: HabitManager())
        .padding()
        .background(ForgeDesign.Colors.background)
        .preferredColorScheme(.dark)
}