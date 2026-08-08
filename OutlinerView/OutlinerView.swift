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
	
	@State private var rows: [OutlinerRowModel] = [
		OutlinerRowModel(
			text: "Hello",
			depth: 0,
			isExpanded: false,
			hasChildren: false,
			height: initialRowHeight
		)
	]
	
	var body: some View {
		ScrollView {
			LazyVStack(alignment: .leading, spacing: 0) {
				ForEach($rows) {
					$row in OutlinerRowView(row: $row)
				}
			}
		}
	}
}

#Preview {
	OutlinerView()
}
