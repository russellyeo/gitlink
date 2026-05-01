public enum Target: Equatable {
    case path(ParsedInput)
    case commit(String)
    case repoRoot

    public var isPath: Bool {
        if case .path = self { return true }
        return false
    }
}
