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
  public let file: SourceFile
  public var line: Int
  public var column: Int
  public var charOffset: Int

  public init(line: Int, column: Int, file: SourceFile, charOffset: Int = 0) {
    self.file = file
    self.line = line
    self.column = column
    self.charOffset = charOffset
  }

  public var description: String {
    let basename = file.path.basename
    return "<\(basename):\(line):\(column)>"
  }
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
}

extension SourceRange: Equatable {
  public static func ==(lhs: SourceRange, rhs: SourceRange) -> Bool {
    return lhs.start == rhs.start && lhs.end == rhs.end
  }
}
