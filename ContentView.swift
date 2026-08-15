//
//  ContentView.swift
//  mysticbook
//
//  Created by Andrew Shinjo on 8/6/26.
//

import SwiftUI

struct ContentView: View {
	@State private var numbers = Array(0..<4)
    var body: some View {
			OutlinerView().padding()
//			List {
//				ForEach(numbers, id: \.self) { number in
//					Text("Number \(number)")
//						.font(.title)
//						.draggable(String(number))
//				}
//				.onMove { indices, newOffset in
//					numbers.move(fromOffsets: indices, toOffset: newOffset)
//				}
//			}
//			.padding()
    }
}

#Preview {
    ContentView()
}
