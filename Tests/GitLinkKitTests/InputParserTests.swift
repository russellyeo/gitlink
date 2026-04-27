import XCTest
@testable import GitLinkKit

final class InputParserTests: XCTestCase {

    // MARK: - Path only (no line spec)

    func test_parse_filePath_returnsPathWithNoLines() {
        // GIVEN a plain file path with no line spec
        let input = "Sources/App/main.swift"

        // WHEN we parse the input
        let result = InputParser.parse(input)

        // THEN the path is extracted with no line spec
        XCTAssertEqual(result.path, "Sources/App/main.swift")
        XCTAssertNil(result.lineSpec)
    }

    func test_parse_directoryPath_returnsPathWithNoLines() {
        // GIVEN a directory path
        let input = "Sources/App/"

        // WHEN we parse the input
        let result = InputParser.parse(input)

        // THEN the path is extracted with no line spec
        XCTAssertEqual(result.path, "Sources/App/")
        XCTAssertNil(result.lineSpec)
    }

    // MARK: - Single line

    func test_parse_pathWithSingleLine_returnsSingleLine() {
        // GIVEN a path with a single line number
        let input = "Sources/App/main.swift:12"

        // WHEN we parse the input
        let result = InputParser.parse(input)

        // THEN the path and single line are extracted
        XCTAssertEqual(result.path, "Sources/App/main.swift")
        XCTAssertEqual(result.lineSpec, .single(12))
    }

    // MARK: - Line range

    func test_parse_pathWithLineRange_returnsRange() {
        // GIVEN a path with a line range
        let input = "Sources/App/main.swift:12-20"

        // WHEN we parse the input
        let result = InputParser.parse(input)

        // THEN the path and line range are extracted
        XCTAssertEqual(result.path, "Sources/App/main.swift")
        XCTAssertEqual(result.lineSpec, .range(start: 12, end: 20))
    }

    // MARK: - Edge cases

    func test_parse_pathWithNoColon_treatsWholeInputAsPath() {
        // GIVEN a path with no colon at all
        let input = "README.md"

        // WHEN we parse the input
        let result = InputParser.parse(input)

        // THEN the entire input is the path
        XCTAssertEqual(result.path, "README.md")
        XCTAssertNil(result.lineSpec)
    }

    func test_parse_pathWithNonNumericAfterColon_treatsWholeInputAsPath() {
        // GIVEN a path where the part after the last colon is not numeric
        let input = "Sources/App/main.swift:abc"

        // WHEN we parse the input
        let result = InputParser.parse(input)

        // THEN the entire input is treated as the path (colon is part of path)
        XCTAssertEqual(result.path, "Sources/App/main.swift:abc")
        XCTAssertNil(result.lineSpec)
    }

    // MARK: - Validation errors

    func test_validateLineSpec_withZeroLine_throwsInvalidLineSpec() {
        // GIVEN a line spec with zero
        let spec = LineSpec.single(0)

        // WHEN we validate the line spec
        // THEN it throws an invalidLineSpec error
        XCTAssertThrowsError(try InputParser.validateLineSpec(spec)) { error in
            XCTAssertEqual(error as? GitLinkError, .invalidLineSpec("0"))
        }
    }

    func test_validateLineSpec_withReversedRange_throwsInvalidLineSpec() {
        // GIVEN a line spec where start > end
        let spec = LineSpec.range(start: 20, end: 12)

        // WHEN we validate the line spec
        // THEN it throws an invalidLineSpec error
        XCTAssertThrowsError(try InputParser.validateLineSpec(spec)) { error in
            XCTAssertEqual(error as? GitLinkError, .invalidLineSpec("20-12"))
        }
    }

    func test_validateLineSpec_withNegativeLine_throwsInvalidLineSpec() {
        // GIVEN a line spec with a negative number
        let spec = LineSpec.single(-1)

        // WHEN we validate the line spec
        // THEN it throws an invalidLineSpec error
        XCTAssertThrowsError(try InputParser.validateLineSpec(spec)) { error in
            XCTAssertEqual(error as? GitLinkError, .invalidLineSpec("-1"))
        }
    }

    func test_validateLineSpec_withValidSingleLine_doesNotThrow() {
        // GIVEN a valid single line spec
        let spec = LineSpec.single(5)

        // WHEN we validate the line spec
        // THEN no error is thrown
        XCTAssertNoThrow(try InputParser.validateLineSpec(spec))
    }

    func test_validateLineSpec_withValidRange_doesNotThrow() {
        // GIVEN a valid line range
        let spec = LineSpec.range(start: 5, end: 10)

        // WHEN we validate the line spec
        // THEN no error is thrown
        XCTAssertNoThrow(try InputParser.validateLineSpec(spec))
    }

    func test_parse_pathWithSameStartAndEnd_returnsSingleLine() {
        // GIVEN a range where start equals end
        let input = "main.swift:5-5"

        // WHEN we parse the input
        let result = InputParser.parse(input)

        // THEN it is treated as a range (start equals end)
        XCTAssertEqual(result.path, "main.swift")
        XCTAssertEqual(result.lineSpec, .range(start: 5, end: 5))
    }
}
