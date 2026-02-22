//
//  APIService.swift
//  ios-nutri-campus-ai
//
//  Created by Trần Hoà on 21/2/26.
//

import Foundation

class APIService {
    
    static let shared = APIService()
    private let baseURL = "http://localhost:3000/api/mealplan"
    
    func generateMealPlan(studentId: String,
                          height: Double,
                          weight: Double) async throws -> MealPlan {
        
        let url = URL(string: "\(baseURL)/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "student_id": studentId,
            "height_cm": height,
            "weight_kg": weight
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Parse MealPlanResponse trước
        let response = try JSONDecoder().decode(MealPlanResponse.self, from: data)
        
        guard response.code == 200 else {
            throw NSError(domain: "API Error", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])
        }
        
        return response.data // MealPlan
    }
}
