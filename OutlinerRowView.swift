//
//  OutlinerRowView.swift
//  mysticbook
//
//  Created by Andrew Shinjo on 8/6/26.
//

import SwiftUI

private let chevronButtonWidth: CGFloat = 14
private let bulletTopPadding: CGFloat = 5

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
			.frame(width: chevronButtonWidth)
			
			// Bullet icon
			Circle()
				.frame(width: 5, height: 5)
				.padding(.top, bulletTopPadding)
			
			// Editable text view
			OutlinerTextViewRepresentable(height: $row.height, text: $row.text)
				.frame(height: row.height)
		}
		.padding(.vertical, 2)
		.padding(.horizontal, 8)
	}
}
