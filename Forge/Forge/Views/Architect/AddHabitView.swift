//
//  AddHabitView.swift
//  Forge
//
//  Created by Josiah Naguar on 05/08/2025.
//

import SwiftUI

struct AddHabitView: View {
    @ObservedObject var habitManager: HabitManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var habitName = ""
    @State private var selectedPillar: Pillar = .health
    @State private var selectedType: HabitType = .binary
    @State private var selectedCategory: HabitCategory = .build
    @State private var selectedFrequency: HabitFrequency = .daily
    @State private var selectedDifficulty = 1
    @State private var trigger = ""
    @State private var recipe = ""
    @State private var targetValue: Double = 0
    @State private var unit = ""
    @State private var targetDuration: TimeInterval = 1800
    
    private let totalSteps = 5
    
    var body: some View {
        NavigationView {
            VStack(spacing: ForgeDesign.Spacing.lg) {
                progressBar
                
                stepContent
                
                Spacer()
                
                navigationButtons
            }
            .padding(ForgeDesign.Spacing.lg)
            .background(ForgeDesign.Colors.background)
            .navigationTitle("The Architect")
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
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(spacing: ForgeDesign.Spacing.sm) {
            HStack {
                Text("Step \(currentStep + 1) of \(totalSteps)")
                    .font(ForgeDesign.Typography.caption1)
                    .foregroundColor(ForgeDesign.Colors.textSecondary)
                
                Spacer()
                
                Text("\(Int(Double(currentStep + 1) / Double(totalSteps) * 100))%")
                    .font(ForgeDesign.Typography.caption1)
                    .foregroundColor(ForgeDesign.Colors.accent)
            }
            
            ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                .tint(ForgeDesign.Colors.accent)
                .scaleEffect(y: 2)
        }
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            nameAndCategoryStep
        case 1:
            pillarStep
        case 2:
            typeAndTargetStep
        case 3:
            frequencyAndDifficultyStep
        case 4:
            triggerAndRecipeStep
        default:
            EmptyView()
        }
    }
    
    // MARK: - Step 1: Name and Category
    
