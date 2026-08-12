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
/// Width of the drag handle; the handle always reserves its width so rows do
/// not shift when it appears on hover.
private let dragHandleWidth: CGFloat = 16
private let bulletSize: CGFloat = 5
private let bulletTopPadding: CGFloat = 5
/// Opacity of a row's bullet while hovered; dimmer than the focused bullet.
private let bulletHoveredOpacity: CGFloat = 0.5
/// Duration of the bullet's fade-in/fade-out animation.
private let bulletFadeDuration: Double = 0.2
private let rowVerticalPadding: CGFloat = 2
private let rowHorizontalPadding: CGFloat = 8
private let chevronExpandedAngle: Double = 90
/// The 14 pt font size for regular (non-root) row text.
private let editorFontSize: CGFloat = 14
/// The 30 pt font size for the root row's text, which renders larger and bold.
private let rootFontSize: CGFloat = 30
/// Ghost text shown in a focused empty root row.
private let rootPlaceholderText = "Untitled"
/// Ghost text shown in a focused empty non-root row.
private let rowPlaceholderText = "Write something..."

/// Renders a single outline row: an indent, an expand/collapse chevron, a bullet, and an editable text view.
struct OutlinerRowView: View {
	
	@Binding var row: OutlinerRowModel
	
	/// Whether this is the root row, the topmost row in the hierarchy, which
	/// renders larger than the rest.
	var isRoot: Bool
	
	var isFocused: Bool
	
	@State
	private var isHovered = false
	
	/// The row's underlying text view, used to build the drag preview.
	@State
	private var textView: OutlinerTextView?
	
	var onFocusChange: ((Bool) -> Void)?
	
	var onInsertNewRow: ((UUID, NSTextView) -> Void)?
	
	var onDeleteRow: ((UUID) -> Void)?
	
	var onIndentRow: ((UUID) -> Void)?
	
	var onOutdentRow: ((UUID) -> Void)?
	
	var body: some View {
		// The root row's expander sits at the row's vertical center, so it
		// stays centered as the row's text grows. Other rows stay top-aligned.
		HStack(alignment: isRoot ? .center : .top, spacing: rowSpacing) {
			
			Spacer().frame(width: CGFloat(row.depth) * indentWidthPerDepth)
			
			// Drag handle; the root row can never be dragged, so it renders none.
			// Hidden until hovered, but always reserves its width so rows do not
			// shift when it appears.
			if !isRoot {
				Image(systemName: "line.3.horizontal")
					.font(.system(size: 12))
					.foregroundStyle(.secondary)
					.frame(width: dragHandleWidth, height: chevronButtonWidth + 2)
					.opacity(isHovered ? 1 : 0)
					.animation(.easeInOut(duration: bulletFadeDuration), value: isHovered)
					.draggable(row.id.uuidString) {
						if let textView, let image = snapshot(of: textView) {
							Image(nsImage: image)
								.fixedSize()
								.offset(x: image.size.width / 2)
						}
					}
			}
			
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
			
			// Bullet icon; the root row has no bullet. Hidden until hovered or
			// focused, and dimmer while hovered than while focused.
			if !isRoot {
				Circle()
					.opacity(isHovered || isFocused ? (isFocused ? 1 : bulletHoveredOpacity) : 0)
					.frame(width: bulletSize, height: bulletSize)
					.padding(.top, bulletTopPadding)
					.animation(.easeInOut(duration: bulletFadeDuration), value: isHovered)
					.animation(.easeInOut(duration: bulletFadeDuration), value: isFocused)
			}
			
			// Editable text view
			OutlinerTextViewRepresentable(
				height: $row.height,
				text: $row.text,
				fontSize: isRoot ? rootFontSize : editorFontSize,
				isBold: isRoot,
				placeholder: isRoot ? rootPlaceholderText : rowPlaceholderText,
				isFocused: isFocused,
				onFocusChange: onFocusChange,
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
				onTextViewReady: {
					newText in
					// Defer the state write out of SwiftUI's update pass, which
					// `updateNSView` runs during, to avoid mutating state mid-update.
					DispatchQueue.main.async {
						if textView !== newText {
							textView = newText
						}
					}
				},
			)
				.frame(height: row.height)
		}
		.padding(.vertical, rowVerticalPadding)
		.padding(.horizontal, rowHorizontalPadding)
		.frame(maxWidth: .infinity, alignment: .leading)
		.contentShape(Rectangle())
		.onHover { isHovered = $0 }
	}
	
	/// Snapshot of a text view's rendered contents, used as the drag preview.
	///
	/// Prefers a bitmap snapshot; falls back to a PDF snapshot when the bitmap
	/// comes out blank, which layer-backed text views sometimes do.
	private func snapshot(of textView: NSTextView) -> NSImage? {
		if let rep = textView.bitmapImageRepForCachingDisplay(in: textView.bounds) {
			textView.cacheDisplay(in: textView.bounds, to: rep)
			if hasVisibleContent(rep) {
				let image = NSImage(size: rep.size)
				image.addRepresentation(rep)
				return image
			}
		}
		let pdfData = textView.dataWithPDF(inside: textView.bounds)
		return NSImage(data: pdfData)
	}
	
	/// Whether a bitmap snapshot contains any non-transparent (or non-zero) pixels.
	private func hasVisibleContent(_ rep: NSBitmapImageRep) -> Bool {
		guard let data = rep.bitmapData else { return false }
		let bytesPerRow = rep.bytesPerRow
		let width = rep.pixelsWide
		let height = rep.pixelsHigh
		let samplesPerPixel = rep.samplesPerPixel
		for row in 0..<height {
			let rowPtr = data + row * bytesPerRow
			for col in 0..<width {
				let offset = col * samplesPerPixel
				if rep.hasAlpha {
					if rowPtr[offset + samplesPerPixel - 1] > 0 { return true }
				}
				else if rowPtr[offset] != 0 || rowPtr[offset + 1] != 0 || rowPtr[offset + 2] != 0 {
					return true
				}
			}
		}
		return false
	}
}
