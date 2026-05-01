import Foundation

public final class LinkGenerator {

    private let gitService: GitService

    public init(gitService: GitService) {
        self.gitService = gitService
    }

    public struct Result {
        public let url: String
        public let target: Target
        public let repoName: String
        public let ref: String
    }

    public func generate(
        target: Target,
        workingDirectory: String,
        branch: String?,
        commit: String? = nil
    ) throws -> Result {
        let remoteURLString = try gitService.remoteURL()
        let remote = try GitRemoteParser.parse(remoteURLString)

        switch target {
        case .path(let parsed):
            return try generatePath(
                parsed: parsed,
                workingDirectory: workingDirectory,
                branch: branch,
                commit: commit,
                remote: remote
            )

        case .commit(let hash):
            let resolved = try gitService.resolveCommit(hash)
            let url = try URLBuilder.buildURL(
                remote: remote,
                ref: resolved,
                target: .commit(resolved),
                isDirectory: nil
            )
            return Result(url: url, target: .commit(resolved), repoName: remote.repo, ref: resolved)

        case .repoRoot:
            let ref = try branch ?? gitService.currentBranch()
            let url = try URLBuilder.buildURL(
                remote: remote,
                ref: ref,
                target: .repoRoot,
                isDirectory: nil
            )
            return Result(url: url, target: .repoRoot, repoName: remote.repo, ref: ref)
        }
    }

    private func generatePath(
        parsed: ParsedInput,
        workingDirectory: String,
        branch: String?,
        commit: String?,
        remote: GitRemote
    ) throws -> Result {
        try parsed.lineSpec?.validate()

        let repoRoot = try gitService.repositoryRoot()
        let absolutePath = resolvePath(parsed.path, workingDirectory: workingDirectory)
        let fileInfo = try PathValidator.validate(path: absolutePath)

        if let lineSpec = parsed.lineSpec {
            try PathValidator.validateLines(lineSpec, fileInfo: fileInfo)
        }

        let ref: String
        if let commit {
            ref = try gitService.resolveCommit(commit)
        } else if let branch {
            ref = branch
        } else {
            ref = try gitService.currentBranch()
        }
        let relativePath = makeRelativePath(absolutePath: absolutePath, repoRoot: repoRoot)
        let relativeTarget = Target.path(ParsedInput(path: relativePath, lineSpec: parsed.lineSpec))

        let url = try URLBuilder.buildURL(
            remote: remote,
            ref: ref,
            target: relativeTarget,
            isDirectory: fileInfo.isDirectory
        )

        return Result(url: url, target: relativeTarget, repoName: remote.repo, ref: ref)
    }

    private func resolvePath(_ path: String, workingDirectory: String) -> String {
        if path.hasPrefix("/") {
            return path
        }
        let workingURL = URL(filePath: workingDirectory)
        return workingURL.appending(path: path).standardized.path
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
