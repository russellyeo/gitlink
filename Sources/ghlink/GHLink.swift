import ArgumentParser
import Foundation
import GHLinkKit

@main
struct GHLink: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate GitHub links from local file paths.",
        usage: """
            ghlink <path>[:<line>[-<end_line>]]
            ghlink --commit [<hash>] <path>[:<line>[-<end_line>]]
            ghlink --branch <name> <path>[:<line>[-<end_line>]]
            """,
        discussion: """
            Converts local file or directory paths into GitHub URLs for sharing.

            Examples:
              ghlink Sources/App/main.swift              File on current branch
              ghlink Sources/App/main.swift:12-20        File with line range
              ghlink Sources/App/                        Directory
              ghlink --commit Sources/App/main.swift     Pinned to HEAD commit
              ghlink --commit abc123 Sources/App/main.swift  Pinned to specific commit
              ghlink --branch main Sources/App/main.swift    Specific branch
              ghlink --copy Sources/App/main.swift       Copy URL to clipboard
            """
    )

    @Argument(help: "File or directory path, optionally with :<line>[-<end>] (e.g. Sources/main.swift:12-20)")
    var path: String

    @Option(name: .long, help: "Use a specific branch instead of the current one.")
    var branch: String?

    @Option(name: .long, help: "Pin to a commit. Use without value for HEAD, or provide a hash.")
    var commit: String?

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

        let url: String
        do {
            url = try generator.generate(
                input: path,
                workingDirectory: cwd,
                branch: branch,
                commit: commit
            )
        } catch let error as GHLinkError {
            FileHandle.standardError.write(Data("Error: \(error.errorDescription ?? "\(error)")\n".utf8))
            throw ExitCode.failure
        }

        print(url)

        if copy {
            copyToClipboard(url)
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
