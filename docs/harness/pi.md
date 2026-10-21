# pstack in Pi

Pi implements the [Agent Skills](https://agentskills.io) specification, so the
pstack skills load as they are. Pi has no subagent tool, no structured
question tool, and no todo tool in core, so most of pstack's fan-out becomes
sequential work in the same session.

This adapter is for Pi 1.1 or later. Facts here come from Pi's own docs in
`<agent-dir>/install/releases/<version>/node_modules/@earendil-works/pi-coding-agent/docs/`.

## Detect

Pi sets two process markers that child processes inherit:

| Variable | Value |
|---|---|
| `AI_AGENT` | `pi` |
| `PI_CODING_AGENT` | `true` |

The Pi shell tool also injects the live session state:

| Variable | Meaning |
|---|---|
| `PI_SESSION_ID` | Current session ID |
| `PI_SESSION_FILE` | Absolute path of the current session JSONL |
| `PI_PROVIDER` | Current model provider |
| `PI_MODEL` | Current model ID |
| `PI_REASONING_LEVEL` | `off`, `minimal`, `low`, `medium`, `high`, `xhigh`, or `max` |

`scripts/harness-detect.sh` reads these and reports `pi`. Inside Pi, ask
`printf '%s/%s\n' "$PI_PROVIDER" "$PI_MODEL"` for the exact model, rather
than inferring it.

## Tools

| Cursor | Pi |
|---|---|
| `Task` | No subagent tool in core. See **Subagents** below. |
| `AskQuestion` | None. Ask in chat with numbered options. |
| Open a todolist | None in core. Keep the list in your reply and update it at each phase, or write a Markdown checklist. |
| `Grep`, `Glob` | `bash` with `rg` and `fd`. |
| Run another pstack skill | `Read` the sibling skill's `SKILL.md` and follow it. See **Invoking a skill** below. |

## Subagents

Pi core ships no subagent tool. The optional `pi-subagents` package adds a
`subagent` tool with single-agent, chain, parallel, async, forked-context, and
resume workflows. Install it and use it, or do the work yourself.

```bash
pi install npm:pi-subagents
```

Without a subagent tool, run each delegated step in the main session, one
after another. Keep the brief, the scope, and the model in your own context
so the steps stay separable, and say so in the reply. Do not fabricate `Task`
calls.

### The `subagent` tool

The package's `subagent` tool takes `agent`, `task`, `model`, `async`, `cwd`,
`worktree`, `options.context`, and `action`. It ships these agents:

| Agent | Use it for |
|---|---|
| `scout` | Fast local codebase recon: relevant files, entry points, data flow, risks. |
| `researcher` | Web and docs research with sources. |
| `evidence-auditor` | Checks whether research claims are supported by their sources. |
| `worker` | Implementation work. |
| `reviewer` | Code review and small fixes. |
| `oracle` | A second opinion that challenges assumptions without editing. |
| `delegate` | A general delegate that behaves close to the parent session. |

`model` takes a `provider/id`, the same slug Pi itself uses, and a
`:thinking` suffix sets the child's thinking level, such as
`magpie/codex/gpt-6.1-sol:xhigh`. `options.context` picks `fresh`, `fork`, or
`profile`; `fresh` is the clean context pstack wants. `async: true` runs the
child in the background.

One quirk matters for pstack. On a fresh session, some models see a small
`subagents_enable` loader instead of the full `subagent` schema, because
adding a tool mid-conversation would break the provider's prompt cache. The
loader appears when the request or the instructions authorize delegation.
pstack's skills authorize it by asking for a subagent, so call the loader and
the `subagent` tool is there on the next model request.

### Mapping Cursor's subagent fields

| Cursor | Pi |
|---|---|
| `subagent_type: generalPurpose` | The `subagent` tool, if `pi-subagents` is installed. Otherwise do the step yourself. |
| `poteto-agent`, `comment-sicko` | Same. These are pstack's own agent files, not Pi's. Spawn a packaged agent such as `delegate` and put the poteto-mode instruction at the top of the task. |
| `readonly: true` | The `scout`, `researcher`, and `oracle` agents do not edit. Otherwise say "do not edit files" in the brief and check `git status` afterward. |
| `readonly: false` | The `worker` agent. |
| `environment: "cloud"` | No equivalent. Run the worker locally in its own worktree. |
| `environment: "local"` | Omit. |
| `cloud_base_branch: <b>` | Tell the worker to check out `<b>` first. |
| `run_in_background: true` | `async: true`. |
| `model` | A `provider/id` slug, optionally with a `:thinking` suffix. See **Models**. |
| `resume` | Start a new step and paste the earlier result into its brief. |
| `file_attachments` | List the paths in the brief. |

## Models

A Pi model is a provider and a model ID. The slug is `<provider>/<model-id>`,
for example `codex/gpt-6.1-sol`.

| Cursor | Pi |
|---|---|
| `claude-opus-5-5-xhigh` | The closest slug in your Pi model list. Pi's reasoning level is separate from the model, so pick the model and set `PI_REASONING_LEVEL`. |
| A `grok-*`, `gpt-*`, or other non-Claude slug | Same rule. Use the slug your provider exposes. |
| `auto` or `inherit-parent` | Omit the model so the step runs on the current session model. |
| A role value `<model> <effort>` | A model slug plus a reasoning level. |

The reasoning ladder in Pi is `off`, `minimal`, `low`, `medium`, `high`,
`xhigh`, `max`. pstack's budget labels map onto it:

| pstack budget | Pi reasoning level |
|---|---|
| `unlimited` | `max` |
| `large` | `xhigh` |
| `medium` | `high` |
| `small` | `medium` |

Where the model comes from:

| File | Holds |
|---|---|
| `~/.pi/agent/models.json` | Providers, their endpoints, and each provider's model list with `id`, `name`, `reasoning`, and `thinkingLevelMap`. |
| `~/.pi/agent/settings.json` | `defaultProvider`, `defaultModel`, `defaultThinkingLevel`. |
| `~/.pi/agent/auth.json` | API keys and OAuth credentials. |
| `~/.agents/pstack-models.pi.md` | pstack's per-role model choices, in Pi's `<provider>/<model-id>` dialect. The shared `~/.agents/pstack-models.md` is a fallback. Read it at task start. |

To list the models Pi can actually reach, read `models.json`, or run
`pi --list-models` if that flag exists in your version. Never write a slug you
have not confirmed.

## Paths

| Cursor | Pi |
|---|---|
| `.cursor/skills/`, `~/.cursor/skills/` | `.pi/skills/` in the project, `~/.pi/agent/skills/` for the user. Pi also reads `~/.agents/skills/` and `.agents/skills/`. |
| `~/.cursor/rules/*.mdc` | `~/.pi/agent/AGENTS.md`. See **Always-loaded files** below. |
| `~/.cursor/plugins/`, `.cursor-plugin/plugin.json` | No plugin system. Install skills into a skills directory. |
| `https://github.com/cursor/plugins/blob/main/pstack/<path>` | The local copy, when the repository is on disk. Read it and never fetch it. Give the user the URL when they need a link. |
| Transcripts in `~/.cursor/projects/<slug>/agent-transcripts/` | `~/.pi/agent/sessions/--<slug>--/<timestamp>_<id>.jsonl`, where `<slug>` is the workspace path with the leading slash dropped and each `/` turned into `-`, wrapped in `--`. `/Users/dean/proj` becomes `--Users-dean-proj--`. |

Pi also reads the Agent Skills locations `~/.agents/skills/` and
`.agents/skills/`. Project `.agents/skills/` directories are discovered from
the working directory through its ancestors, stopping at the repository root.

### Always-loaded files

Pi loads context files from the agent directory, the working directory, and
the working directory's parents. A context file applies to everything below
its directory.

| Path | Role |
|---|---|
| `~/.pi/agent/AGENTS.md` | User instructions across every project. |
| `~/.pi/agent/AGENTS.override.md` | Replaces `AGENTS.md` or `CLAUDE.md` in the same directory only. |
| `~/.pi/agent/CLAUDE.md` | Alternative name for the same slot. |
| `<project>/AGENTS.md` | Project instructions. |
| `.pi/SYSTEM.md` | Replaces Pi's default system prompt for the project. |
| `.pi/APPEND_SYSTEM.md` | Adds instructions to the system prompt. |

`/setup-pstack` writes the pointer to `~/.agents/pstack-models.pi.md` into
`~/.pi/agent/AGENTS.md`. Run `/reload` after editing it.

## Invoking a skill

Pi registers each skill as a `/skill:<name>` command:

```text
/skill:poteto-mode
```

Most pstack skills set `disable-model-invocation: true` in their frontmatter,
which means Pi's model will not select them on its own. The user has to
invoke them by name. Tell the user to type `/skill:poteto-mode`.

To follow a sibling skill from inside another skill, read its `SKILL.md` and
follow it. Use a path relative to the skill directory.

## Cursor-only features

Pi has no Cursor Automations, Bugbot, cloud agents, or built-in PR tool. When
a step needs one, put one line in your reply, `Skipped in Pi: <step>.
<reason>.`, then go on to the next step. Do not stop, ask, or retry.

| Cursor | Pi |
|---|---|
| Cursor Automations: routines, `update_state`, webhooks, `SendToUser` | Skip with the line. |
| Bugbot | Bugbot comments on a GitHub PR are ordinary review threads. Triage them with the forge command the step gives, usually `gh`. Skip a step that starts, waits for, or configures Bugbot when the PR has no Bugbot check. |
| Cursor cloud agents | `environment: "cloud"` maps to a local worktree. Skip a step that needs the cloud agent itself, such as its dashboard. |
| A built-in PR tool | Use the forge command the step gives, such as `gh pr create`. That is not a skip, so write no line. |
| `create-skill` | Use Anthropic's `skill-creator`, or follow the Agent Skills format at agentskills.io. |
| `deslop`, `control-cli`, `control-ui` from `cursor-team-kit` | No equivalent. Without `deslop`, reread the diff before commit and cut AI slop yourself. Without the control skills, drive the app with the automation you have: Playwright or a CDP browser for web and Electron, tmux or a PTY for CLIs and TUIs. |
| `/loop` | No builtin. Wait between checks with a timed shell command. |
