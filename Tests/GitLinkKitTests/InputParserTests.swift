import Testing
@testable import GitLinkKit

@Suite struct InputParserTests {

    // MARK: - Path only (no line spec)

    @Test func parse_filePath_returnsPathWithNoLines() {
        // GIVEN a plain file path with no line spec
        let input = "Sources/App/main.swift"

        // WHEN we parse the input
        let result = InputParser.parse(input)

        // THEN the path is extracted with no line spec
        #expect(result.path == "Sources/App/main.swift")
        #expect(result.lineSpec == nil)
    }

    @Test func parse_directoryPath_returnsPathWithNoLines() {
        // GIVEN a directory path
        let input = "Sources/App/"

        // WHEN we parse the input
        let result = InputParser.parse(input)

        // THEN the path is extracted with no line spec
        #expect(result.path == "Sources/App/")
        #expect(result.lineSpec == nil)
    }

    // MARK: - Single line

    @Test func parse_pathWithSingleLine_returnsSingleLine() {
        // GIVEN a path with a single line number
        let input = "Sources/App/main.swift:12"

        // WHEN we parse the input
        let result = InputParser.parse(input)

        // THEN the path and single line are extracted
        #expect(result.path == "Sources/App/main.swift")
        #expect(result.lineSpec == .single(12))
    }

    // MARK: - Line range

    @Test func parse_pathWithLineRange_returnsRange() {
        // GIVEN a path with a line range
        let input = "Sources/App/main.swift:12-20"

        // WHEN we parse the input
        let result = InputParser.parse(input)

        // THEN the path and line range are extracted
        #expect(result.path == "Sources/App/main.swift")
        #expect(result.lineSpec == .range(start: 12, end: 20))
    }

    // MARK: - Edge cases

    @Test func parse_pathWithNoColon_treatsWholeInputAsPath() {
        // GIVEN a path with no colon at all
        let input = "README.md"

        // WHEN we parse the input
        let result = InputParser.parse(input)

        // THEN the entire input is the path
        #expect(result.path == "README.md")
        #expect(result.lineSpec == nil)
    }

    @Test func parse_pathWithNonNumericAfterColon_treatsWholeInputAsPath() {
        // GIVEN a path where the part after the last colon is not numeric
        let input = "Sources/App/main.swift:abc"

        // WHEN we parse the input
        let result = InputParser.parse(input)

        // THEN the entire input is treated as the path (colon is part of path)
        #expect(result.path == "Sources/App/main.swift:abc")
        #expect(result.lineSpec == nil)
    }

    // MARK: - Validation errors

    @Test func validateLineSpec_withZeroLine_throwsInvalidLineSpec() {
        // GIVEN a line spec with zero
        let spec = LineSpec.single(0)

        // WHEN we validate the line spec
        // THEN it throws an invalidLineSpec error
        #expect(throws: GitLinkError.invalidLineSpec("0")) {
            try spec.validate()
        }
    }

    @Test func validateLineSpec_withReversedRange_throwsInvalidLineSpec() {
        // GIVEN a line spec where start > end
        let spec = LineSpec.range(start: 20, end: 12)

        // WHEN we validate the line spec
        // THEN it throws an invalidLineSpec error
        #expect(throws: GitLinkError.invalidLineSpec("20-12")) {
            try spec.validate()
        }
    }

    @Test func validateLineSpec_withNegativeLine_throwsInvalidLineSpec() {
        // GIVEN a line spec with a negative number
        let spec = LineSpec.single(-1)

        // WHEN we validate the line spec
        // THEN it throws an invalidLineSpec error
        #expect(throws: GitLinkError.invalidLineSpec("-1")) {
            try spec.validate()
        }
    }

    @Test func validateLineSpec_withValidSingleLine_doesNotThrow() throws {
        // GIVEN a valid single line spec
        let spec = LineSpec.single(5)

        // WHEN we validate the line spec
        // THEN no error is thrown
        try spec.validate()
    }

    @Test func validateLineSpec_withValidRange_doesNotThrow() throws {
        // GIVEN a valid line range
        let spec = LineSpec.range(start: 5, end: 10)

        // WHEN we validate the line spec
        // THEN no error is thrown
        try spec.validate()
    }

    @Test func parse_pathWithSameStartAndEnd_returnsSingleLine() {
        // GIVEN a range where start equals end
        let input = "main.swift:5-5"

        // WHEN we parse the input
        let result = InputParser.parse(input)

        // THEN it is treated as a range (start equals end)
        #expect(result.path == "main.swift")
        #expect(result.lineSpec == .range(start: 5, end: 5))
    }
}
