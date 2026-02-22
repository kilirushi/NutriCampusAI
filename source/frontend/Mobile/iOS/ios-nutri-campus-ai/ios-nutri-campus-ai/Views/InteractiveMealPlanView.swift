//
//  InteractiveMealPlanView.swift
//  ios-nutri-campus-ai
//
//  Created by Trần Hoà on 21/2/26.
//

import Foundation
import SwiftUI

import SwiftUI

struct InteractiveMealPlanView: View {
    @ObservedObject var viewModel: MealPlanViewModel
    private let themeColor = Color(hex: "#50AB42") // màu chủ đạo app
    private let todayHighlightColor = Color.orange.opacity(0.3)
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    if let plan = viewModel.mealPlan {
                        
                        // MARK: Header
                        VStack(spacing: 6) {
                            Text("Your BMI: \(plan.BMI, specifier: "%.1f")")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }.padding(.bottom, 16)
                        
                        // MARK: Days
                        ForEach(daysOfWeek(), id: \.self) { dayName in
                            if let dayPlan = dayPlan(for: dayName) {
                                dayCard(title: dayName,
                                        day: dayPlan,
                                        isToday: dayName == getTodayName())
                                    .id(dayName)
                            }
                        }
                    } else {
                        Text("Meal Plan not available")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [themeColor.opacity(0.1), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Weekly Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Scroll tới ngày hôm nay
                let todayName = getTodayName()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(todayName, anchor: .top)
                    }
                }
            }
        }
    }
    
    // MARK: - Days Helper
    func daysOfWeek() -> [String] {
        ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
    }
    
    func dayPlan(for dayName: String) -> DayPlan? {
        guard let plan = viewModel.mealPlan else { return nil }
        switch dayName {
        case "Monday": return plan.Monday
        case "Tuesday": return plan.Tuesday
        case "Wednesday": return plan.Wednesday
        case "Thursday": return plan.Thursday
        case "Friday": return plan.Friday
        case "Saturday": return plan.Saturday
        case "Sunday": return plan.Sunday
        default: return nil
        }
    }
    
    func getTodayName() -> String {
        let weekday = Calendar.current.component(.weekday, from: Date())
        switch weekday {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return "Monday"
        }
    }
    
    // MARK: - Day Card
    func dayCard(title: String, day: DayPlan, isToday: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Day Header
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    Capsule()
                        .fill(isToday ? Color.orange : themeColor)
                        .shadow(radius: isToday ? 5 : 2)
                )
                .scaleEffect(isToday ? 1.05 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isToday)
            
            // Meals
            mealSection(title: "Breakfast", dishes: day.Breakfast.dishes, day: title, time: day.Breakfast.time)
            mealSection(title: "Lunch", dishes: day.Lunch.dishes, day: title, time: day.Lunch.time)
            mealSection(title: "Dinner", dishes: day.Dinner.dishes, day: title, time: day.Dinner.time)
            
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isToday ? todayHighlightColor : Color(.systemBackground))
                .shadow(radius: 3)
        )
    }
    
    // MARK: - Meal Section
    func mealSection(title: String, dishes: [Dish], day: String, time: MealTime?) -> some View {
        let isEditable = isDayEditable(dayName: day, time: time)
        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(dishes.indices, id: \.self) { index in
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(themeColor)
                    
                    Text(dishes[index].name)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { starIndex in
                            Image(systemName: starIndex <= dishes[index].rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                                .scaleEffect(starIndex <= dishes[index].rating ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dishes[index].rating)
                                .onTapGesture {
                                    guard isEditable else { return }
                                    withAnimation {
                                        updateDishRating(dishId: dishes[index].id, newRating: starIndex, day: day)
                                    }
                                }
                        }
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Rating Update
    func updateDishRating(dishId: UUID, newRating: Int, day: String) {
        viewModel.updateDishRating(dishId: dishId, newRating: newRating, day: day)
    }
    
    // MARK: - Editable Logic
    func isDayEditable(dayName: String, time: MealTime?) -> Bool {
        return true
        let todayName = getTodayName()
        guard dayName == todayName else { return false }
        guard let time = time else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        let components = time.start.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return true }
        
        var dateComponents = calendar.dateComponents([.year,.month,.day], from: now)
        dateComponents.hour = components[0]
        dateComponents.minute = components[1]
        dateComponents.second = 0
        guard let startTimeToday = calendar.date(from: dateComponents) else { return true }
        
        return now >= startTimeToday
    }
}
