//
//  Date+Display.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

extension Date {
    var shortDisplay: String {
        formatted(date: .abbreviated, time: .shortened)
    }
}
