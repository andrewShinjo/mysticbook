//
//  TextViewRepresentable.swift
//  mysticbook
//
//  Created by Andrew Shinjo on 8/6/26.
//

import AppKit
import SwiftUI

struct TextViewRepresentable: NSViewRepresentable {
	@Binding var text: String
	
	func makeNSView(context: Context) -> NSTextView {
		let textView = NSTextView()
		textView.delegate = context.coordinator
		return textView
	}
	
	func updateNSView(_ nsView: NSTextView, context: Context) {
		if nsView.string != text {
			nsView.string = text
		}
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	class Coordinator: NSObject, NSTextViewDelegate {
		var parent: TextViewRepresentable
		
		init(_ parent: TextViewRepresentable) {
			self.parent = parent
		}

		func textDidChange(_ notification: Notification) {
			guard let textView = notification.object as? NSTextView else { return }
			parent.text = textView.string
		}
	}
}
