//
//  FocusManager.swift
//  Forge
//
//  Created by Josiah Naguar on 05/08/2025.
//

import Foundation
import SwiftUI
import UserNotifications

@MainActor
class FocusManager: ObservableObject {
    @Published var isInFocusMode = false
    @Published var currentSession: FocusSession?
    @Published var remainingTime: TimeInterval = 0
    @Published var blockedApps: [String] = []
    
    private var timer: Timer?
    private let habitManager: HabitManager
    
    init(habitManager: HabitManager) {
        self.habitManager = habitManager
        setupNotifications()
        loadBlockedApps()
    }
    
    // MARK: - Focus Session Management
    
    func startFocusSession(for habit: Habit, duration: TimeInterval) {
        let session = FocusSession(
            habitId: habit.id,
            habitName: habit.name,
            duration: duration,
            startTime: Date()
        )
        
        currentSession = session
        remainingTime = duration
        isInFocusMode = true
        
        startTimer()
        enableLockdown()
        scheduleNotifications(for: session)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    func pauseFocusSession() {
        guard let session = currentSession, !session.isPaused else { return }
        
        timer?.invalidate()
        currentSession?.isPaused = true
        
        // Disable lockdown while paused
        disableLockdown()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func resumeFocusSession() {
        guard let session = currentSession, session.isPaused else { return }
        
        currentSession?.isPaused = false
        startTimer()
        enableLockdown()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func endFocusSession(completed: Bool = true) {
        guard let session = currentSession else { return }
        
        timer?.invalidate()
        disableLockdown()
        cancelNotifications()
        
        let actualDuration = Date().timeIntervalSince(session.startTime) - session.pausedDuration
        
        if completed && actualDuration >= session.duration * 0.8 { // 80% completion threshold
            // Log the habit completion
            if let habit = habitManager.habits.first(where: { $0.id == session.habitId }) {
                habitManager.logHabit(habit, duration: actualDuration)
            }
            
            // Success haptic
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            
            // Schedule celebration notification
            scheduleCompletionNotification(for: session, actualDuration: actualDuration)
        } else {
            // Failure haptic
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
        }
        
        // Reset state
        currentSession = nil
        remainingTime = 0
        isInFocusMode = false
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
    }
    
    private func updateTimer() {
        guard let session = currentSession, !session.isPaused else { return }
        
        let elapsed = Date().timeIntervalSince(session.startTime) - session.pausedDuration
        remainingTime = max(0, session.duration - elapsed)
        
        if remainingTime <= 0 {
            endFocusSession(completed: true)
        }
    }
    
    // MARK: - App Blocking / Lockdown Mode
    
    private func loadBlockedApps() {
        // Load user's configured blocked apps
        blockedApps = UserDefaults.standard.stringArray(forKey: "blocked_apps") ?? [
            "com.instagram.Instagram",
            "com.zhiliaoapp.musically", // TikTok
            "com.reddit.Reddit",
            "com.twitter.twitter",
            "com.facebook.Facebook",
            "com.snapchat.snapchat"
        ]
    }
    
    func addBlockedApp(_ bundleId: String) {
        if !blockedApps.contains(bundleId) {
            blockedApps.append(bundleId)
            saveBlockedApps()
        }
    }
    
    func removeBlockedApp(_ bundleId: String) {
        blockedApps.removeAll { $0 == bundleId }
        saveBlockedApps()
    }
    
    private func saveBlockedApps() {
        UserDefaults.standard.set(blockedApps, forKey: "blocked_apps")
    }
    
    private func enableLockdown() {
        // Note: In a real app, this would integrate with Screen Time API
        // For now, we'll use notifications and visual cues
        scheduleBlockingReminders()
    }
    
    private func disableLockdown() {
        cancelBlockingReminders()
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }
    
    private func scheduleNotifications(for session: FocusSession) {
        let center = UNUserNotificationCenter.current()
        
        // Milestone notifications (25%, 50%, 75%)
        let milestones = [0.25, 0.5, 0.75]
        
        for milestone in milestones {
            let triggerTime = session.duration * milestone
            
            let content = UNMutableNotificationContent()
            content.title = "Focus Progress"
            content.body = "\(Int(milestone * 100))% complete. Keep going!"
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerTime, repeats: false)
            let request = UNNotificationRequest(
                identifier: "focus_milestone_\(milestone)_\(session.id)",
                content: content,
                trigger: trigger
            )
            
            center.add(request)
        }
    }
    
    private func scheduleCompletionNotification(for session: FocusSession, actualDuration: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Session Complete! 🎉"
        content.body = "You've completed \(session.habitName). Well done!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let request = UNNotificationRequest(
            identifier: "focus_complete_\(session.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleBlockingReminders() {
        guard !blockedApps.isEmpty else { return }
        
        // Schedule periodic reminders during focus mode
        let content = UNMutableNotificationContent()
        content.title = "Stay Focused"
        content.body = "You're in focus mode. Resist the urge to check distracting apps."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: true) // Every 5 minutes
        let request = UNNotificationRequest(
            identifier: "lockdown_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }
    
    private func cancelBlockingReminders() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["lockdown_reminder"])
    }
    
    // MARK: - Intelligent Notifications
    
    func scheduleIntelligentReminders() {
        let center = UNUserNotificationCenter.current()
        
        // Morning briefing
        scheduleMorningBriefing()
        
        // Contextual reminders based on habits
        scheduleContextualReminders()
        
        // Weekly review
        scheduleWeeklyReview()
    }
    
    private func scheduleMorningBriefing() {
        let content = UNMutableNotificationContent()
        
        let todaysHabits = habitManager.getTodaysHabits()
        let habitCount = todaysHabits.count
        let focusAreas = Array(Set(todaysHabits.map { $0.pillar.rawValue })).prefix(2).joined(separator: " & ")
        
        content.title = "Today's Forge"
        content.body = "\(habitCount) habits on deck. Your focus is \(focusAreas). Let's build."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 7
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "morning_briefing",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleContextualReminders() {
        // Example: Gym reminder after work hours
        let workoutHabits = habitManager.habits.filter { 
            $0.pillar == .health && $0.name.lowercased().contains("workout") || $0.name.lowercased().contains("gym")
        }
        
        for habit in workoutHabits {
            let content = UNMutableNotificationContent()
            content.title = "Perfect Timing"
            content.body = "You just finished work. Now is a great time to start your '\(habit.name)' habit."
            content.sound = .default
            
            var dateComponents = DateComponents()
            dateComponents.hour = 17 // 5 PM
            dateComponents.minute = 30
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "contextual_\(habit.id)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    private func scheduleWeeklyReview() {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Review"
        content.body = "Time to review your progress and plan for the week ahead."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 19 // 7 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly_review",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

struct FocusSession: Identifiable {
    let id = UUID()
    let habitId: UUID
    let habitName: String
    let duration: TimeInterval
    let startTime: Date
    var isPaused = false
    var pausedDuration: TimeInterval = 0
    
    var progress: Double {
        let elapsed = Date().timeIntervalSince(startTime) - pausedDuration
        return min(elapsed / duration, 1.0)
    }
    
    var remainingTimeString: String {
        let remaining = max(0, duration - (Date().timeIntervalSince(startTime) - pausedDuration))
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}