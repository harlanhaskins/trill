///
/// ANSIColor.swift
///
/// Copyright 2016-2017 the Trill project authors.
/// Licensed under the MIT License.
///
/// Full license text available at https://github.com/trill-lang/trill
///

import Foundation

public enum ANSIColor: String {
    case black = "\u{001B}[30m"
    case red = "\u{001B}[31m"
    case green = "\u{001B}[32m"
    case yellow = "\u{001B}[33m"
    case blue = "\u{001B}[34m"
    case magenta = "\u{001B}[35m"
    case cyan = "\u{001B}[36m"
    case white = "\u{001B}[37m"
    case bold = "\u{001B}[1m"
    case reset = "\u{001B}[0m"
    
    public func name() -> String {
        switch self {
        case .black: return "Black"
        case .red: return "Red"
        case .green: return "Green"
        case .yellow: return "Yellow"
        case .blue: return "Blue"
        case .magenta: return "Magenta"
        case .cyan: return "Cyan"
        case .white: return "White"
        case .bold: return "Bold"
        case .reset: return "Reset"
        }
    }
    
    public static func all() -> [ANSIColor] {
        return [.black, .red, .green,
                .yellow, .blue, .magenta,
                .cyan, .white, .bold, .reset]
    }
}

public func +(left: ANSIColor, right: String) -> String {
    return left.rawValue + right
}
