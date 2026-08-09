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
/// The 14 pt font size for regular (non-root) row text.
private let editorFontSize: CGFloat = 14
/// The 30 pt font size for the root row's text, which renders larger and bold.
private let rootFontSize: CGFloat = 30

/// Renders a single outline row: an indent, an expand/collapse chevron, a bullet, and an editable text view.
struct OutlinerRowView: View {
	
	@Binding var row: OutlinerRowModel
	
	/// Whether this is the root row, the topmost row in the hierarchy, which
	/// renders larger than the rest.
	var isRoot: Bool
	
	var isFocused: Bool
	
	var onInsertNewRow: ((UUID, NSTextView) -> Void)?
	
	var onDeleteRow: ((UUID) -> Void)?
	
	var onIndentRow: ((UUID) -> Void)?
	
	var onOutdentRow: ((UUID) -> Void)?
	
	var body: some View {
		// The root row's expander sits at the row's vertical center, so it
		// stays centered as the row's text grows. Other rows stay top-aligned.
		HStack(alignment: isRoot ? .center : .top, spacing: rowSpacing) {
			
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
			
			// Bullet icon; the root row has no bullet.
			if !isRoot {
				Circle()
					.frame(width: bulletSize, height: bulletSize)
					.padding(.top, bulletTopPadding)
			}
			
			// Editable text view
			OutlinerTextViewRepresentable(
				height: $row.height,
				text: $row.text,
				fontSize: isRoot ? rootFontSize : editorFontSize,
				isBold: isRoot,
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
