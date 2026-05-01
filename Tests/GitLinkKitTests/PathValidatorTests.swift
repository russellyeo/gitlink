import Foundation
import Testing
@testable import GitLinkKit

@Suite struct PathValidatorTests {

    private let tempDir: URL

    init() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitLinkKitTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    // MARK: - Path existence

    @Test func validate_existingFile_returnsFileInfo() throws {
        // GIVEN a file that exists with 10 lines
        let filePath = tempDir.appendingPathComponent("test.swift")
        let content = (1...10).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)

        // WHEN we validate the path
        let result = try PathValidator.validate(path: filePath.path)

        // THEN it returns file info indicating it's not a directory
        #expect(!result.isDirectory)
        #expect(result.lineCount == 10)
    }

    @Test func validate_existingDirectory_returnsDirectoryInfo() throws {
        // GIVEN a directory that exists
        let dirPath = tempDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true)

        // WHEN we validate the path
        let result = try PathValidator.validate(path: dirPath.path)

        // THEN it returns directory info
        #expect(result.isDirectory)
    }

    @Test func validate_nonExistentPath_throwsPathNotFound() {
        // GIVEN a path that doesn't exist
        let fakePath = tempDir.appendingPathComponent("nope.swift").path

        // WHEN we validate the path
        // THEN it throws a pathNotFound error
        #expect(throws: GitLinkError.pathNotFound(fakePath)) {
            try PathValidator.validate(path: fakePath)
        }
    }

    // MARK: - Line validation

    @Test func validateLines_singleLineInRange_doesNotThrow() throws {
        // GIVEN a file with 10 lines
        let filePath = tempDir.appendingPathComponent("test.swift")
        let content = (1...10).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)
        let info = try PathValidator.validate(path: filePath.path)

        // WHEN we validate a single line within range
        // THEN no error is thrown
        try PathValidator.validateLines(.single(5), fileInfo: info)
    }

    @Test func validateLines_singleLineOutOfRange_throwsLineOutOfRange() throws {
        // GIVEN a file with 10 lines
        let filePath = tempDir.appendingPathComponent("test.swift")
        let content = (1...10).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)
        let info = try PathValidator.validate(path: filePath.path)

        // WHEN we validate a line beyond the file length
        // THEN it throws a lineOutOfRange error
        #expect(throws: GitLinkError.lineOutOfRange(line: 11, totalLines: 10)) {
            try PathValidator.validateLines(.single(11), fileInfo: info)
        }
    }

    @Test func validateLines_rangeEndOutOfRange_throwsLineOutOfRange() throws {
        // GIVEN a file with 10 lines
        let filePath = tempDir.appendingPathComponent("test.swift")
        let content = (1...10).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)
        let info = try PathValidator.validate(path: filePath.path)

        // WHEN we validate a range where the end exceeds file length
        // THEN it throws a lineOutOfRange error
        #expect(throws: GitLinkError.lineOutOfRange(line: 15, totalLines: 10)) {
            try PathValidator.validateLines(.range(start: 5, end: 15), fileInfo: info)
        }
    }

    @Test func validateLines_onDirectory_throwsLinesOnDirectory() throws {
        // GIVEN a directory
        let dirPath = tempDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true)
        let info = try PathValidator.validate(path: dirPath.path)

        // WHEN we validate lines on a directory
        // THEN it throws a linesOnDirectory error
        #expect(throws: GitLinkError.linesOnDirectory) {
            try PathValidator.validateLines(.single(1), fileInfo: info)
        }
    }

    @Test func validate_fileWithTrailingNewline_countsCorrectly() throws {
        // GIVEN a file with 10 lines and a trailing newline
        let filePath = tempDir.appendingPathComponent("trailing.swift")
        let content = (1...10).map { "line \($0)" }.joined(separator: "\n") + "\n"
        try content.write(to: filePath, atomically: true, encoding: .utf8)

        // WHEN we validate the path
        let result = try PathValidator.validate(path: filePath.path)

        // THEN line count is 10, not 11
        #expect(result.lineCount == 10)
    }

    @Test func validate_emptyFile_hasZeroLines() throws {
        // GIVEN an empty file
        let filePath = tempDir.appendingPathComponent("empty.swift")
        try "".write(to: filePath, atomically: true, encoding: .utf8)

        // WHEN we validate the path
        let result = try PathValidator.validate(path: filePath.path)

        // THEN line count is 0
        #expect(result.lineCount == 0)
    }
}
