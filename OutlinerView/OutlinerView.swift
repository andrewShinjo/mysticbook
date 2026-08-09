//
//  OutlinerView.swift
//  mysticbook
//
//  Created by Andrew Shinjo on 8/6/26.
//

import SwiftUI

/// A placeholder height, in points, used for a row before it is measured.
private let initialRowHeight: CGFloat = 20

/// The editable outline: a scrollable list of rows, each rendered by `OutlinerRowView`.
struct OutlinerView: View {
	
	@State
	private var rows: [OutlinerRowModel] = [
		OutlinerRowModel(
			text: "Hello",
			depth: 0,
			isExpanded: false,
			hasChildren: false,
			height: initialRowHeight
		)
	]
	
	@State
	private var focusedRowId: UUID?
	
	/// Splits the row's text at the cursor, and inserts a new sibling row below it.
	private func insertNewRow(
		in rowId: UUID,
		textView: NSTextView
	) {
		
		guard let index = rows.firstIndex(where: {
			$0.id == rowId
		}) else {
			return
		}
		
		let row = rows[index]
		let fullText = textView.string as NSString
		let location = textView.selectedRange().location
		let before = fullText.substring(to: location)
		let after = fullText.substring(from: location)
		
		rows[index].text = before
		
		let newRow = OutlinerRowModel(
			text: after,
			depth: row.depth,
			isExpanded: false,
			hasChildren: false,
			height: initialRowHeight
		)
		
		rows.insert(newRow, at: index + 1)
		
		focusedRowId = newRow.id
	}
	
	var body: some View {
		ScrollView {
			LazyVStack(alignment: .leading, spacing: 0) {
				ForEach($rows) {
					$row in
					OutlinerRowView(
						row: $row,
						isFocused: row.id == focusedRowId,
						onInsertNewRow: insertNewRow
					)
				}
			}
		}
		.onChange(of: focusedRowId) { _, newValue in
			if newValue != nil {
				focusedRowId = nil
			}
		}
	}
}

#Preview {
	OutlinerView()
}
