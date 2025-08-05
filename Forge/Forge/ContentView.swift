//
//  ContentView.swift
//  Forge
//
//  Created by Josiah Naguar on 05/08/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var habitManager = HabitManager()
    @StateObject private var focusManager: FocusManager
    @StateObject private var analyticsEngine: AnalyticsEngine
    
    init() {
        let habitManager = HabitManager()
        let focusManager = FocusManager(habitManager: habitManager)
        let analyticsEngine = AnalyticsEngine(habitManager: habitManager)
        
        self._habitManager = StateObject(wrappedValue: habitManager)
        self._focusManager = StateObject(wrappedValue: focusManager)
        self._analyticsEngine = StateObject(wrappedValue: analyticsEngine)
    }
    
    var body: some View {
        TabView {
            DashboardView(
                habitManager: habitManager,
                focusManager: focusManager,
                analyticsEngine: analyticsEngine
            )
            .tabItem {
                Image(systemName: "square.grid.2x2")
                Text("Dashboard")
            }
            
            CodexView(
                habitManager: habitManager,
                analyticsEngine: analyticsEngine
            )
            .tabItem {
                Image(systemName: "chart.bar.xaxis")
                Text("Codex")
            }
            
            HabitsListView(
                habitManager: habitManager
            )
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Habits")
            }
            
            if focusManager.isInFocusMode {
                FocusModeView(focusManager: focusManager)
                    .tabItem {
                        Image(systemName: "target")
                        Text("Focus")
                    }
            }
        }
        .tint(ForgeDesign.Colors.accent)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Codex View

struct CodexView: View {
    @ObservedObject var habitManager: HabitManager
    @ObservedObject var analyticsEngine: AnalyticsEngine
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: ForgeDesign.Spacing.lg) {
                    pillarPerformanceSection
                    correlationInsightsSection
                    personalRecordsSection
                }
                .padding(ForgeDesign.Spacing.md)
            }
            .background(ForgeDesign.Colors.background)
            .navigationTitle("The Codex")
            .onAppear {
                analyticsEngine.calculateAnalytics()
            }
        }
    }
    
    private var pillarPerformanceSection: some View {
        VStack(alignment: .leading, spacing: ForgeDesign.Spacing.md) {
            Text("PILLAR PERFORMANCE")
                .font(ForgeDesign.Typography.headline)
                .foregroundColor(ForgeDesign.Colors.textPrimary)
            
            LazyVStack(spacing: ForgeDesign.Spacing.sm) {
                ForEach(analyticsEngine.pillarPerformances, id: \.pillar) { performance in
                    PillarPerformanceCard(performance: performance)
                }
            }
        }
        .forgeCard()
    }
    
    private var correlationInsightsSection: some View {
        VStack(alignment: .leading, spacing: ForgeDesign.Spacing.md) {
            Text("CORRELATION INSIGHTS")
                .font(ForgeDesign.Typography.headline)
                .foregroundColor(ForgeDesign.Colors.textPrimary)
            
            if analyticsEngine.correlationInsights.isEmpty {
                Text("Complete more habits to unlock insights")
                    .font(ForgeDesign.Typography.subheadline)
                    .foregroundColor(ForgeDesign.Colors.textSecondary)
            } else {
                LazyVStack(spacing: ForgeDesign.Spacing.sm) {
                    ForEach(analyticsEngine.correlationInsights, id: \.id) { insight in
                        InsightCardView(insight: insight)
                    }
                }
            }
        }
        .forgeCard()
    }
    
    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: ForgeDesign.Spacing.md) {
            Text("PERSONAL RECORDS")
                .font(ForgeDesign.Typography.headline)
                .foregroundColor(ForgeDesign.Colors.textPrimary)
            
            if analyticsEngine.personalRecords.isEmpty {
                Text("Start completing habits to set records")
                    .font(ForgeDesign.Typography.subheadline)
                    .foregroundColor(ForgeDesign.Colors.textSecondary)
            } else {
                LazyVStack(spacing: ForgeDesign.Spacing.sm) {
                    ForEach(analyticsEngine.personalRecords.prefix(5)) { record in
                        PersonalRecordCard(record: record)
                    }
                }
            }
        }
        .forgeCard()
    }
}

