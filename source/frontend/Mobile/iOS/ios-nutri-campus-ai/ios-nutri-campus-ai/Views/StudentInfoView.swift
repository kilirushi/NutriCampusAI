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
    @State private var errorMessage: String? = nil
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // MARK: - Input Card
                VStack(spacing: 15) {
                    Text("Enter Your Details")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 15) {
                        VStack(alignment: .leading) {
                            Text("Feet")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("Feet", value: $feetValue, format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Inches")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("Inches", value: $inchesValue, format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Weight (lbs)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Weight", value: $poundsValue, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }.padding(.leading,32)
                        .padding(.trailing,32)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(15)
                .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // MARK: - Action Buttons
                VStack(spacing: 15) {
                    if viewModel.isMealPlanGeneratedThisWeek(studentId: studentId) {
                        Button {
                            viewModel.loadMealPlanFromLocalAndNavigate()
                        } label: {
                            Text("Show Meal Plan")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#155d97"))
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .cornerRadius(12)
                        }
                    } else {
                        Button {
                            // Reset error
                                errorMessage = nil
                                
                                // Validation
                                guard let feet = feetValue, feet >= 0 else {
                                    errorMessage = "Please enter a valid height in feet"
                                    return
                                }
                                guard let inches = inchesValue, inches >= 0, inches < 12 else {
                                    errorMessage = "Inches must be between 0 and 11"
                                    return
                                }
                                guard let pounds = poundsValue, pounds > 0 else {
                                    errorMessage = "Please enter a valid weight in pounds"
                                    return
                                }
                            
                            let totalInches = ((feetValue ?? 0) * 12) + (inchesValue ?? 0)
                            let finalHeight = Double(totalInches) * 2.54
                            let finalWeight = (poundsValue ?? 0) * 0.453592
                            
                            viewModel.generateMealPlan(
                                studentId: studentId,
                                height: finalHeight,
                                weight: finalWeight
                            )
                        } label: {
                            Text("Generate Meal Plan")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#155d97"))
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .cornerRadius(12)
                        }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    }
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.top, 4)
                            .transition(.opacity)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack {
                            Image("logo") // logo bạn đã có
                                .resizable()
                                .scaledToFit()
                                .frame(height: 36) // chỉnh cao phù hợp
                        }
                    }
                }
            .navigationDestination(isPresented: $viewModel.shouldNavigate) {
                if viewModel.mealPlan != nil {
                    InteractiveMealPlanView(viewModel: viewModel)
                        .onDisappear { viewModel.shouldNavigate = false }
                } else {
                    Text("MealPlan loading error")
                        .foregroundColor(.red)
                }
            }
            .onAppear {
                if studentId.isEmpty {
                    studentId = UUID().uuidString
                }
            }.background(
                Image("bg")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.6)
                    .ignoresSafeArea()
            )
        }
    }
}



extension Color {
    init(hex: String, alpha: Double = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        if hex.count == 6 {
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        } else {
            r = 0; g = 0; b = 0
        }
        self.init(
            red: Double(r)/255,
            green: Double(g)/255,
            blue: Double(b)/255,
            opacity: alpha
        )
    }
}
