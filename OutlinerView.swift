//
//  OutlinerView.swift
//  mysticbook
//
//  Created by Andrew Shinjo on 8/6/26.
//

import SwiftUI

struct OutlinerView: View {
	
	@State private var rows: [OutlinerRowModel] = [
		OutlinerRowModel(
			text: "Hello",
			depth: 0,
			isExpanded: false,
			hasChildren: false,
			height: 20
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
