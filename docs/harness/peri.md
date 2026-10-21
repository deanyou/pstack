# pstack in Peri

Peri is a Claude Code-compatible harness. It reads the same skills, the same
context files, and the same plugin layout, so pstack ports over with almost
no rewriting. The one real difference is the model dialect.

This adapter is written against Peri 3.17.7.

## Detect

| Signal | Value |
|---|---|
| Process | `peri` in the ancestor chain, or a path under `~/.peri/` |
| Config home | `~/.peri/`, holding `settings.json`, `threads/`, `logs/`, `metrics/` |

`scripts/harness-detect.sh` matches both. Override it when the guess is
wrong:

```bash
PSTACK_HARNESS=peri scripts/harness-detect.sh
```

## Tools

| Cursor | Peri |
|---|---|
| `Task` | `Agent`, with `subagent_type: general-purpose`. |
| `AskQuestion` | `AskUserQuestion`. |
| Open a todolist | `TodoWrite`. |
| `Grep`, `Glob` | `Grep` and `Glob`, or `Bash` with `rg` and `fd`. |
| Run another pstack skill | Read the sibling skill's `SKILL.md` and follow it. See **Invoking a skill** below. |

## Subagent fields

| Cursor | Peri |
|---|---|
| `subagent_type: generalPurpose` | `subagent_type: general-purpose`. |
| `poteto-agent`, `comment-sicko` | Not registered here. Spawn a general subagent whose prompt starts with: "Read the poteto-mode skill's SKILL.md in full, including its Principles section, before any work." Then give the task. For `comment-sicko`, pass `skills/no-comments/references/comment-sicko.md` verbatim, then the scope. |
| `readonly: true` | The subagent's read-only option. |
| `readonly: false` | The default. |
| `environment: "cloud"` | No equivalent. Run the worker locally in its own worktree. |
| `environment: "local"` | Omit. |
| `run_in_background: true` | Omit. Peri subagents run in the background by default and notify you when they finish. |
| `model` | A model alias plus an effort, see **Models**. |
| `resume` | Start a new subagent and paste the earlier result into its brief. |
| `file_attachments` | List the paths in the prompt. |

## Models

Config lives in `~/.peri/settings.json`.

| Cursor | Peri |
|---|---|
| `claude-<family>-<version>-<effort>`, such as `claude-opus-5-5-xhigh` | `opus max`, `sonnet high`, `haiku low`. The alias is `opus`, `sonnet`, `haiku`, or `fable`; the effort is `low`, `medium`, `high`, or `max`. |
| A `grok-*`, `gpt-*`, or other non-Claude slug | Not available. Omit the model so the subagent runs on the session model, and say so. |
| `auto` or `inherit-parent` | Omit the model so the step runs on the session model. |
| A role value `<model> <effort>` | An alias plus an effort, such as `opus max`. |

Peri's effort ladder stops at `max`. It has no `xhigh` step, so pstack's
budget labels map onto it as:

| pstack budget | Peri effort |
|---|---|
| `unlimited` | `max` |
| `large` | `max` |
| `medium` | `high` |
| `small` | `medium` |

Per-role model choices live in `~/.agents/pstack-models.peri.md`, with the
shared `~/.agents/pstack-models.md` as a fallback. Read it at task start.
`/setup-pstack` writes a pointer to it in `~/.peri/CLAUDE.md`.

## Paths

| Cursor | Peri |
|---|---|
| `.cursor/skills/`, `~/.cursor/skills/` | `.claude/skills/` in the project, `~/.claude/skills/` for the user. Peri shares Claude Code's skill folders, so the same install serves both. |
| `~/.cursor/rules/*.mdc` | `~/.peri/CLAUDE.md` for the user, plus `CLAUDE.md`, `CLAUDE.local.md`, or `AGENTS.md` in the project. |
| `~/.cursor/plugins/` | `peri plugin`. Peri also understands `CLAUDE_PLUGIN_ROOT` and the Claude Code plugin layout. |
| Transcripts | `~/.peri/threads/threads.db`, a SQLite database with `threads`, `messages`, `projects`, and `workspaces` tables. Peri keeps no per-session JSONL. |
| Machine-wide config | `~/.peri/settings.json`, with `settings.local.json` for local overrides. `peri sync` pushes settings, skills, MCP servers, and plugins between machines. |

## Cursor-only features

| Cursor | Peri |
|---|---|
| Cursor Automations: routines, `update_state`, webhooks, `SendToUser` | Skip with one line: `Skipped in Peri: <step>. No automations here.` Then continue. |
| Bugbot | Bugbot comments on a GitHub PR are ordinary review threads. Triage them with `gh`. Skip a step that starts, waits for, or configures Bugbot when the PR has no Bugbot check. |
| Cursor cloud agents | Skip steps that need the cloud agent's dashboard; run workers in local worktrees instead. |
| A built-in PR tool | `gh pr create` and friends. Not a skip, so write no line. |
| `create-skill` | Follow the Agent Skills format at agentskills.io, or use a skill-authoring skill. |
| `deslop`, `control-cli`, `control-ui` | No equivalent. Reread the diff before commit yourself. Drive UIs with Playwright or a CDP browser, CLIs and TUIs with tmux or a PTY. |
| `/loop` | No builtin loop. Wait between checks with a timed shell command. |

## Invoking a skill

Peri registers each skill as a `/<name>` command, the same form Claude Code
uses:

```text
/poteto-mode
```

Most pstack skills set `disable-model-invocation: true` in their frontmatter,
which means Peri's model will not select them on its own. The user has to
invoke them by name. Tell the user to type `/poteto-mode`.

To follow a sibling skill from inside another skill, read its `SKILL.md` and
follow it. Use a path relative to the skill directory.
