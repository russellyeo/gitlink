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
        let lineCount = content.isEmpty ? 0 : content.components(separatedBy: "\n").count
        return FileInfo(isDirectory: false, lineCount: lineCount)
    }

    public static func validateLines(_ lineSpec: LineSpec, fileInfo: FileInfo) throws {
        if fileInfo.isDirectory {
            throw GitLinkError.linesOnDirectory
        }

        let maxLine: Int
        switch lineSpec {
        case .single(let line):
            maxLine = line
        case .range(_, let end):
            maxLine = end
        }

        if maxLine > fileInfo.lineCount {
            throw GitLinkError.lineOutOfRange(line: maxLine, totalLines: fileInfo.lineCount)
        }
    }
}