    private var nameAndCategoryStep: some View {
        VStack(alignment: .leading, spacing: ForgeDesign.Spacing.lg) {
            VStack(alignment: .leading, spacing: ForgeDesign.Spacing.sm) {
                Text("What do you want to build?")
                    .font(ForgeDesign.Typography.title2)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                
                Text("Give your habit a clear, specific name")
                    .font(ForgeDesign.Typography.subheadline)
                    .foregroundColor(ForgeDesign.Colors.textSecondary)
            }
            
            TextField("e.g., Morning Workout, Read 20 Pages", text: $habitName)
                .font(ForgeDesign.Typography.headline)
                .padding(ForgeDesign.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                        .fill(ForgeDesign.Colors.surface)
                )
            
            VStack(alignment: .leading, spacing: ForgeDesign.Spacing.md) {
                Text("Build or Break?")
                    .font(ForgeDesign.Typography.headline)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                
                HStack(spacing: ForgeDesign.Spacing.md) {
                    ForEach(HabitCategory.allCases, id: \.self) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 2: Pillar
    
    private var pillarStep: some View {
        VStack(alignment: .leading, spacing: ForgeDesign.Spacing.lg) {
            VStack(alignment: .leading, spacing: ForgeDesign.Spacing.sm) {
                Text("Which pillar of life?")
                    .font(ForgeDesign.Typography.title2)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                
                Text("Connect this habit to a larger life goal")
                    .font(ForgeDesign.Typography.subheadline)
                    .foregroundColor(ForgeDesign.Colors.textSecondary)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ForgeDesign.Spacing.md) {
                ForEach(Pillar.allCases, id: \.self) { pillar in
                    PillarButton(
                        pillar: pillar,
                        isSelected: selectedPillar == pillar
                    ) {
                        selectedPillar = pillar
                    }
                }
            }
        }
    }
    
    // MARK: - Step 3: Type and Target
    
    private var typeAndTargetStep: some View {
        VStack(alignment: .leading, spacing: ForgeDesign.Spacing.lg) {
            VStack(alignment: .leading, spacing: ForgeDesign.Spacing.sm) {
                Text("How will you track it?")
                    .font(ForgeDesign.Typography.title2)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                
                Text("Choose the tracking method that fits best")
                    .font(ForgeDesign.Typography.subheadline)
                    .foregroundColor(ForgeDesign.Colors.textSecondary)
            }
            
            VStack(spacing: ForgeDesign.Spacing.md) {
                ForEach(HabitType.allCases, id: \.self) { type in
                    TypeButton(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        selectedType = type
                    }
                }
            }
            
            if selectedType == .quantitative {
                quantitativeTargetSection
            } else if selectedType == .timer {
                timerTargetSection
            }
        }
    }
    
    private var quantitativeTargetSection: some View {
        VStack(alignment: .leading, spacing: ForgeDesign.Spacing.md) {
            Text("Set your target")
                .font(ForgeDesign.Typography.headline)
                .foregroundColor(ForgeDesign.Colors.textPrimary)
            
            HStack {
                TextField("Amount", value: $targetValue, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                
                TextField("Unit", text: $unit)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
    
    private var timerTargetSection: some View {
        VStack(alignment: .leading, spacing: ForgeDesign.Spacing.md) {
            Text("Target duration")
                .font(ForgeDesign.Typography.headline)
                .foregroundColor(ForgeDesign.Colors.textPrimary)
            
            HStack {
                Text("\(Int(targetDuration / 60)) minutes")
                    .font(ForgeDesign.Typography.body)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                
                Spacer()
            }
            
            Slider(value: $targetDuration, in: 300...7200, step: 300)
                .tint(ForgeDesign.Colors.accent)
        }
    }
    
    // MARK: - Step 4: Frequency and Difficulty
    
    private var frequencyAndDifficultyStep: some View {
        VStack(alignment: .leading, spacing: ForgeDesign.Spacing.lg) {
            VStack(alignment: .leading, spacing: ForgeDesign.Spacing.sm) {
                Text("Schedule & intensity")
                    .font(ForgeDesign.Typography.title2)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                
                Text("When and how challenging is this habit?")
                    .font(ForgeDesign.Typography.subheadline)
                    .foregroundColor(ForgeDesign.Colors.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: ForgeDesign.Spacing.md) {
                Text("Frequency")
                    .font(ForgeDesign.Typography.headline)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                
                // Simplified frequency picker for now
                Picker("Frequency", selection: $selectedFrequency) {
                    Text("Daily").tag(HabitFrequency.daily)
                    Text("3x per week").tag(HabitFrequency.xTimesPerWeek(3))
                    Text("5x per week").tag(HabitFrequency.xTimesPerWeek(5))
                }
                .pickerStyle(.segmented)
            }
            
            VStack(alignment: .leading, spacing: ForgeDesign.Spacing.md) {
                Text("Difficulty")
                    .font(ForgeDesign.Typography.headline)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                
                HStack(spacing: ForgeDesign.Spacing.md) {
                    ForEach(1...3, id: \.self) { difficulty in
                        DifficultyButton(
                            difficulty: difficulty,
                            isSelected: selectedDifficulty == difficulty
                        ) {
                            selectedDifficulty = difficulty
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 5: Trigger and Recipe
    
    private var triggerAndRecipeStep: some View {
        VStack(alignment: .leading, spacing: ForgeDesign.Spacing.lg) {
            VStack(alignment: .leading, spacing: ForgeDesign.Spacing.sm) {
                Text("Set yourself up for success")
                    .font(ForgeDesign.Typography.title2)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                
                Text("Optional: Define when and how you'll do this habit")
                    .font(ForgeDesign.Typography.subheadline)
                    .foregroundColor(ForgeDesign.Colors.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: ForgeDesign.Spacing.md) {
                Text("Trigger (when)")
                    .font(ForgeDesign.Typography.headline)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                
                TextField("After I finish my morning coffee...", text: $trigger)
                    .padding(ForgeDesign.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                            .fill(ForgeDesign.Colors.surface)
                    )
            }
            
            VStack(alignment: .leading, spacing: ForgeDesign.Spacing.md) {
                Text("Recipe (how)")
                    .font(ForgeDesign.Typography.headline)
                    .foregroundColor(ForgeDesign.Colors.textPrimary)
                
                TextField("I will meditate for 10 minutes in the living room", text: $recipe)
                    .padding(ForgeDesign.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                            .fill(ForgeDesign.Colors.surface)
                    )
            }
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: ForgeDesign.Spacing.md) {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation(ForgeDesign.Animation.medium) {
                        currentStep -= 1
                    }
                }
                .font(ForgeDesign.Typography.headline)
                .foregroundColor(ForgeDesign.Colors.textPrimary)
                .padding(.horizontal, ForgeDesign.Spacing.lg)
                .padding(.vertical, ForgeDesign.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                        .stroke(ForgeDesign.Colors.textSecondary, lineWidth: 1)
                )
            }
            
            Spacer()
            
            Button(currentStep < totalSteps - 1 ? "Next" : "Create Habit") {
                if currentStep < totalSteps - 1 {
                    withAnimation(ForgeDesign.Animation.medium) {
                        currentStep += 1
                    }
                } else {
                    createHabit()
                }
            }
            .font(ForgeDesign.Typography.headline)
            .foregroundColor(ForgeDesign.Colors.background)
            .padding(.horizontal, ForgeDesign.Spacing.xl)
            .padding(.vertical, ForgeDesign.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                    .fill(isStepValid ? AnyShapeStyle(ForgeDesign.Colors.primaryGradient) : AnyShapeStyle(ForgeDesign.Colors.textTertiary))
            )
            .disabled(!isStepValid)
        }
    }
    
    // MARK: - Validation and Creation
    
    private var isStepValid: Bool {
        switch currentStep {
        case 0:
            return !habitName.isEmpty
        case 1:
            return true // Pillar is always selected
        case 2:
            if selectedType == .quantitative {
                return targetValue > 0 && !unit.isEmpty
            }
            return true
        case 3:
            return true
        case 4:
            return true
        default:
            return false
        }
    }
    
    private func createHabit() {
        let habit = Habit(
            name: habitName,
            pillar: selectedPillar,
            type: selectedType,
            category: selectedCategory,
            frequency: selectedFrequency,
            difficulty: selectedDifficulty,
            trigger: trigger.isEmpty ? nil : trigger,
            recipe: recipe.isEmpty ? nil : recipe,
            targetValue: selectedType == .quantitative ? targetValue : nil,
            unit: selectedType == .quantitative ? unit : nil,
            targetDuration: selectedType == .timer ? targetDuration : nil
        )
        
        habitManager.addHabit(habit)
        dismiss()
    }
}

// MARK: - Supporting Button Views

struct CategoryButton: View {
    let category: HabitCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: ForgeDesign.Spacing.xs) {
                Text(category.rawValue)
                    .font(ForgeDesign.Typography.headline)
                    .foregroundColor(isSelected ? ForgeDesign.Colors.background : ForgeDesign.Colors.textPrimary)
                
                Text(category.description)
                    .font(ForgeDesign.Typography.caption1)
                    .foregroundColor(isSelected ? ForgeDesign.Colors.background.opacity(0.8) : ForgeDesign.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(ForgeDesign.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                    .fill(isSelected ? ForgeDesign.Colors.accent : ForgeDesign.Colors.surface)
            )
        }
    }
}

struct PillarButton: View {
    let pillar: Pillar
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: ForgeDesign.Spacing.sm) {
                Image(systemName: pillar.icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : pillarColor)
                
                Text(pillar.rawValue)
                    .font(ForgeDesign.Typography.headline)
                    .foregroundColor(isSelected ? .white : ForgeDesign.Colors.textPrimary)
                
                Text(pillar.description)
                    .font(ForgeDesign.Typography.caption1)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : ForgeDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(ForgeDesign.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                    .fill(isSelected ? pillarColor : ForgeDesign.Colors.surface)
            )
        }
    }
    
    private var pillarColor: Color {
        switch pillar {
        case .health: return ForgeDesign.Colors.health
        case .wealth: return ForgeDesign.Colors.wealth
        case .knowledge: return ForgeDesign.Colors.knowledge
        case .discipline: return ForgeDesign.Colors.discipline
        case .social: return ForgeDesign.Colors.social
        }
    }
}

struct TypeButton: View {
    let type: HabitType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: ForgeDesign.Spacing.xs) {
                    Text(type.rawValue)
                        .font(ForgeDesign.Typography.headline)
                        .foregroundColor(isSelected ? ForgeDesign.Colors.background : ForgeDesign.Colors.textPrimary)
                    
                    Text(type.description)
                        .font(ForgeDesign.Typography.subheadline)
                        .foregroundColor(isSelected ? ForgeDesign.Colors.background.opacity(0.8) : ForgeDesign.Colors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ForgeDesign.Colors.background)
                }
            }
            .padding(ForgeDesign.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                    .fill(isSelected ? ForgeDesign.Colors.accent : ForgeDesign.Colors.surface)
            )
        }
    }
}

struct DifficultyButton: View {
    let difficulty: Int
    let isSelected: Bool
    let action: () -> Void
    
    private var title: String {
        switch difficulty {
        case 1: return "Easy (1x)"
        case 2: return "Medium (2x)"
        case 3: return "Hard (3x)"
        default: return "Easy (1x)"
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ForgeDesign.Typography.headline)
                .foregroundColor(isSelected ? ForgeDesign.Colors.background : ForgeDesign.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(ForgeDesign.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                        .fill(isSelected ? ForgeDesign.Colors.accent : ForgeDesign.Colors.surface)
                )
        }
    }
}

#Preview {
    AddHabitView(habitManager: HabitManager())
        .preferredColorScheme(.dark)
}