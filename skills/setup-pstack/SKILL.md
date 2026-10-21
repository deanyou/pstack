---
name: setup-pstack
description: Configure which models pstack uses per role and at what reasoning budget. Detects your available models and writes an always-applied rule that overrides the skill defaults. Use for /setup-pstack, "configure pstack models", "pstack budget", or changing pstack's model choices.
---

# Setup pstack

Write pstack's model settings, one model per role.

- **Cursor:** `~/.cursor/rules/pstack-models.mdc`, an always-applied rule.
- **Claude Code:** the same role lines in `~/.claude/rules/pstack-models.md`. Claude Code loads every `.md` in `~/.claude/rules/` into each new session, so no pointer is needed.
- **Every other harness** (Codex, Pi, OMP, Peri, OpenCode, and others): `~/.agents/pstack-models.<harness>.md`, where `<harness>` is your harness's name (`codex`, `pi`, `omp`, `peri`, `opencode`, `gemini-cli`, `crush`, `generic`). One file per harness, because model slugs are not portable: Codex takes a bare slug such as `gpt-6.1-sol`, Pi and OMP take `<provider>/<model-id>` such as `magpie/codex/gpt-6.1-sol`, and OpenCode takes its own provider ids. A file shared by every harness hands each one slugs it cannot resolve.
- **Shared fallback:** `~/.agents/pstack-models.md`. A harness with no file of its own reads this one. It holds whichever dialect last ran this skill, so treat its slugs as a starting point and map them onto your own.

"The settings file" below means your harness's own file, then the shared fallback. When reading, take the first that exists. When writing, write your harness's own file, and refresh the shared fallback so a harness with no file yet has a starting point.

## Steps

### 1. Detect available models

Enumerate the model slugs you can pass to a subagent in this session (Cursor `Task`, Claude Code `Agent`, OpenCode `task`, Codex `spawn_agent`). That is the dependable source. If your harness also has a command that lists the user's models, prefer it for completeness (for example `opencode models` or `pi --list-models`). If you cannot detect any, ask the user to paste the slugs they have access to. Never write a real slug you have not confirmed is available. The aliases `inherit-parent` and `auto` are always valid even though they are not detected slugs.

### 2. Load current state

The default role-to-model mapping is the rule shape shown in step 5 below. If the settings file already exists, read it and treat its `# budget` line and its role values as the current choices. Otherwise start from those defaults. A line whose role is not in step 5, such as `how critics`, is from a retired role. Drop it.

### 3. Budget, map, and confirm

**(a) Ask for a budget.** Prefer your structured-question tool (`AskQuestion` in Cursor, `AskUserQuestion` in Claude Code, `question` in OpenCode) over free text. Offer these four options with these exact labels, and name the current budget when the rule records one. With no rule, say that `large` matches the skill defaults.

- `unlimited — max reasoning`
- `large — xhigh reasoning`
- `medium — high reasoning`
- `small — medium reasoning`

**(b) Apply it.** Build the working table from the skill defaults, and on a re-run keep any role you changed by family, list, or alias (`inherit-parent`, `auto`). `unlimited`, `large`, `medium`, and `small` set the effort token of every real slug, panel entries included, to `max`, `xhigh`, `high`, or `medium`. The effort token is the last token, or the one before a trailing `fast`, on the ladder `max` > `xhigh` > `high` > `medium` > `low`. If the result is not a detected slug, use the same family's detected slug with the highest effort at or below the target, else mark the role as needing a choice. `inherit-parent` and `auto` do not change. So `unlimited` turns `claude-opus-5-5-xhigh` into `claude-opus-5-5-max`. Grok slugs top out at `xhigh`, so under `unlimited` the fallback puts Grok at `xhigh` and keeps `grok-4.7-xhigh-fast` as it is. `large` keeps both defaults. `small` turns them into `claude-opus-5-5-medium` and `grok-4.7-medium-fast`.

**(c) Show the roles and confirm.** Show every role with its model, marking any real slug not in the detected set as needing a choice. Also list each line step 2 dropped. Ask whether to accept as-is or change specific roles, offering the detected models plus `inherit-parent` and `auto` (both mean: this role runs on the parent chat model, which is how Auto users stay on Auto) as the options. Prefer your structured-question tool over free text. For panel roles (arena runners, architect runners, interrogate reviewers) the value is a list, and one subagent runs per entry, alias entries included, so the list length sets the count. `arena cross-judge pool` is also a list, but Arena selects one value from it whose model family differs from the parent's when possible. `swarm workers` is the default model for every worker unless a race or comparison assigns another model per arm.

### 4. Validate

