# pstack in Cursor

Cursor is pstack's home harness. The skills are written in Cursor's names, so
this adapter is mostly the identity mapping, plus a note on where the
Cursor-only features live.

If you are in Cursor, the skills need no translation. Read this once for the
paths and the Cursor-only feature list.

## Detect

Cursor's own agent names its tools `Task` and `AskQuestion`. `scripts/harness-detect.sh`
reports `cursor` when it finds a `.cursor/` directory in the working tree.

## Tools

| Cursor | Cursor |
|---|---|
| `Task` | `Task` |
| `AskQuestion` | `AskQuestion` |
| Open a todolist | The todolist tool. |
| Run another pstack skill | Read the sibling skill's `SKILL.md` and follow it, or tell the user to type `/<name>`. |

## Subagent fields

| Cursor | Cursor |
|---|---|
| `subagent_type: generalPurpose` | `generalPurpose` |
| `poteto-agent`, `comment-sicko` | The same names. pstack ships both as agent files in `agents/`, and the plugin registers them. |
| `readonly: true` | Read-only agent mode. It keeps `Bash`, so say "do not edit files" in the brief and check `git status` afterward. |
| `readonly: false` | Agent mode, with MCP servers. |
| `environment: "cloud"` | A Cursor cloud agent. |
| `environment: "local"` | A local agent. |
| `cloud_base_branch: <b>` | The base branch the cloud agent checks out. |
| `run_in_background: true` | Background the call. |
| `resume` | Resume the prior agent. |
| `file_attachments` | Attach the files. |

## Models

Cursor loads `~/.cursor/rules/pstack-models.mdc`, an always-applied rule,
automatically. Its role lines are already in context. `/setup-pstack` writes
that file. If it is missing, use the skill's default slug.

A Cursor model slug is `claude-<family>-<version>-<effort>[-fast]`, such as
`claude-opus-5-5-xhigh`, or a `grok-*` / `gpt-*` slug. The effort token is
the last token, or the one before a trailing `fast`, on the ladder `max` >
`xhigh` > `high` > `medium` > `low`.

## Paths

| Cursor | Cursor |
|---|---|
| `.cursor/skills/`, `~/.cursor/skills/` | The same. |
| `~/.cursor/rules/*.mdc`, always-applied rules | The same. `alwaysApply: true` in the frontmatter. |
| `~/.cursor/plugins/`, `.cursor-plugin/plugin.json` | The same. |
| Transcripts in `~/.cursor/projects/<slug>/agent-transcripts/` | The same. `<slug>` is the workspace path with the leading slash dropped and each `/` turned into `-`. |

## Invoking a skill

Cursor names pstack's skills directly. `/poteto-mode`, `/setup-pstack`,
`/how`, and so on.

To keep `/poteto-mode` on for the whole chat, pick it from the `/` menu with
Option+Enter on Mac or Alt+Enter on Windows instead of Enter. That makes it a
[Custom Mode](https://cursor.com/docs/skills#using-a-skill-as-a-custom-mode),
which stays in context on every turn until you exit it.

## Cursor-only features

These exist here, so a step that needs one runs rather than being skipped.
Other harnesses skip them with a one-line note.

| Feature | What it does |
|---|---|
| Cursor Automations | Routines, `update_state` routine calls, `api2.cursor.sh/automations` webhooks, routine wakes, `SendToUser` secret requests. |
| Bugbot | Agentic security review on a GitHub PR. Triage per `references/bugbot-triage.md`. Its comments are ordinary review threads, so the forge command handles them. |
| Cursor cloud agents | `environment: "cloud"`. The agent runs in Cursor's cloud, not on this machine. |
| Cursor's built-in PR tool | The step's own PR action. Elsewhere, use the forge command the step gives, such as `gh pr create`. |
| `create-skill` | Cursor's built-in skill-authoring skill. Elsewhere, use Anthropic's `skill-creator` or the Agent Skills format at agentskills.io. |
| `deslop`, `control-cli`, `control-ui` | From the `cursor-team-kit` plugin. `deslop` runs before commit. `control-cli` covers CLIs and TUIs, `control-ui` covers browser, Electron, and web UIs. |
| `/loop` | Cursor's built-in wake mechanism, used by the Autonomous run playbook. |
| Custom Modes | A skill that stays in context on every turn. |
