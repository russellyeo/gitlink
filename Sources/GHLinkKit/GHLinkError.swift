import Foundation

public enum GHLinkError: LocalizedError, Equatable {
    case notAGitRepository
    case noOriginRemote
    case notGitHubRemote(String)
    case pathNotFound(String)
    case linesOnDirectory
    case invalidLineSpec(String)
    case lineOutOfRange(line: Int, totalLines: Int)
    case commitNotFound(String)
    case notOnAnyBranch

    public var errorDescription: String? {
        switch self {
        case .notAGitRepository:
            return "Not a git repository (or any parent up to mount point)"
        case .noOriginRemote:
            return "No 'origin' remote found"
        case .notGitHubRemote(let url):
            return "Remote 'origin' is not a GitHub URL: \(url)"
        case .pathNotFound(let path):
            return "Path not found: \(path)"
        case .linesOnDirectory:
            return "Cannot specify line numbers for a directory"
        case .invalidLineSpec(let spec):
            return "Invalid line spec: \(spec)"
        case .lineOutOfRange(let line, let totalLines):
            return "Line \(line) is out of range (file has \(totalLines) lines)"
        case .commitNotFound(let hash):
            return "Commit not found: \(hash)"
        case .notOnAnyBranch:
            return "HEAD is detached and no --branch or --commit specified"
        }
    }
}
