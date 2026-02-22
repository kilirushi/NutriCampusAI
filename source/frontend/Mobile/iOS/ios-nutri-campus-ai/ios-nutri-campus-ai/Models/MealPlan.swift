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
    var Breakfast: Meal
    var Lunch: Meal
    var Dinner: Meal
    
    enum CodingKeys: String, CodingKey {
        case Breakfast, Lunch, Dinner
    }
    
    init(Breakfast: Meal, Lunch: Meal, Dinner: Meal) {
            self.Breakfast = Breakfast
            self.Lunch = Lunch
            self.Dinner = Dinner
        }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        Breakfast = try container.decode(Meal.self, forKey: .Breakfast)
        Lunch = try container.decode(Meal.self, forKey: .Lunch)
        Dinner = try container.decode(Meal.self, forKey: .Dinner)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Breakfast, forKey: .Breakfast)
        try container.encode(Lunch, forKey: .Lunch)
        try container.encode(Dinner, forKey: .Dinner)
    }
}

// Dish với rating để bind SwiftUI
struct Dish: Codable, Identifiable {
    var id = UUID()
    let name: String
    var rating: Int
}

struct Meal: Codable {
    var dishes: [Dish]
    var time: MealTime?
    
    init(dishes: [Dish], time: MealTime? = nil) {
        self.dishes = dishes
        self.time = time
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Parse dishes
        if let dishArray = try? container.decode([Dish].self, forKey: .dishes) {
            self.dishes = dishArray
        } else if let stringArray = try? container.decode([String].self, forKey: .dishes) {
            // JSON cũ: [String] -> [Dish] với rating mặc định 0
            self.dishes = stringArray.map { Dish(name: $0, rating: 0) }
        } else {
            self.dishes = []
        }
        
        // Parse time
        self.time = try? container.decode(MealTime.self, forKey: .time)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dishes, forKey: .dishes)
        try container.encodeIfPresent(time, forKey: .time)
    }
    
    enum CodingKeys: String, CodingKey {
        case dishes, time
    }
}

// MARK: - MealTime: start/end giờ bữa ăn
struct MealTime: Codable {
    let start: String   // ví dụ "07:00"
    let end: String     // ví dụ "09:00"
}

extension MealPlan {
    mutating func updateDishRating(dishId: UUID, newRating: Int) {
        func updateDishes(_ meal: inout Meal) {
            if let idx = meal.dishes.firstIndex(where: { $0.id == dishId }) {
                meal.dishes[idx].rating = newRating
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
    
    func dayPlan(for dayName: String) -> DayPlan? {
            switch dayName {
            case "Monday": return self.Monday
            case "Tuesday": return self.Tuesday
            case "Wednesday": return self.Wednesday
            case "Thursday": return self.Thursday
            case "Friday": return self.Friday
            case "Saturday": return self.Saturday
            case "Sunday": return self.Sunday
            default: return nil
            }
        }
}
extension MealPlan {
    mutating func updateDishRatingByName(day: String, meal: String, dishName: String, newRating: Int) {
        
        func updateDishes(_ meal: inout Meal) {
            if let idx = meal.dishes.firstIndex(where: { $0.name == dishName }) {
                meal.dishes[idx].rating = newRating
            }
        }
        
        // Lấy dayPlan qua keyPath
        guard let dayKeyPath = dayKeyPath(for: day) else { return }
        var dayPlan = self[keyPath: dayKeyPath]
        
        switch meal {
        case "Breakfast": updateDishes(&dayPlan.Breakfast)
        case "Lunch": updateDishes(&dayPlan.Lunch)
        case "Dinner": updateDishes(&dayPlan.Dinner)
        default: break
        }
        
        // Gán lại
        self[keyPath: dayKeyPath] = dayPlan
    }
    
    private func dayKeyPath(for day: String) -> WritableKeyPath<MealPlan, DayPlan>? {
        switch day {
        case "Monday": return \.Monday
        case "Tuesday": return \.Tuesday
        case "Wednesday": return \.Wednesday
        case "Thursday": return \.Thursday
        case "Friday": return \.Friday
        case "Saturday": return \.Saturday
        case "Sunday": return \.Sunday
        default: return nil
        }
    }
}

extension DayPlan {
    /// Trả về DayPlan mới, chỉ giữ Dish có rating > 0 trong mỗi Meal
    func filteredRatedDishes() -> DayPlan {
        DayPlan(
            Breakfast: Meal(
                dishes: Breakfast.dishes.filter { $0.rating > 0 },
                time: Breakfast.time
            ),
            Lunch: Meal(
                dishes: Lunch.dishes.filter { $0.rating > 0 },
                time: Lunch.time
            ),
            Dinner: Meal(
                dishes: Dinner.dishes.filter { $0.rating > 0 },
                time: Dinner.time
            )
        )
    }
    
    func toRatingsDictionary() -> [String: [String: Int]] {
            var result: [String: [String: Int]] = [:]
            
            let meals: [(String, Meal)] = [
                ("Breakfast", Breakfast),
                ("Lunch", Lunch),
                ("Dinner", Dinner)
            ]
            
            for (mealName, meal) in meals {
                let ratedDishes = meal.dishes.filter { $0.rating > 0 }
                if !ratedDishes.isEmpty {
                    // [DishID: rating]
                    result[mealName] = Dictionary(uniqueKeysWithValues: ratedDishes.map { ($0.name, $0.rating) })
                }
            }
            
            return result
        }
}



