///
/// SourceFileManager.swift
///
/// Copyright 2016-2017 the Trill project authors.
/// Licensed under the MIT License.
///
/// Full license text available at https://github.com/trill-lang/trill
///

public final class SourceFileManager {
  private var contentsCache = [SourceFile: String]()
  private var linesCache = [SourceFile: [String]]()

  public init() {}

  public func contents(of file: SourceFile) throws -> String {
    if let contents = contentsCache[file] { return contents }
    let contents = try fetchContents(file: file)
    contentsCache[file] = contents
    return contents
  }

  public func lines(in file: SourceFile) throws -> [String] {
    if let lines = linesCache[file] { return lines }
    let contents = try self.contents(of: file)
    let lines = contents.components(separatedBy: .newlines)
    linesCache[file] = lines
    return lines
  }

  private func fetchContents(file: SourceFile) throws -> String {
    switch file.path {
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
}
