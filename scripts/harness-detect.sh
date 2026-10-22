#!/usr/bin/env bash
#
# pstack harness detector.
#
# Prints the harness pstack is running under, the adapter document that
# describes that harness, and the paths pstack should use there.
#
# Usage:
#   harness-detect.sh              human-readable summary
#   harness-detect.sh --export     KEY=VALUE lines, for `eval`
#   harness-detect.sh --json       one JSON object
#   harness-detect.sh --harness X  force a harness instead of detecting
#
# Detection order, first match wins:
#   1. the --harness flag
#   2. $PSTACK_HARNESS
#   3. the nearest ancestor process that looks like an agent
#   4. the agent's own process markers in the environment
#      (a marker inherited from a parent harness is only trusted when no
#      harness process was found in step 3; a harness that exports no marker
#      of its own, such as OMP, is found by process name instead)
#   5. a harness-specific directory in the working tree
#   6. "generic"
#
# Exit status is 0 whenever a harness was identified, including "generic".

set -uo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
PSTACK_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd -P)

MODE="text"
FORCED=""

while [ $# -gt 0 ]; do
  case "$1" in
    --export) MODE="export" ;;
    --json) MODE="json" ;;
    --harness)
      shift
      FORCED="${1:-}"
      ;;
    --harness=*) FORCED="${1#--harness=}" ;;
    -h|--help)
      awk 'NR > 2 && /^#/ { sub(/^# ?/, ""); print; next } NR > 2 { exit }' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "harness-detect.sh: unknown argument: $1" >&2
      exit 2
      ;;
  esac
  shift
done

HARNESS=""

# --- 1 and 2. explicit overrides -------------------------------------------

if [ -n "$FORCED" ]; then
  HARNESS="$FORCED"
elif [ -n "${PSTACK_HARNESS:-}" ]; then
  HARNESS="$PSTACK_HARNESS"
fi

# An unknown name would fall through the table below to the generic row and
# print a path that does not exist. Warn and keep detecting instead.
if [ -n "$HARNESS" ]; then
  case "$HARNESS" in
    claude-code | codex | pi | omp | peri | opencode | gemini-cli | crush | cursor | generic) ;;
    *)
      echo "harness-detect.sh: unknown harness '$HARNESS'; detecting instead" >&2
      HARNESS=""
      ;;
  esac
fi

# --- 3. the nearest ancestor that looks like an agent ----------------------
#
# An agent spawns the shell that runs this script, so the agent is an
# ancestor process. Walking outward from the shell finds the agent that
# actually invoked us.

if [ -z "$HARNESS" ] && command -v ps >/dev/null 2>&1; then
  pid=$$
  hops=0
  while [ -n "$pid" ] && [ "$pid" -gt 1 ] 2>/dev/null && [ "$hops" -lt 12 ]; do
    hops=$((hops + 1))
    comm=$(ps -o comm= -p "$pid" 2>/dev/null | tr -d '[:space:]')
    args=$(ps -o args= -p "$pid" 2>/dev/null)
    # Linux reports the executable name; macOS reports its full path. Match
    # on the last path segment so the same table works on both.
    comm_base=""
    [ -n "$comm" ] && comm_base=$(basename -- "$comm" 2>/dev/null)
    case "$comm_base" in
      claude | claude-code) HARNESS="claude-code" ;;
      codex) HARNESS="codex" ;;
      opencode) HARNESS="opencode" ;;
      gemini) HARNESS="gemini-cli" ;;
      crush) HARNESS="crush" ;;
      omp) HARNESS="omp" ;;
      peri) HARNESS="peri" ;;
    esac
    if [ -z "$HARNESS" ]; then
      case "$args" in
        *"/.pi/agent/"* | *"pi-coding-agent"*) HARNESS="pi" ;;
        *"@openai/codex"* | *"codex-darwin"* | *"/codex "*) HARNESS="codex" ;;
        *"opencode-ai"* | *"/opencode "*) HARNESS="opencode" ;;
        *"gemini-cli"* | *"/gemini "*) HARNESS="gemini-cli" ;;
        *"charmbracelet/crush"* | *"charmland/crush"* | *"/crush "*) HARNESS="crush" ;;
        *"claude-code"* | *"/claude "*) HARNESS="claude-code" ;;
        *"/omp "* | *"/omp --"*) HARNESS="omp" ;;
        *"/.peri/"*) HARNESS="peri" ;;
      esac
    fi
    [ -n "$HARNESS" ] && break
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d '[:space:]')
    [ -z "$pid" ] && break
  done
fi

# --- 4. process markers in the environment ----------------------------------
#
# Pi sets AI_AGENT=pi and PI_CODING_AGENT=true. Claude Code sets
# CLAUDECODE=1 and AI_AGENT=claude-code_<version>_<flavor>. Other harnesses
# that follow the same convention set AI_AGENT to their own name.

if [ -z "$HARNESS" ]; then
  case "${AI_AGENT:-}" in
    pi*) HARNESS="pi" ;;
    claude*) HARNESS="claude-code" ;;
    codex*) HARNESS="codex" ;;
    opencode*) HARNESS="opencode" ;;
    gemini*) HARNESS="gemini-cli" ;;
    crush*) HARNESS="crush" ;;
  esac
