# pstack in OpenCode

OpenCode reads the Agent Skills format, and its tool names line up almost one
to one with what pstack skills assume. This adapter covers OpenCode 1.x.

## Detect

`scripts/harness-detect.sh` reports `opencode` from the `opencode` process in
its ancestor chain, or from an `.opencode/` directory in the working tree.

## Tools

| Cursor | OpenCode |
|---|---|
| `Task` | `task`, with `subagent_type` (default `general`), `description`, `prompt`, and `model`. |
| `AskQuestion` | `question`. |
| Open a todolist | `todowrite`. |
| Run another pstack skill | `skill`, or read the sibling's `SKILL.md` and follow it. |
| `Grep`, `Glob` | `grep` and `glob` are separate tools. There is also `shell`, `read`, `write`, `edit`, `patch`, `webfetch`. |

## Subagent fields

| Cursor | OpenCode |
|---|---|
| `subagent_type: generalPurpose` | `subagent_type: "general"` |
| `poteto-agent`, `comment-sicko` | Not registered. Spawn `general` whose prompt starts with: "Read the poteto-mode skill's SKILL.md in full, including its Principles section, before any work." For `comment-sicko`, pass `skills/no-comments/references/comment-sicko.md` verbatim, then the scope. |
| `readonly: true` | The `plan` agent type, if you use it, or say "do not edit files" in the brief and check `git status` afterward. |
| `readonly: false` | The default `general` agent. |
| `environment: "cloud"` | No equivalent. Run the worker locally in its own worktree. |
| `environment: "local"` | Omit. |
| `run_in_background: true` | Omit unless your `task` tool has an async mode. |
| `model` | A slug from `opencode models`. |
| `resume` | Start a new task and paste the earlier result into its prompt. |
| `file_attachments` | List the paths in the prompt. |

Custom agent types live in `.opencode/agent/*.md` (project) or
`~/.config/opencode/agent/*.md` (global). `opencode agent list` shows what is
registered, `opencode agent create` adds one.

## Models

A model is `<provider>/<model-id>`.

| Cursor | OpenCode |
|---|---|
| `claude-opus-5-5-xhigh` | The closest slug from `opencode models`. |
| `auto` or `inherit-parent` | Omit `model` on the `task` call. |
| A role value `<model> <effort>` | A slug, plus your harness's effort level where the provider supports one. |

Per-role choices live in `~/.agents/pstack-models.md`. Read it at task start.
`/setup-pstack` writes a pointer to it in `~/.config/opencode/AGENTS.md`.

Provider credentials and endpoints are in `~/.config/opencode/opencode.json`
(or `.jsonc`), alongside `opencode auth` for login state.

## Skills

OpenCode discovers skills by glob:

| Scope | Pattern |
|---|---|
| Project | `.opencode/skill/**/SKILL.md` **or** `.opencode/skills/**/SKILL.md` (both work) |
| Global | `~/.config/opencode/skills/**/SKILL.md` |
| External | `skills/**/SKILL.md` |

The `skill` tool loads one by name, and the error message lists what is
installed. Skills appear as `<available_skills>` in the system prompt.

## Paths

| Cursor | OpenCode |
|---|---|
| `.cursor/skills/`, `~/.cursor/skills/` | `.opencode/skill/` (or `skills/`) in the project, `~/.config/opencode/skills/` for the user |
| `~/.cursor/rules/*.mdc` | `~/.config/opencode/AGENTS.md` globally, `AGENTS.md` in the project. OpenCode reads `AGENTS.md` and `CLAUDE.md`. |
| `~/.cursor/plugins/` | `opencode plugin <module>` |
| Transcripts | `~/.local/share/opencode/storage/`. Sessions are JSON files under `session/<project-id>/`, messages under `message/`, parts under `part/`. `opencode session list` and `opencode export [sessionID]` work too. |
| Plans | `.opencode/plans/*.md` in a project. |

Read only the active workspace's sessions, never other projects'.

## Invoking a skill

pstack skills set `disable-model-invocation: true` where they should run only
when the user asks. The `skill` tool, or the `/skill` command, forces them.
Tell the user to type `/<name>` (their harness shows it as a skill command).

## Cursor-only features

| Cursor | OpenCode |
|---|---|
| Cursor Automations | Skip with one line: `Skipped in OpenCode: <step>. No automations here.` |
| Bugbot | Triage GitHub PR review threads with `gh`. Skip a step that starts or configures Bugbot when the PR has no Bugbot check. |
| Cursor cloud agents | `environment: "cloud"` maps to a local worktree. Skip steps needing the cloud agent's own dashboard. |
| A built-in PR tool | `gh pr create`. Not a skip, so write no line. |
| `create-skill` | Follow the Agent Skills format at agentskills.io, or use a skill-creator skill. |
| `deslop`, `control-cli`, `control-ui` | No equivalent. Reread the diff before commit yourself. Drive UIs with Playwright or a CDP browser, CLIs and TUIs with tmux or a PTY. |
| `/loop` | No builtin. Wait between checks with a timed shell command. |
