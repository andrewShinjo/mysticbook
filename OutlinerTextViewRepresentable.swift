//
//  OutlinerTextViewRepresentable.swift
//  mysticbook
//
//  Created by Andrew Shinjo on 8/6/26.
//

import AppKit
import SwiftUI

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
		return textView
	}
	
	/// Updates the view's state with new info from SwiftUI.
	func updateNSView(_ nsView: NSTextView, context: Context) {
		if nsView.string != text {
			nsView.string = text
			context.coordinator.syncHeight(for: nsView)
		}
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	class Coordinator: NSObject, NSTextViewDelegate {
		var parent: TextViewRepresentable
		private var lastHeight: CGFloat = 0
		
		init(_ parent: TextViewRepresentable) {
			self.parent = parent
		}

		func textDidChange(_ notification: Notification) {
			guard let textView = notification.object as? NSTextView else { return }
			parent.text = textView.string
			syncHeight(for: textView)
		}
		
		func syncHeight(for textView: NSTextView) {
			guard let layoutManager = textView.layoutManager,
						let textContainer = textView.textContainer else { return }
			
			layoutManager.ensureLayout(for: textContainer)
			
			let contentHeight = ceil(layoutManager.usedRect(for: textContainer).height)
			let font = textView.font ?? .systemFont(ofSize: 30)
			let lineHeight = ceil(font.ascender - font.descender + font.leading)
			let height = max(contentHeight, lineHeight)
			
			DispatchQueue.main.async {
				[weak self] in
				guard let self else { return }
				guard abs(height - lastHeight) > 0.5 else { return }
				lastHeight = height
				parent.height = height
			}
		}
	}
}
