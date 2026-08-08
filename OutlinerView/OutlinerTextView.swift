//
//  OutlinerTextView.swift
//  mysticbook
//
//  Created by Andrew Shinjo on 8/8/26.
//

import AppKit

/// An `NSTextView` subclass that reports each completed layout pass to its owner.
///
/// The outliner uses this callback to re-measure the text view's content height
/// and propagate it back to SwiftUI so the row can resize as the text grows.
final class OutlinerTextView: NSTextView {
	
	/// Invoked after each layout pass of the text view.
	var onLayout: (() -> Void)?
	
	/// Lays out the text and reports the completed layout to `onLayout`.
	override func layout() {
		super.layout()
		onLayout?()
	}
}
