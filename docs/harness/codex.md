# pstack in Codex

Codex ships an Agent Skills system, a plan tool, managed worktrees, and a
collaboration tool set for spawning subagents. Most pstack skills port
directly. This adapter is for Codex 0.145 or later; version notes say where a
fact came from.

## Detect

`scripts/harness-detect.sh` reports `codex` from the `codex` process in its
ancestor chain, from a `CODEX_HOME` marker, or from a `.codex/` directory in
the working tree.

| Signal | Value |
|---|---|
| `CODEX_HOME` | Codex home directory, `~/.codex` by default |
| Process | `codex` (TUI), `codex-app-server` (shared daemon) |

## Tools

| Cursor | Codex |
|---|---|
| `Task` | `spawn_agent` for subagents. The app-server protocol spells these `spawnAgent`, `sendInput`, `resumeAgent`, `wait`, `closeAgent`, `sendMessage`, `followupTask`, `interruptAgent`, `listAgents`. Trust your actual tool list over any table here. |
| `AskQuestion` | None. Ask in chat with numbered options. |
| Open a todolist | `update_plan`, on by default (`tools.update_plan` in `config.toml`). |
| `Grep`, `Glob` | The shell tool with `rg` and `fd`. |
| Run another pstack skill | Read the sibling skill's `SKILL.md` and follow it. See **Skills** below. |

### Multi-agent must be enabled

Collaboration tools require the `multi_agent` feature. Check it before the
first fan-out:

```bash
codex features list | grep multi_agent
```

If it shows `false`, enable it:

```bash
codex features enable multi_agent
```

Which tool names and parameters you get depends on the multi-agent version
your model preset selects. Do not copy a tool name from this file or from an
old session without checking it against your live tool list.

## Subagent fields

| Cursor | Codex |
|---|---|
| `subagent_type: generalPurpose` | A general subagent. Codex attaches role files under `~/.codex/agents/` to isolated forks via `agent_type` on Codex 0.145+. |
| `poteto-agent`, `comment-sicko` | Not registered here. Spawn a general subagent whose prompt starts with: "Read the poteto-mode skill's SKILL.md in full, including its Principles section, before any work." Then give the task. For `comment-sicko`, pass `skills/no-comments/references/comment-sicko.md` verbatim, then the scope. |
| `readonly: true` | Spawn with `sandbox: "read-only"`. |
| `readonly: false` | The default workspace-write sandbox. |
| `environment: "cloud"` | Codex Cloud (`codex cloud`, experimental). Skip a step that needs the cloud agent's own dashboard or machine. Otherwise run the worker locally in its own worktree. |
| `environment: "local"` | Omit. |
| `run_in_background: true` | Codex spawns are async by default. Do not poll. |
| `model` | A model slug **and** `reasoning_effort`, both always explicit. Setting `model` alone resets the child's effort to that model's default. |
| `resume` | `resume_agent`, or `followup_task` for a fix round. |
| `file_attachments` | List the paths in the prompt. |

Spawn children with a clean context: `fork_turns: "none"`. The default copies
your entire transcript into the child.

Wait in bounded stretches with `wait_agent`, `timeout_ms` 300000 to 600000
(5 to 10 minutes). It is an event subscription, not a poll. While you still
have local work, do not wait at all: a finished child's answer arrives with
your next turn. Completion mail cannot wake an idle controller, so a bounded
wait is the only way to cover an idle window.

Cap fan-out with `agents.max_depth` and `agents.max_concurrent_threads_per_session`
in `config.toml`.

## Models

Config lives in `~/.codex/config.toml`.

| Cursor | Codex |
|---|---|
| `model` | `model = "..."` in `config.toml`, or `-m` on the CLI |
| A role value `<model> <effort>` | `model` plus `model_reasoning_effort` |
| `auto` or `inherit-parent` | Omit the child's model so it inherits the session model |

The reasoning effort ladder in Codex is `minimal` > `low` > `medium` > `high` >
`xhigh` > `max`. pstack's budget labels map onto it:

| pstack budget | Codex effort |
|---|---|
| `unlimited` | `max` |
| `large` | `xhigh` |
| `medium` | `high` |
| `small` | `medium` |

Per-role model choices live in `~/.agents/pstack-models.codex.md`, with the
shared `~/.agents/pstack-models.md` as a fallback. Read it at task start.
`/setup-pstack` writes a pointer to it in `~/.codex/AGENTS.md`.

A spawn only accepts models on its spawn allowlist. Never copy a model name
from a skill or an old session without checking it against your current
allowlist; a wrong name hard-errors. Set a backstop so a spawn that slips
through routes somewhere deliberate:

```toml
[agents]
default_subagent_model = "<a mid-tier model from your spawn allowlist>"
default_subagent_reasoning_effort = "medium"
```

## Skills

Codex discovers skills from three places:

| Scope | Path |
|---|---|
| Built-in | `~/.codex/skills/.system/` |
| User | `~/.codex/skills/` |
| Project | `.codex/skills/` and `.agents/skills/` |

A skill is a folder with a `SKILL.md`. Codex lists them through `skills/list`,
and pstack's skills carry `disable-model-invocation: true` where they should
only run when the user types them. To follow a sibling skill, read its
`SKILL.md` and follow it, with a path relative to the skill directory.

pstack skills ship as plain Agent Skills, so copying this repository's
`skills/` folder into `~/.codex/skills/` makes them visible.

## Paths

| Cursor | Codex |
|---|---|
| `.cursor/skills/`, `~/.cursor/skills/` | `.codex/skills/` or `.agents/skills/` in the project, `~/.codex/skills/` for the user |
| `~/.cursor/rules/*.mdc` | `~/.codex/AGENTS.md`, plus a project `AGENTS.md`. Both are loaded. |
| `~/.cursor/plugins/` | No plugin system. `codex plugin` manages Codex plugins, a different thing. |
| Transcripts | `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`. Not grouped by workspace: keep only files whose first line has `payload.cwd` equal to the workspace path. Also `codex resume`, `codex archive`, `codex fork`. |
| Worktrees | `codex --worktree` starts the session in a managed worktree (`worktrees` feature, stable on). |

Read only the active workspace's sessions, never other projects'.

## Cursor-only features

| Cursor | Codex |
|---|---|
| Cursor Automations: routines, `update_state`, webhooks, `SendToUser` | Skip with one line: `Skipped in Codex: <step>. No automations here.` Then continue. |
| Bugbot | Use `codex review` for a non-interactive review, and triage any GitHub PR review threads with `gh`. Skip a step that starts or configures Bugbot when the PR has no Bugbot check. |
| Cursor cloud agents | `codex cloud` is experimental. Skip steps that need its dashboard; run workers in local worktrees instead. |
| A built-in PR tool | `gh pr create` and friends. Not a skip, so write no line. |
| `create-skill` | Follow the Agent Skills format at agentskills.io, or use a skill-creator skill. |
| `deslop`, `control-cli`, `control-ui` | No equivalent. Reread the diff before commit yourself. Drive UIs with Playwright or a CDP browser, CLIs and TUIs with tmux or a PTY. |
| `/loop` | No builtin loop. Wait between checks with a timed shell command. |
