//
//  StarRatingView.swift
//  ios-nutri-campus-ai
//
//  Created by Trần Hoà on 21/2/26.
//

import SwiftUI

struct StarRatingView: View {
    var rating: Int
    var maxRating: Int = 5
    var onRatingChanged: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .foregroundColor(.yellow)
                    .onTapGesture {
                        onRatingChanged(index)
                    }
            }
        }
    }
}
