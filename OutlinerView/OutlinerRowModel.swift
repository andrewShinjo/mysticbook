//
//  OutlinerRowModel.swift
//  mysticbook
//
//  Created by Andrew Shinjo on 8/6/26.
//

import Foundation

struct OutlinerRowModel: Identifiable {
	let id = UUID()
	var text: String
	var depth: Int
	var isExpanded: Bool
	var hasChildren: Bool
	var height: CGFloat
}
