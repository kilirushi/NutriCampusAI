//
//  MealPlan.swift
//  ios-nutri-campus-ai
//
//  Created by Trần Hoà on 21/2/26.
//

import Foundation

// Wrapper theo response backend
struct MealPlanResponse: Codable {
    let code: Int
    let message: String
    let data: MealPlan
}

// MealPlan cho 7 ngày
struct MealPlan: Codable {
    var Monday: DayPlan
        var Tuesday: DayPlan
        var Wednesday: DayPlan
        var Thursday: DayPlan
        var Friday: DayPlan
        var Saturday: DayPlan
        var Sunday: DayPlan
        var BMI: Double
}

// DayPlan với Breakfast, Lunch, Dinner
struct DayPlan: Codable {
    var Breakfast: [Dish]
    var Lunch: [Dish]
    var Dinner: [Dish]
    
    // Custom init để parse mảng String thành Dish
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        func parseDishes(_ key: CodingKeys) throws -> [Dish] {
            let names = try container.decode([String].self, forKey: key)
            return names.map { Dish(name: $0, rating: 0) } // rating mặc định 0
        }
        
        Breakfast = try parseDishes(.Breakfast)
        Lunch = try parseDishes(.Lunch)
        Dinner = try parseDishes(.Dinner)
    }
    
    // Needed for encoding back if necessary
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Breakfast.map { $0.name }, forKey: .Breakfast)
        try container.encode(Lunch.map { $0.name }, forKey: .Lunch)
        try container.encode(Dinner.map { $0.name }, forKey: .Dinner)
    }
    
    enum CodingKeys: String, CodingKey {
        case Breakfast
        case Lunch
        case Dinner
    }
}

// Dish với rating để bind SwiftUI
struct Dish: Codable, Identifiable {
    var id = UUID()
    let name: String
    var rating: Int
}




extension MealPlan {
    mutating func updateDishRating(dishId: UUID, newRating: Int) {
        func updateDishes(_ dishes: inout [Dish]) {
            if let idx = dishes.firstIndex(where: { $0.id == dishId }) {
                dishes[idx].rating = newRating
            }
        }
        
        // Duyệt từng ngày
        [\MealPlan.Monday, \.Tuesday, \.Wednesday, \.Thursday, \.Friday, \.Saturday, \.Sunday].forEach { dayKey in
            var day = self[keyPath: dayKey]
            updateDishes(&day.Breakfast)
            updateDishes(&day.Lunch)
            updateDishes(&day.Dinner)
            self[keyPath: dayKey] = day
        }
    }
}
