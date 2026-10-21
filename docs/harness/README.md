# pstack harness adapters

pstack was written for Cursor. Cursor's tool names, file paths, and model
slugs appear throughout the skills. Every other harness spells those things
differently, so each one gets an adapter here: a short table that says what
Cursor's name means in that harness and where the files live.

Read the adapter for your harness once per session, then apply it.

## Find your adapter

Run the detector from a pstack checkout:

```bash
scripts/harness-detect.sh
```

It prints the harness, the adapter path, and the paths pstack should use. It
detects the harness from the process that invoked it, then from environment
markers, then from a harness directory in the working tree. Override it when
the guess is wrong:

```bash
PSTACK_HARNESS=codex scripts/harness-detect.sh
scripts/harness-detect.sh --harness codex
```

The detector also emits machine-readable output:

```bash
scripts/harness-detect.sh --export    # KEY=VALUE lines, for eval
scripts/harness-detect.sh --json      # one JSON object
```

## Adapters

| Harness | Adapter | Skills, project | Skills, user | Always-loaded file |
|---|---|---|---|---|
| Claude Code | [claude-code.md](claude-code.md) | `.claude/skills/` | `~/.claude/skills/` | `~/.claude/rules/*.md` |
| Codex | [codex.md](codex.md) | `.codex/skills/` | `~/.codex/skills/` | `~/.codex/AGENTS.md` |
| Pi | [pi.md](pi.md) | `.pi/skills/` | `~/.pi/agent/skills/` | `~/.pi/agent/AGENTS.md` |
| OMP | [omp.md](omp.md) | `.agents/skills/` | `~/.agents/skills/` | `~/.agents/AGENTS.md` |
| OpenCode | [opencode.md](opencode.md) | `.opencode/skill/` | `~/.config/opencode/skills/` | `~/.config/opencode/AGENTS.md` |
| Gemini CLI | [gemini-cli.md](gemini-cli.md) | `.gemini/skills/` | `~/.gemini/skills/` | `~/.gemini/GEMINI.md` |
| Crush | [crush.md](crush.md) | `.crush/skills/` | `~/.config/crush/skills/` | `~/.config/crush/CRUSH.md` |
| Cursor | [cursor.md](cursor.md) | `.cursor/skills/` | `~/.cursor/skills/` | `~/.cursor/rules/*.mdc` |
| Anything else | [generic.md](generic.md) | `.agents/skills/` | `~/.agents/skills/` | whatever your harness loads |

`claude-code.md` is Cursor's own file, shipped upstream. The rest are this
mirror's.

## What every adapter covers

Each adapter answers the same six questions, in the same order. Read the one
that matches your harness and you have everything pstack needs.

1. **Tools.** What Cursor's `Task`, `AskQuestion`, and todolist mean here.
2. **Subagent fields.** How Cursor's `subagent_type`, `readonly`,
   `environment`, `model`, and `run_in_background` map onto your subagent
   tool, and which of them to drop.
3. **Models.** How to name a model and a reasoning level, and where the
   per-role model choices live.
4. **Paths.** Where skills, model rules, and session transcripts live.
5. **Cursor-only features.** What to skip, and the one-line note to print.
6. **Invoking another pstack skill.** What to type, and how to read a
   sibling skill's file.

## Conventions that hold everywhere

These four rules apply to every harness. An adapter never contradicts them.

**The model choices live in one file per harness.** Each harness reads
`~/.agents/pstack-models.<harness>.md`, with `~/.agents/pstack-models.md` as a
shared fallback, and the file holds one line per role plus a `# budget` line.
Cursor and Claude Code are the exceptions: they use their own always-loaded
rule, `~/.cursor/rules/pstack-models.mdc` and `~/.claude/rules/pstack-models.md`.
Every other harness gets a pointer to its file in its always-loaded
instruction file, so the roles are in context without the agent having to go
looking. `/setup-pstack` writes both.

One file per harness because model slugs are not portable. Codex takes a bare
slug such as `gpt-6.1-sol`, Pi and OMP take `<provider>/<model-id>` such as
`magpie/codex/gpt-6.1-sol`, and Claude Code takes `<model> <effort>` such as
`opus xhigh`. A file shared by every harness hands each one slugs it cannot
resolve, and the skills then fall back to their defaults without saying so.

**A skill that needs a sibling reads the sibling's file.** There is no
cross-skill tool call. Read `../<name>/SKILL.md` relative to the skill you
are in, or the skill's absolute path, and follow it.

**Name a skill the way your harness names it.** Claude Code prefixes plugin
commands, so `/pstack:poteto-mode`. Pi and OMP register skills as
`/skill:<name>`. Cursor and most others use `/<name>`. The adapter lists the
exact form.

**A missing capability is a skip, not a stop.** When a step needs something
your harness lacks, put one line in your reply, `Skipped in <harness>: <step>.
<reason>.`, then go on to the next step. Do not stop, do not ask, do not
retry. When a later step needs what the skipped step made, leave a
placeholder and name it in the line.

## The inline fallback

The adapters are deep reference. The skills also carry a one-line mapping
each, right where the Cursor name appears, so a skill still works when the
adapter is not on disk. That happens when the skills are installed on their
own, without this repository, through the `skills` CLI:

```bash
npx skills add backnotprop/pstack
```

If a skill's inline mapping and this directory disagree, the inline mapping
wins for that skill. Keep them in step when you change one.
