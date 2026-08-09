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
	
	/// Invoked when Return key is pressed without Shift.
	var onInsertNewline: (() -> Void)?
	
	/// Invoked when the backspace or forward-delete key is pressed with the cursor at position 0.
	var onDeleteRow: (() -> Void)?
	
	/// Invoked when the Tab key is pressed.
	var onIndentRow: (() -> Void)?
	
	/// Invoked when Shift+Tab is pressed.
	var onOutdentRow: (() -> Void)?
	
	/// Invoked after each layout pass of the text view.
	var onLayout: (() -> Void)?
	
	/// Handles the Return key press.
	override func insertNewline(_ sender: Any?) {
		
		let isShiftPressed = NSApp.currentEvent?.modifierFlags.contains(.shift)
			?? false
		
		if isShiftPressed {
			super.insertNewline(sender)
		}
		else {
			onInsertNewline?()
		}
		
	}
	
	/// Handles the Backspace key press.
	override func deleteBackward(_ sender: Any?) {
		
		let range = selectedRange()
		
		// The backspace key is labeled "delete" on Mac keyboards. When the cursor
		// sits at position 0 with no selection it would do nothing; delete the
		// whole row instead.
		if range.location == 0 && range.length == 0 {
			onDeleteRow?()
		}
		else {
			super.deleteBackward(sender)
		}
		
	}
	
	/// Handles the forward-delete key press.
	override func deleteForward(_ sender: Any?) {
		
		let range = selectedRange()
		
		// When the cursor sits at position 0 with no selection, forward-delete
		// would delete the row's first character; delete the whole row instead.
		if range.location == 0 && range.length == 0 {
			onDeleteRow?()
		}
		else {
			super.deleteForward(sender)
		}
		
	}
	
	/// Handles the Tab key press.
	override func insertTab(_ sender: Any?) {
		
		// Indent the row instead of inserting a tab character into the text.
		onIndentRow?()
		
	}
	
	/// Handles the Shift+Tab key press.
	override func insertBacktab(_ sender: Any?) {
		
		onOutdentRow?()
		
	}
	
	/// Lays out the text and reports the completed layout to `onLayout`.
	override func layout() {
		super.layout()
		onLayout?()
	}
}
