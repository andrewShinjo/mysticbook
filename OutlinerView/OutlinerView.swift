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
			isExpanded: true,
			hasChildren: false,
			height: initialRowHeight
		)
	]
	
	/// A one-shot focus signal: set to the newly inserted row's id so it becomes
	/// first responder, then cleared by `onChange(of: focusedRowId)`.
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
			isExpanded: true,
			hasChildren: false,
			height: initialRowHeight
		)
		
		// Insert the new row after the row's descendants so they stay under
		// the original row instead of being stolen by the new row.
		var insertIndex = index + 1
		while insertIndex < rows.count && rows[insertIndex].depth > row.depth {
			insertIndex += 1
		}
		rows.insert(newRow, at: insertIndex)
		
		refreshHasChildren()
		
		focusedRowId = newRow.id
	}
	
	/// Removes the row with the given id, promotes its descendants one level,
	/// and moves focus to the row above it, or to the row below it when the
	/// first row is removed.
	private func deleteRow(_ rowId: UUID) {
		
		guard let index = rows.firstIndex(where: {
			$0.id == rowId
		}) else {
			return
		}
		
		// Keep the outline from ever becoming empty.
		guard rows.count > 1 else { return }
		
		let oldDepth = rows[index].depth
		rows.remove(at: index)
		
		// The row's descendants become siblings of its former siblings.
		shiftDescendantDepths(from: index, deeperThan: oldDepth, by: -1)
		
		let predecessorIndex = index - 1
		let targetRow = predecessorIndex >= 0
			? rows[predecessorIndex]
			: rows[index]
		
		refreshHasChildren()
		
		focusedRowId = targetRow.id
	}
	
	/// Increases the depth of the row with the given id, along with its descendants.
	private func indentRow(_ rowId: UUID) {
		
		guard let index = rows.firstIndex(where: {
			$0.id == rowId
		}) else {
			return
		}
		
		let oldDepth = rows[index].depth
		
		// A row can be indented only when the row that would become its parent
		// sits directly above it and is exactly one depth level shallower than
		// the row's new depth. The would-be parent is the nearest row above
		// whose depth is at most `oldDepth`; it must be exactly `oldDepth`.
		let parentCandidate = rows[..<index].last(where: {
			$0.depth <= oldDepth
		})
		guard parentCandidate?.depth == oldDepth else {
			return
		}
		
		rows[index].depth = oldDepth + 1
		shiftDescendantDepths(from: index + 1, deeperThan: oldDepth, by: 1)
		
		refreshHasChildren()
	}
	
	/// Decreases the depth of the row with the given id, along with its descendants.
	private func outdentRow(_ rowId: UUID) {
		
		guard let index = rows.firstIndex(where: {
			$0.id == rowId
		}) else {
			return
		}
		
		guard rows[index].depth > 0 else { return }
		
		let oldDepth = rows[index].depth
		rows[index].depth = oldDepth - 1
		shiftDescendantDepths(from: index + 1, deeperThan: oldDepth, by: -1)
		
		refreshHasChildren()
	}
	
	/// Shifts the depth of consecutive rows beginning at `startIndex` whose
	/// depth is greater than `parentDepth`, stopping at the first row whose
	/// depth is at most `parentDepth`.
	private func shiftDescendantDepths(
		from startIndex: Int,
		deeperThan parentDepth: Int,
		by delta: Int
	) {
		
		var index = startIndex
		while index < rows.count && rows[index].depth > parentDepth {
			rows[index].depth += delta
			index += 1
		}
	}
	
	/// Recomputes each row's `hasChildren` from the flat structure: a row has
	/// children when the row below it is deeper than it.
	private func refreshHasChildren() {
		for index in rows.indices {
			rows[index].hasChildren = index + 1 < rows.count
				&& rows[index + 1].depth > rows[index].depth
		}
	}
	
	/// The row bindings to render: consecutive rows whose depth is greater than
	/// the nearest collapsed ancestor's depth are hidden until it expands.
	private var visibleRowBindings: [Binding<OutlinerRowModel>] {
		
		var collapsedDepth: Int?
		var result: [Binding<OutlinerRowModel>] = []
		
		for binding in Array($rows) {
			let row = binding.wrappedValue
			
			if let depth = collapsedDepth, row.depth > depth {
				continue
			}
			
			collapsedDepth = nil
			result.append(binding)
			
			if row.hasChildren && !row.isExpanded {
				collapsedDepth = row.depth
			}
		}
		
		return result
	}
	
	var body: some View {
		ScrollView {
			LazyVStack(alignment: .leading, spacing: 0) {
				ForEach(visibleRowBindings, id: \.wrappedValue.id) {
					$row in
					OutlinerRowView(
						row: $row,
						isFocused: row.id == focusedRowId,
						onInsertNewRow: insertNewRow,
						onDeleteRow: deleteRow,
						onIndentRow: indentRow,
						onOutdentRow: outdentRow
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
