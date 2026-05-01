import ArgumentParser
import Foundation
import GitLinkKit

extension OutputFormat: ExpressibleByArgument {}

@main
struct GitLink: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate web links for GitHub repositories.",
        usage: """
            gitlink [options] [<path>[:<line>[-<end_line>]]]
            """,
        discussion: """
            Converts local file or directory paths into web URLs for sharing.
            Run with no arguments to link to the repo root on the current branch.
            Currently supports GitHub.

            Examples:
              gitlink                                         Repo root on current branch
              gitlink --branch develop                        Repo root on specific branch
              gitlink --commit abc123                         Commit page
              gitlink Sources/App/main.swift                  File on current branch
              gitlink Sources/App/main.swift:12-20            File with line range
              gitlink --commit HEAD Sources/App/main.swift    File pinned to commit
              gitlink --output markdown Sources/App/main.swift:12-20  Markdown link
              gitlink --copy --output markdown Sources/App/main.swift Copy markdown to clipboard
            """
    )

    @Argument(help: "File or directory path, optionally with :<line>[-<end>] (e.g. Sources/main.swift:12-20)")
    var path: String?

    @Option(name: .long, help: "Use a specific branch instead of the current one.")
    var branch: String?

    @Option(name: .long, help: "Pin to a commit hash (e.g. --commit HEAD or --commit abc123).")
    var commit: String?

    @Option(name: .long, help: "Output format: url (default) or markdown.")
    var output: OutputFormat?

    @Flag(name: .long, help: "Copy the output to the clipboard.")
    var copy: Bool = false

    mutating func validate() throws {
        if branch != nil && commit != nil {
            throw ValidationError("--branch and --commit are mutually exclusive.")
        }
    }

    func run() throws {
        let gitService = ShellGitService()
        let generator = LinkGenerator(gitService: gitService)
        let cwd = FileManager.default.currentDirectoryPath
        let format = output ?? .url

        let target: Target

        if let path {
            target = .path(InputParser.parse(path))
        } else if let commit {
            target = .commit(commit)
        } else {
            target = .repoRoot
        }

        let result: LinkGenerator.Result
        do {
            result = try generator.generate(
                target: target,
                workingDirectory: cwd,
                branch: branch,
                commit: target.isPath ? commit : nil
            )
        } catch let error as GitLinkError {
            FileHandle.standardError.write(Data("Error: \(error.errorDescription ?? "\(error)")\n".utf8))
            throw ExitCode.failure
        }

        let formatted = OutputFormatter.format(result: result, format: format)

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
