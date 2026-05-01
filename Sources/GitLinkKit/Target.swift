public enum Target: Equatable {
    case path(ParsedInput)
    case commit(String)
    case repoRoot
}
