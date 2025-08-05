//
//  HabitCardView.swift
//  Forge
//
//  Created by Josiah Naguar on 05/08/2025.
//

import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    @ObservedObject var habitManager: HabitManager
    @ObservedObject var focusManager: FocusManager
    
    @State private var isPressed = false
    @State private var pressProgress: Double = 0.0
    @State private var showingFlipAnimation = false
    @State private var showingValueInput = false
    @State private var inputValue = ""
    @State private var showingTimer = false
    @State private var pressTimer: Timer?
    
    private let pressHoldDuration: Double = 1.0
    private var isCompleted: Bool {
        habitManager.isHabitCompletedToday(habit)
    }
    
    var body: some View {
        ZStack {
            if showingFlipAnimation {
                completedCardView
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .transition(.asymmetric(insertion: .identity, removal: .opacity))
            } else {
                habitCardContent
                    .rotation3DEffect(.degrees(showingFlipAnimation ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                    .forgeBackgroundBlur(isActive: isPressed, intensity: pressProgress * 0.3)
            }
        }
        .animation(ForgeDesign.Animation.gentleSpring, value: showingFlipAnimation)
        .sheet(isPresented: $showingValueInput) {
            ValueInputView(
                habit: habit,
                onSubmit: { value in
                    completeHabit(value: value)
                }
            )
        }
        .sheet(isPresented: $showingTimer) {
            TimerView(
                habit: habit,
                focusManager: focusManager
            )
        }
    }
    
    // MARK: - Main Habit Card
    
    private var habitCardContent: some View {
        HStack(spacing: ForgeDesign.Spacing.md) {
            habitIcon
            habitInfo
            Spacer()
            habitStatus
        }
        .padding(ForgeDesign.Spacing.md)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md))
        .overlay(pressOverlay)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .blur(radius: showingFlipAnimation ? 2 : 0)
        .gesture(pressAndHoldGesture)
        .animation(ForgeDesign.Animation.smooth, value: isPressed)
        .animation(ForgeDesign.Animation.gentleSpring, value: pressProgress)
        .animation(ForgeDesign.Animation.medium, value: showingFlipAnimation)
        .zIndex(isPressed ? 1 : 0)
    }
    
    private var habitIcon: some View {
        ZStack {
            Circle()
                .fill(pillarColor)
                .frame(width: 48, height: 48)
            
            Image(systemName: habit.pillar.icon)
                .font(.title2)
                .foregroundColor(.white)
            
            if isCompleted {
                Circle()
                    .stroke(ForgeDesign.Colors.success, lineWidth: 3)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(ForgeDesign.Colors.success)
                            .background(
                                Circle()
                                    .fill(ForgeDesign.Colors.background)
                                    .frame(width: 16, height: 16)
                            )
                            .offset(x: 16, y: -16)
                    )
            }
        }
    }
    
    private var habitInfo: some View {
        VStack(alignment: .leading, spacing: ForgeDesign.Spacing.xs) {
            Text(habit.name)
                .font(ForgeDesign.Typography.headline)
                .foregroundColor(ForgeDesign.Colors.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.9)
            
            HStack(spacing: ForgeDesign.Spacing.xs) {
                Text(habit.pillar.rawValue)
                    .font(ForgeDesign.Typography.caption1)
                    .foregroundColor(pillarColor)
                    .lineLimit(1)
                    .fixedSize()
                
                Text("•")
                    .font(ForgeDesign.Typography.caption1)
                    .foregroundColor(ForgeDesign.Colors.textTertiary)
                
                Text(difficultyText)
                    .font(ForgeDesign.Typography.caption1)
                    .foregroundColor(ForgeDesign.Colors.textSecondary)
                    .lineLimit(1)
                    .fixedSize()
                
                if habit.type != .binary {
                    Text("•")
                        .font(ForgeDesign.Typography.caption1)
                        .foregroundColor(ForgeDesign.Colors.textTertiary)
                    
                    Text(targetText)
                        .font(ForgeDesign.Typography.caption1)
                        .foregroundColor(ForgeDesign.Colors.textSecondary)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var habitStatus: some View {
        VStack(alignment: .trailing, spacing: ForgeDesign.Spacing.xs) {
            if let todaysLog = habitManager.getTodaysLog(for: habit), todaysLog.isCompleted {
                Text(todaysLog.displayValue)
                    .font(ForgeDesign.Typography.habitValue)
                    .foregroundColor(ForgeDesign.Colors.success)
            } else {
                Text("TAP & HOLD")
                    .font(ForgeDesign.Typography.caption1)
                    .foregroundColor(ForgeDesign.Colors.textTertiary)
                    .tracking(0.5)
            }
            
            let stats = habitManager.getHabitStats(for: habit)
            if stats.currentStreak > 0 {
                HStack(spacing: ForgeDesign.Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundColor(ForgeDesign.Colors.warning)
                    
                    Text("\(stats.currentStreak)")
                        .font(ForgeDesign.Typography.streakNumber)
                        .foregroundColor(ForgeDesign.Colors.warning)
                }
            }
        }
    }
    
    // MARK: - Completed Card (Flip Side)
    
    private var completedCardView: some View {
        VStack(spacing: ForgeDesign.Spacing.md) {
            HStack {
                Text("✓ Completed")
                    .font(ForgeDesign.Typography.headline)
                    .foregroundColor(ForgeDesign.Colors.success)
                
                Spacer()
                
                Button("Undo") {
                    undoCompletion()
                }
                .font(ForgeDesign.Typography.caption1)
                .foregroundColor(ForgeDesign.Colors.accent)
            }
            
            SparklineView(habit: habit, habitManager: habitManager)
                .frame(height: 40)
        }
        .padding(ForgeDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                .fill(ForgeDesign.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                        .stroke(ForgeDesign.Colors.success.opacity(0.3), lineWidth: 1)
                )
        )
        .onTapGesture {
            withAnimation(ForgeDesign.Animation.medium) {
                showingFlipAnimation = false
            }
        }
    }
    
    // MARK: - Card Background & Overlay
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
            .fill(ForgeDesign.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                    .stroke(
                        isCompleted ? ForgeDesign.Colors.success.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: ForgeDesign.Shadow.small,
                radius: isPressed ? 6 : 4,
                x: 0,
                y: isPressed ? 3 : 2
            )
    }
    
    private var pressOverlay: some View {
        ZStack {
            // Base press overlay with glow effect
            RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                .stroke(
                    ForgeDesign.Colors.accent.opacity(pressProgress * 0.8),
                    lineWidth: 2
                )
                .shadow(
                    color: ForgeDesign.Colors.accent.opacity(pressProgress * 0.4),
                    radius: 8,
                    x: 0,
                    y: 0
                )
            
            // Subtle background fill during press
            RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                .fill(ForgeDesign.Colors.accent.opacity(pressProgress * 0.05))
            
            // Progress ring overlay
            RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                .trim(from: 0, to: pressProgress)
                .stroke(
                    ForgeDesign.Colors.accent,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .opacity(isPressed ? 1 : 0)
                .shadow(
                    color: ForgeDesign.Colors.accent.opacity(0.6),
                    radius: 4,
                    x: 0,
                    y: 0
                )
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Gesture & Actions
    
    private var pressAndHoldGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isPressed {
                    isPressed = true
                    startProgressTimer()
                }
            }
            .onEnded { _ in
                if pressProgress >= 1.0 {
                    completeHabitAction()
                }
                resetPressState()
            }
    }
    
    private func resetPressState() {
        pressTimer?.invalidate()
        pressTimer = nil
        
        withAnimation(ForgeDesign.Animation.smooth) {
            isPressed = false
        }
        
        withAnimation(ForgeDesign.Animation.gentleSpring) {
            pressProgress = 0.0
        }
    }
    
    private func startProgressTimer() {
        pressTimer?.invalidate()
        
        let updateInterval: TimeInterval = 0.03 // Increased to 30ms for smoother animation
        var startTime = Date()
        
        pressTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = elapsed / pressHoldDuration
            
            withAnimation(ForgeDesign.Animation.smooth) {
                pressProgress = min(progress, 1.0)
            }
            
            if progress >= 1.0 {
                timer.invalidate()
                completeHabitAction()
            }
        }
    }
    
    private func completeHabitAction() {
        guard pressProgress >= 1.0 else { return }
        
        switch habit.type {
        case .binary:
            completeHabit()
        case .quantitative:
            showingValueInput = true
        case .timer:
            showingTimer = true
        }
    }
    
    private func completeHabit(value: Double? = nil, duration: TimeInterval? = nil) {
        habitManager.logHabit(habit, value: value, duration: duration)
        
        // Show flip animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(ForgeDesign.Animation.gentleSpring) {
                showingFlipAnimation = true
            }
            
            // Auto-hide after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(ForgeDesign.Animation.gentleSpring) {
                    showingFlipAnimation = false
                }
            }
        }
    }
    
    private func undoCompletion() {
        habitManager.unlogHabit(habit)
        withAnimation(ForgeDesign.Animation.gentleSpring) {
            showingFlipAnimation = false
        }
    }
    
    // MARK: - Helper Properties
    
    private var pillarColor: Color {
        switch habit.pillar {
        case .health:
            return ForgeDesign.Colors.health
        case .wealth:
            return ForgeDesign.Colors.wealth
        case .knowledge:
            return ForgeDesign.Colors.knowledge
        case .discipline:
            return ForgeDesign.Colors.discipline
        case .social:
            return ForgeDesign.Colors.social
        }
    }
    
    private var difficultyText: String {
        switch habit.difficulty {
        case 1:
            return "Easy"
        case 2:
            return "Medium"
        case 3:
            return "Hard"
        default:
            return "Easy"
        }
    }
    
    private var targetText: String {
        switch habit.type {
        case .quantitative:
            if let target = habit.targetValue, let unit = habit.unit {
                return "\(Int(target)) \(unit)"
            }
        case .timer:
            if let target = habit.targetDuration {
                let minutes = Int(target / 60)
                return "\(minutes) min"
            }
        default:
            break
        }
        return ""
    }
}

