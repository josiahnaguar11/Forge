//
//  DashboardView.swift
//  Forge
//
//  Created by Josiah Naguar on 05/08/2025.
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var habitManager: HabitManager
    @ObservedObject var focusManager: FocusManager
    @ObservedObject var analyticsEngine: AnalyticsEngine
    
    @State private var showingAddHabit = false
    @State private var selectedHabit: Habit?
    @State private var isAnyCardPressed = false
    @State private var pressIntensity: Double = 0.0
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: ForgeDesign.Spacing.lg) {
                headerSection
                    .forgeGlobalBlur(isActive: isAnyCardPressed, intensity: pressIntensity * 0.5)
                momentumScoreSection
                    .forgeGlobalBlur(isActive: isAnyCardPressed, intensity: pressIntensity * 0.5)
                todaysForgeSection
                weeklyHeatmapSection
                    .forgeGlobalBlur(isActive: isAnyCardPressed, intensity: pressIntensity * 0.5)
                insightsSection
                    .forgeGlobalBlur(isActive: isAnyCardPressed, intensity: pressIntensity * 0.5)
            }
            .padding(ForgeDesign.Spacing.md)
        }
        .background(ForgeDesign.Colors.background)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView(habitManager: habitManager)
        }
        .onAppear {
            analyticsEngine.calculateAnalytics()
            focusManager.scheduleIntelligentReminders()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: ForgeDesign.Spacing.xs) {
                Text(greetingText)
                    .font(ForgeDesign.Typography.title2)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                
                Text("Time to forge your day")
                    .font(ForgeDesign.Typography.subheadline)
                    .foregroundColor(ForgeDesign.Colors.textSecondary)
            }
            
            Spacer()
            
            Button(action: { showingAddHabit = true }) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(ForgeDesign.Colors.accent)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(ForgeDesign.Colors.surface)
                            .shadow(color: ForgeDesign.Shadow.small, radius: 4, x: 0, y: 2)
                    )
            }
            .forgePressable()
        }
    }
    
    // MARK: - Momentum Score Section
    
    private var momentumScoreSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: ForgeDesign.Spacing.sm) {
                Text("MOMENTUM SCORE")
                    .font(ForgeDesign.Typography.caption1)
                    .foregroundColor(ForgeDesign.Colors.textTertiary)
                    .tracking(1.0)
                
                Text(String(format: "%.0f", habitManager.currentMomentumScore))
                    .font(ForgeDesign.Typography.momentumScore)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                    .forgeGlow(color: momentumColor, radius: 6)
                
                Text(momentumDescription)
                    .font(ForgeDesign.Typography.footnote)
                    .foregroundColor(ForgeDesign.Colors.textSecondary)
            }
            
            Spacer()
            
            MomentumRingView(score: habitManager.currentMomentumScore)
                .frame(width: 80, height: 80)
        }
        .forgeCard(elevated: true)
    }
    
    private var momentumColor: Color {
        switch habitManager.currentMomentumScore {
        case 80...100:
            return ForgeDesign.Colors.success
        case 60..<80:
            return ForgeDesign.Colors.accent
        case 40..<60:
            return ForgeDesign.Colors.warning
        default:
            return ForgeDesign.Colors.error
        }
    }
    
    private var momentumDescription: String {
        switch habitManager.currentMomentumScore {
        case 80...100:
            return "Exceptional momentum"
        case 60..<80:
            return "Strong momentum"
        case 40..<60:
            return "Building momentum"
        case 20..<40:
            return "Gaining momentum"
        default:
            return "Ready to build"
        }
    }
    
    // MARK: - Today's Forge Section
    
    private var todaysForgeSection: some View {
        VStack(alignment: .leading, spacing: ForgeDesign.Spacing.md) {
            HStack {
                Text("TODAY'S FORGE")
                    .font(ForgeDesign.Typography.headline)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                
                Spacer()
                
                Text("\(completedHabitsToday)/\(todaysHabits.count)")
                    .font(ForgeDesign.Typography.subheadline)
                    .foregroundColor(ForgeDesign.Colors.textSecondary)
            }
            
            if todaysHabits.isEmpty {
                EmptyStateView(
                    icon: "target",
                    title: "No habits for today",
                    subtitle: "Add your first habit to start building",
                    action: { showingAddHabit = true }
                )
            } else {
                LazyVStack(spacing: ForgeDesign.Spacing.sm) {
                    ForEach(todaysHabits) { habit in
                        HabitCardView(
                            habit: habit,
                            habitManager: habitManager,
                            focusManager: focusManager
                        )
                    }
                }
            }
        }
    }
    
    private var todaysHabits: [Habit] {
        habitManager.getTodaysHabits()
    }
    
    private var completedHabitsToday: Int {
        todaysHabits.filter { habitManager.isHabitCompletedToday($0) }.count
    }
    
    // MARK: - Weekly Heatmap Section
    
    private var weeklyHeatmapSection: some View {
        VStack(alignment: .leading, spacing: ForgeDesign.Spacing.md) {
            Text("WEEKLY ACTIVITY")
                .font(ForgeDesign.Typography.headline)
                .foregroundColor(ForgeDesign.Colors.textPrimary)
            
            WeeklyHeatmapView(habitManager: habitManager)
        }
        .forgeCard()
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: ForgeDesign.Spacing.md) {
            Text("INSIGHTS")
                .font(ForgeDesign.Typography.headline)
                .foregroundColor(ForgeDesign.Colors.textPrimary)
            
            if analyticsEngine.correlationInsights.isEmpty {
                Text("Complete more habits to unlock insights")
                    .font(ForgeDesign.Typography.subheadline)
                    .foregroundColor(ForgeDesign.Colors.textSecondary)
            } else {
                LazyVStack(spacing: ForgeDesign.Spacing.sm) {
                    ForEach(analyticsEngine.correlationInsights.prefix(3), id: \.id) { insight in
                        InsightCardView(insight: insight)
                    }
                }
            }
        }
        .forgeCard()
    }
    
    // MARK: - Helper Properties
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }
}

// MARK: - Supporting Views

struct MomentumRingView: View {
    let score: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(ForgeDesign.Colors.surface, lineWidth: 8)
            
            Circle()
                .trim(from: 0.0, to: score / 100.0)
                .stroke(
                    ForgeDesign.Colors.primaryGradient,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(ForgeDesign.Animation.spring, value: score)
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: ForgeDesign.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(ForgeDesign.Colors.textTertiary)
            
            VStack(spacing: ForgeDesign.Spacing.xs) {
                Text(title)
                    .font(ForgeDesign.Typography.headline)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                
                Text(subtitle)
                    .font(ForgeDesign.Typography.subheadline)
                    .foregroundColor(ForgeDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add Habit", action: action)
                .font(ForgeDesign.Typography.headline)
                .foregroundColor(ForgeDesign.Colors.background)
                .padding(.horizontal, ForgeDesign.Spacing.lg)
                .padding(.vertical, ForgeDesign.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.sm)
                        .fill(ForgeDesign.Colors.primaryGradient)
                )
                .forgePressable()
        }
        .padding(ForgeDesign.Spacing.xl)
    }
}

#Preview {
    NavigationView {
        DashboardView(
            habitManager: HabitManager(),
            focusManager: FocusManager(habitManager: HabitManager()),
            analyticsEngine: AnalyticsEngine(habitManager: HabitManager())
        )
    }
    .preferredColorScheme(.dark)
}