// MARK: - Habits List View

struct HabitsListView: View {
    @ObservedObject var habitManager: HabitManager
    @State private var showingAddHabit = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(habitManager.habits) { habit in
                    HabitRowView(habit: habit, habitManager: habitManager)
                        .listRowBackground(ForgeDesign.Colors.surface)
                        .listRowSeparator(.hidden)
                }
                .onDelete(perform: deleteHabits)
            }
            .listStyle(.plain)
            .background(ForgeDesign.Colors.background)
            .navigationTitle("All Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddHabit = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(habitManager: habitManager)
            }
        }
    }
    
    private func deleteHabits(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                habitManager.deleteHabit(habitManager.habits[index])
            }
        }
    }
}

// MARK: - Focus Mode View

struct FocusModeView: View {
    @ObservedObject var focusManager: FocusManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: ForgeDesign.Spacing.xl) {
                if let session = focusManager.currentSession {
                    VStack(spacing: ForgeDesign.Spacing.lg) {
                        Text("FOCUS SESSION")
                            .font(ForgeDesign.Typography.caption1)
                            .foregroundColor(ForgeDesign.Colors.textTertiary)
                            .tracking(1.0)
                        
                        Text(session.habitName)
                            .font(ForgeDesign.Typography.title1)
                            .foregroundColor(ForgeDesign.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text(session.remainingTimeString)
                            .font(ForgeDesign.Typography.largeTitle)
                            .foregroundColor(ForgeDesign.Colors.accent)
                            .forgeGlow(color: ForgeDesign.Colors.accent, radius: 8)
                        
                        ProgressRingView(progress: session.progress)
                            .frame(width: 250, height: 250)
                        
                        HStack(spacing: ForgeDesign.Spacing.lg) {
                            if session.isPaused {
                                Button("Resume") {
                                    focusManager.resumeFocusSession()
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            } else {
                                Button("Pause") {
                                    focusManager.pauseFocusSession()
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }
                            
                            Button("End Session") {
                                focusManager.endFocusSession(completed: false)
                            }
                            .buttonStyle(TertiaryButtonStyle())
                        }
                    }
                } else {
                    EmptyStateView(
                        icon: "target",
                        title: "No active session",
                        subtitle: "Start a timer habit to begin a focus session",
                        action: {}
                    )
                }
                
                Spacer()
            }
            .padding(ForgeDesign.Spacing.lg)
            .background(ForgeDesign.Colors.background)
            .navigationTitle("Focus")
        }
    }
}

// MARK: - Supporting Views

struct PillarPerformanceCard: View {
    let performance: PillarPerformance
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: ForgeDesign.Spacing.xs) {
                HStack {
                    Image(systemName: performance.pillar.icon)
                        .foregroundColor(pillarColor)
                    
                    Text(performance.pillar.rawValue)
                        .font(ForgeDesign.Typography.headline)
                        .foregroundColor(ForgeDesign.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text(performance.trend.emoji)
                        .font(.title2)
                }
                
                Text("\(Int(performance.completionRate * 100))% completion rate")
                    .font(ForgeDesign.Typography.subheadline)
                    .foregroundColor(ForgeDesign.Colors.textSecondary)
                
                Text("\(performance.habitCount) habits")
                    .font(ForgeDesign.Typography.caption1)
                    .foregroundColor(ForgeDesign.Colors.textTertiary)
            }
            
            Spacer()
            
            VStack {
                Text(String(format: "%.0f", performance.momentum))
                    .font(ForgeDesign.Typography.title2)
                    .foregroundColor(pillarColor)
                
                Text("MOMENTUM")
                    .font(ForgeDesign.Typography.caption1)
                    .foregroundColor(ForgeDesign.Colors.textTertiary)
                    .tracking(0.5)
            }
        }
        .padding(ForgeDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                .fill(ForgeDesign.Colors.surfaceElevated)
        )
    }
    
    private var pillarColor: Color {
        switch performance.pillar {
        case .health: return ForgeDesign.Colors.health
        case .wealth: return ForgeDesign.Colors.wealth
        case .knowledge: return ForgeDesign.Colors.knowledge
        case .discipline: return ForgeDesign.Colors.discipline
        case .social: return ForgeDesign.Colors.social
        }
    }
}

