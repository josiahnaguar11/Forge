//
//  InsightCardView.swift
//  Forge
//
//  Created by Josiah Naguar on 05/08/2025.
//

import SwiftUI

struct InsightCardView: View {
    let insight: CorrelationInsight
    
    var body: some View {
        HStack(spacing: ForgeDesign.Spacing.md) {
            iconView
            
            VStack(alignment: .leading, spacing: ForgeDesign.Spacing.xs) {
                HStack {
                    Text(insight.title)
                        .font(ForgeDesign.Typography.headline)
                        .foregroundColor(ForgeDesign.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text(insight.strengthDescription)
                        .font(ForgeDesign.Typography.caption1)
                        .foregroundColor(strengthColor)
                        .padding(.horizontal, ForgeDesign.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.sm)
                                .fill(strengthColor.opacity(0.2))
                        )
                }
                
                Text(insight.description)
                    .font(ForgeDesign.Typography.subheadline)
                    .foregroundColor(ForgeDesign.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(ForgeDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                .fill(ForgeDesign.Colors.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                        .stroke(typeColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(typeColor.opacity(0.2))
                .frame(width: 44, height: 44)
            
            Text(insight.emoji)
                .font(.title2)
        }
    }
    
    private var typeColor: Color {
        switch insight.type {
        case .positive:
            return ForgeDesign.Colors.success
        case .negative:
            return ForgeDesign.Colors.warning
        case .temporal:
            return ForgeDesign.Colors.accent
        }
    }
    
    private var strengthColor: Color {
        switch insight.strength {
        case 0.8...1.0:
            return ForgeDesign.Colors.success
        case 0.6..<0.8:
            return ForgeDesign.Colors.accent
        case 0.4..<0.6:
            return ForgeDesign.Colors.warning
        default:
            return ForgeDesign.Colors.textTertiary
        }
    }
}

#Preview {
    VStack(spacing: ForgeDesign.Spacing.md) {
        InsightCardView(
            insight: CorrelationInsight(
                title: "Synergy Detected",
                description: "You are 73% more likely to complete 'Read 20 Pages' on days you complete 'Morning Workout'",
                strength: 0.73,
                type: .positive,
                habitIds: []
            )
        )
        
        InsightCardView(
            insight: CorrelationInsight(
                title: "Weekly Pattern",
                description: "Your 'Meditate' success rate is 45% higher on Sundays than Mondays",
                strength: 0.45,
                type: .temporal,
                habitIds: []
            )
        )
    }
    .padding()
    .background(ForgeDesign.Colors.background)
    .preferredColorScheme(.dark)
}