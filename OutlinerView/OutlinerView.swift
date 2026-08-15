//
//  OutlinerView.swift
//  mysticbook
//
//  Created by Andrew Shinjo on 8/6/26.
//

import SwiftUI

private let initialRowHeight: CGFloat = 20
private let rootRowIndex = 0
private let rootRowDepth = 0
private let minimumRowDepth = 1

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
	
	@State
	private var focusedRowId: UUID?
	
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
			// The root row (depth 0) is the only row at its depth; a row split
			// off it must become its child at depth 1.
			depth: max(row.depth, minimumRowDepth),
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
	/// and moves focus to the row above it.
	private func deleteRow(_ rowId: UUID) {
		
		guard let index = rows.firstIndex(where: {
			$0.id == rowId
		}) else {
			return
		}
		
		// The root row is the topmost row and can never be deleted.
		guard index != rootRowIndex else { return }
		
		// Keep the outline from ever becoming empty.
		guard rows.count > 1 else { return }
		
		let oldDepth = rows[index].depth
		rows.remove(at: index)
		
		// The row's descendants become siblings of its former siblings.
		shiftDescendantDepths(from: index, deeperThan: oldDepth, by: -1)
		
		// A row above always exists because the root row can never be deleted.
		let targetRow = rows[index - 1]
		
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
		
		// The root row can never be indented.
		guard index != rootRowIndex else { return }
		
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
		
		// Non-root rows bottom out at depth 1; the root row (depth 0) can
		// never be outdented.
		guard rows[index].depth > minimumRowDepth else { return }
		
		let oldDepth = rows[index].depth
		rows[index].depth = oldDepth - 1
		shiftDescendantDepths(from: index + 1, deeperThan: oldDepth, by: -1)
		
		refreshHasChildren()
	}
	
	/// Tracks focus: records the focused row, and clears it only when the
	/// currently focused row resigns.
	private func updateFocus(for rowId: UUID, focused: Bool) {
		if focused {
			focusedRowId = rowId
		}
		else if focusedRowId == rowId {
			focusedRowId = nil
		}
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
	
	/// The full-array indices of the rows to render: consecutive rows whose
	/// depth is greater than the nearest collapsed ancestor's depth are hidden
	/// until it expands.
	private var visibleRowIndices: [Int] {
		
		var collapsedDepth: Int?
		var result: [Int] = []
		
		for index in rows.indices {
			let row = rows[index]
			
			if let depth = collapsedDepth, row.depth > depth {
				continue
			}
			
			collapsedDepth = nil
			result.append(index)
			
			if row.hasChildren && !row.isExpanded {
				collapsedDepth = row.depth
			}
		}
		
		return result
	}
	
	/// The row bindings to render, derived from the visible row indices.
	private var visibleRowBindings: [Binding<OutlinerRowModel>] {
		visibleRowIndices.map { $rows[$0] }
	}
	
	/// Moves the dragged row, along with the hidden descendants it carries, to
	/// a new visible position. The dragged row becomes a sibling of the row now
	/// above it (a child of the root when it lands directly beneath it), while
	/// its descendants keep their depth offsets relative to the row, preserving
	/// the outline's tree shape.
	///
	/// The move arrives in visible-row indices, which the dragged row's hidden
	/// descendants do not occupy; the full rows array is remapped both times.
	private func moveRows(from source: IndexSet, to destination: Int) {
		
		// The root row is topmost and can never be dragged.
		guard !source.contains(0), let sourceIndex = source.min() else { return }
		
		let visible = visibleRowIndices
		guard sourceIndex < visible.count else { return }
		
		// Find the dragged row's subtree: the contiguous rows below it whose
		// depth is greater than its own.
		let startIndex = visible[sourceIndex]
		let topDepth = rows[startIndex].depth
		
		var subtreeEnd = startIndex + 1
		while subtreeEnd < rows.count && rows[subtreeEnd].depth > topDepth {
			subtreeEnd += 1
		}
		
		// Extract the subtree, then remap the visible indices over the rows
		// that remain so the drop position lands correctly.
		var subtree = Array(rows[startIndex..<subtreeEnd])
		rows.removeSubrange(startIndex..<subtreeEnd)
		
		// The drop offset arrives relative to the array before the move, so
		// shrink it by the one visible row the removal took, matching the
		// semantics of `move(fromOffsets:toOffset:)`. A drop at the very top
		// would place the row above the root, which must stay topmost; clamp it
		// to just below the root.
		var destination = destination
		if sourceIndex < destination { destination -= 1 }
		if destination <= 0 { destination = 1 }
		
		let remainingVisible = visibleRowIndices
		let insertIndex: Int
		if destination >= remainingVisible.count {
			insertIndex = rows.endIndex
		}
		else {
			insertIndex = remainingVisible[destination]
		}
		
		// The subtree's top becomes a sibling of the row above the drop; rows
		// below it keep their depth offsets, which preserves the invariant that
		// a row's depth is at most one more than the row above it.
		let baseDepth = insertIndex > 0
			? max(rows[insertIndex - 1].depth, minimumRowDepth)
			: minimumRowDepth
		let offsets = subtree.map { $0.depth - topDepth }
		for index in subtree.indices {
			subtree[index].depth = baseDepth + offsets[index]
		}
		
		rows.insert(contentsOf: subtree, at: insertIndex)
		
		refreshHasChildren()
	}
	
	var body: some View {
		List {
			ForEach(visibleRowBindings, id: \.wrappedValue.id) {
				$row in
				OutlinerRowView(
					row: $row,
					isRoot: row.depth == rootRowDepth,
					isFocused: row.id == focusedRowId,
					onFocusChange: {
						updateFocus(for: row.id, focused: $0)
					},
					onInsertNewRow: insertNewRow,
					onDeleteRow: deleteRow,
					onIndentRow: indentRow,
					onOutdentRow: outdentRow
				)
				.listRowSeparator(.hidden)
				.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
				.listRowBackground(Color.clear)
				.moveDisabled(row.depth == rootRowDepth)
			}
			.onMove(perform: moveRows)
		}
		.listStyle(.plain)
		.scrollContentBackground(.hidden)
	}
}

#Preview {
	OutlinerView()
}
