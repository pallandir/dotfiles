# OpenCode Configuration

Production-ready [OpenCode](https://opencode.ai) configuration with specialized AI agents for software development.

## Overview

This configuration provides:
- **LiteLLM integration** with environment-based credentials
- **8 specialized agents** for different development tasks
- **6 MCP servers** for enhanced capabilities
- **Conservative permissions** for safe operation

## Project Structure

```
opencode/
├── opencode.json       # Main configuration
├── .env.example        # Environment template
├── install.sh          # Installation script
└── agents/
    ├── backend.md      # Python, FastAPI, Pydantic, PostgreSQL
    ├── architect.md    # System design, documentation, cloud
    ├── ui.md           # React, Vue, Next.js, TypeScript, Tailwind
    ├── rust.md         # Rust systems programming
    ├── golang.md       # Go backend services
    ├── reviewer.md     # Code review (read-only)
    ├── security.md     # Security audits (read-only)
    └── devops.md       # Docker, Kubernetes, CI/CD
```

## Installation

### Automated (via dotfiles)

The install script is run automatically by the main dotfiles installer.

### Manual

```bash
cd /path/to/dotfiles/opencode
./install.sh
```

This will:
1. Symlink `opencode.json` to `~/.config/opencode/`
2. Symlink `agents/` directory to `~/.config/opencode/agents/`
3. Create `.env` file from template (if not exists)

### Verify Installation

```bash
ls -la ~/.config/opencode/
# Should show:
# opencode.json -> /path/to/dotfiles/opencode/opencode.json
# agents -> /path/to/dotfiles/opencode/agents
# .env
```

## Configuration

### Environment Variables

Edit `~/.config/opencode/.env` with your credentials:

```bash
# Required: LiteLLM
LITELLM_BASE_URL=http://localhost:4000
LITELLM_API_KEY=your-api-key
OPENCODE_MODEL=your-primary-model-id
OPENCODE_SMALL_MODEL=your-small-model-id

# Required: GitLab (if using gitlab MCP)
GITLAB_TOKEN=your-personal-access-token
GITLAB_API_URL=https://gitlab.com/api/v4

# Optional: Figma
FIGMA_ACCESS_TOKEN=your-figma-token

# Optional: SonarQube
SONARQUBE_URL=http://localhost:9000
SONARQUBE_TOKEN=your-sonarqube-token
```

### Loading Environment

Add to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
# Load OpenCode environment
if [ -f ~/.config/opencode/.env ]; then
  set -a && source ~/.config/opencode/.env && set +a
fi
```

Or load manually before running:

```bash
set -a && source ~/.config/opencode/.env && set +a
opencode
```

## Agents

### Primary Agents (can be used as main or subagent)

| Agent | Description | Use For |
|-------|-------------|---------|
| `backend` | Python, FastAPI, Pydantic, pydantic_ai, PostgreSQL | API development, data validation, database design |
| `architect` | System design, documentation, GCP, AWS | Architecture decisions, technical docs, READMEs |
| `ui` | Vue.js, React, Next.js, TypeScript, shadcn/ui, Tailwind | Frontend development, component design |
| `rust` | Rust, axum, tokio, sqlx | Systems programming, CLI tools, performance |
| `golang` | Go, chi/gin, database/sql | Backend services, cloud-native apps |
| `devops` | Docker, Kubernetes, GitLab CI, Terraform | CI/CD, infrastructure, containerization |

### Subagents (read-only, for analysis)

| Agent | Description | Use For |
|-------|-------------|---------|
| `reviewer` | Code review across all languages | PR reviews, code quality feedback |
| `security` | Security audits, OWASP checks | Vulnerability assessment, secure coding |

### Using Agents

```bash
# Start with a specific agent
opencode --agent backend

# Or switch during session
/agent backend
```

## MCP Servers

| Server | Purpose | Requirements |
|--------|---------|--------------|
| **context7** | Documentation lookup | npx |
| **gitlab** | GitLab API integration | `GITLAB_TOKEN`, `GITLAB_API_URL` |
| **figma** | UI design context from Figma | `FIGMA_ACCESS_TOKEN` |
| **eslint** | JavaScript/TypeScript linting | npx, eslint installed |
| **sonarqube** | Code quality analysis | Docker, `SONARQUBE_URL`, `SONARQUBE_TOKEN` |
| **python-analyzer** | Python linting (Ruff + Vulture) | uvx |

### Disabling MCP Servers

To disable an MCP server you don't need, add to your project's `opencode.json`:

```json
{
  "mcp": {
    "sonarqube": false,
    "figma": false
  }
}
```

## Permissions

This configuration uses a **conservative** permission model:

### Allowed (no prompt)
- `read`, `glob`, `grep`, `list` - File reading and searching
- `lsp`, `codesearch` - Code intelligence
- `webfetch`, `websearch` - Web access
- `todoread`, `question` - Utilities
- Safe bash commands: `git status/log/diff`, `ls`, `cat`, `docker ps`, etc.

### Ask (prompts for approval)
- `edit`, `write`, `patch` - File modifications
- `bash` - Most shell commands
- `task`, `skill` - Agent spawning
- `todowrite` - Todo modifications
- `external_directory` - Access outside project

### Denied (blocked)
- `rm -rf`, `rm -r` - Recursive deletion
- `sudo` - Privilege escalation
- `chmod 777` - Insecure permissions
- `curl|bash`, `wget|bash` - Remote code execution
- Other destructive commands

## Project-Specific Configuration

Create `opencode.json` in your project root to override settings:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "default": "backend"
  },
  "permission": {
    "bash": {
      "pytest *": "allow",
      "make *": "allow"
    }
  }
}
```

## Maintenance

### Updating Agents

Since agents are symlinked from the dotfiles repo:

```bash
cd ~/path/to/dotfiles
git pull
# Changes are immediately available
```

### Adding New Agents

1. Create a new markdown file in `opencode/agents/`:

```markdown
---
description: Brief description of what this agent does
mode: all  # or: primary, subagent
temperature: 0.3
tools:
  read: true
  edit: true
  # ... other tools
---

You are a specialized agent for...

## Your Instructions Here
```

2. The agent is immediately available (no restart needed)

### Customizing Existing Agents

Edit the agent files in `opencode/agents/`. Changes take effect on next opencode session.

## Troubleshooting

### MCP Server Fails to Start

Check if required tools are installed:

```bash
# For context7, gitlab, figma, eslint
which npx

# For python-analyzer
which uvx

# For sonarqube
docker --version
```

### Environment Variables Not Loading

Verify your `.env` file:

```bash
cat ~/.config/opencode/.env

# Test loading
set -a && source ~/.config/opencode/.env && set +a
echo $LITELLM_BASE_URL
```

### Agent Not Found

Check the agents directory is properly linked:

```bash
ls -la ~/.config/opencode/agents/
```

## References

- [OpenCode Documentation](https://opencode.ai/docs)
- [OpenCode Agents](https://opencode.ai/docs/agents)
- [OpenCode Configuration](https://opencode.ai/docs/config)
- [MCP Protocol](https://modelcontextprotocol.io)
