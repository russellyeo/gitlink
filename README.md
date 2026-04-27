# ghlink

Generate GitHub links from local file paths.

## Usage

```
ghlink <path>[:<line>[-<end_line>]]
```

### Examples

```bash
# File on current branch
ghlink Sources/App/main.swift
# → https://github.com/your-org/your-repo/blob/feature-x/Sources/App/main.swift

# File with line range
ghlink Sources/App/main.swift:12-20
# → https://github.com/your-org/your-repo/blob/feature-x/Sources/App/main.swift#L12-L20

# Single line
ghlink Sources/App/main.swift:12
# → https://github.com/your-org/your-repo/blob/feature-x/Sources/App/main.swift#L12

# Directory
ghlink Sources/App/
# → https://github.com/your-org/your-repo/tree/feature-x/Sources/App

# Pin to HEAD commit
ghlink --commit Sources/App/main.swift
# → https://github.com/your-org/your-repo/blob/4f2d8d5.../Sources/App/main.swift

# Pin to specific commit
ghlink --commit abc123 Sources/App/main.swift
# → https://github.com/your-org/your-repo/blob/abc123.../Sources/App/main.swift

# Use a specific branch
ghlink --branch main Sources/App/main.swift
# → https://github.com/your-org/your-repo/blob/main/Sources/App/main.swift

# Copy to clipboard
ghlink --copy Sources/App/main.swift
```

### Options

| Option | Description |
|---|---|
| `--commit [<hash>]` | Pin to a commit. Without a value, uses HEAD. |
| `--branch <name>` | Use a specific branch instead of the current one. |
| `--copy` | Copy the URL to the system clipboard. |
| `--help` | Show help information. |

## How It Works

1. Parses the input path and optional line spec
2. Reads the `origin` remote URL from git to determine the GitHub owner and repo
3. Validates the path exists and line numbers are within range
4. Builds the GitHub URL

The tool must be run inside a git repository with an `origin` remote pointing to GitHub.

## Install

### Build from source

```bash
git clone https://github.com/your-org/ghlink.git
cd ghlink
swift build -c release
# Binary is at .build/release/ghlink
# Optionally copy to your PATH:
cp .build/release/ghlink /usr/local/bin/
```

## Agent Integration

ghlink is designed for use by coding agents (Claude Code, Copilot, etc.):

- Single URL output on stdout — easy to capture
- Non-zero exit code on errors, messages on stderr
- `--help` for discoverability
- No interactive prompts

## Requirements

- macOS 13+
- Swift 5.9+
- Git
- A GitHub `origin` remote
