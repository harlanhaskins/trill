///
/// SourceFile.swift
///
/// Copyright 2016-2017 the Trill project authors.
/// Licensed under the MIT License.
///
/// Full license text available at https://github.com/trill-lang/trill
///

import Foundation

public enum SourceFileType: Equatable {
  public static func ==(lhs: SourceFileType, rhs: SourceFileType) -> Bool {
    switch (lhs, rhs) {
    case (.input(let lhsURL, _), .input(let rhsURL, _)),
         (.file(let lhsURL), .file(let rhsURL)):
      return lhsURL == rhsURL
    case (.stdin, .stdin):
      return true
    case (.none, .none):
      return true
    default:
      return false
    }
  }

  case input(url: URL, contents: String)
  case file(URL)
  case stdin
  case none
  
  public var basename: String {
    switch self {
    case .file(let url), .input(let url, _):
      return url.lastPathComponent
    case .stdin, .none:
      return filename
    }
  }
  
  public var filename: String {
    switch self {
    case .file(let url), .input(let url, _):
      return url.path
    case .stdin:
      return "<stdin>"
    case .none:
      return "<none>"
    }
  }
}

public struct SourceFile: Equatable {
  public static func ==(lhs: SourceFile, rhs: SourceFile) -> Bool {
    return lhs.path == rhs.path
  }

  public let path: SourceFileType
  public let contents: String
  public let lines: [String]
  
  public init(path: SourceFileType) throws {
    let fetchContents: () throws -> String = {
      switch path {
      case .stdin:
        var str = ""
        while let line = readLine() {
          str += line
        }
        return str
      case .input(_, let contents):
        return contents
      case .file(let url):
        return try String(contentsOf: url)
      case .none:
        return ""
      }
    }
    
    self.path = path
    self.contents = try fetchContents()
    self.lines = self.contents.components(separatedBy: .newlines)
  }
}
