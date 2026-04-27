import ArgumentParser
import Foundation
import GitLinkKit

extension OutputFormat: ExpressibleByArgument {}

@main
struct GitLink: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate web links from local file paths for GitHub, GitLab, and Bitbucket repositories.",
        usage: """
            gitlink <path>[:<line>[-<end_line>]]
            gitlink --commit <hash> <path>[:<line>[-<end_line>]]
            gitlink --branch <name> <path>[:<line>[-<end_line>]]
            """,
        discussion: """
            Converts local file or directory paths into web URLs for sharing.
            Currently supports GitHub. GitLab and Bitbucket support is planned.

            Examples:
              gitlink Sources/App/main.swift              File on current branch
              gitlink Sources/App/main.swift:12-20        File with line range
              gitlink Sources/App/                        Directory
              gitlink --commit HEAD Sources/App/main.swift    Pinned to HEAD commit
              gitlink --commit abc123 Sources/App/main.swift  Pinned to specific commit
              gitlink --branch main Sources/App/main.swift    Specific branch
              gitlink --copy Sources/App/main.swift       Copy URL to clipboard
            """
    )

    @Argument(help: "File or directory path, optionally with :<line>[-<end>] (e.g. Sources/main.swift:12-20)")
    var path: String

    @Option(name: .long, help: "Use a specific branch instead of the current one.")
    var branch: String?

    @Option(name: .long, help: "Pin to a commit hash (e.g. --commit HEAD or --commit abc123).")
    var commit: String?

    @Option(name: .long, help: "Output format: url (default) or markdown.")
    var output: OutputFormat?

    @Flag(name: .long, help: "Copy the URL to the clipboard.")
    var copy: Bool = false

    mutating func validate() throws {
        if branch != nil && commit != nil {
            throw ValidationError("--branch and --commit are mutually exclusive.")
        }
    }

    func run() throws {
        let generator = LinkGenerator(gitService: ShellGitService())
        let cwd = FileManager.default.currentDirectoryPath
        let format = output ?? .url

        let result: LinkGenerator.Result
        do {
            result = try generator.generate(
                input: path,
                workingDirectory: cwd,
                branch: branch,
                commit: commit
            )
        } catch let error as GitLinkError {
            FileHandle.standardError.write(Data("Error: \(error.errorDescription ?? "\(error)")\n".utf8))
            throw ExitCode.failure
        }

        let formatted = OutputFormatter.format(
            url: result.url,
            path: result.relativePath,
            lineSpec: result.lineSpec,
            format: format
        )

        print(formatted)

        if copy {
            copyToClipboard(formatted)
        }
    }

    private func copyToClipboard(_ text: String) {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pbcopy")
        process.standardInput = pipe
        try? process.run()
        pipe.fileHandleForWriting.write(Data(text.utf8))
        pipe.fileHandleForWriting.closeFile()
        process.waitUntilExit()
    }
}
