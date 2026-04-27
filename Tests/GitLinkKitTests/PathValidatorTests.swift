import XCTest
@testable import GitLinkKit

final class PathValidatorTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitLinkKitTests-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Path existence

    func test_validate_existingFile_returnsFileInfo() throws {
        // GIVEN a file that exists with 10 lines
        let filePath = tempDir.appendingPathComponent("test.swift")
        let content = (1...10).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)

        // WHEN we validate the path
        let result = try PathValidator.validate(path: filePath.path)

        // THEN it returns file info indicating it's not a directory
        XCTAssertFalse(result.isDirectory)
        XCTAssertEqual(result.lineCount, 10)
    }

    func test_validate_existingDirectory_returnsDirectoryInfo() throws {
        // GIVEN a directory that exists
        let dirPath = tempDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true)

        // WHEN we validate the path
        let result = try PathValidator.validate(path: dirPath.path)

        // THEN it returns directory info
        XCTAssertTrue(result.isDirectory)
    }

    func test_validate_nonExistentPath_throwsPathNotFound() {
        // GIVEN a path that doesn't exist
        let fakePath = tempDir.appendingPathComponent("nope.swift").path

        // WHEN we validate the path
        // THEN it throws a pathNotFound error
        XCTAssertThrowsError(try PathValidator.validate(path: fakePath)) { error in
            XCTAssertEqual(error as? GitLinkError, .pathNotFound(fakePath))
        }
    }

    // MARK: - Line validation

    func test_validateLines_singleLineInRange_doesNotThrow() throws {
        // GIVEN a file with 10 lines
        let filePath = tempDir.appendingPathComponent("test.swift")
        let content = (1...10).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)
        let info = try PathValidator.validate(path: filePath.path)

        // WHEN we validate a single line within range
        // THEN no error is thrown
        XCTAssertNoThrow(try PathValidator.validateLines(.single(5), fileInfo: info))
    }

    func test_validateLines_singleLineOutOfRange_throwsLineOutOfRange() throws {
        // GIVEN a file with 10 lines
        let filePath = tempDir.appendingPathComponent("test.swift")
        let content = (1...10).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)
        let info = try PathValidator.validate(path: filePath.path)

        // WHEN we validate a line beyond the file length
        // THEN it throws a lineOutOfRange error
        XCTAssertThrowsError(try PathValidator.validateLines(.single(11), fileInfo: info)) { error in
            XCTAssertEqual(error as? GitLinkError, .lineOutOfRange(line: 11, totalLines: 10))
        }
    }

    func test_validateLines_rangeEndOutOfRange_throwsLineOutOfRange() throws {
        // GIVEN a file with 10 lines
        let filePath = tempDir.appendingPathComponent("test.swift")
        let content = (1...10).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: filePath, atomically: true, encoding: .utf8)
        let info = try PathValidator.validate(path: filePath.path)

        // WHEN we validate a range where the end exceeds file length
        // THEN it throws a lineOutOfRange error
        XCTAssertThrowsError(try PathValidator.validateLines(.range(start: 5, end: 15), fileInfo: info)) { error in
            XCTAssertEqual(error as? GitLinkError, .lineOutOfRange(line: 15, totalLines: 10))
        }
    }

    func test_validateLines_onDirectory_throwsLinesOnDirectory() throws {
        // GIVEN a directory
        let dirPath = tempDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true)
        let info = try PathValidator.validate(path: dirPath.path)

        // WHEN we validate lines on a directory
        // THEN it throws a linesOnDirectory error
        XCTAssertThrowsError(try PathValidator.validateLines(.single(1), fileInfo: info)) { error in
            XCTAssertEqual(error as? GitLinkError, .linesOnDirectory)
        }
    }

    func test_validate_fileWithTrailingNewline_countsCorrectly() throws {
        // GIVEN a file with 10 lines and a trailing newline
        let filePath = tempDir.appendingPathComponent("trailing.swift")
        let content = (1...10).map { "line \($0)" }.joined(separator: "\n") + "\n"
        try content.write(to: filePath, atomically: true, encoding: .utf8)

        // WHEN we validate the path
        let result = try PathValidator.validate(path: filePath.path)

        // THEN line count is 10, not 11
        XCTAssertEqual(result.lineCount, 10)
    }

    func test_validate_emptyFile_hasZeroLines() throws {
        // GIVEN an empty file
        let filePath = tempDir.appendingPathComponent("empty.swift")
        try "".write(to: filePath, atomically: true, encoding: .utf8)

        // WHEN we validate the path
        let result = try PathValidator.validate(path: filePath.path)

        // THEN line count is 0
        XCTAssertEqual(result.lineCount, 0)
    }
}
