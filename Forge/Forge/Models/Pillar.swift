//
//  Pillar.swift
//  Forge
//
//  Created by Josiah Naguar on 05/08/2025.
//

import Foundation

enum Pillar: String, CaseIterable, Identifiable, Codable {
    case health = "Health"
    case wealth = "Wealth"
    case knowledge = "Knowledge"
    case discipline = "Discipline"
    case social = "Social"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .health:
            return "heart.fill"
        case .wealth:
            return "dollarsign.circle.fill"
        case .knowledge:
            return "brain.head.profile"
        case .discipline:
            return "target"
        case .social:
            return "person.2.fill"
        }
    }
    
    var color: String {
        switch self {
        case .health:
            return "FF6B6B" // Red
        case .wealth:
            return "4ECDC4" // Teal
        case .knowledge:
            return "45B7D1" // Blue
        case .discipline:
            return "FFA726" // Orange
        case .social:
            return "AB47BC" // Purple
        }
    }
    
    var description: String {
        switch self {
        case .health:
            return "Physical and mental well-being"
        case .wealth:
            return "Financial growth and security"
        case .knowledge:
            return "Learning and skill development"
        case .discipline:
            return "Self-control and consistency"
        case .social:
            return "Relationships and connections"
        }
    }
}