///
/// SourceLocation.swift
///
/// Copyright 2016-2017 the Trill project authors.
/// Licensed under the MIT License.
///
/// Full license text available at https://github.com/trill-lang/trill
///

import Foundation

public struct SourceLocation: CustomStringConvertible {
  public let file: String?
  public var line: Int
  public var column: Int
  public var charOffset: Int

  public init(line: Int, column: Int, file: String? = nil, charOffset: Int = 0) {
    self.file = file
    self.line = line
    self.column = column
    self.charOffset = charOffset
  }

  public var description: String {
    let basename: String
    if let file = file {
      basename = URL(fileURLWithPath: file).lastPathComponent
    } else {
      basename = "<none>"
    }
    return "<\(basename):\(line):\(column)>"
  }

  public static let zero = SourceLocation(line: 0, column: 0)
}

extension SourceLocation: Comparable {}
public func ==(lhs: SourceLocation, rhs: SourceLocation) -> Bool {
  if lhs.charOffset == rhs.charOffset { return true }
  return lhs.line == rhs.line && lhs.column == rhs.column
}

public func <(lhs: SourceLocation, rhs: SourceLocation) -> Bool {
  if lhs.charOffset < rhs.charOffset { return true }
  if lhs.line < rhs.line { return true }
  return lhs.column < rhs.column
}

public struct SourceRange {
  public let start: SourceLocation
  public let end: SourceLocation

  public init(start: SourceLocation, end: SourceLocation) {
    self.start = start
    self.end = end
  }
  
  public static let zero = SourceRange(start: .zero, end: .zero)
}

extension SourceRange: Equatable {
  public static func ==(lhs: SourceRange, rhs: SourceRange) -> Bool {
    return lhs.start == rhs.start && lhs.end == rhs.end
  }
}
