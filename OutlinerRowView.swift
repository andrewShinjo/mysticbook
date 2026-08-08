//
//  OutlinerRowView.swift
//  mysticbook
//
//  Created by Andrew Shinjo on 8/6/26.
//

import SwiftUI

struct OutlinerRowView: View {
	
	@Binding var row: OutlinerRowModel
	
	var body: some View {
		HStack(alignment: .top, spacing: 4) {
			
			Spacer().frame(width: CGFloat(row.depth * 16))
			
			// Expand/collapse button
			Button(action: { row.isExpanded.toggle() }) {
				Image(systemName: "chevron.right")
					.rotationEffect(row.isExpanded ? .degrees(90) : .zero)
			}
			.buttonStyle(.plain)
			.frame(width: 14, height: 20)
			
			// Bullet icon
			Circle()
				.frame(width: 5, height: 5)
				.padding(.top, 7.5)
			
			// Editable text view
			TextViewRepresentable(text: $row.text)
				.frame(minHeight: 20)
		}
		.padding(.vertical, 2)
		.padding(.horizontal, 8)
	}
}