Every real slug written must be in the detected set. `inherit-parent` and `auto` always pass. If a chosen real slug is not available, stop and ask again.

### 5. Write the rule

Write the settings file with a `# budget` line with the chosen label and its target effort, and one line per role, using the same labels poteto-mode uses. In Cursor, include the frontmatter below with `alwaysApply: true`. In Claude Code, write `~/.claude/rules/pstack-models.md` with no frontmatter. In every other harness, write `~/.agents/pstack-models.<harness>.md` with no frontmatter (start at the first `#` line). Overwrite the whole file so re-runs stay idempotent. Write the shared fallback `~/.agents/pstack-models.md` with the same content when it is missing, so a harness with no file of its own has a starting point. Shape:

```
---
description: pstack per-role model choices (overrides skill defaults)
alwaysApply: true
---
# pstack model configuration. One line per role. Delete a line to fall back to the skill default.
# `inherit-parent` or `auto` as a value: the role runs on the parent chat model (omit the subagent `model`). Alias entries in a panel list still count toward its fan-out.
# budget: large (xhigh)
feature, refactoring: grok-4.7-xhigh-fast
bug-fix: grok-4.7-xhigh-fast
perf-issue: grok-4.7-xhigh-fast
hillclimb: grok-4.7-xhigh-fast
judgment and prose: claude-opus-5-5-xhigh
hardest tasks: claude-opus-5-5-xhigh
how explorer: grok-4.7-xhigh-fast
how explainer: claude-opus-5-5-xhigh
why investigators: grok-4.7-xhigh-fast
why synthesizer: claude-opus-5-5-xhigh
reflect tooling: grok-4.7-xhigh-fast
reflect judgment, divergent, synthesizer: claude-opus-5-5-xhigh
arena runners: claude-opus-5-5-xhigh, grok-4.7-xhigh-fast
arena cross-judge pool: claude-opus-5-5-xhigh, grok-4.7-xhigh-fast
swarm workers: grok-4.7-xhigh-fast
architect runners: claude-opus-5-5-xhigh, grok-4.7-xhigh-fast
interrogate reviewers: claude-opus-5-5-xhigh, grok-4.7-xhigh-fast
```

### 6. Point each harness at it

Only for harnesses other than Cursor and Claude Code. Their always-loaded file gets a pointer to your harness's settings file, so the roles are in context without the agent having to go looking. The pointer is a block between these two comment markers, and updating it is idempotent: if the markers are already in the file, replace the lines between them, otherwise append the block at the end.

```markdown
<!-- pstack:models:start -->
## pstack model configuration

Read your harness's pstack settings file at task start: `~/.agents/pstack-models.<harness>.md` if it exists, else `~/.agents/pstack-models.md`. It holds one line per role and a `# budget` line. A missing file or a missing role line means the skill's default model applies.
<!-- pstack:models:end -->
```

Write it into, in order of preference, the first path that exists:

| Harness | Always-loaded file |
|---|---|
| Codex | `~/.codex/AGENTS.md` |
| Pi | `~/.pi/agent/AGENTS.md` |
| OMP | `~/.agents/AGENTS.md`, or `~/.omp/AGENTS.md` |
| Peri | `~/.peri/CLAUDE.md` |
| OpenCode | `~/.config/opencode/AGENTS.md` |
| Gemini CLI | `~/.gemini/GEMINI.md` |
| Crush | `AGENTS.md` in the project root (Crush has no global instruction file) |
| Anything else | Its global `AGENTS.md` or equivalent, when one exists |

When no path exists, put one line in your reply, `Skipped in <harness>: pstack model pointer. No always-loaded file found.`, and go on. The skill still works: the skills read your harness's settings file directly when they pick a model.

### 7. Confirm

Tell the user which file was written. In Cursor, the rule applies to new sessions. In Claude Code, the rules file applies to new sessions. Elsewhere, pstack skills read `~/.agents/pstack-models.<harness>.md` when they pick a model, and the pointer in the harness's instruction file puts the roles in context from the first turn. Re-running this skill updates all of them.

### 8. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with /create-verification-skill." On yes, invoke `/create-verification-skill` (resolves wherever pstack is installed: workspace, user, or plugin). On no, move on without pushing.

### 9. Offer a formal verification skill (optional)

Check whether the project already has a formal verification skill (a project skill that runs a model checker, a proof, or another verifier against the code). If not, offer once: "want a formal verification skill, so agents can prove a key property of your code holds in every case in scope, not only the cases tests reach? I can generate one with /create-formal-verification-skill." On yes, invoke `/create-formal-verification-skill` (resolves wherever pstack is installed: workspace, user, or plugin). On no, move on without pushing.
