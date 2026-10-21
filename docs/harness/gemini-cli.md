# pstack in Gemini CLI

Gemini CLI is close to a plain Markdown harness: context files, extensions,
and a shell tool. What it does not have is a subagent tool, so pstack's fan-out
skills run their steps in sequence.

**Version note.** Facts here describe current Gemini CLI. This mirror verified
the installed CLI is `0.1.12`, which predates Agent Skills support: its bundle
contains no `SKILL.md` handling. On that version, install the skills as
Markdown instructions (see **Skills** below) rather than expecting Gemini to
discover them. Re-check with your own version before you rely on a row.

## Detect

`scripts/harness-detect.sh` reports `gemini-cli` from the `gemini` process in
its ancestor chain, or from a `.gemini/` directory in the working tree.

## Tools

| Cursor | Gemini CLI |
|---|---|
| `Task` | No subagent tool. Do each delegated step yourself, one after another. |
| `AskQuestion` | None. Ask in chat with numbered options. |
| Open a todolist | None. Keep the list in your reply, or a Markdown checklist, and update it at each phase. |
| `Grep`, `Glob` | `run_shell_command` with `rg` and `fd`. |
| Run another pstack skill | Read the sibling skill's `SKILL.md` and follow it. |

Gemini CLI has no subagent tool in core, so never fabricate a `Task` call.
Run the steps in the main session and say so in the reply: `No subagent tool
in Gemini CLI, so this ran in sequence.`

## Subagents

| Cursor | Gemini CLI |
|---|---|
| `subagent_type: generalPurpose` | Do the step yourself. |
| `readonly: true` | Do the step yourself, and do not edit files. Check `git status` after. |
| `environment: "cloud"` | No equivalent. If the work needs a worktree, create one with git yourself. |
| `run_in_background: true` | Do the step and wait. |

If your Gemini CLI install has a third-party subagent extension, treat it as
one exists: use its tool, drop parameters it lacks, and say which one you used.

## Models

| Cursor | Gemini CLI |
|---|---|
| `claude-opus-5-5-xhigh` | The nearest Gemini model slug. `gemini-2.5-pro` and `gemini-2.5-flash` are typical. |
| `auto` or `inherit-parent` | Omit `-m`, so the default model runs. |
| A role value `<model> <effort>` | A model plus its thinking level where the model supports one. |

Select a model with `-m/--model` or `settings.json`. Per-role choices live in
`~/.agents/pstack-models.gemini-cli.md`, with the shared
`~/.agents/pstack-models.md` as a fallback; read it at task start and map each
role onto the Gemini model that exists on your plan. Mark any role you cannot map as needing
a choice rather than inventing a slug.

## Skills

Gemini CLI discovers skills from `.gemini/skills/` in a project and
`~/.gemini/skills/` for the user, one folder per skill holding a `SKILL.md`,
when your version supports Agent Skills.

On a version without that support, the skills still work as instructions:
copy the skill folder anywhere, then Read its `SKILL.md` and follow it. That
is all a skill is, so nothing about pstack depends on discovery.

## Paths

| Cursor | Gemini CLI |
|---|---|
| `.cursor/skills/`, `~/.cursor/skills/` | `.gemini/skills/`, `~/.gemini/skills/` |
| `~/.cursor/rules/*.mdc` | `GEMINI.md` in the project and `~/.gemini/GEMINI.md` for the user |
| `~/.cursor/plugins/` | `~/.gemini/extensions/`, loaded with `-e/--extensions` |
| Transcripts | `~/.gemini/tmp/`, one subdirectory per workspace hash. Read only this workspace's. |

### Always-loaded files

| Path | Role |
|---|---|
| `~/.gemini/GEMINI.md` | User instructions across projects |
| `<project>/GEMINI.md` | Project instructions |

`/setup-pstack` writes a pointer to `~/.agents/pstack-models.gemini-cli.md` in
`~/.gemini/GEMINI.md`.

## Invoking a skill

Most pstack skills set `disable-model-invocation: true`, so they run when the
user types them. Tell the user the command their version shows. Otherwise say
to name the skill in the prompt, and the agent reads the `SKILL.md`.

## Cursor-only features

| Cursor | Gemini CLI |
|---|---|
| Cursor Automations | Skip with one line: `Skipped in Gemini CLI: <step>. No automations here.` |
| Bugbot | Triage GitHub PR review threads with `gh`. Skip a step that starts or configures Bugbot when the PR has no Bugbot check. |
| Cursor cloud agents | `environment: "cloud"` maps to a local worktree. |
| A built-in PR tool | `gh pr create`. Not a skip, so write no line. |
| `create-skill` | Follow the Agent Skills format at agentskills.io. |
| `deslop`, `control-cli`, `control-ui` | No equivalent. Reread the diff before commit yourself. Drive UIs with Playwright or a CDP browser, CLIs and TUIs with tmux or a PTY. |
| `/loop` | No builtin. Wait between checks with a timed shell command. |
