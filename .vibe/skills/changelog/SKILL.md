---
name: changelog
description: Old name of /write-changelog. Prints one line, then runs /write-changelog.
user-invocable: true
disable-model-invocation: true
allowed-tools: skill
metadata:
  argument-hint: '[version|sprint-number]'
  cc-model: sonnet
  ported-from: claude-code-game-studios
---

> Ported from Claude Code Game Studios to Mistral Vibe. CC tool names map to Vibe as: Read→read_file, Write→write_file, Edit→edit, Glob/Grep/LS→bash, Bash→bash, Agent/Task→agents_spawn, AskUserQuestion→ask_user_question, Skill→skill, WebSearch/WebFetch→connector_web_search.*. Lines marked 'Run first' are NOT auto-executed in Vibe — run them yourself before continuing.


# /changelog — old name of /write-changelog

Several AI tools keep `/changelog` for a command of their own, so this skill is now
`/write-changelog`.

1. Print this line exactly, as the first line of your reply:

   /changelog is now /write-changelog. Running /write-changelog.

2. Run the `write-changelog` skill with the Skill tool, passing these arguments unchanged
   (none, if this is empty): $ARGUMENTS

Do nothing else here: `/write-changelog` does the work.
