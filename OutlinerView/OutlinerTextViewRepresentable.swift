//
//  OutlinerTextViewRepresentable.swift
//  mysticbook
//
//  Created by Andrew Shinjo on 8/6/26.
//

import AppKit
import SwiftUI

private let editorFontSize: CGFloat = 14

/// Minimum height change, in points, that triggers a row-height update.
private let heightChangeThreshold: CGFloat = 0.5

/// A SwiftUI wrapper around an editable text view that reports its measured
/// content height back to the row model.
///
/// Outliner rows rely on this to keep each row's height in sync with the height
/// of the text it contains as the user types.
struct OutlinerTextViewRepresentable: NSViewRepresentable {
	
	@Binding var height: CGFloat
	@Binding var text: String
	
	/// The font size for the row's text; the root row uses a larger size.
	var fontSize: CGFloat = editorFontSize
	
	/// Whether the row's text is bold; the root row renders bold.
	var isBold: Bool = false
	
	/// Ghost text drawn when the row is focused and empty.
	var placeholder: String = ""
	
	var isFocused: Bool
	
	/// Called when the text view gains or loses first responder status.
	var onFocusChange: ((Bool) -> Void)?
	
	var onInsertNewRow: ((NSTextView) -> Void)?
	
	var onDeleteRow: ((NSTextView) -> Void)?
	
	var onIndentRow: (() -> Void)?
	
	var onOutdentRow: (() -> Void)?
	
	/// Creates the view object, and configures its initial state.
	func makeNSView(context: Context) -> NSTextView {
		
		let textView = OutlinerTextView()
		
		textView.onInsertNewline = { [weak textView] in
			guard let textView else { return }
			context.coordinator.onInsertNewRow?(textView)
		}
		
		textView.onDeleteRow = { [weak textView] in
			guard let textView else { return }
			context.coordinator.onDeleteRow?(textView)
		}
		
		textView.onIndentRow = {
			context.coordinator.onIndentRow?()
		}
		
		textView.onOutdentRow = {
			context.coordinator.onOutdentRow?()
		}
		
		textView.onLayout = { [weak textView] in
			guard let textView else { return }
			context.coordinator.syncHeight(for: textView)
		}
		
		textView.onFocusChange = { [weak textView] focused in
			guard let textView else { return }
			context.coordinator.onFocusChange?(focused)
		}
		
		textView.placeholder = placeholder
		
		textView.delegate = context.coordinator
		textView.isHorizontallyResizable = false
		textView.isVerticallyResizable = true
		textView.textContainer?.widthTracksTextView = true
		textView.textContainer?.size.height = .greatestFiniteMagnitude
		
		// The text view does not drive the container's height; the container is
		// unbounded, and the view's height is set from measured content instead.
		textView.textContainer?.heightTracksTextView = false
		
		// Inset is padding.
		textView.textContainerInset = .zero
		textView.font = .systemFont(
			ofSize: fontSize,
			weight: isBold ? .bold : .regular
		)
		return textView
	}
	
	/// Updates the view's state with new info from SwiftUI.
	func updateNSView(_ nsView: NSTextView, context: Context) {
		
		// Refresh the coordinator's parent so its bindings track the row's
		// current storage. Keeping the struct captured at makeCoordinator would
		// leave stale bindings pointing at a different row after the rows array
		// shifts (e.g. deleting a row above).
		context.coordinator.parent = self
		
		// Sync SwiftUI's focus intent into the text view before the async
		// makeFirstResponder below runs, so programmatic focus is allowed.
		(nsView as? OutlinerTextView)?.isRowFocused = isFocused
		
		(nsView as? OutlinerTextView)?.placeholder = placeholder
		
		context.coordinator.onInsertNewRow = onInsertNewRow
		context.coordinator.onDeleteRow = onDeleteRow
		context.coordinator.onIndentRow = onIndentRow
		context.coordinator.onOutdentRow = onOutdentRow
		context.coordinator.onFocusChange = onFocusChange
		
		if nsView.string != text {
			nsView.string = text
			nsView.setSelectedRange(NSRange(location: 0, length: 0))
			context.coordinator.syncHeight(for: nsView)
		}
		
		if isFocused {
			DispatchQueue.main.async {
				guard let window = nsView.window, window.firstResponder !== nsView
				else {
					return
				}
				
				window.makeFirstResponder(nsView)
			}
		}
														
	}
	
	/// Creates the coordinator that mediates between the text view and SwiftUI.
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	/// The object that observes text changes and keeps the measured height in sync.
	class Coordinator: NSObject, NSTextViewDelegate {

		fileprivate var parent: OutlinerTextViewRepresentable

		/// The height most recently written to the binding, used to skip redundant updates.
		private var lastHeight: CGFloat = 0
		
		var onInsertNewRow: ((NSTextView) -> Void)?
		
		var onFocusChange: ((Bool) -> Void)?
		
		var onDeleteRow: ((NSTextView) -> Void)?
		
		var onIndentRow: (() -> Void)?
		
		var onOutdentRow: (() -> Void)?
		
		/// Creates a coordinator for the given representable.
		init(_ parent: OutlinerTextViewRepresentable) {
			self.parent = parent
		}

		/// Called when the text view's content changes; updates the bound text and height.
		func textDidChange(_ notification: Notification) {
			guard let textView = notification.object as? NSTextView else { return }
			parent.text = textView.string
			syncHeight(for: textView)
		}
		
		/// Measures the text view's content and publishes the height if it changed.
		func syncHeight(for textView: NSTextView) {
			guard let layoutManager = textView.layoutManager,
						let textContainer = textView.textContainer else { return }
			
			layoutManager.ensureLayout(for: textContainer)
			
			let contentHeight = layoutManager.usedRect(for: textContainer).height
			let font = textView.font ?? .systemFont(ofSize: editorFontSize)
			let lineHeight = font.ascender - font.descender + font.leading
			let height = max(contentHeight, lineHeight)
			
			DispatchQueue.main.async {
				[weak self] in
				guard let self else { return }
				guard abs(height - lastHeight) > heightChangeThreshold else { return }
				lastHeight = height
				parent.height = height
			}
		}
	}
}
