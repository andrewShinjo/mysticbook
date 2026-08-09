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
	
	/// Invoked when the text view gains or loses first responder status.
	var onFocusChange: ((Bool) -> Void)?
	
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
	
	/// Whether this row is the row SwiftUI intends to be focused.
	var isRowFocused = false
	
	/// Reports to `onFocusChange` when the text view becomes first responder.
	override func becomeFirstResponder() -> Bool {
		// When the window is first brought onscreen, AppKit auto-focuses the
		// first key view (the root row). Reject that so no row is focused when
		// the app opens; real clicks (an event is in flight) and SwiftUI-driven
		// focus (the row is flagged) still succeed.
		guard isRowFocused || NSApp.currentEvent != nil else {
			return false
		}
		let became = super.becomeFirstResponder()
		if became {
			onFocusChange?(true)
		}
		return became
	}
	
	/// Reports to `onFocusChange` when the text view resigns first responder.
	override func resignFirstResponder() -> Bool {
		let resigned = super.resignFirstResponder()
		if resigned {
			onFocusChange?(false)
		}
		return resigned
	}
}
