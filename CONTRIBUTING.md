# Contributing to OpenClaw Dev

Thank you for your interest in contributing to the OpenClaw Dev Toolkit!

## Getting Started

### Prerequisites
- Node.js 20+ or equivalent runtime
- A code agent (Claude Code, Codex, Qwen, or Gemini)
- Git

### Installation
```bash
git clone https://github.com/a13-team/openclaw-dev.git
cd openclaw-dev

# For Claude Code
git clone https://github.com/a13-team/openclaw-dev.git
# Enable as Claude Code plugin (point to the cloned directory)

# For other platforms
bash install.sh
```

## Development Workflow

### 1. Fork and Clone
```bash
git clone https://github.com/YOUR_USERNAME/openclaw-dev.git
cd openclaw-dev
```

### 2. Create a Feature Branch
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 3. Make Changes
- Follow the existing code style
- Add comments for complex logic
- Keep changes focused and atomic

### 4. Test Your Changes
```bash
npm install
npm test
npm run lint
```

### 5. Commit and Push
```bash
git add .
git commit -m "feat: add new feature"
git push origin feature/your-feature-name
```

### 6. Open a Pull Request
- Use the PR template
- Describe your changes clearly
- Link any related issues

## Project Structure

```
openclaw-dev/
├── commands/       # User-facing commands (/diagnose, /status, etc.)
├── skills/         # Reusable skills for code agents
├── scripts/        # Utility scripts
├── .github/        # GitHub configuration (CI, templates)
└── CONTRIBUTING.md # This file
```

## Commands Available

| Command | Purpose |
|---------|---------|
| `/diagnose` | Runtime log diagnosis |
| `/status` | Status overview (supports multi-Gateway) |
| `/lint-config` | Configuration validation |
| `/create-skill` | New skill lifecycle |
| `/validate-skill` | Skill validation |
| `/evolve-skill` | Data-driven skill improvement |

## Coding Standards

- Use clear, descriptive names
- Add JSDoc comments for functions
- Handle errors explicitly
- No hardcoded secrets or credentials

## Reporting Issues

When reporting bugs, please include:
- OpenClaw Dev version
- Your code agent and platform
- Steps to reproduce
- Expected vs actual behavior

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