fi

if [ -z "$HARNESS" ]; then
  if [ "${PI_CODING_AGENT:-}" = "true" ] || [ -n "${PI_MANAGED_INSTALL_ROOT:-}" ]; then
    HARNESS="pi"
  elif [ -n "${CLAUDECODE:-}" ] || [ -n "${CLAUDE_CODE_ENTRYPOINT:-}" ] || [ "${AI_AGENT:-}" = "claude-code_2-1-260_agent" ]; then
    HARNESS="claude-code"
  fi
fi

# --- 5. a harness directory in the working tree -----------------------------

if [ -z "$HARNESS" ]; then
  for dir in .claude .codex .pi .omp .peri .opencode .gemini .cursor; do
    if [ -d "$dir" ]; then
      case "$dir" in
        .claude) HARNESS="claude-code" ;;
        .codex) HARNESS="codex" ;;
        .pi) HARNESS="pi" ;;
        .omp) HARNESS="omp" ;;
        .peri) HARNESS="peri" ;;
        .opencode) HARNESS="opencode" ;;
        .gemini) HARNESS="gemini-cli" ;;
        .cursor) HARNESS="cursor" ;;
      esac
      break
    fi
  done
fi

[ -z "$HARNESS" ] && HARNESS="generic"

# --- the harness table ------------------------------------------------------
#
# Keep these rows in step with docs/harness/<name>.md.
#
# ALWAYS_LOADED names the file a harness loads into every session. For
# Cursor and Claude Code that file holds the role lines itself, so it is the
# same path as MODELS_FILE. For every other harness it is the harness's
# instruction file, which carries a pointer to the models file rather than
# the roles.

case "$HARNESS" in
  claude-code)
    SKILLS_PROJECT=".claude/skills/"
    SKILLS_USER="~/.claude/skills/"
    MODELS_FILE="~/.claude/rules/pstack-models.md"
    ALWAYS_LOADED="~/.claude/rules/pstack-models.md"
    SUBAGENT_TOOL="Agent (subagent_type: general-purpose)"
    QUESTION_TOOL="AskUserQuestion"
    TODO_TOOL="TodoWrite"
    TRANSCRIPTS="~/.claude/projects/<slug>/*.jsonl"
    ;;
  codex)
    SKILLS_PROJECT=".codex/skills/"
    SKILLS_USER="~/.codex/skills/"
    MODELS_FILE="~/.agents/pstack-models.codex.md"
    ALWAYS_LOADED="~/.codex/AGENTS.md"
    SUBAGENT_TOOL="spawn_agent"
    QUESTION_TOOL="none (ask in chat with numbered options)"
    TODO_TOOL="update_plan"
    TRANSCRIPTS="~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl"
    ;;
  pi)
    SKILLS_PROJECT=".pi/skills/"
    SKILLS_USER="~/.pi/agent/skills/"
    MODELS_FILE="~/.agents/pstack-models.pi.md"
    ALWAYS_LOADED="~/.pi/agent/AGENTS.md"
    if [ -d "$HOME/.pi/agent/npm/node_modules/pi-subagents" ]; then
      SUBAGENT_TOOL="subagent (pi-subagents installed)"
    else
      SUBAGENT_TOOL="none in core (pi install npm:pi-subagents adds subagent)"
    fi
    QUESTION_TOOL="none (ask in chat with numbered options)"
    TODO_TOOL="none in core (use a Markdown checklist or TODO.md)"
    TRANSCRIPTS="~/.pi/agent/sessions/--<cwd-slug>--/*.jsonl"
    ;;
  omp)
    SKILLS_PROJECT=".agents/skills/"
    SKILLS_USER="~/.agents/skills/"
    MODELS_FILE="~/.agents/pstack-models.omp.md"
    ALWAYS_LOADED="~/.agents/AGENTS.md"
    SUBAGENT_TOOL="task (agent_type)"
    QUESTION_TOOL="ask"
    TODO_TOOL="todo"
    TRANSCRIPTS="~/.omp/agent/sessions/--<cwd-slug>--/session.jsonl"
    ;;
  peri)
    SKILLS_PROJECT=".claude/skills/"
    SKILLS_USER="~/.claude/skills/"
    MODELS_FILE="~/.agents/pstack-models.peri.md"
    ALWAYS_LOADED="~/.peri/CLAUDE.md"
    SUBAGENT_TOOL="Agent (subagent_type: general-purpose)"
    QUESTION_TOOL="AskUserQuestion"
    TODO_TOOL="TodoWrite"
    TRANSCRIPTS="~/.peri/threads/threads.db (SQLite)"
    ;;
  opencode)
    SKILLS_PROJECT=".opencode/skill/ or .opencode/skills/"
    SKILLS_USER="~/.config/opencode/skills/"
    MODELS_FILE="~/.agents/pstack-models.opencode.md"
    ALWAYS_LOADED="~/.config/opencode/AGENTS.md"
    SUBAGENT_TOOL="task (subagent_type: general)"
    QUESTION_TOOL="question"
    TODO_TOOL="todowrite"
    TRANSCRIPTS="~/.local/share/opencode/storage/"
    ;;
  cursor)
    SKILLS_PROJECT=".cursor/skills/"
    SKILLS_USER="~/.cursor/skills/"
    MODELS_FILE="~/.cursor/rules/pstack-models.mdc"
    ALWAYS_LOADED="~/.cursor/rules/pstack-models.mdc"
    SUBAGENT_TOOL="Task (subagent_type: generalPurpose)"
    QUESTION_TOOL="AskQuestion"
    TODO_TOOL="todo list"
    TRANSCRIPTS="~/.cursor/projects/<slug>/agent-transcripts/"
    ;;
  gemini-cli)
    SKILLS_PROJECT=".gemini/skills/"
    SKILLS_USER="~/.gemini/skills/"
    MODELS_FILE="~/.agents/pstack-models.gemini-cli.md"
    ALWAYS_LOADED="~/.gemini/GEMINI.md"
    SUBAGENT_TOOL="none (run each delegated step in sequence)"
    QUESTION_TOOL="none (ask in chat with numbered options)"
    TODO_TOOL="none (use a Markdown checklist or TODO.md)"
    TRANSCRIPTS="~/.gemini/tmp/"
    ;;
  crush)
    SKILLS_PROJECT="./skills (via crush.json options.skills_paths)"
    SKILLS_USER="~/.config/crush/skills/"
    MODELS_FILE="~/.agents/pstack-models.crush.md"
    ALWAYS_LOADED="AGENTS.md (project, written by crush init)"
    SUBAGENT_TOOL="none (run each delegated step in sequence)"
    QUESTION_TOOL="none (ask in chat with numbered options)"
    TODO_TOOL="none (use a Markdown checklist or TODO.md)"
    TRANSCRIPTS="~/.local/share/crush/"
    ;;
  *)
    SKILLS_PROJECT=".agents/skills/"
    SKILLS_USER="~/.agents/skills/"
    MODELS_FILE="~/.agents/pstack-models.md"
    ALWAYS_LOADED="none (write your harness's always-loaded instruction file)"
    SUBAGENT_TOOL="your harness's subagent tool"
    QUESTION_TOOL="none (ask in chat with numbered options)"
    TODO_TOOL="none (use a Markdown checklist or TODO.md)"
    TRANSCRIPTS="your harness's session directory"
    ;;
