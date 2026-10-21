# pstack in any other harness

This adapter covers a harness pstack has no specific file for. It is the
fallback: work out what your harness calls things, map the Cursor names onto
it, and keep going.

The Agent Skills specification is the common ground. If your harness reads
`SKILL.md` files with `name` and `description` frontmatter, it can run
pstack's skills as they are.

## Detect

`scripts/harness-detect.sh` falls back to `generic` when it recognizes
nothing more specific. Force it when the guess is wrong:

```bash
PSTACK_HARNESS=generic scripts/harness-detect.sh
scripts/harness-detect.sh --harness generic
```

## Find the four things you need

Ask your harness these four questions, once per session. Everything else in
pstack follows from the answers.

1. **What is my subagent tool?** A tool that starts another agent with its own
   context. If there is none, do every delegated step yourself, in order.
2. **What is my structured-question tool?** A tool that asks the user a
   multiple-choice question. If there is none, ask in chat with numbered
   options.
3. **What is my task-list tool?** A tool that records a checklist. If there is
   none, keep the list in your reply and update it at each phase.
4. **Where does my harness keep skills, and where does it load instruction
   files from?** Those are the two paths you need.

## Tools

| Cursor | Generic |
|---|---|
| `Task` | Your subagent tool. Drop the parameters it does not have. |
| `AskQuestion` | Your structured-question tool, or plain chat with numbered options. |
| Open a todolist | Your task-list tool, a Markdown checklist, or the list in your reply. |
| `Grep`, `Glob` | `bash` with `rg` and `fd`. |
| Run another pstack skill | Read the sibling skill's `SKILL.md` and follow it. |

## Subagent fields

| Cursor | Generic |
|---|---|
| `subagent_type: generalPurpose` | A general-purpose subagent. |
| `poteto-agent`, `comment-sicko` | These are pstack's own agent files, in `agents/`. Where they are not registered as subagent types, spawn a general subagent whose prompt starts with: "Read the poteto-mode skill's SKILL.md in full, including its Principles section, before any work." Then give the task. For `comment-sicko`, pass `skills/no-comments/references/comment-sicko.md` verbatim as the prompt, then the scope. |
| `readonly: true` | A read-only mode, if your tool has one. Otherwise say "do not edit files" in the brief and check `git status` afterward. |
| `readonly: false` | The default. |
| `environment: "cloud"` | No equivalent. Run the worker locally in its own worktree. |
| `environment: "local"` | Omit. |
| `cloud_base_branch: <b>` | Tell the worker to check out `<b>` first. |
| `run_in_background: true` | A background or async mode, if your tool has one. Otherwise run it and wait. |
| `model` | A model slug your harness accepts. |
| `resume` | Start a new step and paste the earlier result into its brief. |
| `file_attachments` | List the paths in the brief. |

## Models

The per-role model choices live in `~/.agents/pstack-models.md`, one line per
role, plus a `# budget` line. Read it at task start. If the file or a role's
line is missing, use the skill's default slug.

Name a model the way your harness does. If a slug your harness rejects comes
back, use the same family's nearest valid slug from its error message or your
harness's model list, and say so. If a role's value is `auto` or
`inherit-parent`, omit the model so the step runs on the parent chat model.

The effort ladder pstack uses is `max` > `xhigh` > `high` > `medium` > `low`,
and the budget labels map onto it:

| pstack budget | Effort |
|---|---|
| `unlimited` | `max` |
| `large` | `xhigh` |
| `medium` | `high` |
| `small` | `medium` |

## Paths

| Cursor | Generic |
|---|---|
| `.cursor/skills/`, `~/.cursor/skills/` | `.agents/skills/` in the project, `~/.agents/skills/` for the user. Many harnesses also read `.claude/skills/`, `.codex/skills/`, `.pi/skills/`, or `.opencode/skill/`. |
| `~/.cursor/rules/*.mdc`, always-applied rules | Whatever your harness loads on every session. Often `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `CRUSH.md`, or a rules directory. |
| `~/.cursor/plugins/`, `.cursor-plugin/plugin.json` | No plugin system. Install skills into a skills directory. |
| `https://github.com/cursor/plugins/blob/main/pstack/<path>` | The local copy, when the repository is on disk. Read it and never fetch it. Give the user the URL when they need a link. |
| Transcripts in `~/.cursor/projects/<slug>/agent-transcripts/` | Your harness's session directory, scoped to this workspace. Never read another project's sessions. |

## Invoking a skill

Most pstack skills set `disable-model-invocation: true`, so they are meant to
be invoked by name. The form your harness uses is usually `/<name>`, but some
harnesses register skills as `/skill:<name>` and some prefix plugin commands.
Give the user the exact form your harness accepts.

To follow a sibling skill from inside another skill, read its `SKILL.md` and
follow it. Use a path relative to the skill directory.

## Cursor-only features

Your harness has none of these. When a step needs one, put one line in your
reply, `Skipped in <harness>: <step>. <reason>.`, then go on to the next
step. Do not stop, ask, or retry. When a later step needs what the skipped
step made, such as a URL or a key, leave a placeholder and name it in the
line.

| Cursor | Generic |
|---|---|
| Cursor Automations: routines, `update_state`, webhooks, `SendToUser` | Skip with the line. |
| Bugbot | Bugbot comments on a GitHub PR are ordinary review threads. Triage them with the forge command the step gives, usually `gh`. Skip a step that starts, waits for, or configures Bugbot when the PR has no Bugbot check. |
| Cursor cloud agents | `environment: "cloud"` maps to a local worktree. Skip a step that needs the cloud agent itself. |
| A built-in PR tool | Use the forge command the step gives, such as `gh pr create`. That is not a skip, so write no line. |
| `create-skill` | Use Anthropic's `skill-creator`, or follow the Agent Skills format at agentskills.io. |
| `deslop`, `control-cli`, `control-ui` from `cursor-team-kit` | No equivalent. Without `deslop`, reread the diff before commit and cut AI slop yourself. Without the control skills, drive the app with the automation you have: Playwright or a CDP browser for web and Electron, tmux or a PTY for CLIs and TUIs. |
| `/loop` | No builtin. Wait between checks with a timed shell command. |
