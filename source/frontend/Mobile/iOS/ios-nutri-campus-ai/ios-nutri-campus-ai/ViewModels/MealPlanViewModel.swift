//
//  MealPlanViewModel.swift
//  ios-nutri-campus-ai
//
//  Created by Trần Hoà on 21/2/26.
//

import SwiftUI
import Combine

@MainActor
class MealPlanViewModel: ObservableObject {
    @Published var mealPlan: MealPlan?
    @Published var isLoading = false
    @Published var shouldNavigate = false

    private let cacheDays: TimeInterval = 1 * 24 * 60 * 60 // 1 ngày
    private let mealPlanFileName = "mealplan.json"
    
    var studentId: String {
            UserDefaults.standard.string(forKey: "studentId") ?? ""
    }

    // MARK: - Check nếu tuần này đã tạo
    func isMealPlanGeneratedThisWeek(studentId: String) -> Bool {
        let week = getWeekMondayISO()
        let dict = UserDefaults.standard.dictionary(forKey: "generatedWeeks") as? [String: [String: Any]] ?? [:]
        
        guard let info = dict[studentId],
              let savedWeek = info["week"] as? String,
              let timestamp = info["timestamp"] as? TimeInterval
        else { return false }
        
        if savedWeek != week { return false }
        if Date().timeIntervalSince1970 - timestamp > cacheDays { return false }
        return true
    }

    // MARK: - Generate Meal Plan từ API
    func generateMealPlan(studentId: String, height: Double, weight: Double) {
        Task {
            isLoading = true
            do {
                let plan = try await APIService.shared.generateMealPlan(studentId: studentId, height: height, weight: weight)
                
                self.mealPlan = plan
                saveMealPlanToLocal(plan)
                saveCurrentWeekGenerated(studentId: studentId)
                
                isLoading = false
                shouldNavigate = true
            } catch {
                print(error)
                isLoading = false
            }
        }
    }

    // MARK: - Load Meal Plan từ local
    func loadMealPlanFromLocal() {
        guard let plan = loadMealPlanFromFile() else { return }
        self.mealPlan = plan
    }

    // Load và navigate ngay
    func loadMealPlanFromLocalAndNavigate() {
        loadMealPlanFromLocal()
        if mealPlan != nil {
            shouldNavigate = true
        }
    }

    // MARK: - Update rating
    func updateDishRating(dishId: UUID, newRating: Int,day:String) {
        guard var plan = mealPlan else { return }
        plan.updateDishRating(dishId: dishId, newRating: newRating)
        
        // Gán lại để SwiftUI nhận thay đổi
        self.mealPlan = plan
        
        
        // Lưu file async
        saveMealPlanToLocal(plan)
        
        // async api
        
        if let mondayPlan = self.mealPlan?.dayPlan(for: day),let dict = UserDefaults.standard.dictionary(forKey: "generatedWeeks") as? [String: [String: Any]],let info = dict[studentId],let savedWeek = info["week"] as? String {
            let rating =  mondayPlan.filteredRatedDishes().toRatingsDictionary()
            Task {
                do {
                    let plan = try await APIService.shared.rateDish(studentId: studentId, weekStart: savedWeek, day: day, ratings: rating)
                } catch {
                    print(error)
                }
            }
        }
    }

    // MARK: - Private helpers
    private func saveCurrentWeekGenerated(studentId: String) {
        let week = getWeekMondayISO()
        var dict = UserDefaults.standard.dictionary(forKey: "generatedWeeks") as? [String: [String: Any]] ?? [:]
        dict[studentId] = ["week": week, "timestamp": Date().timeIntervalSince1970]
        UserDefaults.standard.set(dict, forKey: "generatedWeeks")
    }
    
    private func getWeekMondayISO() -> String {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysToMonday, to: today)!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: monday)
    }

    // MARK: - Local Storage
    private func mealPlanFileURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(mealPlanFileName)
    }
    
    func saveMealPlanToLocal(_ plan: MealPlan) {
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(plan)
                try data.write(to: self.mealPlanFileURL())
                print("MealPlan saved locally")
            } catch {
                print("Failed to save MealPlan locally:", error)
            }
        }
    }
    
    private func loadMealPlanFromFile() -> MealPlan? {
        let url = mealPlanFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(MealPlan.self, from: data)
        } catch {
            print("Failed to load MealPlan:", error)
            return nil
        }
    }
}
