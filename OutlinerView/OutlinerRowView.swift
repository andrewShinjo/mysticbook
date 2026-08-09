//
//  OutlinerRowView.swift
//  mysticbook
//
//  Created by Andrew Shinjo on 8/6/26.
//

import SwiftUI

private let rowSpacing: CGFloat = 4
private let indentWidthPerDepth: CGFloat = 16
private let chevronButtonWidth: CGFloat = 14
private let bulletSize: CGFloat = 5
private let bulletTopPadding: CGFloat = 5
private let rowVerticalPadding: CGFloat = 2
private let rowHorizontalPadding: CGFloat = 8
private let chevronExpandedAngle: Double = 90

/// Renders a single outline row: an indent, an expand/collapse chevron, a bullet, and an editable text view.
struct OutlinerRowView: View {
	
	@Binding var row: OutlinerRowModel
	
	var isFocused: Bool
	
	var onInsertNewRow: ((UUID, NSTextView) -> Void)?
	
	var onDeleteRow: ((UUID) -> Void)?
	
	var onIndentRow: ((UUID) -> Void)?
	
	var onOutdentRow: ((UUID) -> Void)?
	
	var body: some View {
		HStack(alignment: .top, spacing: rowSpacing) {
			
			Spacer().frame(width: CGFloat(row.depth) * indentWidthPerDepth)
			
			// Expand/collapse button
			if row.hasChildren {
				Button(action: { row.isExpanded.toggle() }) {
					Image(systemName: "chevron.right")
						.rotationEffect(row.isExpanded ? .degrees(chevronExpandedAngle) : .zero)
				}
				.buttonStyle(.plain)
				.frame(width: chevronButtonWidth)
			}
			else {
				// Reserve the chevron's width so bullets and text stay aligned.
				Spacer().frame(width: chevronButtonWidth)
			}
			
			// Bullet icon
			Circle()
				.frame(width: bulletSize, height: bulletSize)
				.padding(.top, bulletTopPadding)
			
			// Editable text view
			OutlinerTextViewRepresentable(
				height: $row.height,
				text: $row.text,
				isFocused: isFocused,
				onInsertNewRow: {
					textView in onInsertNewRow?(row.id, textView)
				},
				onDeleteRow: {
					_ in onDeleteRow?(row.id)
				},
				onIndentRow: {
					onIndentRow?(row.id)
				},
				onOutdentRow: {
					onOutdentRow?(row.id)
				},
			)
				.frame(height: row.height)
		}
		.padding(.vertical, rowVerticalPadding)
		.padding(.horizontal, rowHorizontalPadding)
	}
}
