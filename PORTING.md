# Porting to Mistral Vibe

This fork carries a Vibe-native port of the Claude Code Game Studios setup,
generated from the `.claude/` tree. The original `.claude/` directory is kept
untouched so the repo still works with Claude Code.

## What was ported

| CCGS source | Vibe target | Notes |
|---|---|---|
| `CLAUDE.md` + `.claude/rules/*.md` | `AGENTS.md` (repo root) | `@import` lines rewritten to "read on demand"; rules appended with their path globs |
| `.claude/skills/*/SKILL.md` (78) | `.vibe/skills/<name>/SKILL.md` | frontmatter mapped: `name`, `description`, `user-invocable`, `disable-model-invocation`, `allowed-tools` (CC tool names → Vibe names), `metadata` (`argument-hint`, `cc-model`); support files copied |
| `.claude/agents/*.md` (49) | `.vibe/agents/<name>.toml` | `agent_type = "subagent"`, `safety = "neutral"`, `instructions` = original body; `tools`/`disallowedTools` → `enabled_tools`/`disabled_tools`; CC-only fields kept as a comment header |
| `.claude/settings.json` hooks (14) | `.vibe/hooks.toml` + `.vibe/hooks/cc-adapter.sh` | CC scripts copied unchanged to `.vibe/hooks/cc/`; the adapter translates the Vibe payload (event name, qualified tool name, `CLAUDE_PROJECT_DIR`) to the CC format and maps CC block/advisory output back to Vibe's structured responses |
| `.claude/settings.json` permissions | `.vibe/config.toml` | `Bash(...)` deny → `[tools.bash] denylist`, allow → `allowlist`; `Read(**/.env*)` → `[tools.read_file] denylist`; `Edit(...)` → `[tools.edit] denylist`. Vibe checks denylist before allowlist, so guards keep winning |
| — | `~/.vibe/trusted_folders.toml` | this repo added to `trusted` (project-local `.vibe/` only loads in trusted folders) |

## Body transformations in skills

- `${CLAUDE_SKILL_DIR}/../../x` → `x` (project-root relative), `${CLAUDE_SKILL_DIR}/x` → `x` (relative to the skill dir, Vibe's support-file convention)
- CC `!`bash ...`` pre-run lines → `> **Run first:** ...` — Vibe does not auto-execute them, run them manually
- Each skill body starts with a tool-name mapping note

## Not portable (by design)

- `PreCompact` hook (`pre-compact.sh`): Vibe has no pre-compaction hook event
- `PowerShell(...)` deny rules: no PowerShell tool on Linux
- CC model tiers (`haiku`/`sonnet`/`opus` in skill/agent frontmatter): Vibe runs the session model; kept as `cc-model` metadata
- `statusLine` / `worktree.baseRef` from `settings.json`: CC-specific
- Subagent start/stop logging mapped to `pre_agent`/`post_agent`, filtered to subagent turns via `parent_session_id`

## Test

Start Vibe in this repo (`/reload` if a session is already open), then `/skills`
should list the ported skills (e.g. `/prototype`) and the hooks should appear
without config warnings.
