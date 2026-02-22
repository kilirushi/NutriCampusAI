//
//  MealPlanView.swift
//  ios-nutri-campus-ai
//
//  Created by Trần Hoà on 21/2/26.
//

//import SwiftUI
//
//struct MealPlanView: View {
//    
//    let mealPlan: MealPlan?
//    @ObservedObject var viewModel: MealPlanViewModel
//    
//    // Màu highlight cho ngày hiện tại
//    private let todayHighlightColor = Color.yellow.opacity(0.3)
//    
//    var body: some View {
//        ScrollViewReader { proxy in
//            ScrollView {
//                VStack(spacing: 16) {
//                    
//                    // Header với BMI
//                    if let plan = mealPlan {
//                        VStack(spacing: 8) {
//                            Text("Weekly Meal Plan")
//                                .font(.largeTitle)
//                                .bold()
//                            Text("BMI: \(plan.BMI, specifier: "%.1f")")
//                                .font(.headline)
//                                .foregroundColor(.secondary)
//                        }
//                        .padding(.bottom, 16)
//                        
//                        // Lặp qua các ngày, thêm .id(dayName)
//                        ForEach(daysOfWeek(), id: \.self) { dayName in
//                            if let dayPlan = dayPlan(for: dayName) {
//                                dayCard(title: dayName, day: dayPlan, isToday: dayName == getTodayName())
//                                    .id(dayName)
//                            }
//                        }
//                    } else {
//                        Text("Meal Plan not available")
//                            .foregroundColor(.secondary)
//                            .padding()
//                    }
//                }
//                .padding()
//            }
//            .navigationTitle("Meal Plan")
//            .onAppear {
//                // Scroll tới ngày hiện tại sau khi layout xong
//                let todayName = getTodayName()
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    withAnimation(.easeInOut) {
//                        proxy.scrollTo(todayName, anchor: .top)
//                    }
//                }
//            }
//        }
//    }
//    
//    // MARK: - Helpers
//    func daysOfWeek() -> [String] {
//        ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
//    }
//    
//    func dayPlan(for dayName: String) -> DayPlan? {
//        guard let plan = mealPlan else { return nil }
//        switch dayName {
//        case "Monday": return plan.Monday
//        case "Tuesday": return plan.Tuesday
//        case "Wednesday": return plan.Wednesday
//        case "Thursday": return plan.Thursday
//        case "Friday": return plan.Friday
//        case "Saturday": return plan.Saturday
//        case "Sunday": return plan.Sunday
//        default: return nil
//        }
//    }
//    
//    func getTodayName() -> String {
//        let calendar = Calendar.current
//        let weekday = calendar.component(.weekday, from: Date())
//        switch weekday {
//        case 1: return "Sunday"
//        case 2: return "Monday"
//        case 3: return "Tuesday"
//        case 4: return "Wednesday"
//        case 5: return "Thursday"
//        case 6: return "Friday"
//        case 7: return "Saturday"
//        default: return "Monday"
//        }
//    }
//    
//    // MARK: - Day Card
//    func dayCard(title: String, day: DayPlan, isToday: Bool) -> some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text(title)
//                .font(.title2)
//                .bold()
//                .foregroundColor(.white)
//                .padding(8)
//                .frame(maxWidth: .infinity)
//                .background(isToday ? Color.orange : Color.blue)
//                .cornerRadius(8)
//            
//            mealSection(title: "Breakfast", dishes: day.Breakfast, color: Color.orange.opacity(0.2))
//            mealSection(title: "Lunch", dishes: day.Lunch, color: Color.green.opacity(0.2))
//            mealSection(title: "Dinner", dishes: day.Dinner, color: Color.purple.opacity(0.2))
//        }
//        .padding()
//        .background(RoundedRectangle(cornerRadius: 12)
//                        .fill(isToday ? todayHighlightColor : Color(.systemBackground))
//                        .shadow(radius: 3))
//    }
//    
//    // MARK: - Meal Section
//    func mealSection(title: String, dishes: [Dish], color: Color) -> some View {
//        VStack(alignment: .leading, spacing: 6) {
//            Text(title)
//                .font(.headline)
//                .padding(.vertical, 4)
//                .padding(.horizontal, 6)
//                .background(color)
//                .cornerRadius(6)
//            
//            ForEach(dishes) { dish in
//                HStack {
//                    Image(systemName: "circle.fill")
//                        .font(.system(size: 8))
//                        .foregroundColor(.blue)
//                    Text(dish.name)
//                        .font(.subheadline)
//                    Spacer()
//                    if dish.rating > 0 {
//                        HStack(spacing: 2) {
//                            ForEach(0..<dish.rating, id: \.self) { _ in
//                                Image(systemName: "star.fill")
//                                    .font(.caption2)
//                                    .foregroundColor(.yellow)
//                            }
//                        }
//                    }
//                }
//                .padding(.leading, 8)
//            }
//        }
//    }
//}
