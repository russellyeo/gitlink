import Foundation

public final class LinkGenerator {

    private let gitService: GitService

    public init(gitService: GitService) {
        self.gitService = gitService
    }

    public func generate(
        input: String,
        workingDirectory: String,
        branch: String?,
        commit: String?
    ) throws -> String {
        let parsed = InputParser.parse(input)

        if let lineSpec = parsed.lineSpec {
            try InputParser.validateLineSpec(lineSpec)
        }

        let repoRoot = try gitService.repositoryRoot()
        let absolutePath = resolvePath(parsed.path, workingDirectory: workingDirectory)
        let fileInfo = try PathValidator.validate(path: absolutePath)

        if let lineSpec = parsed.lineSpec {
            try PathValidator.validateLines(lineSpec, fileInfo: fileInfo)
        }

        let remoteURLString = try gitService.remoteURL()
        let remote = try GitRemoteParser.parse(remoteURLString)

        let ref = try resolveRef(branch: branch, commit: commit)

        let relativePath = makeRelativePath(absolutePath: absolutePath, repoRoot: repoRoot)

        return try URLBuilder.buildURL(
            remote: remote,
            ref: ref,
            path: relativePath,
            isDirectory: fileInfo.isDirectory,
            lineSpec: parsed.lineSpec
        )
    }

    private func resolveRef(branch: String?, commit: String?) throws -> String {
        if let commit {
            let ref = commit.isEmpty ? nil : commit
            return try gitService.resolveCommit(ref)
        }
        if let branch {
            return branch
        }
        return try gitService.currentBranch()
    }

    private func resolvePath(_ path: String, workingDirectory: String) -> String {
        if path.hasPrefix("/") {
            return path
        }
        let workingURL = URL(fileURLWithPath: workingDirectory)
        return workingURL.appendingPathComponent(path).standardized.path
    }

    private func makeRelativePath(absolutePath: String, repoRoot: String) -> String {
        var root = repoRoot
        if !root.hasSuffix("/") {
            root += "/"
        }
        if absolutePath.hasPrefix(root) {
            return String(absolutePath.dropFirst(root.count))
        }
        return absolutePath
    }
}