struct PersonalRecordCard: View {
    let record: PersonalRecord
    
    var body: some View {
        HStack {
            Image(systemName: record.type.icon)
                .font(.title2)
                .foregroundColor(ForgeDesign.Colors.accent)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: ForgeDesign.Spacing.xs) {
                Text(record.habitName)
                    .font(ForgeDesign.Typography.headline)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                
                Text(record.type.title)
                    .font(ForgeDesign.Typography.caption1)
                    .foregroundColor(ForgeDesign.Colors.textSecondary)
            }
            
            Spacer()
            
            Text(record.displayValue)
                .font(ForgeDesign.Typography.title3)
                .foregroundColor(ForgeDesign.Colors.accent)
        }
        .padding(ForgeDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                .fill(ForgeDesign.Colors.surfaceElevated)
        )
    }
}

struct HabitRowView: View {
    let habit: Habit
    @ObservedObject var habitManager: HabitManager
    
    var body: some View {
        HStack {
            Image(systemName: habit.pillar.icon)
                .foregroundColor(pillarColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: ForgeDesign.Spacing.xs) {
                Text(habit.name)
                    .font(ForgeDesign.Typography.headline)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.9)
                
                HStack {
                    Text(habit.pillar.rawValue)
                        .font(ForgeDesign.Typography.caption1)
                        .foregroundColor(pillarColor)
                        .lineLimit(1)
                        .fixedSize()
                    
                    Text("•")
                        .font(ForgeDesign.Typography.caption1)
                        .foregroundColor(ForgeDesign.Colors.textTertiary)
                    
                    Text(habit.frequency.description)
                        .font(ForgeDesign.Typography.caption1)
                        .foregroundColor(ForgeDesign.Colors.textSecondary)
                        .lineLimit(1)
                        .fixedSize()
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { habit.isActive },
                set: { _ in habitManager.toggleHabitActive(habit) }
            ))
            .tint(ForgeDesign.Colors.accent)
        }
        .padding(.vertical, ForgeDesign.Spacing.xs)
    }
    
    private var pillarColor: Color {
        switch habit.pillar {
        case .health: return ForgeDesign.Colors.health
        case .wealth: return ForgeDesign.Colors.wealth
        case .knowledge: return ForgeDesign.Colors.knowledge
        case .discipline: return ForgeDesign.Colors.discipline
        case .social: return ForgeDesign.Colors.social
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ForgeDesign.Typography.headline)
            .foregroundColor(ForgeDesign.Colors.background)
            .padding(.horizontal, ForgeDesign.Spacing.lg)
            .padding(.vertical, ForgeDesign.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                    .fill(ForgeDesign.Colors.primaryGradient)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(ForgeDesign.Animation.fast, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ForgeDesign.Typography.headline)
            .foregroundColor(ForgeDesign.Colors.background)
            .padding(.horizontal, ForgeDesign.Spacing.lg)
            .padding(.vertical, ForgeDesign.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                    .fill(ForgeDesign.Colors.warning)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(ForgeDesign.Animation.fast, value: configuration.isPressed)
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ForgeDesign.Typography.headline)
            .foregroundColor(ForgeDesign.Colors.textPrimary)
            .padding(.horizontal, ForgeDesign.Spacing.lg)
            .padding(.vertical, ForgeDesign.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                    .stroke(ForgeDesign.Colors.textSecondary, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(ForgeDesign.Animation.fast, value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
