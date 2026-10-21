# pstack in Crush

Crush reads the Agent Skills standard, keeps configuration in `crush.json`, and
has no subagent tool, so pstack's fan-out steps run in sequence.

Verified against Crush 0.31.0 on macOS using `crush --help`, `crush dirs`, and
its bundled README.

## Detect

`scripts/harness-detect.sh` reports `crush` from the `crush` process in its
ancestor chain.

`crush dirs` prints the two directories that matter:

```text
~/.config/crush    # config
~/.local/share/crush   # data (sessions)
```

Override them with `CRUSH_GLOBAL_CONFIG` and `CRUSH_GLOBAL_DATA`.

## Tools

| Cursor | Crush |
|---|---|
| `Task` | No subagent tool. Do each delegated step yourself, one after another. |
| `AskQuestion` | None. Ask in chat with numbered options. |
| Open a todolist | None. Keep the list in your reply, or a Markdown checklist, and update it at each phase. |
| `Grep`, `Glob` | The shell tool with `rg` and `fd`. |
| Run another pstack skill | Read the sibling skill's `SKILL.md` and follow it. |

Never fabricate a `Task` call. Say in the reply: `No subagent tool in Crush,
so this ran in sequence.`

## Subagents

| Cursor | Crush |
|---|---|
| `subagent_type: generalPurpose` | Do the step yourself. |
| `readonly: true` | Do the step yourself, and do not edit files. Check `git status` after. |
| `environment: "cloud"` | No equivalent. Use `git worktree add` yourself when the step needs isolation. |
| `run_in_background: true` | Do the step and wait. |

## Models

Crush routes per provider through `crush.json`:

```jsonc
{
  "$schema": "https://charm.land/crush.json",
  "llm": { "provider": "...", "model": "...", "api_key": "..." }
}
```

| Cursor | Crush |
|---|---|
| `claude-opus-5-5-xhigh` | The nearest model your configured provider serves. |
| `auto` or `inherit-parent` | The session's current model. |
| A role value `<model> <effort>` | A model plus its reasoning level where the provider supports one. |

Per-role pstack choices live in `~/.agents/pstack-models.crush.md`, with the
shared `~/.agents/pstack-models.md` as a fallback. Read it at task start and
map each role onto a model your providers actually serve. Mark any
role you cannot map as needing a choice rather than inventing a slug.
`/setup-pstack` writes a pointer to it in `~/.config/crush/AGENTS.md` when
that file exists.

Switch models mid-session with `/models`; Crush preserves the conversation.

## Skills

Skills are folders with a `SKILL.md`, discovered from:

| Scope | Path |
|---|---|
| Global | `~/.config/crush/skills/` (override with `CRUSH_SKILLS_DIR`) |
| Extra | Any path in `options.skills_paths` in `crush.json`, including `./skills` |

```jsonc
{
  "options": { "skills_paths": ["~/.config/crush/skills", "./skills"] }
}
```

Copy this repository's `skills/` folder to `~/.config/crush/skills/`, or point
`skills_paths` at it. Crush advertises each skill's name and description and
activates one when the task calls for it.

## Paths

| Cursor | Crush |
|---|---|
| `.cursor/skills/`, `~/.cursor/skills/` | `~/.config/crush/skills/`, plus any `skills_paths` entry |
| `~/.cursor/rules/*.mdc` | `AGENTS.md` in the project (name configurable with `options.initialize_as`), created by `crush init` |
| `~/.cursor/plugins/` | No plugin system |
| Transcripts | `~/.local/share/crush/` |
| Config | `~/.config/crush/crush.json`, also `$HOME/.config/crush/crush.json` |

### Always-loaded files

Crush's context file is the project `AGENTS.md`, which `crush init` writes by
default. There is no separate global instruction file, so pstack's model
pointer goes into the project `AGENTS.md` when it exists, and setup notes the
skip when it does not.

## Invoking a skill

pstack skills set `disable-model-invocation: true` where they should run only
when the user asks. Tell the user to name the skill in their prompt, or type
`/<name>` if Crush registers it as a command.

`crush run "prompt"` is the non-interactive form, useful for one-shot setup
steps.

## Cursor-only features

| Cursor | Crush |
|---|---|
| Cursor Automations | Skip with one line: `Skipped in Crush: <step>. No automations here.` |
| Bugbot | Triage GitHub PR review threads with `gh`. Skip a step that starts or configures Bugbot when the PR has no Bugbot check. |
| Cursor cloud agents | `environment: "cloud"` maps to a local worktree. |
| A built-in PR tool | `gh pr create`. Not a skip, so write no line. |
| `create-skill` | Follow the Agent Skills format at agentskills.io. |
| `deslop`, `control-cli`, `control-ui` | No equivalent. Reread the diff before commit yourself. Drive UIs with Playwright or a CDP browser, CLIs and TUIs with tmux or a PTY. |
| `/loop` | No builtin. Wait between checks with a timed shell command. |
