---
name: settings
description: Old name of /project-settings. Prints one line, then runs /project-settings.
user-invocable: true
disable-model-invocation: true
allowed-tools: skill
metadata:
  argument-hint: '[key | key=value | --local key=value]'
  cc-model: sonnet
  ported-from: claude-code-game-studios
---

> Ported from Claude Code Game Studios to Mistral Vibe. CC tool names map to Vibe as: Read→read_file, Write→write_file, Edit→edit, Glob/Grep/LS→bash, Bash→bash, Agent/Task→agents_spawn, AskUserQuestion→ask_user_question, Skill→skill, WebSearch/WebFetch→connector_web_search.*. Lines marked 'Run first' are NOT auto-executed in Vibe — run them yourself before continuing.


# /settings — old name of /project-settings

Several AI tools keep `/settings` for a command of their own, so this skill is now
`/project-settings`.

1. Print this line exactly, as the first line of your reply:

   /settings is now /project-settings. Running /project-settings.

2. Run the `project-settings` skill with the Skill tool, passing these arguments unchanged
   (none, if this is empty): $ARGUMENTS

Do nothing else here: `/project-settings` does the work.
