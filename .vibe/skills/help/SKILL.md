---
name: help
description: Old name of /next-step. Prints one line, then runs /next-step.
user-invocable: true
disable-model-invocation: true
allowed-tools: skill
metadata:
  argument-hint: '[optional: what you just finished, e.g. ''finished design-review'' or ''stuck on ADRs'']'
  cc-model: haiku
  ported-from: claude-code-game-studios
---

> Ported from Claude Code Game Studios to Mistral Vibe. CC tool names map to Vibe as: Read→read_file, Write→write_file, Edit→edit, Glob/Grep/LS→bash, Bash→bash, Agent/Task→agents_spawn, AskUserQuestion→ask_user_question, Skill→skill, WebSearch/WebFetch→connector_web_search.*. Lines marked 'Run first' are NOT auto-executed in Vibe — run them yourself before continuing.


# /help — old name of /next-step

Most AI tools keep `/help` for a command of their own, so this skill is now
`/next-step`.

1. Print this line exactly, as the first line of your reply:

   /help is now /next-step. Running /next-step.

2. Run the `next-step` skill with the Skill tool, passing these arguments unchanged
   (none, if this is empty): $ARGUMENTS

Do nothing else here: `/next-step` does the work.
