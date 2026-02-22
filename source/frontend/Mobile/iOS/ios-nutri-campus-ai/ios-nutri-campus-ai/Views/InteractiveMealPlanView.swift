//
//  InteractiveMealPlanView.swift
//  ios-nutri-campus-ai
//
//  Created by Trần Hoà on 21/2/26.
//

import Foundation
import SwiftUI

struct InteractiveMealPlanView: View {
    @ObservedObject var viewModel: MealPlanViewModel
    private let todayHighlightColor = Color.yellow.opacity(0.3)

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    if let plan = viewModel.mealPlan {
                        VStack(spacing: 8) {
                            Text("Weekly Meal Plan")
                                .font(.largeTitle).bold()
                            Text("BMI: \(plan.BMI, specifier: "%.1f")")
                                .font(.headline).foregroundColor(.secondary)
                        }.padding(.bottom, 16)

                        ForEach(daysOfWeek(), id: \.self) { dayName in
                            if let dayPlan = dayPlan(for: dayName) {
                                dayCard(title: dayName, day: dayPlan, isToday: dayName == getTodayName())
                                    .id(dayName)
                            }
                        }
                    } else {
                        Text("Meal Plan not available")
                            .foregroundColor(.secondary).padding()
                    }
                }.padding()
            }
            .navigationTitle("Meal Plan")
            .onAppear {
                // Scroll tới ngày hôm nay
                let todayName = getTodayName()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation { proxy.scrollTo(todayName, anchor: .top) }
                }
            }
        }
    }

    // Helpers
    func daysOfWeek() -> [String] {
        ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
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
            Text(title)
                .font(.title2).bold()
                .foregroundColor(.white)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(isToday ? Color.orange : Color.blue)
                .cornerRadius(8)

            mealSection(title: "Breakfast", dishes: day.Breakfast)
            mealSection(title: "Lunch", dishes: day.Lunch)
            mealSection(title: "Dinner", dishes: day.Dinner)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12)
                        .fill(isToday ? todayHighlightColor : Color(.systemBackground))
                        .shadow(radius: 3))
    }

    // MARK: - Meal Section Interactive
    func mealSection(title: String, dishes: [Dish]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline).padding(.vertical, 4)

            ForEach(dishes.indices, id: \.self) { index in
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8)).foregroundColor(.blue)
                    Text(dishes[index].name).font(.subheadline)
                    Spacer()

                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { starIndex in
                            Image(systemName: starIndex <= dishes[index].rating ? "star.fill" : "star")
                                .font(.caption2).foregroundColor(.yellow)
                                .onTapGesture {
                                    // Click star → update rating async + UI ngay
                                    updateDishRating(dishId: dishes[index].id, newRating: starIndex)
                                }
                        }
                    }
                }.padding(.leading, 8)
            }
        }
    }

    func updateDishRating(dishId: UUID, newRating: Int) {
        viewModel.updateDishRating(dishId: dishId, newRating: newRating)
    }
}