esac

ADAPTER="$PSTACK_ROOT/docs/harness/$HARNESS.md"
[ -f "$ADAPTER" ] || ADAPTER=""

# --- output -----------------------------------------------------------------

case "$MODE" in
  export)
    printf 'HARNESS=%s\n' "$HARNESS"
    printf 'ADAPTER=%s\n' "$ADAPTER"
    printf 'SKILLS_PROJECT=%s\n' "$SKILLS_PROJECT"
    printf 'SKILLS_USER=%s\n' "$SKILLS_USER"
    printf 'MODELS_FILE=%s\n' "$MODELS_FILE"
    printf 'ALWAYS_LOADED=%s\n' "$ALWAYS_LOADED"
    printf 'SUBAGENT_TOOL=%s\n' "$SUBAGENT_TOOL"
    printf 'QUESTION_TOOL=%s\n' "$QUESTION_TOOL"
    printf 'TODO_TOOL=%s\n' "$TODO_TOOL"
    printf 'TRANSCRIPTS=%s\n' "$TRANSCRIPTS"
    ;;
  json)
    printf '{"harness":"%s","adapter":"%s","skills_project":"%s","skills_user":"%s","models_file":"%s","always_loaded":"%s","subagent_tool":"%s","question_tool":"%s","todo_tool":"%s","transcripts":"%s"}\n' \
      "$HARNESS" "$ADAPTER" "$SKILLS_PROJECT" "$SKILLS_USER" "$MODELS_FILE" \
      "$ALWAYS_LOADED" "$SUBAGENT_TOOL" "$QUESTION_TOOL" "$TODO_TOOL" "$TRANSCRIPTS"
    ;;
  *)
    printf 'harness:         %s\n' "$HARNESS"
    if [ -n "$ADAPTER" ]; then
      printf 'adapter:         %s\n' "$ADAPTER"
    else
      printf 'adapter:         (not found; use the inline mapping in the skill)\n'
    fi
    printf 'skills project:  %s\n' "$SKILLS_PROJECT"
    printf 'skills user:     %s\n' "$SKILLS_USER"
    printf 'models file:     %s\n' "$MODELS_FILE"
    printf 'always loaded:   %s\n' "$ALWAYS_LOADED"
    printf 'subagent tool:   %s\n' "$SUBAGENT_TOOL"
    printf 'question tool:   %s\n' "$QUESTION_TOOL"
    printf 'todo tool:       %s\n' "$TODO_TOOL"
    printf 'transcripts:     %s\n' "$TRANSCRIPTS"
    ;;
esac