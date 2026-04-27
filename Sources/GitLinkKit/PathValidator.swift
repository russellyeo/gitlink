import Foundation

public struct FileInfo: Equatable {
    public let isDirectory: Bool
    public let lineCount: Int
}

public enum PathValidator {

    public static func validate(path: String) throws -> FileInfo {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir) else {
            throw GitLinkError.pathNotFound(path)
        }

        if isDir.boolValue {
            return FileInfo(isDirectory: true, lineCount: 0)
        }

        let content = try String(contentsOfFile: path, encoding: .utf8)
        if content.isEmpty { return FileInfo(isDirectory: false, lineCount: 0) }
        var lines = content.components(separatedBy: "\n")
        if lines.last == "" { lines.removeLast() }
        let lineCount = lines.count
        return FileInfo(isDirectory: false, lineCount: lineCount)
    }

    public static func validateLines(_ lineSpec: LineSpec, fileInfo: FileInfo) throws {
        if fileInfo.isDirectory {
            throw GitLinkError.linesOnDirectory
        }

        if lineSpec.maxLine > fileInfo.lineCount {
            throw GitLinkError.lineOutOfRange(line: lineSpec.maxLine, totalLines: fileInfo.lineCount)
        }
    }
}
