//
//  OutlinerTextView.swift
//  mysticbook
//
//  Created by Andrew Shinjo on 8/8/26.
//

import AppKit

final class OutlinerTextView: NSTextView {
	
	var onLayout: (() -> Void)?
	
	override func layout() {
		super.layout()
		onLayout?()
	}
}

