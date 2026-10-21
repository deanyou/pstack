# pstack in OMP

OMP is a pi-family harness. It loads the same Agent Skills spec as Pi,
registers skills the same way, and reads the same context files. It adds a
`task` tool for subagents, an `ask` tool for questions, role models, and a
plugin system. Most pstack skills port directly.

This adapter is written against OMP 18.12.3. Check your live tool list before
trusting a name here.

## Detect

OMP exports no harness marker. Verified in a clean environment: no
`AI_AGENT`, no `PI_CODING_AGENT`, no `PI_MODEL`, and no `OMP_*` variable
reaches the tool environment. Detect it by process instead.

| Signal | Value |
|---|---|
| Process | `omp` in the ancestor chain |
| Config home | `~/.omp/agent/`, holding `config.yml`, `models.yml`, `sessions/`, `extensions/`, `agents/` |

`scripts/harness-detect.sh` matches the `omp` process name. Override it when
the guess is wrong:

```bash
PSTACK_HARNESS=omp scripts/harness-detect.sh
```

Do not use the presence of `~/.omp/` as a signal. It stays on disk after the
last OMP session and would mislabel every other harness on the machine.

## Tools

| Cursor | OMP |
|---|---|
| `Task` | The `task` tool. It takes `agent_type`, `model`, `background`, `isolation`, and `resume`. Trust your live tool list over this table. |
| `AskQuestion` | The `ask` tool. |
| Open a todolist | The `todo` tool. |
| `Grep`, `Glob` | The `grep` and `glob` tools, or `bash` with `rg` and `fd`. |
| Run another pstack skill | Read the sibling skill's `SKILL.md` and follow it. See **Invoking a skill** below. |

## Subagent fields

| Cursor | OMP |
|---|---|
| `subagent_type: generalPurpose` | `agent_type`. OMP ships task agents as files under `~/.omp/agent/agents/`, listed by `omp agents`. |
| `poteto-agent`, `comment-sicko` | Not registered here. Spawn a general task agent whose prompt starts with: "Read the poteto-mode skill's SKILL.md in full, including its Principles section, before any work." Then give the task. For `comment-sicko`, pass `skills/no-comments/references/comment-sicko.md` verbatim, then the scope. |
| `readonly: true` | The `isolation` or `sandbox` field of the `task` tool, set to its read-only value. Check your tool schema for the exact name. |
| `readonly: false` | The default workspace-write setting. |
| `environment: "cloud"` | No equivalent. Run the worker locally in its own worktree. |
| `environment: "local"` | Omit. |
| `run_in_background: true` | `background: true`. |
| `model` | A model slug, see **Models**. |
| `resume` | The `resume` field of the `task` tool, or start a new agent and paste the earlier result into its brief. |
| `file_attachments` | List the paths in the prompt. |

## Models

Config lives in `~/.omp/agent/models.yml` and `~/.omp/agent/config.yml`.

| Cursor | OMP |
|---|---|
| `model` | A `<provider>/<model-id>` slug, such as `magpie/codex/gpt-6.1-sol`. |
| A role value `<model> <effort>` | A model slug plus a thinking level. |
| `auto` or `inherit-parent` | Omit the model so the step runs on the session model. |

The thinking ladder is `off`, `minimal`, `low`, `medium`, `high`, `xhigh`,
`max`, `auto`, set with `--thinking`. pstack's budget labels map onto it:

| pstack budget | OMP thinking |
|---|---|
| `unlimited` | `max` |
| `large` | `xhigh` |
| `medium` | `high` |
| `small` | `medium` |

OMP also has role models: `--smol` for fast work, `--slow` for analysis, and
`--plan` for planning. They are session defaults, not per-role pstack
settings.

Per-role model choices live in `~/.agents/pstack-models.omp.md`, with the
shared `~/.agents/pstack-models.md` as a fallback. Read it at task start.
`/setup-pstack` writes a pointer to it in `~/.agents/AGENTS.md`.

## Paths

| Cursor | OMP |
|---|---|
| `.cursor/skills/`, `~/.cursor/skills/` | `.agents/skills/` in the project, `~/.agents/skills/` for the user. OMP also reads `.agent/skills/`, `.claude/skills/`, `.codex/skills/`, `~/.codex/skills/`, `~/.config/opencode/skills/`, `.opencode/skills/`, and `.github/skills/`. |
| `~/.cursor/rules/*.mdc` | `AGENTS.md` from `.agent/` and `.agents/`, in the project and in the user home. OMP also reads `AGENTS.md` from `.omp/`, `~/.config/opencode/`, and `~/.codex/AGENTS.md` (user level only), `CLAUDE.md` from `.claude/`, and `GEMINI.md` files. |
| `~/.cursor/plugins/` | `omp plugin`, and Claude Code marketplace plugins under `~/.claude/plugins/cache/`. |
| Transcripts | `~/.omp/agent/sessions/--<slug>--/session.jsonl`, where `<slug>` is the workspace path with the leading slash dropped and each `/` turned into `-`. Keep only the active workspace's files. `omp --restore` and `omp --export` work on them. |

## Cursor-only features

| Cursor | OMP |
|---|---|
| Cursor Automations: routines, `update_state`, webhooks, `SendToUser` | Skip with one line: `Skipped in OMP: <step>. No automations here.` Then continue. |
| Bugbot | Bugbot comments on a GitHub PR are ordinary review threads. Triage them with `gh`. Skip a step that starts, waits for, or configures Bugbot when the PR has no Bugbot check. |
| Cursor cloud agents | Skip steps that need the cloud agent's dashboard; run workers in local worktrees instead. |
| A built-in PR tool | `gh pr create` and friends. Not a skip, so write no line. |
| `create-skill` | Follow the Agent Skills format at agentskills.io, or use a skill-authoring skill. |
| `deslop`, `control-cli`, `control-ui` | No equivalent. Reread the diff before commit yourself. Drive UIs with Playwright or a CDP browser, CLIs and TUIs with tmux or a PTY. |
| `/loop` | No builtin loop. Wait between checks with a timed shell command. |

## Invoking a skill

OMP registers each skill as a `/skill:<name>` command:

```text
/skill:poteto-mode
```

Most pstack skills set `disable-model-invocation: true` in their frontmatter,
which means OMP's model will not select them on its own. The user has to
invoke them by name. Tell the user to type `/skill:poteto-mode`.

To follow a sibling skill from inside another skill, read its `SKILL.md` and
follow it. Use a path relative to the skill directory.
