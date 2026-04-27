# gitlink

Generate web links from local file paths for code repositories.

Currently only supports **GitHub**.

## Usage

```
gitlink <path>[:<line>[-<end_line>]]
```

### Examples

```bash
# File on current branch
gitlink Sources/App/main.swift
# → https://github.com/your-org/your-repo/blob/feature-x/Sources/App/main.swift

# File with line range
gitlink Sources/App/main.swift:12-20
# → https://github.com/your-org/your-repo/blob/feature-x/Sources/App/main.swift#L12-L20

# Single line
gitlink Sources/App/main.swift:12
# → https://github.com/your-org/your-repo/blob/feature-x/Sources/App/main.swift#L12

# Directory
gitlink Sources/App/
# → https://github.com/your-org/your-repo/tree/feature-x/Sources/App

# Pin to HEAD commit
gitlink --commit HEAD Sources/App/main.swift
# → https://github.com/your-org/your-repo/blob/4f2d8d5.../Sources/App/main.swift

# Pin to specific commit
gitlink --commit abc123 Sources/App/main.swift
# → https://github.com/your-org/your-repo/blob/abc123.../Sources/App/main.swift

# Use a specific branch
gitlink --branch main Sources/App/main.swift
# → https://github.com/your-org/your-repo/blob/main/Sources/App/main.swift

# Copy to clipboard
gitlink --copy Sources/App/main.swift
```

### Options

| Option | Description |
|---|---|
| `--commit <hash>` | Pin to a commit hash (e.g. `--commit HEAD` or `--commit abc123`). |
| `--branch <name>` | Use a specific branch instead of the current one. |
| `--copy` | Copy the URL to the system clipboard. |
| `--help` | Show help information. |


## Install

### Build from source

```bash
git clone https://github.com/russellyeo/gitlink.git
cd gitlink
swift build -c release
# Binary is at .build/release/gitlink
# Optionally copy to your PATH:
cp .build/release/gitlink /usr/local/bin/
```

## Agent Integration

gitlink is designed for use by coding agents (Claude Code, Copilot, etc.):

- Single URL output on stdout — easy to capture
- Non-zero exit code on errors, messages on stderr
- `--help` for discoverability
- No interactive prompts

## Requirements

- macOS 13+
- Swift 5.9+
- Git
- A supported `origin` remote (GitHub)
