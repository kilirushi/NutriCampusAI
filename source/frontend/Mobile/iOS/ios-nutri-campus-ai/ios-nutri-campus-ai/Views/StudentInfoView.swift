//
//  StudentInfoView.swift
//  ios-nutri-campus-ai
//
//  Created by Trần Hoà on 21/2/26.
//

import SwiftUI

struct StudentInfoView: View {
    
    @AppStorage("studentId") private var studentId = ""
    @AppStorage("feet") private var feetValue: Int?
    @AppStorage("inches") private var inchesValue: Int?
    @AppStorage("pounds") private var poundsValue: Double?
    
    @StateObject var viewModel = MealPlanViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack {
                    TextField("Feet", value: $feetValue, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Inches", value: $inchesValue, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
                
                TextField("Weight (lbs)", value: $poundsValue, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                
                if viewModel.isMealPlanGeneratedThisWeek(studentId: studentId) {
                    HStack(spacing: 20) {
                        Button("Rating Meal Plan") {
                            // Bạn có thể mở modal rating riêng nếu muốn
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Show Meal Plan") {
                            viewModel.loadMealPlanFromLocalAndNavigate()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    Button("Generate Meal Plan") {
                        let totalInches = ((feetValue ?? 0) * 12) + (inchesValue ?? 0)
                        let finalHeight = Double(totalInches) * 2.54
                        let finalWeight = (poundsValue ?? 0) * 0.453592
                        
                        viewModel.generateMealPlan(
                            studentId: studentId,
                            height: finalHeight,
                            weight: finalWeight
                        )
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .padding()
            .navigationTitle("NutriCampus AI")
            .navigationDestination(isPresented: $viewModel.shouldNavigate) {
                if viewModel.mealPlan != nil {
                    InteractiveMealPlanView(viewModel: viewModel)
                        .onDisappear { viewModel.shouldNavigate = false }
                } else {
                    Text("MealPlan loading error")
                }
            }
            .onAppear {
                if studentId.isEmpty {
                    studentId = UUID().uuidString
                }
            }
        }
    }
}