// MARK: - Supporting Views

struct SparklineView: View {
    let habit: Habit
    @ObservedObject var habitManager: HabitManager
    
    private var recentLogs: [HabitLog] {
        let calendar = Calendar.current
        let last14Days = (0..<14).compactMap { i in
            calendar.date(byAdding: .day, value: -i, to: Date())
        }.reversed()
        
        return last14Days.map { date in
            habitManager.habitLogs.first { log in
                log.habitId == habit.id && calendar.isDate(log.date, inSameDayAs: date)
            } ?? HabitLog(habitId: habit.id, date: date)
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(recentLogs.enumerated()), id: \.offset) { index, log in
                Rectangle()
                    .fill(log.isCompleted ? ForgeDesign.Colors.success : ForgeDesign.Colors.surface)
                    .frame(width: 6)
                    .animation(ForgeDesign.Animation.fast.delay(Double(index) * 0.05), value: log.isCompleted)
            }
        }
    }
}

struct ValueInputView: View {
    let habit: Habit
    let onSubmit: (Double) -> Void
    
    @State private var inputValue = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: ForgeDesign.Spacing.lg) {
                VStack(spacing: ForgeDesign.Spacing.sm) {
                    Text(habit.name)
                        .font(ForgeDesign.Typography.title2)
                        .foregroundColor(ForgeDesign.Colors.textPrimary)
                    
                    if let unit = habit.unit {
                        Text("Enter \(unit)")
                            .font(ForgeDesign.Typography.subheadline)
                            .foregroundColor(ForgeDesign.Colors.textSecondary)
                    }
                }
                
                TextField("Value", text: $inputValue)
                    .font(ForgeDesign.Typography.largeTitle)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                
                if let unit = habit.unit {
                    Text(unit)
                        .font(ForgeDesign.Typography.headline)
                        .foregroundColor(ForgeDesign.Colors.textSecondary)
                }
                
                Button("Complete") {
                    if let value = Double(inputValue) {
                        onSubmit(value)
                        dismiss()
                    }
                }
                .font(ForgeDesign.Typography.headline)
                .foregroundColor(ForgeDesign.Colors.background)
                .padding(.horizontal, ForgeDesign.Spacing.xl)
                .padding(.vertical, ForgeDesign.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                        .fill(ForgeDesign.Colors.primaryGradient)
                )
                .disabled(inputValue.isEmpty)
                
                Spacer()
            }
            .padding(ForgeDesign.Spacing.lg)
            .background(ForgeDesign.Colors.background)
            .navigationTitle("Log Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TimerView: View {
    let habit: Habit
    @ObservedObject var focusManager: FocusManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: ForgeDesign.Spacing.xl) {
                Text(habit.name)
                    .font(ForgeDesign.Typography.title1)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                
                if let session = focusManager.currentSession {
                    FocusSessionView(session: session, focusManager: focusManager)
                } else {
                    TimerSetupView(habit: habit, focusManager: focusManager)
                }
                
                Spacer()
            }
            .padding(ForgeDesign.Spacing.lg)
            .background(ForgeDesign.Colors.background)
            .navigationTitle("Focus Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TimerSetupView: View {
    let habit: Habit
    @ObservedObject var focusManager: FocusManager
    @State private var selectedDuration: TimeInterval
    
    init(habit: Habit, focusManager: FocusManager) {
        self.habit = habit
        self.focusManager = focusManager
        self._selectedDuration = State(initialValue: habit.targetDuration ?? 1800) // Default 30 minutes
    }
    
    private let durations: [TimeInterval] = [
        900,   // 15 min
        1800,  // 30 min
        2700,  // 45 min
        3600,  // 60 min
        5400,  // 90 min
        7200   // 120 min
    ]
    
    var body: some View {
        VStack(spacing: ForgeDesign.Spacing.lg) {
            Text("Select duration")
                .font(ForgeDesign.Typography.headline)
                .foregroundColor(ForgeDesign.Colors.textSecondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ForgeDesign.Spacing.md) {
                ForEach(durations, id: \.self) { duration in
                    Button(action: { selectedDuration = duration }) {
                        Text("\(Int(duration/60)) min")
                            .font(ForgeDesign.Typography.headline)
                            .foregroundColor(selectedDuration == duration ? ForgeDesign.Colors.background : ForgeDesign.Colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(ForgeDesign.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                                    .fill(selectedDuration == duration ? ForgeDesign.Colors.accent : ForgeDesign.Colors.surface)
                            )
                    }
                }
            }
            
            Button("Start Focus Session") {
                focusManager.startFocusSession(for: habit, duration: selectedDuration)
            }
            .font(ForgeDesign.Typography.headline)
            .foregroundColor(ForgeDesign.Colors.background)
            .padding(.horizontal, ForgeDesign.Spacing.xl)
            .padding(.vertical, ForgeDesign.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                    .fill(ForgeDesign.Colors.primaryGradient)
            )
        }
    }
}

struct FocusSessionView: View {
    let session: FocusSession
    @ObservedObject var focusManager: FocusManager
    
    var body: some View {
        VStack(spacing: ForgeDesign.Spacing.xl) {
            Text(session.remainingTimeString)
                .font(ForgeDesign.Typography.largeTitle)
                .foregroundColor(ForgeDesign.Colors.textPrimary)
                .forgeGlow(color: ForgeDesign.Colors.accent, radius: 8)
            
            ProgressRingView(progress: session.progress)
                .frame(width: 200, height: 200)
            
            HStack(spacing: ForgeDesign.Spacing.lg) {
                if session.isPaused {
                    Button("Resume") {
                        focusManager.resumeFocusSession()
                    }
                    .font(ForgeDesign.Typography.headline)
                    .foregroundColor(ForgeDesign.Colors.background)
                    .padding(.horizontal, ForgeDesign.Spacing.lg)
                    .padding(.vertical, ForgeDesign.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.sm)
                            .fill(ForgeDesign.Colors.success)
                    )
                } else {
                    Button("Pause") {
                        focusManager.pauseFocusSession()
                    }
                    .font(ForgeDesign.Typography.headline)
                    .foregroundColor(ForgeDesign.Colors.background)
                    .padding(.horizontal, ForgeDesign.Spacing.lg)
                    .padding(.vertical, ForgeDesign.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.sm)
                            .fill(ForgeDesign.Colors.warning)
                    )
                }
                
                Button("End") {
                    focusManager.endFocusSession(completed: false)
                }
                .font(ForgeDesign.Typography.headline)
                .foregroundColor(ForgeDesign.Colors.textPrimary)
                .padding(.horizontal, ForgeDesign.Spacing.lg)
                .padding(.vertical, ForgeDesign.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.sm)
                        .stroke(ForgeDesign.Colors.textSecondary, lineWidth: 1)
                )
            }
        }
    }
}

struct ProgressRingView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(ForgeDesign.Colors.surface, lineWidth: 12)
            
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(
                    ForgeDesign.Colors.primaryGradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(ForgeDesign.Animation.medium, value: progress)
        }
    }
}

#Preview {
    VStack {
        HabitCardView(
            habit: Habit(name: "Morning Workout", pillar: .health, type: .timer, difficulty: 3),
            habitManager: HabitManager(),
            focusManager: FocusManager(habitManager: HabitManager())
        )
        
        HabitCardView(
            habit: Habit(name: "Read 20 Pages", pillar: .knowledge, type: .quantitative, targetValue: 20, unit: "pages"),
            habitManager: HabitManager(),
            focusManager: FocusManager(habitManager: HabitManager())
        )
    }
    .padding()
    .background(ForgeDesign.Colors.background)
    .preferredColorScheme(.dark)
}