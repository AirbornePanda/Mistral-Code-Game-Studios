#!/bin/sh
# cc-adapter.sh <cc-hook-script.sh> — runs an original Claude Code Game Studios
# hook script against a Vibe hook payload by translating the payload to the
# Claude Code format (hook_event_name, short tool_name, CLAUDE_PROJECT_DIR).
#
# Result translation (CC -> Vibe):
#   CC exit 2 / decision "block"  -> Vibe {"decision":"deny","reason":...}
#   CC hookSpecificOutput.additionalContext -> Vibe additional_context (post_tool)
#                                           or system_message (pre_tool/pre_agent)
#   any other non-zero exit       -> fail open (Vibe default), with a system_message note
set -u
script="$1"
payload="$(cat)"

event="$(printf '%s' "$payload" | jq -r '.hook_event_name // empty' 2>/dev/null)"
tool="$(printf '%s' "$payload" | jq -r '.tool_name // empty' 2>/dev/null)"
parent="$(printf '%s' "$payload" | jq -r '.parent_session_id // empty' 2>/dev/null)"

# CC subagent events only make sense for subagent turns (parent_session_id set)
case "$script" in
  log-agent.sh|log-agent-stop.sh|validate-agent-artifact.sh)
    [ -n "$parent" ] || exit 0 ;;
esac

case "$event" in
  pre_tool)      cc_event=PreToolUse ;;
  post_tool)     cc_event=PostToolUse ;;
  pre_agent)     cc_event=UserPromptSubmit ;;
  post_agent)    cc_event=SubagentStop ;;
  session_start) cc_event=SessionStart ;;
  session_end)   cc_event=Stop ;;
  notification)  cc_event=Notification ;;
  *)             cc_event="$event" ;;
esac

short="$tool"
case "$tool" in
  file_system.write_file)   short=Write ;;
  file_system.edit)         short=Edit ;;
  file_system.read_file)    short=Read ;;
  file_system.bash)         short=Bash ;;
  process_start)            short=Bash ;;
  agents_spawn)             short=Agent ;;
  ask_user_question)        short=AskUserQuestion ;;
  skill)                    short=Skill ;;
  connector_web_search.*)   short=WebSearch ;;
esac

cc_payload="$(printf '%s' "$payload" | jq --arg e "$cc_event" --arg t "$short" '
  .hook_event_name = $e |
  (if $t != "" then .tool_name = $t else . end)')"

export CLAUDE_PROJECT_DIR="$PWD"
errfile="$(mktemp)"
out="$(printf '%s' "$cc_payload" | bash ".vibe/hooks/cc/$script" 2>"$errfile")"; rc=$?
err="$(cat "$errfile")"; rm -f "$errfile"

if [ "$rc" -eq 2 ]; then
  reason="$(printf '%s' "$out" | jq -r '.reason // empty' 2>/dev/null)"
  [ -n "$reason" ] || reason="$err"
  [ -n "$reason" ] || reason="blocked by hook $script"
  printf '{"decision":"deny","reason":%s}\n' "$(printf '%s' "$reason" | jq -Rs .)"
  exit 0
fi

if [ "$rc" -ne 0 ]; then
  case "$event" in
    pre_tool|post_tool|pre_agent)
      printf '{"system_message":%s}\n' "$(printf 'hook %s exited %s; allowed (fail-open)' "$script" "$rc" | jq -Rs .)" ;;
  esac
  exit 0
fi

dec="$(printf '%s' "$out" | jq -r '.decision // empty' 2>/dev/null)"
if [ "$dec" = "block" ]; then
  reason="$(printf '%s' "$out" | jq -r '.reason // "blocked by hook"' 2>/dev/null)"
  printf '{"decision":"deny","reason":%s}\n' "$(printf '%s' "$reason" | jq -Rs .)"
  exit 0
fi

ctx="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext // empty' 2>/dev/null)"
case "$event" in
  post_tool)  [ -n "$ctx" ] && printf '{"hook_specific_output":{"additional_context":%s}}\n' "$(printf '%s' "$ctx" | jq -Rs .)" || exit 0 ;;
  pre_tool|pre_agent) [ -n "$ctx" ] && printf '{"system_message":%s}\n' "$(printf '%s' "$ctx" | jq -Rs .)" || exit 0 ;;
  *) exit 0 ;;
esac
