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
	
	/// Creates the view object, and configures its initial state.
	func makeNSView(context: Context) -> NSTextView {
		
		let textView = OutlinerTextView()
		
		textView.onLayout = { [weak textView] in
			guard let textView else { return }
			context.coordinator.syncHeight(for: textView)
		}
		
		textView.delegate = context.coordinator
		textView.isHorizontallyResizable = false
		textView.isVerticallyResizable = true
		textView.textContainer?.widthTracksTextView = true
		textView.textContainer?.size.height = .greatestFiniteMagnitude
		
		// The text view object controls the text container's height.
		// We will manually control the text view's height with custom logic.
		textView.textContainer?.heightTracksTextView = false
		
		// Inset is padding.
		textView.textContainerInset = .zero
		textView.font = .systemFont(ofSize: editorFontSize)
		return textView
	}
	
	/// Updates the view's state with new info from SwiftUI.
	func updateNSView(_ nsView: NSTextView, context: Context) {
		if nsView.string != text {
			nsView.string = text
			context.coordinator.syncHeight(for: nsView)
		}
	}
	
	/// Creates the coordinator that mediates between the text view and SwiftUI.
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	/// The object that observes text changes and keeps the measured height in sync.
	class Coordinator: NSObject, NSTextViewDelegate {

		private let parent: OutlinerTextViewRepresentable

		/// The height most recently written to the binding, used to skip redundant updates.
		private var lastHeight: CGFloat = 0
		
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
			
			let contentHeight = ceil(layoutManager.usedRect(for: textContainer).height)
			let font = textView.font ?? .systemFont(ofSize: editorFontSize)
			let lineHeight = ceil(font.ascender - font.descender + font.leading)
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
