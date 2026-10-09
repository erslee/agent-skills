# dev-pipeline

An opinionated engineering workflow for Claude Code: two skills and the five subagents they delegate to.

## What's in it

**Skills**

- **`dev-pipeline`** — the full pipeline for a non-trivial coding task: repo check (detects the repo's design principles) → research → solution proposal (**approval gate**) → decomposition into tasks (**approval gate, task by task**) → implement → test & verify with a bounded fix-loop → commit → optional code review. It biases toward doing the work inline and spawns subagents only for parallelism, context isolation, or fresh eyes.
- **`commit`** — the git flow: branch off `dev` as `feature/{task_name}-short-description`, commit as `[{task_name}] Short description`, push, then kick off a background review of the commit. Branch name and commit message both require explicit approval.

**Agents** (`researcher`, `principal-developer`, `test-writer`, `code-reviewer`, `ui-tester`)

These ship with the plugin because `dev-pipeline` references them by name. Installing the skills without them leaves the pipeline calling agents that don't exist.

## Install

```
/plugin marketplace add erslee/agent-skills
/plugin install dev-pipeline@erslee-agent-skills
```

## Usage

Invoke explicitly with `/dev-pipeline <task>`, or let Claude pick it up from the skill description.

To make it automatic for every coding task, add this to your `~/.claude/CLAUDE.md`:

```markdown
## Coding task pipeline

For any non-trivial coding task (new feature, bug fix, refactor, migration — anything that
changes code across one or more files), invoke the `dev-pipeline` skill before starting work.

Do not invoke it for pure Q&A, explanations, read-only exploration, or a single trivial
one-line edit (typo, rename, string tweak) — just do those directly.
```

Plugins can't ship a `CLAUDE.md`, so that snippet is a manual step per machine.

## Assumptions worth knowing

The `commit` skill encodes one specific team's git flow. Fork the skill if yours differs:

- The integration branch is **`dev`** — it stashes, pulls, and branches off `dev`, and refuses to commit on `main`/`master`.
- Branch names are `feature/{task_name}-...`, commit subjects are `[{task_name}] ...`, single line, no body, no trailers.
- If `package.json` has an `fm:fix` script, it runs `npm run fm:fix` before committing.
- It never force-pushes, amends, or rewrites history.

## Local development (authoring machine)

Installing the plugin **copies** it into `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`,
pinned to a git SHA — even from a local-path marketplace. So an installed plugin never reflects
uncommitted edits; you'd have to bump the version and reinstall on every change.

For the machine where you actually edit these files, don't install the plugin. Symlink your
personal skill and agent paths at this repo instead — Claude Code follows symlinks for both
skill directories and agent files, so edits are live in the next session and `git status` in
this repo is the single source of truth:

```bash
REPO=~/dev/agent-skills/plugins/dev-pipeline

for s in dev-pipeline commit; do
  rm -rf ~/.claude/skills/$s
  ln -s "$REPO/skills/$s" ~/.claude/skills/$s
done

for a in researcher principal-developer test-writer code-reviewer ui-tester; do
  rm -f ~/.claude/agents/$a.md
  ln -s "$REPO/agents/$a.md" ~/.claude/agents/$a.md
done
```

Every *other* machine installs the plugin normally from the marketplace. Don't do both on the
same machine — you'll see each skill and agent listed twice.
