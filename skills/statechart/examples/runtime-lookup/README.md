# Runtime lookup verification

`RuntimeLookup.tla` models the selection policy in `scripts/run.ts:findTlc`.
TLC explores 48 input combinations, reaching 132 states. The seven invariants
and the deadlock check hold. The chart has six states and nine arrows.

Run from the repository root, supplying a new output directory outside the
repository:

```sh
skills/statechart/examples/runtime-lookup/verify.sh /tmp/statechart-runtime-check
```

The helper uses the regular statechart launcher and compares the generated
chart and report with `expected/`. Runtime setup follows the skill's documented
configuration or environment variables. It needs a TypeScript runtime and
Java/TLC; the model itself does not download anything.

| Rule | Promise |
| --- | --- |
| EnvironmentFirst | An explicit TLC path wins over configuration and mise. |
| LocalBeforeMise | A valid local configuration wins over mise. |
| JavaOverride | An explicit Java executable overrides other Java choices. |
| DefaultJava | Without a Java override, Java comes from the selected source, or PATH for an explicit TLC path. |
| NoUnnecessaryInstall | Installation happens only when no explicit or local runtime is selected and mise has no runtime. |
| InvalidConfigStops | An invalid selected local configuration fails instead of triggering installation. |
| CompleteSelection | Successful selection supplies both a jar and Java executable. |

The implementation searches the XDG runtime file before the default home
configuration. A missing XDG file permits the default file; an invalid existing
file stops lookup. The model's `config` input describes the first existing file
after this search. CLI tests separately exercise that filesystem search.

The diagram merges different input combinations into the same visible phase.
Its 48 hidden transitions are terminal self-loops. No other actions are hidden.
No rule breaks, so there is no counterexample path to replay against the code.

## Scope

This is a bounded selection-policy model. It abstracts environment values to
presence, local configuration to absent/valid/invalid, and mise to available or
installable. Installation success assumes that both pinned tools can then be
located. It does not prove filesystem permissions, executable compatibility,
artifact integrity, network reliability, concurrent config edits, or model
checker correctness.

`scripts/test/cli.test.ts` checks the actual implementation, including explicit
environment precedence, configured tools without environment variables, a
Java-only override, malformed JSON, relative paths, missing XDG configuration,
and invalid XDG configuration. The installed fixed runtime was also exercised
with the current shell environment, including its unusual XDG value.

## Mirror sync regression

The old `scripts/` exclusion in `mirror-paths.txt` matched directories at every
depth. A dry run against the pristine `cursor/plugins` snapshot `0f77cd5`
selected zero files under `skills/statechart/scripts/`. Anchoring the rule as
`/scripts/` selects all 405 upstream runtime and test files while preserving
the mirror-owned root scripts. This PR restores those files from that snapshot.

Run the sync regression against synthetic source and target folders:

```sh
node --test scripts/sync-exclusions.test.mjs
```
